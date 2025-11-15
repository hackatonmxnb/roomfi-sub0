// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RentalAgreementFactory
 * @author RoomFi Team - Firrton
 * @notice Factory para crear rental agreements dinámicamente usando Clone pattern
 * @dev Implementa EIP-1167 para reducir gas costs en deployment de agreements
 *
 * Características:
 * - Clone pattern (minimal proxy) para gas efficiency
 * - Tracking de agreements por propiedad
 * - Validaciones integradas con PropertyRegistry y TenantPassport
 * - Eventos completos para indexing
 */

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RentalAgreement.sol";
import "./Interfaces.sol";

contract RentalAgreementFactory is Ownable {

    // Storage

    address public immutable rentalAgreementImplementation;
    address public immutable propertyRegistry;
    address public immutable tenantPassport;
    address public immutable disputeResolver;

    mapping(uint256 => address[]) public propertyAgreements;
    mapping(address => address[]) public tenantAgreements;
    mapping(address => address[]) public landlordAgreements;

    address[] public allAgreements;
    mapping(address => bool) public isValidAgreement;

    uint256 public totalAgreementsCreated;
    uint256 public activeAgreements;

    uint32 public constant MIN_TENANT_REPUTATION = 40;
    uint256 public constant MIN_DURATION = 1;
    uint256 public constant MAX_DURATION = 24;

    // Eventos

    event AgreementCreated(
        address indexed agreement,
        uint256 indexed propertyId,
        address indexed tenant,
        address landlord,
        uint256 monthlyRent,
        uint256 duration,
        uint256 timestamp
    );

    event AgreementActivated(
        address indexed agreement,
        uint256 timestamp
    );

    event AgreementCompleted(
        address indexed agreement,
        uint256 timestamp
    );

    event AgreementTerminated(
        address indexed agreement,
        address indexed initiator,
        uint256 timestamp
    );

    // Modifiers

    modifier onlyValidAgreement() {
        require(isValidAgreement[msg.sender], "RentalFactory: Agreement no valido");
        _;
    }

    // Constructor

    /**
     * @notice Inicializa el factory con las referencias a los contratos core
     * @param _propertyRegistry Dirección del PropertyRegistry
     * @param _tenantPassport Dirección del TenantPassport
     * @param _disputeResolver Dirección del DisputeResolver
     * @param _rentalAgreementImpl Dirección del implementation de RentalAgreement
     * @param initialOwner Owner inicial del factory
     */
    constructor(
        address _propertyRegistry,
        address _tenantPassport,
        address _disputeResolver,
        address _rentalAgreementImpl,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_propertyRegistry != address(0), "Invalid PropertyRegistry");
        require(_tenantPassport != address(0), "Invalid TenantPassport");
        require(_disputeResolver != address(0), "Invalid DisputeResolver");
        require(_rentalAgreementImpl != address(0), "Invalid RentalAgreement implementation");

        propertyRegistry = _propertyRegistry;
        tenantPassport = _tenantPassport;
        disputeResolver = _disputeResolver;
        rentalAgreementImplementation = _rentalAgreementImpl;
    }

    // Funciones principales

    /**
     * @notice Crea un nuevo rental agreement usando Clone pattern
     * @param propertyId ID de la propiedad
     * @param tenant Dirección del tenant
     * @param monthlyRent Renta mensual en wei
     * @param securityDeposit Depósito de garantía en wei
     * @param duration Duración en meses
     * @return agreement Dirección del nuevo agreement
     */
    function createAgreement(
        uint256 propertyId,
        address tenant,
        uint256 monthlyRent,
        uint256 securityDeposit,
        uint256 duration
    ) external returns (address agreement) {
        require(tenant != address(0), "Invalid tenant address");
        require(tenant != msg.sender, "Landlord cannot be tenant");
        require(monthlyRent > 0, "Rent must be greater than 0");
        require(securityDeposit > 0, "Deposit must be greater than 0");
        require(duration >= MIN_DURATION && duration <= MAX_DURATION, "Invalid duration");

        // Validar que el caller sea el owner de la property
        address landlord = IPropertyRegistry(propertyRegistry).ownerOf(propertyId);
        require(landlord == msg.sender, "Not property owner");

        // Validar disponibilidad de property (activa, verificada, no delisted)
        require(
            IPropertyRegistry(propertyRegistry).isPropertyAvailableForRent(propertyId),
            "Property not available for rent"
        );

        require(
            ITenantPassport(tenantPassport).hasPassport(tenant),
            "Tenant needs passport"
        );

        uint256 tenantTokenId = ITenantPassport(tenantPassport).getTokenIdByAddress(tenant);
        uint32 tenantReputation = ITenantPassport(tenantPassport).getReputationWithDecay(tenantTokenId);
        require(
            tenantReputation >= MIN_TENANT_REPUTATION,
            "Tenant reputation too low"
        );

        agreement = Clones.clone(rentalAgreementImplementation);

        IRentalAgreement(agreement).initialize(
            propertyId,
            landlord,
            tenant,
            monthlyRent,
            securityDeposit,
            duration,
            propertyRegistry,
            tenantPassport,
            address(this),
            disputeResolver
        );

        propertyAgreements[propertyId].push(agreement);
        tenantAgreements[tenant].push(agreement);
        landlordAgreements[landlord].push(agreement);
        allAgreements.push(agreement);
        isValidAgreement[agreement] = true;

        totalAgreementsCreated++;

        emit AgreementCreated(
            agreement,
            propertyId,
            tenant,
            landlord,
            monthlyRent,
            duration,
            block.timestamp
        );

        return agreement;
    }

    /**
     * @notice Callback llamado por agreement cuando se activa
     * @dev Solo puede ser llamado por agreements válidos
     */
    function notifyAgreementActivated() external onlyValidAgreement {
        activeAgreements++;
        emit AgreementActivated(msg.sender, block.timestamp);
    }

    /**
     * @notice Callback llamado por agreement cuando se completa
     * @dev Solo puede ser llamado por agreements válidos
     */
    function notifyAgreementCompleted() external onlyValidAgreement {
        require(activeAgreements > 0, "No active agreements to complete");
        activeAgreements--;
        emit AgreementCompleted(msg.sender, block.timestamp);
    }

    /**
     * @notice Callback llamado por agreement cuando se termina anticipadamente
     * @dev Solo puede ser llamado por agreements válidos
     */
    function notifyAgreementTerminated(address initiator) external onlyValidAgreement {
        require(activeAgreements > 0, "No active agreements to terminate");
        activeAgreements--;
        emit AgreementTerminated(msg.sender, initiator, block.timestamp);
    }

    // View functions

    /**
     * @notice Obtiene todos los agreements de una propiedad
     */
    function getPropertyAgreements(uint256 propertyId)
        external
        view
        returns (address[] memory)
    {
        return propertyAgreements[propertyId];
    }

    /**
     * @notice Obtiene todos los agreements de un tenant
     */
    function getTenantAgreements(address tenant)
        external
        view
        returns (address[] memory)
    {
        return tenantAgreements[tenant];
    }

    /**
     * @notice Obtiene todos los agreements de un landlord
     */
    function getLandlordAgreements(address landlord)
        external
        view
        returns (address[] memory)
    {
        return landlordAgreements[landlord];
    }

    /**
     * @notice Obtiene el total de agreements creados
     */
    function getTotalAgreements() external view returns (uint256) {
        return allAgreements.length;
    }

    /**
     * @notice Obtiene agreements en un rango (paginación)
     */
    function getAgreements(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        uint256 total = allAgreements.length;
        if (offset >= total) {
            return new address[](0);
        }

        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }

        address[] memory result = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = allAgreements[i];
        }

        return result;
    }

    /**
     * @notice Verifica si un agreement fue creado por este factory
     */
    function isAgreementValid(address agreement) external view returns (bool) {
        return isValidAgreement[agreement];
    }

    /**
     * @notice Obtiene estadísticas del factory
     */
    function getFactoryStats()
        external
        view
        returns (
            uint256 total,
            uint256 active,
            uint256 completed
        )
    {
        total = totalAgreementsCreated;
        active = activeAgreements;
        completed = total > active ? total - active : 0;

        return (total, active, completed);
    }
}
