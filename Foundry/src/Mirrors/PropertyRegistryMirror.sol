// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PropertyRegistryMirror
 * @author RoomFi Team - Firrton
 * @notice Mirror read-only del PropertyRegistry en Paseo, sincronizado via Hyperbridge ISMP
 * @dev Deployed en Moonbeam/Arbitrum para consultas locales de propiedades
 *
 * ARQUITECTURA:
 * - NO acuña PropertyNFTs (solo almacena metadatos)
 * - NO permite registro directo de propiedades
 * - Sincroniza solo propiedades VERIFIED y activas
 * - Gas-efficient para búsquedas y filtros
 *
 * FLUJO:
 * 1. Landlord registra propiedad en Paseo PropertyRegistry
 * 2. Propiedad es verificada → VERIFIED
 * 3. Paseo pallet-roomfi-bridge envía mensaje ISMP
 * 4. Hyperbridge propaga el mensaje
 * 5. ISMPMessageHandler actualiza este mirror
 * 6. DApps en Moonbeam/Arbitrum pueden consultar propiedades
 */

import "@openzeppelin/contracts/access/Ownable.sol";

contract PropertyRegistryMirror is Ownable {

    // Enums

    enum PropertyType {
        HOUSE,
        APARTMENT,
        ROOM,
        STUDIO,
        LOFT,
        SHARED_ROOM
    }

    enum VerificationStatus {
        VERIFIED,           // Solo sincronizamos propiedades verificadas
        EXPIRED,            // Verificación expiró
        SUSPENDED           // Suspendida
    }

    // Structs simplificados

    struct MirroredBasicInfo {
        string name;
        PropertyType propertyType;
        string city;
        string neighborhood;
        int256 latitude;
        int256 longitude;
    }

    struct MirroredFeatures {
        uint8 bedrooms;
        uint8 bathrooms;
        uint8 maxOccupants;
        uint16 squareMeters;
        uint256 amenities;          // Bitmask de amenities
    }

    struct MirroredFinancialInfo {
        uint256 monthlyRent;
        uint256 securityDeposit;
        bool utilitiesIncluded;
        bool furnishedIncluded;
    }

    struct MirroredReputation {
        uint32 rating;              // 0-100
        uint32 totalRentals;
        uint32 completedRentals;
        uint32 disputes;
    }

    struct MirroredPropertyBadges {
        bool verifiedOwnership;
        bool verifiedLocation;
        bool reliableLandlord;
        bool perfectScore;
        bool longTermProperty;
    }

    struct MirroredProperty {
        uint256 propertyId;
        address landlord;
        MirroredBasicInfo basicInfo;
        MirroredFeatures features;
        MirroredFinancialInfo financialInfo;
        MirroredReputation reputation;
        VerificationStatus status;
        string metadataURI;
        bool isActive;
        uint256 lastSyncTimestamp;
    }

    // Storage

    /// @notice Propiedades por ID
    mapping(uint256 => MirroredProperty) public properties;

    /// @notice Badges por propiedad
    mapping(uint256 => MirroredPropertyBadges) public propertyBadges;

    /// @notice Propiedades que existen en este mirror
    mapping(uint256 => bool) public propertyExists;

    /// @notice Propiedades por landlord
    mapping(address => uint256[]) public landlordProperties;

    /// @notice Lista de todas las propiedades sincronizadas
    uint256[] public allProperties;

    /// @notice Propiedades por ciudad (para búsqueda eficiente)
    mapping(bytes32 => uint256[]) public propertiesByCity;

    /// @notice Address del ISMPMessageHandler autorizado
    address public ismpMessageHandler;

    /// @notice Chain ID de la source chain (Paseo)
    uint256 public sourceChainId;

    /// @notice Último sync global
    uint256 public lastGlobalSync;

    /// @notice Total de propiedades sincronizadas
    uint256 public totalProperties;

    // Eventos

    event PropertySynced(
        uint256 indexed propertyId,
        address indexed landlord,
        string city,
        uint256 timestamp,
        bytes32 messageHash
    );

    event PropertyBadgesSynced(
        uint256 indexed propertyId,
        uint256 timestamp
    );

    event PropertyStatusUpdated(
        uint256 indexed propertyId,
        VerificationStatus newStatus,
        uint256 timestamp
    );

    event ISMPHandlerUpdated(
        address indexed oldHandler,
        address indexed newHandler
    );

    event SyncReceived(
        bytes32 indexed messageHash,
        uint256 timestamp
    );

    // Modifiers

    modifier onlyISMPHandler() {
        require(msg.sender == ismpMessageHandler, "PropertyMirror: Only ISMP handler");
        _;
    }

    modifier propertyMustExist(uint256 propertyId) {
        require(propertyExists[propertyId], "PropertyMirror: Property not synced");
        _;
    }

    // Constructor

    /**
     * @notice Inicializa el mirror contract
     * @param _ismpHandler Address del ISMPMessageHandler (puede ser 0x0, configurar después)
     * @param _sourceChainId Chain ID de Paseo (source)
     * @param initialOwner Owner del contrato
     */
    constructor(
        address _ismpHandler,
        uint256 _sourceChainId,
        address initialOwner
    ) Ownable(initialOwner) {
        // Permitir address(0) para configurar después con setISMPHandler
        ismpMessageHandler = _ismpHandler;
        sourceChainId = _sourceChainId;
        lastGlobalSync = block.timestamp;
    }

    // Funciones de sincronización (solo ISMP handler)

    /**
     * @notice Sincroniza o actualiza una propiedad completa
     * @dev Solo puede ser llamado por ISMPMessageHandler
     */
    function syncProperty(
        uint256 propertyId,
        address landlord,
        string calldata name,
        PropertyType propertyType,
        string calldata city,
        string calldata neighborhood,
        int256 latitude,
        int256 longitude,
        uint8 bedrooms,
        uint8 bathrooms,
        uint8 maxOccupants,
        uint16 squareMeters,
        uint256 amenities,
        uint256 monthlyRent,
        uint256 securityDeposit,
        bool utilitiesIncluded,
        bool furnishedIncluded,
        uint32 rating,
        uint32 totalRentals,
        uint32 completedRentals,
        uint32 disputes,
        string calldata metadataURI,
        bool isActive,
        bytes32 messageHash
    ) external onlyISMPHandler {
        require(landlord != address(0), "Invalid landlord");
        require(propertyId != 0, "Invalid property ID");

        // Si es primera vez, agregar a listas
        if (!propertyExists[propertyId]) {
            propertyExists[propertyId] = true;
            allProperties.push(propertyId);
            landlordProperties[landlord].push(propertyId);

            // Agregar a índice por ciudad
            bytes32 cityHash = keccak256(bytes(city));
            propertiesByCity[cityHash].push(propertyId);

            totalProperties++;
        }

        // Actualizar información completa
        properties[propertyId] = MirroredProperty({
            propertyId: propertyId,
            landlord: landlord,
            basicInfo: MirroredBasicInfo({
                name: name,
                propertyType: propertyType,
                city: city,
                neighborhood: neighborhood,
                latitude: latitude,
                longitude: longitude
            }),
            features: MirroredFeatures({
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                maxOccupants: maxOccupants,
                squareMeters: squareMeters,
                amenities: amenities
            }),
            financialInfo: MirroredFinancialInfo({
                monthlyRent: monthlyRent,
                securityDeposit: securityDeposit,
                utilitiesIncluded: utilitiesIncluded,
                furnishedIncluded: furnishedIncluded
            }),
            reputation: MirroredReputation({
                rating: rating,
                totalRentals: totalRentals,
                completedRentals: completedRentals,
                disputes: disputes
            }),
            status: VerificationStatus.VERIFIED,
            metadataURI: metadataURI,
            isActive: isActive,
            lastSyncTimestamp: block.timestamp
        });

        lastGlobalSync = block.timestamp;

        emit PropertySynced(propertyId, landlord, city, block.timestamp, messageHash);
        emit SyncReceived(messageHash, block.timestamp);
    }

    /**
     * @notice Sincroniza badges de una propiedad
     */
    function syncPropertyBadges(
        uint256 propertyId,
        bool verifiedOwnership,
        bool verifiedLocation,
        bool reliableLandlord,
        bool perfectScore,
        bool longTermProperty
    ) external onlyISMPHandler propertyMustExist(propertyId) {
        propertyBadges[propertyId] = MirroredPropertyBadges({
            verifiedOwnership: verifiedOwnership,
            verifiedLocation: verifiedLocation,
            reliableLandlord: reliableLandlord,
            perfectScore: perfectScore,
            longTermProperty: longTermProperty
        });

        emit PropertyBadgesSynced(propertyId, block.timestamp);
    }

    /**
     * @notice Actualiza solo la reputación de una propiedad
     * @dev Más gas-efficient que sync completo cuando solo cambió reputación
     */
    function syncPropertyReputation(
        uint256 propertyId,
        uint32 rating,
        uint32 totalRentals,
        uint32 completedRentals,
        uint32 disputes,
        bytes32 messageHash
    ) external onlyISMPHandler propertyMustExist(propertyId) {
        MirroredProperty storage prop = properties[propertyId];

        prop.reputation = MirroredReputation({
            rating: rating,
            totalRentals: totalRentals,
            completedRentals: completedRentals,
            disputes: disputes
        });

        prop.lastSyncTimestamp = block.timestamp;
        lastGlobalSync = block.timestamp;

        emit PropertySynced(
            propertyId,
            prop.landlord,
            prop.basicInfo.city,
            block.timestamp,
            messageHash
        );
    }

    /**
     * @notice Actualiza estado de disponibilidad
     */
    function syncPropertyStatus(
        uint256 propertyId,
        bool isActive,
        VerificationStatus status
    ) external onlyISMPHandler propertyMustExist(propertyId) {
        MirroredProperty storage prop = properties[propertyId];
        prop.isActive = isActive;
        prop.status = status;
        prop.lastSyncTimestamp = block.timestamp;

        emit PropertyStatusUpdated(propertyId, status, block.timestamp);
    }

    /**
     * @notice Batch sync para múltiples propiedades (gas efficient)
     */
    function batchSyncProperties(
        uint256[] calldata propertyIds,
        address[] calldata landlords,
        MirroredReputation[] calldata reputations,
        bool[] calldata activeStatus,
        bytes32 messageHash
    ) external onlyISMPHandler {
        require(propertyIds.length == landlords.length, "Length mismatch");
        require(propertyIds.length == reputations.length, "Length mismatch");
        require(propertyIds.length == activeStatus.length, "Length mismatch");
        require(propertyIds.length <= 20, "Batch too large");

        for (uint256 i = 0; i < propertyIds.length; i++) {
            uint256 propId = propertyIds[i];

            if (propertyExists[propId]) {
                properties[propId].reputation = reputations[i];
                properties[propId].isActive = activeStatus[i];
                properties[propId].lastSyncTimestamp = block.timestamp;

                emit PropertySynced(
                    propId,
                    landlords[i],
                    properties[propId].basicInfo.city,
                    block.timestamp,
                    messageHash
                );
            }
        }

        lastGlobalSync = block.timestamp;
        emit SyncReceived(messageHash, block.timestamp);
    }

    // View functions - Query de datos

    /**
     * @notice Obtiene información completa de una propiedad
     */
    function getProperty(uint256 propertyId)
        external
        view
        propertyMustExist(propertyId)
        returns (MirroredProperty memory)
    {
        return properties[propertyId];
    }

    /**
     * @notice Obtiene badges de una propiedad
     */
    function getPropertyBadges(uint256 propertyId)
        external
        view
        propertyMustExist(propertyId)
        returns (MirroredPropertyBadges memory)
    {
        return propertyBadges[propertyId];
    }

    /**
     * @notice Verifica si una propiedad está disponible para rentar
     */
    function isPropertyAvailable(uint256 propertyId)
        external
        view
        returns (bool)
    {
        if (!propertyExists[propertyId]) return false;

        MirroredProperty memory prop = properties[propertyId];
        return prop.isActive && prop.status == VerificationStatus.VERIFIED;
    }

    /**
     * @notice Obtiene propiedades de un landlord
     */
    function getLandlordProperties(address landlord)
        external
        view
        returns (uint256[] memory)
    {
        return landlordProperties[landlord];
    }

    /**
     * @notice Obtiene propiedades activas por ciudad
     */
    function getPropertiesByCity(string calldata city)
        external
        view
        returns (uint256[] memory)
    {
        bytes32 cityHash = keccak256(bytes(city));
        return propertiesByCity[cityHash];
    }

    /**
     * @notice Busca propiedades activas con filtros
     * @dev Gas intensive, usar con límite
     */
    function searchProperties(
        string calldata city,
        uint8 minBedrooms,
        uint256 maxRent,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory) {
        bytes32 cityHash = keccak256(bytes(city));
        uint256[] memory cityProps = propertiesByCity[cityHash];

        if (offset >= cityProps.length) {
            return new uint256[](0);
        }

        // Primera pasada: contar matches
        uint256 matchCount = 0;
        uint256 end = offset + limit > cityProps.length ? cityProps.length : offset + limit;

        for (uint256 i = offset; i < end; i++) {
            uint256 propId = cityProps[i];
            MirroredProperty memory prop = properties[propId];

            if (prop.isActive &&
                prop.status == VerificationStatus.VERIFIED &&
                prop.features.bedrooms >= minBedrooms &&
                prop.financialInfo.monthlyRent <= maxRent) {
                matchCount++;
            }
        }

        // Segunda pasada: llenar array
        uint256[] memory results = new uint256[](matchCount);
        uint256 currentIndex = 0;

        for (uint256 i = offset; i < end && currentIndex < matchCount; i++) {
            uint256 propId = cityProps[i];
            MirroredProperty memory prop = properties[propId];

            if (prop.isActive &&
                prop.status == VerificationStatus.VERIFIED &&
                prop.features.bedrooms >= minBedrooms &&
                prop.financialInfo.monthlyRent <= maxRent) {
                results[currentIndex] = propId;
                currentIndex++;
            }
        }

        return results;
    }

    /**
     * @notice Obtiene propiedades destacadas (mejor rating)
     */
    function getFeaturedProperties(uint256 limit)
        external
        view
        returns (uint256[] memory)
    {
        require(limit <= 50, "Limit too high");

        uint256 total = allProperties.length;
        if (total == 0) return new uint256[](0);

        // Encontrar propiedades con rating >= 90 y activas
        uint256[] memory featured = new uint256[](limit);
        uint256 count = 0;

        for (uint256 i = 0; i < total && count < limit; i++) {
            uint256 propId = allProperties[i];
            MirroredProperty memory prop = properties[propId];

            if (prop.isActive &&
                prop.status == VerificationStatus.VERIFIED &&
                prop.reputation.rating >= 90) {
                featured[count] = propId;
                count++;
            }
        }

        // Resize array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = featured[i];
        }

        return result;
    }

    /**
     * @notice Verifica si propiedad tiene un badge específico
     */
    function hasPropertyBadge(uint256 propertyId, string calldata badgeName)
        external
        view
        propertyMustExist(propertyId)
        returns (bool)
    {
        MirroredPropertyBadges memory badges = propertyBadges[propertyId];
        bytes32 badgeHash = keccak256(bytes(badgeName));

        if (badgeHash == keccak256("VERIFIED_OWNERSHIP")) return badges.verifiedOwnership;
        if (badgeHash == keccak256("VERIFIED_LOCATION")) return badges.verifiedLocation;
        if (badgeHash == keccak256("RELIABLE_LANDLORD")) return badges.reliableLandlord;
        if (badgeHash == keccak256("PERFECT_SCORE")) return badges.perfectScore;
        if (badgeHash == keccak256("LONG_TERM_PROPERTY")) return badges.longTermProperty;

        return false;
    }

    /**
     * @notice Verifica si datos están frescos
     */
    function isSyncFresh(uint256 propertyId, uint256 maxAge)
        external
        view
        propertyMustExist(propertyId)
        returns (bool)
    {
        return block.timestamp <= properties[propertyId].lastSyncTimestamp + maxAge;
    }

    /**
     * @notice Obtiene estadísticas del mirror
     */
    function getMirrorStats()
        external
        view
        returns (
            uint256 totalSynced,
            uint256 totalActive,
            uint256 lastSync,
            uint256 chainId
        )
    {
        // Contar propiedades activas
        uint256 active = 0;
        for (uint256 i = 0; i < allProperties.length; i++) {
            if (properties[allProperties[i]].isActive) {
                active++;
            }
        }

        return (totalProperties, active, lastGlobalSync, sourceChainId);
    }

    // Funciones de administración

    /**
     * @notice Actualiza el address del ISMP handler
     */
    function setISMPHandler(address newHandler) external onlyOwner {
        require(newHandler != address(0), "Invalid handler");
        address oldHandler = ismpMessageHandler;
        ismpMessageHandler = newHandler;
        emit ISMPHandlerUpdated(oldHandler, newHandler);
    }

    /**
     * @notice Actualiza el chain ID de la source chain
     */
    function setSourceChainId(uint256 newChainId) external onlyOwner {
        sourceChainId = newChainId;
    }

    /**
     * @notice Emergency: Permite al owner actualizar manualmente una propiedad
     */
    function emergencyUpdateProperty(
        uint256 propertyId,
        MirroredProperty calldata prop
    ) external onlyOwner {
        require(propertyId != 0, "Invalid property ID");

        if (!propertyExists[propertyId]) {
            propertyExists[propertyId] = true;
            allProperties.push(propertyId);
            landlordProperties[prop.landlord].push(propertyId);

            bytes32 cityHash = keccak256(bytes(prop.basicInfo.city));
            propertiesByCity[cityHash].push(propertyId);

            totalProperties++;
        }

        properties[propertyId] = prop;
        emit PropertySynced(propertyId, prop.landlord, prop.basicInfo.city, block.timestamp, bytes32(0));
    }
}
