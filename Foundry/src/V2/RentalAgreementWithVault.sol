// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces.sol";

/**
 * @title RentalAgreementWithVault
 * @author RoomFi Team - Firrton
 * @notice Contrato de rental agreement con integración al RoomFiVault para yield farming
 * @dev Version mejorada que deposita security deposits en vault para generar yield
 *
 * DIFERENCIAS vs RentalAgreement básico:
 * - Security deposit va al RoomFiVault (genera yield 6-12% APY)
 * - Al completar, tenant recibe deposit + 70% del yield
 * - Protocol recibe 30% del yield como revenue adicional
 * - Usa USDT (6 decimals) en lugar de native token
 * - Integración con Acala para yield farming
 *
 * FLUJO COMPLETO:
 * 1. Tenant paga deposit → RoomFiVault
 * 2. Vault → Acala Strategy → Acala Lending/DEX
 * 3. Durante 6-24 meses: genera yield
 * 4. Al completar → Vault withdraw con yield
 * 5. Tenant recibe: deposit + 70% yield
 * 6. Protocol recibe: 30% yield
 */
contract RentalAgreementWithVault is ReentrancyGuard {

    // ============================================
    // ENUMS
    // ============================================

    enum AgreementStatus {
        PENDING,        // Esperando firmas + deposit
        ACTIVE,         // Activo, pagos en curso
        COMPLETED,      // Completado exitosamente
        TERMINATED,     // Terminado anticipadamente
        DISPUTED        // En disputa
    }

    // ============================================
    // STRUCTS
    // ============================================

    struct Agreement {
        uint256 propertyId;
        address landlord;
        address tenant;
        uint256 monthlyRent;         // en USDT (6 decimals)
        uint256 securityDeposit;     // en USDT (6 decimals)
        uint256 startDate;
        uint256 endDate;
        uint256 duration;            // en meses
        AgreementStatus status;

        uint256 depositAmount;       // Deposit pagado
        uint256 totalPaid;           // Total rent pagado
        uint256 paymentsMade;
        uint256 paymentsMissed;

        bool landlordSigned;
        bool tenantSigned;
    }

    // ============================================
    // STATE VARIABLES
    // ============================================

    Agreement public agreement;

    // Contracts references
    IERC20 public immutable usdt;
    IRoomFiVault public immutable vault;
    IPropertyRegistry public propertyRegistry;
    ITenantPassport public tenantPassport;
    address public factory;
    address public disputeResolver;

    // Payment tracking
    uint256 public lastPaymentDate;
    uint256 public nextPaymentDue;

    // Dispute tracking
    uint256 public activeDisputeId;
    bool public paymentsLockedByDispute;

    // Protocol fees
    uint256 public constant PROTOCOL_FEE_PERCENT = 15; // 15% de rent
    uint256 public constant VAULT_YIELD_SPLIT = 70;    // 70% yield para tenant

    bool private initialized;

    // ============================================
    // EVENTS
    // ============================================

    event AgreementSigned(address indexed signer, bool isLandlord, uint256 timestamp);
    event DepositPaid(address indexed tenant, uint256 amount, uint256 timestamp);
    event DepositDepositedToVault(uint256 amount, uint256 timestamp);
    event RentPaid(uint256 indexed month, uint256 amount, uint256 timestamp);
    event AgreementActivated(uint256 startDate, uint256 endDate);
    event AgreementTerminated(address indexed initiator, string reason, uint256 timestamp);
    event DisputeRaised(address indexed initiator, string reason, uint256 timestamp);
    event DepositReturned(address indexed tenant, uint256 principal, uint256 yield, uint256 timestamp);
    event AgreementCompleted(uint256 timestamp);
    event YieldDistributed(uint256 tenantYield, uint256 protocolYield, uint256 timestamp);

    // ============================================
    // ERRORS
    // ============================================

    error NotInitialized();
    error AlreadyInitialized();
    error NotLandlord();
    error NotTenant();
    error NotParty();
    error InvalidStatus();
    error AlreadySigned();
    error DepositAlreadyPaid();
    error IncorrectAmount();
    error PaymentsLocked();
    error DisputeAlreadyActive();
    error TransferFailed();

    // ============================================
    // MODIFIERS
    // ============================================

    modifier onlyInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }

    modifier onlyLandlord() {
        if (msg.sender != agreement.landlord) revert NotLandlord();
        _;
    }

    modifier onlyTenant() {
        if (msg.sender != agreement.tenant) revert NotTenant();
        _;
    }

    modifier onlyParty() {
        if (msg.sender != agreement.tenant && msg.sender != agreement.landlord) {
            revert NotParty();
        }
        _;
    }

    modifier onlyStatus(AgreementStatus status) {
        if (agreement.status != status) revert InvalidStatus();
        _;
    }

    // ============================================
    // CONSTRUCTOR & INITIALIZATION
    // ============================================

    constructor(address _usdt, address _vault) {
        require(_usdt != address(0), "Invalid USDT");
        require(_vault != address(0), "Invalid vault");

        usdt = IERC20(_usdt);
        vault = IRoomFiVault(_vault);
    }

    /**
     * @notice Inicializa el agreement (llamado por factory)
     */
    function initialize(
        uint256 _propertyId,
        address _landlord,
        address _tenant,
        uint256 _monthlyRent,
        uint256 _securityDeposit,
        uint256 _duration,
        address _propertyRegistry,
        address _tenantPassport,
        address _factory,
        address _disputeResolver
    ) external {
        if (initialized) revert AlreadyInitialized();

        agreement = Agreement({
            propertyId: _propertyId,
            landlord: _landlord,
            tenant: _tenant,
            monthlyRent: _monthlyRent,
            securityDeposit: _securityDeposit,
            startDate: 0,
            endDate: 0,
            duration: _duration,
            status: AgreementStatus.PENDING,
            depositAmount: 0,
            totalPaid: 0,
            paymentsMade: 0,
            paymentsMissed: 0,
            landlordSigned: false,
            tenantSigned: false
        });

        propertyRegistry = IPropertyRegistry(_propertyRegistry);
        tenantPassport = ITenantPassport(_tenantPassport);
        factory = _factory;
        disputeResolver = _disputeResolver;

        initialized = true;
    }

    // ============================================
    // SIGNING FUNCTIONS
    // ============================================

    /**
     * @notice Tenant firma el agreement
     */
    function signAsTenant()
        external
        onlyInitialized
        onlyTenant
        onlyStatus(AgreementStatus.PENDING)
    {
        if (agreement.tenantSigned) revert AlreadySigned();

        agreement.tenantSigned = true;
        emit AgreementSigned(msg.sender, false, block.timestamp);

        _checkActivation();
    }

    /**
     * @notice Landlord firma el agreement
     */
    function signAsLandlord()
        external
        onlyInitialized
        onlyLandlord
        onlyStatus(AgreementStatus.PENDING)
    {
        if (agreement.landlordSigned) revert AlreadySigned();

        agreement.landlordSigned = true;
        emit AgreementSigned(msg.sender, true, block.timestamp);

        _checkActivation();
    }

    // ============================================
    // DEPOSIT & PAYMENT FUNCTIONS
    // ============================================

    /**
     * @notice Tenant paga security deposit en USDT
     * @dev Deposit va directo al RoomFiVault para generar yield
     *
     * FLUJO:
     * 1. Transfer USDT del tenant al agreement
     * 2. Approve vault
     * 3. Deposit en vault → empieza yield farming
     * 4. Check activation
     */
    function paySecurityDeposit()
        external
        nonReentrant
        onlyInitialized
        onlyTenant
        onlyStatus(AgreementStatus.PENDING)
    {
        if (agreement.depositAmount != 0) revert DepositAlreadyPaid();

        uint256 depositAmount = agreement.securityDeposit;

        // Transfer USDT del tenant al agreement
        bool success = usdt.transferFrom(msg.sender, address(this), depositAmount);
        if (!success) revert TransferFailed();

        // Approve vault para depositar
        usdt.approve(address(vault), depositAmount);

        // Depositar en vault → comienza yield farming
        vault.deposit(depositAmount, address(this));

        agreement.depositAmount = depositAmount;

        emit DepositPaid(msg.sender, depositAmount, block.timestamp);
        emit DepositDepositedToVault(depositAmount, block.timestamp);

        _checkActivation();
    }

    /**
     * @notice Verifica si se puede activar el agreement
     * @dev Se activa cuando: ambos firman + deposit pagado
     */
    function _checkActivation() internal {
        if (
            agreement.landlordSigned &&
            agreement.tenantSigned &&
            agreement.depositAmount == agreement.securityDeposit
        ) {
            agreement.status = AgreementStatus.ACTIVE;
            agreement.startDate = block.timestamp;
            agreement.endDate = block.timestamp + (agreement.duration * 30 days);
            nextPaymentDue = block.timestamp + 30 days;

            // Notificar factory
            (bool success, ) = factory.call(
                abi.encodeWithSignature("notifyAgreementActivated()")
            );
            require(success, "Factory notification failed");

            // Incrementar properties rented en TenantPassport
            uint256 tenantTokenId = tenantPassport.getTokenIdByAddress(agreement.tenant);
            tenantPassport.incrementPropertiesRented(tenantTokenId);

            emit AgreementActivated(agreement.startDate, agreement.endDate);
        }
    }

    /**
     * @notice Tenant paga renta mensual en USDT
     *
     * FLUJO:
     * 1. Transfer USDT del tenant
     * 2. Split: 85% landlord, 15% protocol fee
     * 3. Actualizar reputación tenant
     * 4. Si es último pago → completar agreement
     */
    function payRent()
        external
        nonReentrant
        onlyInitialized
        onlyTenant
        onlyStatus(AgreementStatus.ACTIVE)
    {
        if (paymentsLockedByDispute) revert PaymentsLocked();

        uint256 rentAmount = agreement.monthlyRent;

        // Transfer USDT del tenant
        bool success = usdt.transferFrom(msg.sender, address(this), rentAmount);
        if (!success) revert TransferFailed();

        // CHECKS
        bool onTime = block.timestamp <= nextPaymentDue;

        // EFFECTS
        agreement.totalPaid += rentAmount;
        agreement.paymentsMade++;
        lastPaymentDate = block.timestamp;
        nextPaymentDue = block.timestamp + 30 days;

        if (!onTime) {
            agreement.paymentsMissed++;
        }

        // Split payment
        uint256 landlordAmount = (rentAmount * (100 - PROTOCOL_FEE_PERCENT)) / 100;
        uint256 protocolFee = rentAmount - landlordAmount;

        // INTERACTIONS
        // Transfer a landlord
        usdt.transfer(agreement.landlord, landlordAmount);

        // Transfer protocol fee al factory/owner
        usdt.transfer(factory, protocolFee);

        // Actualizar reputación del tenant
        uint256 tenantTokenId = tenantPassport.getTokenIdByAddress(msg.sender);
        tenantPassport.updateTenantInfo(tenantTokenId, onTime, rentAmount);

        emit RentPaid(agreement.paymentsMade, rentAmount, block.timestamp);

        // Si llegó al final del contrato → completar
        if (block.timestamp >= agreement.endDate) {
            _completeAgreement();
        }
    }

    /**
     * @notice Completa el agreement y retorna deposit + yield
     *
     * FLUJO:
     * 1. Withdraw del vault (deposit + yield)
     * 2. Split yield: 70% tenant, 30% protocol
     * 3. Transfer deposit + tenant yield al tenant
     * 4. Transfer protocol yield al factory
     * 5. Actualizar reputación property
     */
    function _completeAgreement() internal {
        agreement.status = AgreementStatus.COMPLETED;

        uint256 depositAmount = agreement.depositAmount;

        // Withdraw del vault CON yield generado
        (uint256 principal, uint256 yieldEarned) = vault.withdraw(
            depositAmount,
            address(this)
        );

        // Split del yield: 70% tenant, 30% protocol
        uint256 tenantYield = (yieldEarned * VAULT_YIELD_SPLIT) / 100;
        uint256 protocolYield = yieldEarned - tenantYield;

        // Transfer deposit + tenant yield al tenant
        uint256 totalReturn = principal + tenantYield;
        usdt.transfer(agreement.tenant, totalReturn);

        // Transfer protocol yield
        if (protocolYield > 0) {
            usdt.transfer(factory, protocolYield);
        }

        emit AgreementCompleted(block.timestamp);
        emit DepositReturned(agreement.tenant, principal, tenantYield, block.timestamp);
        emit YieldDistributed(tenantYield, protocolYield, block.timestamp);

        // Actualizar reputación de la propiedad
        propertyRegistry.updatePropertyReputation(
            agreement.propertyId,
            true,  // completado exitosamente
            false, // sin disputas
            80, 80, 80 // ratings default (TODO: implementar sistema de ratings)
        );

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementCompleted()")
        );
        require(success, "Factory notification failed");
    }

    // ============================================
    // TERMINATION & DISPUTE FUNCTIONS
    // ============================================

    /**
     * @notice Termina el agreement anticipadamente
     */
    function terminateAgreement(string calldata reason)
        external
        nonReentrant
        onlyInitialized
        onlyParty
        onlyStatus(AgreementStatus.ACTIVE)
    {
        agreement.status = AgreementStatus.TERMINATED;

        uint256 depositReturn = agreement.depositAmount;
        uint256 penalty = 0;

        // Si tenant termina y tiene pagos perdidos → penalty
        if (msg.sender == agreement.tenant && agreement.paymentsMissed > 0) {
            penalty = (depositReturn * 20) / 100; // 20% penalty
            depositReturn = depositReturn - penalty;
        }

        // Withdraw del vault
        (uint256 principal, uint256 yieldEarned) = vault.withdraw(
            agreement.depositAmount,
            address(this)
        );

        // Si hay penalty, va al landlord
        if (penalty > 0) {
            usdt.transfer(agreement.landlord, penalty);
        }

        // Return deposit (menos penalty) + tenant yield
        uint256 tenantYield = (yieldEarned * VAULT_YIELD_SPLIT) / 100;
        uint256 protocolYield = yieldEarned - tenantYield;

        uint256 tenantTotal = (principal - penalty) + tenantYield;
        usdt.transfer(agreement.tenant, tenantTotal);

        if (protocolYield > 0) {
            usdt.transfer(factory, protocolYield);
        }

        emit AgreementTerminated(msg.sender, reason, block.timestamp);

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementTerminated(address)", msg.sender)
        );
        require(success, "Factory notification failed");
    }

    /**
     * @notice Levanta una disputa
     */
    function raiseDispute(
        uint8 reasonCode,
        string calldata evidenceURI,
        uint256 amountInDispute
    )
        external
        payable
        nonReentrant
        onlyInitialized
        onlyParty
        onlyStatus(AgreementStatus.ACTIVE)
    {
        if (activeDisputeId != 0) revert DisputeAlreadyActive();
        require(disputeResolver != address(0), "DisputeResolver not set");

        // Cambiar estado
        agreement.status = AgreementStatus.DISPUTED;
        paymentsLockedByDispute = true;

        // Determinar quién es initiator
        bool initiatorIsTenant = (msg.sender == agreement.tenant);
        address respondent = initiatorIsTenant ? agreement.landlord : agreement.tenant;

        // Crear disputa en DisputeResolver
        (bool success, bytes memory data) = disputeResolver.call{value: msg.value}(
            abi.encodeWithSignature(
                "createDispute(address,address,uint8,string,uint256,bool)",
                address(this),
                respondent,
                reasonCode,
                evidenceURI,
                amountInDispute,
                initiatorIsTenant
            )
        );

        require(success, "Failed to create dispute");

        // Decodificar disputeId
        activeDisputeId = abi.decode(data, (uint256));

        emit DisputeRaised(msg.sender, evidenceURI, block.timestamp);
    }

    /**
     * @notice Aplica resolución de disputa
     * @dev Solo puede ser llamado por DisputeResolver
     */
    function applyDisputeResolution(
        uint256 disputeId,
        bool favorTenant
    ) external nonReentrant {
        require(msg.sender == disputeResolver, "Only DisputeResolver");
        require(activeDisputeId == disputeId, "Invalid dispute ID");
        require(agreement.status == AgreementStatus.DISPUTED, "Not disputed");

        // Desbloquear pagos
        paymentsLockedByDispute = false;
        activeDisputeId = 0;

        // Terminar agreement
        agreement.status = AgreementStatus.TERMINATED;

        // Withdraw del vault
        (uint256 principal, uint256 yieldEarned) = vault.withdraw(
            agreement.depositAmount,
            address(this)
        );

        if (favorTenant) {
            // Tenant gana → recibe deposit completo + yield
            uint256 tenantYield = (yieldEarned * VAULT_YIELD_SPLIT) / 100;
            uint256 totalReturn = principal + tenantYield;

            usdt.transfer(agreement.tenant, totalReturn);

            // Protocol yield
            uint256 protocolYield = yieldEarned - tenantYield;
            if (protocolYield > 0) {
                usdt.transfer(factory, protocolYield);
            }
        } else {
            // Landlord gana → tenant pierde 30% del deposit
            uint256 penalty = (principal * 30) / 100;

            usdt.transfer(agreement.landlord, penalty);
            usdt.transfer(agreement.tenant, principal - penalty);

            // Yield va al protocol en este caso
            if (yieldEarned > 0) {
                usdt.transfer(factory, yieldEarned);
            }
        }

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementTerminated(address)", msg.sender)
        );
        require(success, "Factory notification failed");
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Obtiene detalles completos del agreement
     */
    function getAgreementDetails() external view returns (Agreement memory) {
        return agreement;
    }

    /**
     * @notice Verifica si un pago está atrasado
     */
    function isPaymentOverdue() external view returns (bool) {
        return block.timestamp > nextPaymentDue &&
               agreement.status == AgreementStatus.ACTIVE;
    }

    /**
     * @notice Obtiene días de atraso en pago
     */
    function getDaysOverdue() external view returns (uint256) {
        if (block.timestamp <= nextPaymentDue) return 0;
        return (block.timestamp - nextPaymentDue) / 1 days;
    }

    /**
     * @notice Obtiene tasa de éxito de pagos
     */
    function getPaymentSuccessRate() external view returns (uint256) {
        uint256 total = agreement.paymentsMade + agreement.paymentsMissed;
        if (total == 0) return 0;
        return (agreement.paymentsMade * 10000) / total; // basis points
    }

    /**
     * @notice Obtiene progreso del agreement
     */
    function getAgreementProgress() external view returns (uint256) {
        if (agreement.status != AgreementStatus.ACTIVE) return 0;
        if (block.timestamp < agreement.startDate) return 0;
        if (block.timestamp >= agreement.endDate) return 10000;

        uint256 elapsed = block.timestamp - agreement.startDate;
        uint256 totalDuration = agreement.endDate - agreement.startDate;
        return (elapsed * 10000) / totalDuration;
    }

    /**
     * @notice Obtiene yield generado por el deposit
     */
    function getDepositYield() external view returns (uint256) {
        if (agreement.depositAmount == 0) return 0;
        return vault.calculateYield(address(this));
    }

    /**
     * @notice Obtiene balance total en vault (deposit + yield)
     */
    function getTotalDepositValue() external view returns (uint256) {
        if (agreement.depositAmount == 0) return 0;
        return vault.balanceOf(address(this));
    }

    /**
     * @notice Obtiene info detallada del vault deposit
     */
    function getVaultDepositInfo() external view returns (
        uint256 depositAmount,
        uint256 yieldEarned,
        uint256 totalValue,
        uint256 daysDeposited,
        uint256 projectedAPY
    ) {
        if (agreement.depositAmount == 0) {
            return (0, 0, 0, 0, 0);
        }

        (
            depositAmount,
            yieldEarned,
            totalValue,
            ,
            daysDeposited
        ) = vault.getUserInfo(address(this));

        projectedAPY = vault.getCurrentAPY();
    }

    receive() external payable {}
}
