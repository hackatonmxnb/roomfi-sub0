// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interfaces.sol";

/**
 * @title RentalAgreement
 * @author RoomFi Team - Firrton
 * @notice Contrato individual de alquiler
 * @dev Clonable via EIP-1167 para gas efficiency
 *
 * ARQUITECTURA V2:
 * - USDT como token de pago (no ETH nativo)
 * - Security deposits → RoomFiVault (generan yield)
 * - Rent payments → USDT transfers directos
 * - Yield → distribuido 70% tenant, 30% protocol
 */
contract RentalAgreement is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum AgreementStatus {
        PENDING,
        ACTIVE,
        COMPLETED,
        TERMINATED,
        DISPUTED,
        CANCELLED
    }

    struct Agreement {
        uint256 propertyId;
        address landlord;
        address tenant;
        uint256 monthlyRent;
        uint256 securityDeposit;
        uint256 startDate;
        uint256 endDate;
        uint256 duration;
        AgreementStatus status;

        uint256 depositAmount;
        uint256 totalPaid;
        uint256 paymentsMade;
        uint256 paymentsMissed;

        bool landlordSigned;
        bool tenantSigned;
    }

    Agreement public agreement;

    address public propertyRegistry;
    address public tenantPassport;
    address public factory;
    address public disputeResolver;

    IERC20 public usdt;
    IRoomFiVault public vault;

    uint256 public lastPaymentDate;
    uint256 public nextPaymentDue;

    uint256 public activeDisputeId;     // ID de disputa activa (0 si no hay)
    bool public paymentsLockedByDispute; // Pagos pausados durante disputa

    bool private initialized;

    // Eventos

    event AgreementSigned(address indexed signer, bool isLandlord);
    event DepositPaid(address indexed tenant, uint256 amount);
    event RentPaid(uint256 indexed month, uint256 amount, uint256 timestamp);
    event AgreementActivated(uint256 startDate, uint256 endDate);
    event AgreementCancelled(address indexed canceller, uint256 timestamp);
    event AgreementTerminated(address indexed terminator, string reason, uint256 penalty);
    event AgreementAutoTerminated(address indexed tenant, string reason);
    event DisputeRaised(address indexed initiator, string reason);
    event DepositReturned(address indexed tenant, uint256 principal, uint256 yieldEarned);
    event AgreementCompleted(uint256 timestamp);
    event VaultWithdrawFailed(uint256 expected, uint256 actual);

    // Modifiers

    modifier onlyInitialized() {
        require(initialized, "Not initialized");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == agreement.landlord, "Not landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == agreement.tenant, "Not tenant");
        _;
    }

    modifier onlyParty() {
        require(
            msg.sender == agreement.tenant || msg.sender == agreement.landlord,
            "Not party"
        );
        _;
    }

    modifier onlyStatus(AgreementStatus status) {
        require(agreement.status == status, "Invalid status");
        _;
    }

    // Initialize (llamado por factory)

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
        address _disputeResolver,
        address _usdt,
        address _vault
    ) external {
        require(!initialized, "Already initialized");
        require(_usdt != address(0), "Invalid USDT address");
        require(_vault != address(0), "Invalid vault address");

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

        propertyRegistry = _propertyRegistry;
        tenantPassport = _tenantPassport;
        factory = _factory;
        disputeResolver = _disputeResolver;
        usdt = IERC20(_usdt);
        vault = IRoomFiVault(_vault);
        initialized = true;
    }

    // Funciones principales

    function signAsTenant() external onlyInitialized onlyTenant onlyStatus(AgreementStatus.PENDING) {
        require(!agreement.tenantSigned, "Already signed");

        agreement.tenantSigned = true;
        emit AgreementSigned(msg.sender, false);

        _checkActivation();
    }

    function signAsLandlord() external onlyInitialized onlyLandlord onlyStatus(AgreementStatus.PENDING) {
        require(!agreement.landlordSigned, "Already signed");

        agreement.landlordSigned = true;
        emit AgreementSigned(msg.sender, true);

        _checkActivation();
    }

    /**
     * @notice Paga security deposit en USDT y lo deposita en vault para generar yield
     * @dev Requiere approve previo de USDT
     */
    function paySecurityDeposit() external nonReentrant onlyInitialized onlyTenant onlyStatus(AgreementStatus.PENDING) {
        require(agreement.depositAmount == 0, "Deposit already paid");

        uint256 depositAmount = agreement.securityDeposit;

        // Transfer USDT del tenant al contrato
        usdt.safeTransferFrom(msg.sender, address(this), depositAmount);

        // Depositar en vault para generar yield
        // El vault requiere approve
        usdt.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, address(this));

        agreement.depositAmount = depositAmount;
        emit DepositPaid(msg.sender, depositAmount);

        _checkActivation();
    }

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

            emit AgreementActivated(agreement.startDate, agreement.endDate);
        }
    }

    /**
     * @notice Paga renta mensual en USDT
     * @dev Requiere approve previo de USDT. Split: 85% landlord, 15% protocol
     */
    function payRent() external nonReentrant onlyInitialized onlyTenant onlyStatus(AgreementStatus.ACTIVE) {
        require(!paymentsLockedByDispute, "Payments locked by dispute");

        uint256 rentAmount = agreement.monthlyRent;

        // CHECKS
        bool onTime = block.timestamp <= nextPaymentDue;
        uint256 landlordAmount = (rentAmount * 85) / 100;
        uint256 protocolAmount = rentAmount - landlordAmount;

        // EFFECTS (actualizar estado ANTES de interacciones externas)
        agreement.totalPaid += rentAmount;
        agreement.paymentsMade++;
        lastPaymentDate = block.timestamp;
        nextPaymentDue = block.timestamp + 30 days;

        if (!onTime) {
            agreement.paymentsMissed++;
        }

        emit RentPaid(agreement.paymentsMade, rentAmount, block.timestamp);

        // INTERACTIONS (transferencias al final usando SafeERC20)
        usdt.safeTransferFrom(msg.sender, agreement.landlord, landlordAmount);
        usdt.safeTransferFrom(msg.sender, factory, protocolAmount); // Protocol fee va al factory/owner

        // Actualizar reputación del tenant en TenantPassport
        uint256 tenantTokenId = ITenantPassport(tenantPassport).getTokenIdByAddress(agreement.tenant);
        ITenantPassport(tenantPassport).updateTenantInfo(tenantTokenId, onTime, rentAmount);

        if (block.timestamp >= agreement.endDate) {
            _completeAgreement();
        }
    }

    /**
     * @notice Completa agreement y retorna deposit + yield del vault
     * @dev Usa try-catch para manejar failures del vault withdraw
     */
    function _completeAgreement() internal {
        // EFFECTS
        agreement.status = AgreementStatus.COMPLETED;
        uint256 principalDeposit = agreement.depositAmount;

        emit AgreementCompleted(block.timestamp);

        // INTERACTIONS - Withdraw del vault con try-catch
        try vault.withdraw(principalDeposit, address(this))
            returns (uint256 principal, uint256 yieldEarned)
        {
            // Success path: Distribuir principal + yield al tenant
            // El vault ya aplicó protocol fee (30%), tenant recibe 70% del yield
            uint256 totalToReturn = principal + yieldEarned;

            usdt.safeTransfer(agreement.tenant, totalToReturn);

            emit DepositReturned(agreement.tenant, principal, yieldEarned);
        } catch {
            // Fallback: Si vault falla, intentar retornar lo que tenemos en balance
            uint256 contractBalance = usdt.balanceOf(address(this));

            if (contractBalance >= principalDeposit) {
                usdt.safeTransfer(agreement.tenant, principalDeposit);
                emit DepositReturned(agreement.tenant, principalDeposit, 0);
            } else {
                // Emergency: Retornar lo que hay
                if (contractBalance > 0) {
                    usdt.safeTransfer(agreement.tenant, contractBalance);
                }
                emit VaultWithdrawFailed(principalDeposit, contractBalance);
            }
        }

        // Actualizar reputación de la propiedad
        // TODO: Implementar sistema de ratings. Por ahora usa valores por defecto 80/100
        bool hadDispute = false; // Si no llegó a DISPUTED, no hubo disputa
        IPropertyRegistry(propertyRegistry).updatePropertyReputation(
            agreement.propertyId,
            true,  // rentalCompleted = true
            hadDispute,
            80,  // cleanlinessRating (default)
            80,  // locationRating (default)
            80   // valueRating (default)
        );

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementCompleted()")
        );
        require(success, "Factory notification failed");
    }

    /**
     * @notice Cancela un agreement en estado PENDING
     * @dev Solo landlord, tenant o factory pueden cancelar antes de que esté activo
     */
    function cancel()
        external
        nonReentrant
        onlyStatus(AgreementStatus.PENDING)
    {
        require(
            msg.sender == agreement.landlord ||
            msg.sender == agreement.tenant ||
            msg.sender == factory,
            "No autorizado"
        );

        agreement.status = AgreementStatus.CANCELLED;

        // Si hay deposit pagado, retornarlo (raro pero posible)
        if (agreement.depositAmount > 0) {
            // Withdraw de vault sin yield (no aplica yield a cancelaciones)
            try vault.withdraw(agreement.depositAmount, address(this))
                returns (uint256 principal, uint256 /* yieldEarned */)
            {
                usdt.safeTransfer(agreement.tenant, principal);
            } catch {
                // Fallback: retornar lo que hay en balance
                uint256 balance = usdt.balanceOf(address(this));
                if (balance > 0) {
                    usdt.safeTransfer(agreement.tenant, balance);
                }
            }
        }

        emit AgreementCancelled(msg.sender, block.timestamp);
    }

    /**
     * @notice Termina early un agreement ACTIVE con penalties calculados
     * @param reason Razón de la terminación
     * @dev Penalties basados en tiempo restante y quién termina
     */
    function terminateEarly(string calldata reason)
        external
        nonReentrant
        onlyInitialized
        onlyParty
        onlyStatus(AgreementStatus.ACTIVE)
    {
        // Calcular penalty basado en tiempo restante
        uint256 monthsRemaining = (agreement.endDate - block.timestamp) / 30 days;
        uint256 penalty = 0;

        if (monthsRemaining > 0) {
            // Penalty: 0.5 meses de renta por mes restante (cap 2 meses)
            penalty = (agreement.monthlyRent * monthsRemaining) / 2;
            if (penalty > agreement.monthlyRent * 2) {
                penalty = agreement.monthlyRent * 2;
            }
        }

        agreement.status = AgreementStatus.TERMINATED;

        // Withdraw deposit con yield del vault
        try vault.withdraw(agreement.depositAmount, address(this))
            returns (uint256 principal, uint256 yieldEarned)
        {
            // Si tenant termina: Pierde parte del deposit (penalty)
            // Si landlord termina: Tenant recupera todo + penalty extra
            if (msg.sender == agreement.tenant) {
                // Tenant termina early
                if (penalty <= principal) {
                    usdt.safeTransfer(agreement.tenant, principal - penalty + yieldEarned);
                    usdt.safeTransfer(agreement.landlord, penalty);
                } else {
                    // Penalty > deposit (raro), todo al landlord
                    usdt.safeTransfer(agreement.landlord, principal + yieldEarned);
                }
            } else {
                // Landlord termina early (malo para tenant)
                usdt.safeTransfer(agreement.tenant, principal + yieldEarned);

                // Landlord paga penalty extra del propio bolsillo
                if (penalty > 0) {
                    usdt.safeTransferFrom(agreement.landlord, agreement.tenant, penalty);
                }
            }
        } catch {
            // Fallback si vault falla
            uint256 balance = usdt.balanceOf(address(this));
            if (balance > 0) {
                usdt.safeTransfer(agreement.tenant, balance);
            }
            emit VaultWithdrawFailed(agreement.depositAmount, balance);
        }

        emit AgreementTerminated(msg.sender, reason, penalty);

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementTerminated(address)", msg.sender)
        );
        require(success, "Factory notification failed");
    }

    /**
     * @notice DEPRECATED: Usar terminateEarly() en su lugar
     */
    function terminateAgreement(string calldata reason)
        external
        nonReentrant
        onlyInitialized
        onlyParty
        onlyStatus(AgreementStatus.ACTIVE)
    {
        // CHECKS & EFFECTS
        agreement.status = AgreementStatus.TERMINATED;

        uint256 depositReturn = agreement.depositAmount;
        uint256 penalty = 0;

        if (msg.sender == agreement.tenant && agreement.paymentsMissed > 0) {
            penalty = (agreement.depositAmount * 20) / 100;
            depositReturn = agreement.depositAmount - penalty;
        }

        emit AgreementTerminated(msg.sender, reason, penalty);

        // INTERACTIONS
        if (penalty > 0) {
            payable(agreement.landlord).transfer(penalty);
        }

        if (depositReturn > 0) {
            payable(agreement.tenant).transfer(depositReturn);
        }

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementTerminated(address)", msg.sender)
        );
        require(success, "Factory notification failed");
    }

    /**
     * @notice Auto-termina agreement si 90+ días sin pago
     * @dev Callable por cualquiera. Previene overflow de nextPaymentDue
     */
    function checkAutoTerminate() external {
        require(agreement.status == AgreementStatus.ACTIVE, "Solo ACTIVE");

        // Si 90 días (3 meses) desde último pago esperado
        if (block.timestamp > nextPaymentDue + 90 days) {
            agreement.status = AgreementStatus.TERMINATED;

            // No retornar deposit (forfeit por no pagar)
            // Deposit va al landlord como compensación
            try vault.withdraw(agreement.depositAmount, address(this))
                returns (uint256 principal, uint256 yieldEarned)
            {
                usdt.safeTransfer(agreement.landlord, principal + yieldEarned);
            } catch {
                // Fallback
                uint256 balance = usdt.balanceOf(address(this));
                if (balance > 0) {
                    usdt.safeTransfer(agreement.landlord, balance);
                }
            }

            // Penalizar tenant reputation severamente
            uint256 tenantTokenId = ITenantPassport(tenantPassport).getTokenIdByAddress(agreement.tenant);

            // Registrar 3 missed payments para impactar reputation
            for (uint i = 0; i < 3; i++) {
                ITenantPassport(tenantPassport).updateTenantInfo(tenantTokenId, false, 0);
            }

            emit AgreementAutoTerminated(agreement.tenant, "90+ dias sin pago");
        }
    }

    /**
     * @notice Levanta una disputa y la envía al DisputeResolver
     * @param reasonCode Código de la razón (ver DisputeResolver.DisputeReason)
     * @param evidenceURI IPFS con evidencia
     * @param amountInDispute Wei en disputa (ej: depósito, rent)
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
        require(activeDisputeId == 0, "Dispute already active");
        require(disputeResolver != address(0), "DisputeResolver not configured");

        // Cambiar estado
        agreement.status = AgreementStatus.DISPUTED;
        paymentsLockedByDispute = true;

        // Determinar quién es initiator y respondent
        bool initiatorIsTenant = (msg.sender == agreement.tenant);
        address respondent = initiatorIsTenant ? agreement.landlord : agreement.tenant;

        // Crear disputa en DisputeResolver
        // Forward el msg.value como arbitration fee
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

        // Decodificar disputeId retornado
        activeDisputeId = abi.decode(data, (uint256));

        // NOTE: TenantPassport no tiene incrementDisputes() en V2
        // El DisputeResolver se encargará de la reputación

        emit DisputeRaised(msg.sender, evidenceURI);
    }

    /**
     * @notice Aplica la resolución de una disputa
     * @dev Solo puede ser llamado por DisputeResolver después de votación
     * @param disputeId ID de la disputa resuelta
     * @param favorTenant true si resolvió a favor del tenant
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
        agreement.status = AgreementStatus.TERMINATED;

        // Withdraw deposit con yield del vault
        if (agreement.depositAmount > 0) {
            try vault.withdraw(agreement.depositAmount, address(this))
                returns (uint256 principal, uint256 yieldEarned)
            {
                if (favorTenant) {
                    // Tenant ganó → devolver depósito completo + yield
                    usdt.safeTransfer(agreement.tenant, principal + yieldEarned);
                } else {
                    // Landlord ganó → tenant pierde 30% del depósito
                    uint256 penalty = (principal * 30) / 100;
                    uint256 remaining = principal - penalty;

                    usdt.safeTransfer(agreement.landlord, penalty);
                    usdt.safeTransfer(agreement.tenant, remaining + yieldEarned);
                }
            } catch {
                // Fallback si vault falla
                uint256 balance = usdt.balanceOf(address(this));
                if (balance > 0) {
                    // En caso de error, dar todo al tenant (favor del duda)
                    usdt.safeTransfer(agreement.tenant, balance);
                }
                emit VaultWithdrawFailed(agreement.depositAmount, balance);
            }

            agreement.depositAmount = 0;
        }

        // Notificar factory
        (bool success, ) = factory.call(
            abi.encodeWithSignature("notifyAgreementTerminated(address)", msg.sender)
        );
        require(success, "Factory notification failed");
    }

    // View functions

    function getAgreementDetails() external view returns (Agreement memory) {
        return agreement;
    }

    function isPaymentOverdue() external view returns (bool) {
        return block.timestamp > nextPaymentDue &&
               agreement.status == AgreementStatus.ACTIVE;
    }

    function getDaysOverdue() external view returns (uint256) {
        if (block.timestamp <= nextPaymentDue) return 0;
        return (block.timestamp - nextPaymentDue) / 1 days;
    }

    function getPaymentSuccessRate() external view returns (uint256) {
        uint256 total = agreement.paymentsMade + agreement.paymentsMissed;
        if (total == 0) return 0;
        return (agreement.paymentsMade * 10000) / total;
    }

    function getAgreementProgress() external view returns (uint256) {
        if (agreement.status != AgreementStatus.ACTIVE) return 0;
        if (block.timestamp < agreement.startDate) return 0;
        if (block.timestamp >= agreement.endDate) return 10000;

        uint256 elapsed = block.timestamp - agreement.startDate;
        uint256 totalDuration = agreement.endDate - agreement.startDate;
        return (elapsed * 10000) / totalDuration;
    }
}
