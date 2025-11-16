// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TenantPassportMirror
 * @author RoomFi Team - Firrton
 * @notice Mirror read-only del TenantPassport en Paseo, sincronizado via Hyperbridge ISMP
 * @dev Deployed en Moonbeam/Arbitrum para consultas locales sin cross-chain calls
 *
 * ARQUITECTURA:
 * - NO acuña NFTs (solo almacena datos)
 * - NO permite cambios directos (solo via ISMP messages)
 * - Gas-efficient para queries
 * - Syncs automáticos desde Paseo
 *
 * FLUJO:
 * 1. Usuario en Paseo actualiza reputación (paga renta, etc)
 * 2. Paseo pallet-roomfi-bridge envía mensaje ISMP
 * 3. Hyperbridge propaga el mensaje
 * 4. ISMPMessageHandler en esta chain recibe el mensaje
 * 5. Handler actualiza este Mirror contract
 * 6. DApps en Moonbeam/Arbitrum leen datos actualizados
 */

import "@openzeppelin/contracts/access/Ownable.sol";

contract TenantPassportMirror is Ownable {

    // Struct simplificado de TenantInfo (solo datos relevantes para mirrors)
    struct MirroredTenantInfo {
        uint32 reputation;
        uint32 paymentsMade;
        uint32 paymentsMissed;
        uint32 propertiesRented;
        uint32 consecutiveOnTimePayments;
        uint32 totalMonthsRented;
        uint32 disputesCount;
        uint256 totalRentPaid;
        uint256 lastSyncTimestamp;
        bool isVerified;
    }

    // Badges simplificados (solo los más importantes para cross-chain)
    struct MirroredBadges {
        // KYC Badges
        bool verifiedID;
        bool verifiedIncome;
        bool cleanCredit;

        // Performance Badges
        bool reliableTenant;
        bool longTermTenant;
        bool zeroDisputes;
        bool highValue;
    }

    // Storage

    /// @notice Información de cada tenant por address (no tokenId aquí)
    mapping(address => MirroredTenantInfo) public tenantInfo;

    /// @notice Badges por tenant
    mapping(address => MirroredBadges) public tenantBadges;

    /// @notice Tenants que existen en este mirror
    mapping(address => bool) public tenantExists;

    /// @notice Lista de tenants sincronizados
    address[] public allTenants;

    /// @notice Address del ISMPMessageHandler autorizado para actualizar
    address public ismpMessageHandler;

    /// @notice Chain ID de la chain source (Paseo)
    uint256 public sourceChainId;

    /// @notice Último sync global
    uint256 public lastGlobalSync;

    /// @notice Total de tenants sincronizados
    uint256 public totalTenants;

    // Constantes

    uint32 private constant MAX_REPUTATION = 100;
    uint32 private constant MIN_REPUTATION = 0;

    // Eventos

    event TenantSynced(
        address indexed tenant,
        uint32 reputation,
        uint256 timestamp,
        bytes32 messageHash
    );

    event TenantBadgesSynced(
        address indexed tenant,
        uint256 timestamp
    );

    event ISMPHandlerUpdated(
        address indexed oldHandler,
        address indexed newHandler
    );

    event SyncReceived(
        bytes32 indexed messageHash,
        address indexed tenant,
        uint256 timestamp
    );

    // Modifiers

    modifier onlyISMPHandler() {
        require(msg.sender == ismpMessageHandler, "TenantMirror: Only ISMP handler");
        _;
    }

    modifier tenantMustExist(address tenant) {
        require(tenantExists[tenant], "TenantMirror: Tenant not synced");
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
     * @notice Sincroniza o actualiza información de un tenant
     * @dev Solo puede ser llamado por ISMPMessageHandler
     * @param tenant Address del tenant
     * @param reputation Reputación actualizada
     * @param paymentsMade Total de pagos hechos
     * @param paymentsMissed Total de pagos perdidos
     * @param propertiesRented Propiedades rentadas
     * @param consecutiveOnTimePayments Pagos consecutivos a tiempo
     * @param totalMonthsRented Meses totales rentados
     * @param disputesCount Disputas totales
     * @param totalRentPaid Total pagado en renta (wei)
     * @param isVerified Si está verificado
     * @param messageHash Hash del mensaje ISMP (para tracking)
     */
    function syncTenantInfo(
        address tenant,
        uint32 reputation,
        uint32 paymentsMade,
        uint32 paymentsMissed,
        uint32 propertiesRented,
        uint32 consecutiveOnTimePayments,
        uint32 totalMonthsRented,
        uint32 disputesCount,
        uint256 totalRentPaid,
        bool isVerified,
        bytes32 messageHash
    ) external onlyISMPHandler {
        require(tenant != address(0), "Invalid tenant address");
        require(reputation <= MAX_REPUTATION, "Invalid reputation");

        // Si es primera vez, agregar a lista
        if (!tenantExists[tenant]) {
            tenantExists[tenant] = true;
            allTenants.push(tenant);
            totalTenants++;
        }

        // Actualizar información
        tenantInfo[tenant] = MirroredTenantInfo({
            reputation: reputation,
            paymentsMade: paymentsMade,
            paymentsMissed: paymentsMissed,
            propertiesRented: propertiesRented,
            consecutiveOnTimePayments: consecutiveOnTimePayments,
            totalMonthsRented: totalMonthsRented,
            disputesCount: disputesCount,
            totalRentPaid: totalRentPaid,
            lastSyncTimestamp: block.timestamp,
            isVerified: isVerified
        });

        lastGlobalSync = block.timestamp;

        emit TenantSynced(tenant, reputation, block.timestamp, messageHash);
        emit SyncReceived(messageHash, tenant, block.timestamp);
    }

    /**
     * @notice Sincroniza badges de un tenant
     * @dev Solo puede ser llamado por ISMPMessageHandler
     */
    function syncTenantBadges(
        address tenant,
        bool verifiedID,
        bool verifiedIncome,
        bool cleanCredit,
        bool reliableTenant,
        bool longTermTenant,
        bool zeroDisputes,
        bool highValue
    ) external onlyISMPHandler tenantMustExist(tenant) {
        tenantBadges[tenant] = MirroredBadges({
            verifiedID: verifiedID,
            verifiedIncome: verifiedIncome,
            cleanCredit: cleanCredit,
            reliableTenant: reliableTenant,
            longTermTenant: longTermTenant,
            zeroDisputes: zeroDisputes,
            highValue: highValue
        });

        emit TenantBadgesSynced(tenant, block.timestamp);
    }

    /**
     * @notice Batch sync para múltiples tenants (gas efficient)
     * @dev Solo puede ser llamado por ISMPMessageHandler
     */
    function batchSyncTenants(
        address[] calldata tenants,
        MirroredTenantInfo[] calldata infos,
        bytes32 messageHash
    ) external onlyISMPHandler {
        require(tenants.length == infos.length, "Length mismatch");
        require(tenants.length <= 50, "Batch too large"); // Límite para evitar out-of-gas

        for (uint256 i = 0; i < tenants.length; i++) {
            address tenant = tenants[i];
            require(tenant != address(0), "Invalid tenant");

            if (!tenantExists[tenant]) {
                tenantExists[tenant] = true;
                allTenants.push(tenant);
                totalTenants++;
            }

            tenantInfo[tenant] = infos[i];
            tenantInfo[tenant].lastSyncTimestamp = block.timestamp;

            emit TenantSynced(tenant, infos[i].reputation, block.timestamp, messageHash);
        }

        lastGlobalSync = block.timestamp;
        emit SyncReceived(messageHash, address(0), block.timestamp);
    }

    // View functions - Query de datos

    /**
     * @notice Obtiene información completa de un tenant
     */
    function getTenantInfo(address tenant)
        external
        view
        tenantMustExist(tenant)
        returns (MirroredTenantInfo memory)
    {
        return tenantInfo[tenant];
    }

    /**
     * @notice Obtiene badges de un tenant
     */
    function getTenantBadges(address tenant)
        external
        view
        tenantMustExist(tenant)
        returns (MirroredBadges memory)
    {
        return tenantBadges[tenant];
    }

    /**
     * @notice Obtiene reputación de un tenant
     */
    function getReputation(address tenant)
        external
        view
        tenantMustExist(tenant)
        returns (uint32)
    {
        return tenantInfo[tenant].reputation;
    }

    /**
     * @notice Verifica si un tenant tiene reputación mínima
     */
    function hasMinimumReputation(address tenant, uint32 minReputation)
        external
        view
        returns (bool)
    {
        if (!tenantExists[tenant]) return false;
        return tenantInfo[tenant].reputation >= minReputation;
    }

    /**
     * @notice Obtiene métricas del tenant
     */
    function getTenantMetrics(address tenant)
        external
        view
        tenantMustExist(tenant)
        returns (
            uint32 reputation,
            uint32 totalPayments,
            uint32 successRate,
            uint256 totalPaid,
            bool isActive
        )
    {
        MirroredTenantInfo memory info = tenantInfo[tenant];

        reputation = info.reputation;
        totalPayments = info.paymentsMade + info.paymentsMissed;

        // Success rate en basis points (10000 = 100%)
        if (totalPayments > 0) {
            successRate = uint32((uint256(info.paymentsMade) * 10000) / totalPayments);
        } else {
            successRate = 0;
        }

        totalPaid = info.totalRentPaid;

        // Considerar activo si se sincronizó en las últimas 24 horas
        isActive = block.timestamp <= info.lastSyncTimestamp + 24 hours;

        return (reputation, totalPayments, successRate, totalPaid, isActive);
    }

    /**
     * @notice Verifica si un tenant tiene un badge específico
     */
    function hasBadge(address tenant, string calldata badgeName)
        external
        view
        tenantMustExist(tenant)
        returns (bool)
    {
        MirroredBadges memory badges = tenantBadges[tenant];

        bytes32 badgeHash = keccak256(bytes(badgeName));

        if (badgeHash == keccak256("VERIFIED_ID")) return badges.verifiedID;
        if (badgeHash == keccak256("VERIFIED_INCOME")) return badges.verifiedIncome;
        if (badgeHash == keccak256("CLEAN_CREDIT")) return badges.cleanCredit;
        if (badgeHash == keccak256("RELIABLE_TENANT")) return badges.reliableTenant;
        if (badgeHash == keccak256("LONG_TERM_TENANT")) return badges.longTermTenant;
        if (badgeHash == keccak256("ZERO_DISPUTES")) return badges.zeroDisputes;
        if (badgeHash == keccak256("HIGH_VALUE")) return badges.highValue;

        return false;
    }

    /**
     * @notice Cuenta badges activos de un tenant
     */
    function getBadgeCount(address tenant)
        external
        view
        tenantMustExist(tenant)
        returns (uint256 count)
    {
        MirroredBadges memory badges = tenantBadges[tenant];

        count = 0;
        if (badges.verifiedID) count++;
        if (badges.verifiedIncome) count++;
        if (badges.cleanCredit) count++;
        if (badges.reliableTenant) count++;
        if (badges.longTermTenant) count++;
        if (badges.zeroDisputes) count++;
        if (badges.highValue) count++;

        return count;
    }

    /**
     * @notice Obtiene todos los tenants sincronizados (paginado)
     */
    function getAllTenants(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        uint256 total = allTenants.length;
        if (offset >= total) {
            return new address[](0);
        }

        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }

        address[] memory result = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = allTenants[i];
        }

        return result;
    }

    /**
     * @notice Verifica si datos están frescos (sincronizados recientemente)
     */
    function isSyncFresh(address tenant, uint256 maxAge)
        external
        view
        tenantMustExist(tenant)
        returns (bool)
    {
        return block.timestamp <= tenantInfo[tenant].lastSyncTimestamp + maxAge;
    }

    /**
     * @notice Obtiene estadísticas globales del mirror
     */
    function getMirrorStats()
        external
        view
        returns (
            uint256 totalSynced,
            uint256 lastSync,
            uint256 chainId
        )
    {
        return (totalTenants, lastGlobalSync, sourceChainId);
    }

    // Funciones de administración

    /**
     * @notice Actualiza el address del ISMP handler
     * @dev Solo owner puede cambiar esto
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
     * @notice Emergency: Permite al owner actualizar manualmente datos
     * @dev Solo para casos extremos de desincronización
     */
    function emergencyUpdateTenant(
        address tenant,
        MirroredTenantInfo calldata info
    ) external onlyOwner {
        require(tenant != address(0), "Invalid tenant");

        if (!tenantExists[tenant]) {
            tenantExists[tenant] = true;
            allTenants.push(tenant);
            totalTenants++;
        }

        tenantInfo[tenant] = info;
        emit TenantSynced(tenant, info.reputation, block.timestamp, bytes32(0));
    }
}
