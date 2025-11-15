// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/V2/TenantPassportV2.sol";
import "../src/V2/PropertyRegistry.sol";
import "../src/V2/DisputeResolver.sol";
import "../src/V2/RentalAgreementFactory.sol";
import "../src/V2/RentalAgreementWithVault.sol";
import "../src/V2/RoomFiVault.sol";
import "../src/V2/strategies/AcalaYieldStrategy.sol";

/**
 * @title DeployRoomFiV2
 * @notice Script de deployment para RoomFi V2 en Moonbeam (Paseo testnet)
 * @dev Despliega todos los contratos en el orden correcto
 *
 * ORDEN DE DEPLOYMENT:
 * 1. AcalaYieldStrategy
 * 2. RoomFiVault
 * 3. TenantPassportV2
 * 4. PropertyRegistry
 * 5. DisputeResolver
 * 6. RentalAgreementWithVault (implementation)
 * 7. RentalAgreementFactory
 * 8. Setup & Autorizaciones
 *
 * NETWORKS:
 * - Moonbase Alpha (Moonbeam testnet): chainId 1287
 * - Moonbeam Mainnet: chainId 1284
 *
 * USAGE:
 * forge script script/DeployRoomFiV2.s.sol:DeployRoomFiV2 \
 *   --rpc-url $MOONBASE_RPC \
 *   --broadcast \
 *   --verify \
 *   -vvvv
 */
contract DeployRoomFiV2 is Script {

    // ============================================
    // DEPLOYMENT ADDRESSES (will be populated)
    // ============================================

    address public usdtAddress;
    address public acalaStrategy;
    address public roomfiVault;
    address public tenantPassport;
    address public propertyRegistry;
    address public disputeResolver;
    address public rentalAgreementImplementation;
    address public rentalFactory;

    // Deployer
    address public deployer;

    // ============================================
    // CONFIGURATION
    // ============================================

    // USDT address en Moonbase Alpha (testnet)
    // Si no existe, necesitas deployar un mock USDT primero
    address public constant USDT_MOONBASE = address(0); // TODO: Set real USDT address

    // Si USDT_MOONBASE == 0, deployamos mock USDT
    bool public deployMockUSDT = true;

    // ============================================
    // MAIN DEPLOYMENT FUNCTION
    // ============================================

    function run() external {
        // Setup deployer
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("ROOMFI V2 - DEPLOYMENT SCRIPT");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("========================================\n");

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // STEP 0: Deploy/Setup USDT
        // ========================================
        console.log("STEP 0: Setup USDT...");

        if (USDT_MOONBASE != address(0)) {
            usdtAddress = USDT_MOONBASE;
            console.log("Using existing USDT:", usdtAddress);
        } else if (deployMockUSDT) {
            usdtAddress = _deployMockUSDT();
            console.log("Deployed Mock USDT:", usdtAddress);
        } else {
            revert("USDT address not configured");
        }

        console.log("");

        // ========================================
        // STEP 1: Deploy AcalaYieldStrategy
        // ========================================
        console.log("STEP 1: Deploying AcalaYieldStrategy...");

        acalaStrategy = address(new AcalaYieldStrategy(
            usdtAddress,
            deployer  // initialOwner
        ));

        console.log("AcalaYieldStrategy deployed at:", acalaStrategy);
        console.log("");

        // ========================================
        // STEP 2: Deploy RoomFiVault
        // ========================================
        console.log("STEP 2: Deploying RoomFiVault...");

        roomfiVault = address(new RoomFiVault(
            usdtAddress,
            acalaStrategy,
            deployer  // initialOwner
        ));

        console.log("RoomFiVault deployed at:", roomfiVault);
        console.log("");

        // ========================================
        // STEP 3: Deploy TenantPassportV2
        // ========================================
        console.log("STEP 3: Deploying TenantPassportV2...");

        tenantPassport = address(new TenantPassportV2(
            deployer  // initialOwner
        ));

        console.log("TenantPassportV2 deployed at:", tenantPassport);
        console.log("");

        // ========================================
        // STEP 4: Deploy PropertyRegistry
        // ========================================
        console.log("STEP 4: Deploying PropertyRegistry...");

        propertyRegistry = address(new PropertyRegistry(
            tenantPassport,
            deployer  // initialOwner
        ));

        console.log("PropertyRegistry deployed at:", propertyRegistry);
        console.log("");

        // ========================================
        // STEP 5: Deploy DisputeResolver
        // ========================================
        console.log("STEP 5: Deploying DisputeResolver...");

        disputeResolver = address(new DisputeResolver(
            tenantPassport,
            propertyRegistry,
            deployer  // initialOwner
        ));

        console.log("DisputeResolver deployed at:", disputeResolver);
        console.log("");

        // ========================================
        // STEP 6: Deploy RentalAgreement Implementation
        // ========================================
        console.log("STEP 6: Deploying RentalAgreementWithVault (implementation)...");

        rentalAgreementImplementation = address(new RentalAgreementWithVault(
            usdtAddress,
            roomfiVault
        ));

        console.log("RentalAgreementWithVault implementation deployed at:", rentalAgreementImplementation);
        console.log("");

        // ========================================
        // STEP 7: Deploy RentalAgreementFactory
        // ========================================
        console.log("STEP 7: Deploying RentalAgreementFactory...");

        rentalFactory = address(new RentalAgreementFactory(
            propertyRegistry,
            tenantPassport,
            disputeResolver,
            rentalAgreementImplementation,  // implementation address
            deployer  // initialOwner
        ));

        console.log("RentalAgreementFactory deployed at:", rentalFactory);
        console.log("");

        // ========================================
        // STEP 8: Setup & Autorizaciones
        // ========================================
        console.log("STEP 8: Setting up authorizations...");

        // Autorizar factory como updater en TenantPassport
        TenantPassportV2(tenantPassport).authorizeUpdater(rentalFactory);
        console.log("  - RentalFactory authorized as updater in TenantPassport");

        // Autorizar factory como updater en PropertyRegistry
        PropertyRegistry(propertyRegistry).authorizeUpdater(rentalFactory);
        console.log("  - RentalFactory authorized as updater in PropertyRegistry");

        // NOTA: Cada RentalAgreement clone debe ser autorizado individualmente en el Vault
        // Esto se debe hacer cuando se cree cada agreement llamando:
        // roomfiVault.setAuthorizedDepositor(agreementAddress, true)
        // El owner del vault puede hacer esto manualmente o via script

        // TODO: Autorizar verificadores iniciales
        // PropertyRegistry(propertyRegistry).authorizeVerifier(VERIFIER_ADDRESS);

        // TODO: Autorizar árbitros iniciales
        // DisputeResolver(disputeResolver).authorizeArbitrator(ARBITRATOR_ADDRESS);

        console.log("");

        vm.stopBroadcast();

        // ========================================
        // DEPLOYMENT SUMMARY
        // ========================================
        _printDeploymentSummary();

        // ========================================
        // Save addresses to file
        // ========================================
        _saveAddresses();
    }

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    /**
     * @notice Deploys a mock USDT for testing
     */
    function _deployMockUSDT() internal returns (address) {
        // Deploy mock ERC20 with 6 decimals (como USDT real)
        MockUSDT mockUSDT = new MockUSDT();

        // Mint initial supply al deployer (1M USDT)
        mockUSDT.mint(deployer, 1_000_000 * 1e6);

        return address(mockUSDT);
    }

    /**
     * @notice Prints deployment summary
     */
    function _printDeploymentSummary() internal view {
        console.log("========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("USDT:                    ", usdtAddress);
        console.log("AcalaYieldStrategy:      ", acalaStrategy);
        console.log("RoomFiVault:             ", roomfiVault);
        console.log("TenantPassportV2:        ", tenantPassport);
        console.log("PropertyRegistry:        ", propertyRegistry);
        console.log("DisputeResolver:         ", disputeResolver);
        console.log("RentalAgreement (impl):  ", rentalAgreementImplementation);
        console.log("RentalAgreementFactory:  ", rentalFactory);
        console.log("========================================");
        console.log("\nDeployment completed successfully!");
        console.log("\nNext steps:");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Authorize verifiers in PropertyRegistry");
        console.log("3. Authorize arbitrators in DisputeResolver");
        console.log("4. Update frontend config with new addresses");
        console.log("5. Test full flow on testnet");
        console.log("========================================\n");
    }

    /**
     * @notice Saves addresses to JSON file
     */
    function _saveAddresses() internal {
        string memory obj = "deployment";

        vm.serializeAddress(obj, "USDT", usdtAddress);
        vm.serializeAddress(obj, "AcalaYieldStrategy", acalaStrategy);
        vm.serializeAddress(obj, "RoomFiVault", roomfiVault);
        vm.serializeAddress(obj, "TenantPassportV2", tenantPassport);
        vm.serializeAddress(obj, "PropertyRegistry", propertyRegistry);
        vm.serializeAddress(obj, "DisputeResolver", disputeResolver);
        vm.serializeAddress(obj, "RentalAgreementImplementation", rentalAgreementImplementation);
        string memory finalJson = vm.serializeAddress(obj, "RentalAgreementFactory", rentalFactory);

        vm.writeJson(finalJson, "./deployment-addresses.json");

        console.log("Addresses saved to deployment-addresses.json");
    }
}

/**
 * @title MockUSDT
 * @notice Mock USDT for testing (6 decimals like real USDT)
 */
contract MockUSDT {
    string public constant name = "Mock USDT";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
