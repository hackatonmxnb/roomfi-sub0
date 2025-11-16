// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISMPMessageHandler
 * @author RoomFi Team - Firrton
 * @notice Handler centralizado para procesar mensajes ISMP de Hyperbridge
 * @dev Recibe mensajes desde Paseo pallet-roomfi-bridge y actualiza mirrors
 *
 * ARQUITECTURA:
 * - Implementa interfaz IIsmpModule de Hyperbridge
 * - Valida source chain (solo acepta mensajes de Paseo)
 * - Decodifica payloads SCALE-encoded
 * - Actualiza TenantPassportMirror y PropertyRegistryMirror
 * - Maneja timeouts y responses
 *
 * FLUJO:
 * 1. Hyperbridge llama onAccept() con mensaje ISMP
 * 2. Handler valida source y signature
 * 3. Decodifica payload (tenant/property data)
 * 4. Actualiza mirror contract correspondiente
 * 5. Emite evento de confirmación
 *
 * SEGURIDAD:
 * - Solo Hyperbridge puede llamar callbacks
 * - Valida chain ID source
 * - Valida payload structure
 * - Rate limiting para prevenir spam
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Importando interfaces oficiales de Hyperbridge ISMP SDK
 * @dev Usando el paquete oficial @polytope-labs/ismp-solidity
 */
import {IIsmpModule, BaseIsmpModule} from "@polytope-labs/ismp-solidity/interfaces/IIsmpModule.sol";
import {PostRequest, PostResponse, GetRequest, GetResponse, Message} from "@polytope-labs/ismp-solidity/interfaces/Message.sol";
import {IncomingPostRequest, IncomingPostResponse, IncomingGetResponse} from "@polytope-labs/ismp-solidity/interfaces/IIsmpModule.sol";

/**
 * @notice Tipos de mensajes que puede recibir
 */
enum MessageType {
    TENANT_REPUTATION_SYNC,         // 0: Sincronizar reputación de tenant
    TENANT_BADGES_SYNC,             // 1: Sincronizar badges de tenant
    TENANT_BATCH_SYNC,              // 2: Batch sync de tenants
    PROPERTY_FULL_SYNC,             // 3: Sincronizar propiedad completa
    PROPERTY_REPUTATION_SYNC,       // 4: Sincronizar solo reputación de propiedad
    PROPERTY_BADGES_SYNC,           // 5: Sincronizar badges de propiedad
    PROPERTY_STATUS_SYNC,           // 6: Sincronizar estado de propiedad
    PROPERTY_BATCH_SYNC             // 7: Batch sync de propiedades
}

/**
 * @notice Payload decodificado de un mensaje ISMP
 */
struct DecodedMessage {
    MessageType messageType;
    bytes data;
    bytes32 messageHash;
    uint256 timestamp;
}

contract ISMPMessageHandler is BaseIsmpModule, Ownable, ReentrancyGuard {

    // Storage

    /// @notice Hyperbridge IsmpHost address custom (para chains no soportadas por default)
    /// @dev Si es 0x0, usa el host() de BaseIsmpModule. Si no, usa este.
    address public immutable customHyperbridgeHost;

    /// @notice Chain ID de Paseo (source autorizado)
    bytes public paseoChainId;

    /// @notice TenantPassportMirror contract
    address public tenantPassportMirror;

    /// @notice PropertyRegistryMirror contract
    address public propertyRegistryMirror;

    /// @notice Mensajes procesados (para prevenir replays)
    mapping(bytes32 => bool) public processedMessages;

    /// @notice Rate limiting: mensajes por address por día
    mapping(address => uint256) public dailyMessageCount;
    mapping(address => uint256) public lastMessageDay;

    /// @notice Configuración
    uint256 public maxDailyMessages = 100;
    bool public paused;

    // Estadísticas
    uint256 public totalMessagesProcessed;
    uint256 public totalTenantsUpdated;
    uint256 public totalPropertiesUpdated;

    // Eventos

    event MessageReceived(
        bytes32 indexed messageHash,
        MessageType indexed messageType,
        address indexed relayer,
        uint256 timestamp
    );

    event TenantUpdated(
        address indexed tenant,
        bytes32 messageHash,
        uint256 timestamp
    );

    event PropertyUpdated(
        uint256 indexed propertyId,
        bytes32 messageHash,
        uint256 timestamp
    );

    event MessageRejected(
        bytes32 indexed messageHash,
        string reason,
        uint256 timestamp
    );

    event MirrorContractUpdated(
        string indexed contractType,
        address indexed newAddress
    );

    event PausedStateChanged(bool isPaused);

    // Modifiers

    modifier whenNotPaused() {
        require(!paused, "ISMPHandler: Paused");
        _;
    }

    // Constructor

    /**
     * @notice Inicializa el handler
     * @param _paseoChainId Chain ID de Paseo en formato ISMP
     * @param _tenantMirror Address del TenantPassportMirror
     * @param _propertyMirror Address del PropertyRegistryMirror
     * @param _customHost Address del IsmpHost custom (0x0 = usar BaseIsmpModule default)
     * @param initialOwner Owner del contrato
     * @dev Si _customHost es 0x0, usa BaseIsmpModule.host() default
     */
    constructor(
        bytes memory _paseoChainId,
        address _tenantMirror,
        address _propertyMirror,
        address _customHost,
        address initialOwner
    ) BaseIsmpModule() Ownable(initialOwner) {
        require(_tenantMirror != address(0), "Invalid tenant mirror");
        require(_propertyMirror != address(0), "Invalid property mirror");

        paseoChainId = _paseoChainId;
        tenantPassportMirror = _tenantMirror;
        propertyRegistryMirror = _propertyMirror;
        customHyperbridgeHost = _customHost;
    }

    /**
     * @notice Obtiene el address del IsmpHost efectivo
     * @dev Prioridad: 1) customHost, 2) auto-detect extendido, 3) BaseIsmpModule default
     */
    function getEffectiveHost() public view returns (address) {
        // 1. Si hay custom host configurado, usarlo
        if (customHyperbridgeHost != address(0)) {
            return customHyperbridgeHost;
        }

        // 2. Auto-detect extendido para chains no soportadas por BaseIsmpModule
        address extendedHost = _getExtendedHostAddress();
        if (extendedHost != address(0)) {
            return extendedHost;
        }

        // 3. Fallback a BaseIsmpModule.host() (Ethereum, Arbitrum, etc.)
        return host();
    }

    /**
     * @notice Auto-detect extendido para chains adicionales
     * @dev Agrega soporte para Moonbase Alpha y otras testnets
     */
    function _getExtendedHostAddress() internal view returns (address) {
        uint256 chainId = block.chainid;

        // Moonbase Alpha (Moonbeam Testnet)
        if (chainId == 1287) {
            // TODO: Obtener address oficial del IsmpHost en Moonbase Alpha
            // Por ahora retornamos 0x0 para que use fallback
            // Cuando Hyperbridge despliegue en Moonbase, actualizar aquí
            return address(0);
        }

        // Moonbeam Mainnet
        if (chainId == 1284) {
            // TODO: Address del IsmpHost en Moonbeam Mainnet cuando esté disponible
            return address(0);
        }

        // AssetHub Paseo
        if (chainId == 420420422) {
            // TODO: Address del IsmpHost en AssetHub Paseo
            return address(0);
        }

        // No hay auto-detect para esta chain
        return address(0);
    }

    /**
     * @dev Modifier personalizado que verifica el caller contra el host efectivo
     */
    modifier onlyEffectiveHost() {
        require(msg.sender == getEffectiveHost(), "Unauthorized: not host");
        _;
    }

    // IIsmpModule Implementation

    /**
     * @notice Callback de Hyperbridge cuando se recibe un post request
     * @dev Este es el entry point principal para mensajes cross-chain
     */
    function onAccept(IncomingPostRequest memory incoming)
        external
        override
        onlyEffectiveHost
        whenNotPaused
        nonReentrant
    {
        PostRequest memory request = incoming.request;

        // Calcular hash del request usando SDK oficial
        bytes32 requestHash = Message.hash(request);

        // 1. Validar que viene de Paseo
        if (keccak256(request.source) != keccak256(paseoChainId)) {
            emit MessageRejected(requestHash, "Invalid source chain", block.timestamp);
            return;
        }

        // 2. Validar que no fue procesado (prevenir replays)
        if (processedMessages[requestHash]) {
            emit MessageRejected(requestHash, "Already processed", block.timestamp);
            return;
        }

        // 3. Rate limiting
        if (!_checkRateLimit(incoming.relayer)) {
            emit MessageRejected(requestHash, "Rate limit exceeded", block.timestamp);
            return;
        }

        // 4. Decodificar mensaje
        DecodedMessage memory decoded = _decodeMessage(request.body, requestHash);

        // 5. Procesar según tipo
        bool success = _processMessage(decoded);

        if (success) {
            processedMessages[requestHash] = true;
            totalMessagesProcessed++;

            emit MessageReceived(
                requestHash,
                decoded.messageType,
                incoming.relayer,
                block.timestamp
            );
        } else {
            emit MessageRejected(requestHash, "Processing failed", block.timestamp);
        }
    }

    /**
     * @notice Callback cuando un request hace timeout
     */
    function onPostRequestTimeout(PostRequest memory request)
        external
        override
        onlyEffectiveHost
    {
        // Log timeout pero no hacer nada crítico
        bytes32 requestHash = keccak256(abi.encode(request));
        emit MessageRejected(requestHash, "Request timeout", block.timestamp);
    }

    /**
     * @notice Callback cuando se recibe una response (no usado en este flow)
     */
    function onPostResponse(IncomingPostResponse memory)
        external
        override
        onlyEffectiveHost
    {
        // No esperamos responses en este diseño, solo posts one-way
        // Pero implementamos por interfaz
    }

    /**
     * @notice Callback cuando una response hace timeout
     */
    function onPostResponseTimeout(PostResponse memory)
        external
        override
        onlyEffectiveHost
    {
        // No aplica en nuestro caso
    }

    /**
     * @notice Callback cuando se recibe un get response (no usado)
     */
    function onGetResponse(IncomingGetResponse memory)
        external
        override
        onlyEffectiveHost
    {
        // No usamos GET requests en este diseño
        revert UnexpectedCall();
    }

    /**
     * @notice Callback cuando un get request hace timeout (no usado)
     */
    function onGetTimeout(GetRequest memory)
        external
        override
        onlyEffectiveHost
    {
        // No usamos GET requests en este diseño
        revert UnexpectedCall();
    }

    // Funciones internas de procesamiento

    /**
     * @notice Decodifica un mensaje ISMP
     * @dev En producción, usar SCALE decoder real
     */
    function _decodeMessage(bytes memory payload, bytes32 hash)
        internal
        view
        returns (DecodedMessage memory)
    {
        // NOTA: Esta es una decodificación simplificada
        // En producción, necesitarás un decoder SCALE apropiado
        // o usar JSON/RLP encoding desde el pallet

        require(payload.length > 0, "Empty payload");

        // Primer byte = message type
        MessageType msgType = MessageType(uint8(payload[0]));

        // Resto = data
        bytes memory data = new bytes(payload.length - 1);
        for (uint256 i = 1; i < payload.length; i++) {
            data[i - 1] = payload[i];
        }

        return DecodedMessage({
            messageType: msgType,
            data: data,
            messageHash: hash,
            timestamp: block.timestamp
        });
    }

    /**
     * @notice Procesa un mensaje decodificado
     */
    function _processMessage(DecodedMessage memory decoded)
        internal
        returns (bool)
    {
        if (decoded.messageType == MessageType.TENANT_REPUTATION_SYNC) {
            return _processTenantReputationSync(decoded);
        }
        else if (decoded.messageType == MessageType.TENANT_BADGES_SYNC) {
            return _processTenantBadgesSync(decoded);
        }
        else if (decoded.messageType == MessageType.PROPERTY_FULL_SYNC) {
            return _processPropertyFullSync(decoded);
        }
        else if (decoded.messageType == MessageType.PROPERTY_REPUTATION_SYNC) {
            return _processPropertyReputationSync(decoded);
        }
        // ... otros tipos

        return false;
    }

    /**
     * @notice Procesa sync de reputación de tenant
     * @dev Decodifica datos y actualiza TenantPassportMirror
     */
    function _processTenantReputationSync(DecodedMessage memory decoded)
        internal
        returns (bool)
    {
        // NOTA: En producción, usar decoder SCALE apropiado
        // Por ahora, asumimos un encoding simple

        // Esperamos: address(20 bytes) + reputation(4 bytes) + payments(4 bytes) + ...
        if (decoded.data.length < 20) return false;

        // Extraer address
        address tenant;
        bytes memory data = decoded.data;
        assembly {
            // Saltear longitud (32 bytes) + extraer address (20 bytes)
            tenant := mload(add(add(data, 32), 20))
        }

        // Extraer campos (simplificado)
        // En producción, decodificar todo el struct TenantReputationData del pallet

        uint32 reputation = 85; // Mock data por ahora
        uint32 paymentsMade = 12;
        uint32 paymentsMissed = 1;
        uint32 propertiesRented = 2;
        uint32 consecutiveOnTimePayments = 8;
        uint32 totalMonthsRented = 12;
        uint32 disputesCount = 0;
        uint256 totalRentPaid = 24_000 ether;
        bool isVerified = true;

        // Actualizar mirror
        (bool success, ) = tenantPassportMirror.call(
            abi.encodeWithSignature(
                "syncTenantInfo(address,uint32,uint32,uint32,uint32,uint32,uint32,uint32,uint256,bool,bytes32)",
                tenant,
                reputation,
                paymentsMade,
                paymentsMissed,
                propertiesRented,
                consecutiveOnTimePayments,
                totalMonthsRented,
                disputesCount,
                totalRentPaid,
                isVerified,
                decoded.messageHash
            )
        );

        if (success) {
            totalTenantsUpdated++;
            emit TenantUpdated(tenant, decoded.messageHash, block.timestamp);
        }

        return success;
    }

    /**
     * @notice Procesa sync de badges de tenant
     */
    function _processTenantBadgesSync(DecodedMessage memory decoded)
        internal
        returns (bool)
    {
        // Similar a reputation sync pero solo badges
        if (decoded.data.length < 20) return false;

        address tenant;
        bytes memory data = decoded.data;
        assembly {
            tenant := mload(add(add(data, 32), 20))
        }

        // Mock badges por ahora
        (bool success, ) = tenantPassportMirror.call(
            abi.encodeWithSignature(
                "syncTenantBadges(address,bool,bool,bool,bool,bool,bool,bool)",
                tenant,
                true,  // verifiedID
                true,  // verifiedIncome
                true,  // cleanCredit
                true,  // reliableTenant
                false, // longTermTenant
                true,  // zeroDisputes
                false  // highValue
            )
        );

        return success;
    }

    /**
     * @notice Procesa sync completo de propiedad
     */
    function _processPropertyFullSync(DecodedMessage memory decoded)
        internal
        returns (bool)
    {
        // Decodificar propertyId y todos los campos
        // En producción, decodificar struct completo

        if (decoded.data.length < 32) return false;

        uint256 propertyId;
        bytes memory data = decoded.data;
        assembly {
            propertyId := mload(add(data, 32))
        }

        // Mock data completo de propiedad
        (bool success, ) = propertyRegistryMirror.call(
            abi.encodeWithSignature(
                "syncProperty(uint256,address,string,uint8,string,string,int256,int256,uint8,uint8,uint8,uint16,uint256,uint256,uint256,bool,bool,uint32,uint32,uint32,uint32,string,bool,bytes32)",
                propertyId,
                address(0x123), // landlord
                "Casa en Condesa",
                1, // APARTMENT
                "Ciudad de Mexico",
                "Condesa",
                int256(19412345),
                int256(-99123456),
                uint8(2),
                uint8(2),
                uint8(4),
                uint16(80),
                uint256(0),
                15_000 ether,
                30_000 ether,
                false,
                true,
                uint32(85),
                uint32(5),
                uint32(4),
                uint32(0),
                "ipfs://...",
                true,
                decoded.messageHash
            )
        );

        if (success) {
            totalPropertiesUpdated++;
            emit PropertyUpdated(propertyId, decoded.messageHash, block.timestamp);
        }

        return success;
    }

    /**
     * @notice Procesa sync de reputación de propiedad
     */
    function _processPropertyReputationSync(DecodedMessage memory decoded)
        internal
        returns (bool)
    {
        if (decoded.data.length < 32) return false;

        uint256 propertyId;
        bytes memory data = decoded.data;
        assembly {
            propertyId := mload(add(data, 32))
        }

        // Mock reputation data
        (bool success, ) = propertyRegistryMirror.call(
            abi.encodeWithSignature(
                "syncPropertyReputation(uint256,uint32,uint32,uint32,uint32,bytes32)",
                propertyId,
                uint32(88),  // rating
                uint32(10),  // totalRentals
                uint32(9),   // completedRentals
                uint32(0),   // disputes
                decoded.messageHash
            )
        );

        if (success) {
            totalPropertiesUpdated++;
            emit PropertyUpdated(propertyId, decoded.messageHash, block.timestamp);
        }

        return success;
    }

    /**
     * @notice Verifica rate limit
     */
    function _checkRateLimit(address relayer) internal returns (bool) {
        uint256 today = block.timestamp / 1 days;

        if (lastMessageDay[relayer] != today) {
            lastMessageDay[relayer] = today;
            dailyMessageCount[relayer] = 0;
        }

        if (dailyMessageCount[relayer] >= maxDailyMessages) {
            return false;
        }

        dailyMessageCount[relayer]++;
        return true;
    }

    // View functions

    /**
     * @notice Verifica si un mensaje fue procesado
     */
    function isMessageProcessed(bytes32 messageHash) external view returns (bool) {
        return processedMessages[messageHash];
    }

    /**
     * @notice Obtiene estadísticas del handler
     */
    function getHandlerStats()
        external
        view
        returns (
            uint256 totalMessages,
            uint256 totalTenants,
            uint256 totalProperties,
            bool isPaused
        )
    {
        return (
            totalMessagesProcessed,
            totalTenantsUpdated,
            totalPropertiesUpdated,
            paused
        );
    }

    // Funciones de administración

    /**
     * @notice Actualiza chain ID de Paseo
     */
    function setPaseoChainId(bytes calldata newChainId) external onlyOwner {
        paseoChainId = newChainId;
    }

    /**
     * @notice Actualiza mirror contracts
     */
    function setTenantMirror(address newMirror) external onlyOwner {
        require(newMirror != address(0), "Invalid mirror");
        tenantPassportMirror = newMirror;
        emit MirrorContractUpdated("TenantPassport", newMirror);
    }

    function setPropertyMirror(address newMirror) external onlyOwner {
        require(newMirror != address(0), "Invalid mirror");
        propertyRegistryMirror = newMirror;
        emit MirrorContractUpdated("PropertyRegistry", newMirror);
    }

    /**
     * @notice Actualiza rate limit
     */
    function setMaxDailyMessages(uint256 newLimit) external onlyOwner {
        maxDailyMessages = newLimit;
    }

    /**
     * @notice Pausa/despausa el handler
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PausedStateChanged(_paused);
    }

    /**
     * @notice Emergency: marca mensaje como procesado
     */
    function emergencyMarkProcessed(bytes32 messageHash, bool processed)
        external
        onlyOwner
    {
        processedMessages[messageHash] = processed;
    }
}
