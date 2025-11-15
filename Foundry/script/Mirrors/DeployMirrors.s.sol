// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/Mirrors/TenantPassportMirror.sol";
import "../../src/Mirrors/PropertyRegistryMirror.sol";
import "../../src/Mirrors/ISMPMessageHandler.sol";

/**
 * @title DeployMirrors
 * @notice Script para deployar contratos mirror en Moonbeam/Arbitrum
 * @dev Usar con Foundry: forge script script/Mirrors/DeployMirrors.s.sol
 *
 * CHAINS SOPORTADAS:
 * - Moonbeam (chainId: 1284)
 * - Moonbase Alpha Testnet (chainId: 1287)
 * - Arbitrum One (chainId: 42161)
 * - Arbitrum Sepolia (chainId: 421614)
 *
 * SETUP:
 * 1. Configurar .env con:
 *    - PRIVATE_KEY
 *    - MOONBEAM_RPC_URL / ARBITRUM_RPC_URL
 *    - PASEO_CHAIN_ID
 *    (NOTA: HYPERBRIDGE_HOST_ADDRESS ya NO es necesario - se auto-detecta por chainId)
 *
 * 2. Ejecutar:
 *    forge script script/Mirrors/DeployMirrors.s.sol:DeployMirrors \
 *      --rpc-url $MOONBEAM_RPC_URL \
 *      --broadcast \
 *      --verify
 *
 * DEPLOYMENT ORDER:
 * 1. TenantPassportMirror
 * 2. PropertyRegistryMirror
 * 3. ISMPMessageHandler
 * 4. Configuración de permisos
 */
contract DeployMirrors is Script {

    // Configuración por chain
    struct ChainConfig {
        string name;
        bytes paseoChainId;
        uint256 sourceChainId; // Paseo chain ID
    }

    // NOTE: hyperbridgeHost is auto-detected by BaseIsmpModule per chainId
    // No need to configure manually

    // Contratos deployados
    TenantPassportMirror public tenantMirror;
    PropertyRegistryMirror public propertyMirror;
    ISMPMessageHandler public messageHandler;

    function run() external virtual {
        _run();
    }

    function _run() internal {
        // Leer configuración
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===========================================");
        console.log("  RoomFi Mirror Contracts Deployment");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        // Obtener configuración de la chain actual
        ChainConfig memory config = getChainConfig(block.chainid);
        console.log("Deploying to:", config.name);
        console.log("Source Chain ID (Paseo):", config.sourceChainId);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ==============================================
        // PASO 1: Deploy TenantPassportMirror
        // ==============================================
        console.log("1. Deploying TenantPassportMirror...");

        // Primero deployamos con address(0) para handler, lo actualizamos después
        tenantMirror = new TenantPassportMirror(
            address(0),              // ismpHandler (actualizar después)
            config.sourceChainId,    // Paseo chain ID
            deployer                 // initialOwner
        );

        console.log("   TenantPassportMirror deployed at:", address(tenantMirror));
        console.log("");

        // ==============================================
        // PASO 2: Deploy PropertyRegistryMirror
        // ==============================================
        console.log("2. Deploying PropertyRegistryMirror...");

        propertyMirror = new PropertyRegistryMirror(
            address(0),              // ismpHandler (actualizar después)
            config.sourceChainId,    // Paseo chain ID
            deployer                 // initialOwner
        );

        console.log("   PropertyRegistryMirror deployed at:", address(propertyMirror));
        console.log("");

        // ==============================================
        // PASO 3: Deploy ISMPMessageHandler
        // ==============================================
        console.log("3. Deploying ISMPMessageHandler...");
        console.log("   NOTE: Using official Hyperbridge SDK (BaseIsmpModule)");
        console.log("   Hyperbridge Host is auto-detected by chainId");

        messageHandler = new ISMPMessageHandler(
            config.paseoChainId,      // Paseo chain ID en formato ISMP
            address(tenantMirror),    // TenantPassportMirror
            address(propertyMirror),  // PropertyRegistryMirror
            deployer                  // initialOwner
        );

        console.log("   ISMPMessageHandler deployed at:", address(messageHandler));
        console.log("   Hyperbridge Host auto-detected:", messageHandler.host());
        console.log("");

        // ==============================================
        // PASO 4: Configurar permisos
        // ==============================================
        console.log("4. Configuring permissions...");

        // TenantPassportMirror: autorizar handler
        tenantMirror.setISMPHandler(address(messageHandler));
        console.log("   TenantMirror handler set");

        // PropertyRegistryMirror: autorizar handler
        propertyMirror.setISMPHandler(address(messageHandler));
        console.log("   PropertyMirror handler set");

        console.log("");

        vm.stopBroadcast();

        // ==============================================
        // RESUMEN
        // ==============================================
        console.log("===========================================");
        console.log("  Deployment Complete!");
        console.log("===========================================");
        console.log("");
        console.log("DEPLOYED CONTRACTS:");
        console.log("-------------------------------------------");
        console.log("TenantPassportMirror:", address(tenantMirror));
        console.log("PropertyRegistryMirror:", address(propertyMirror));
        console.log("ISMPMessageHandler:", address(messageHandler));
        console.log("");
        console.log("NEXT STEPS:");
        console.log("-------------------------------------------");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Register these addresses in Paseo pallet:");
        console.log("   - Call: roomfiBridge.registerMirrorContract()");
        console.log("   - Chain:", config.name);
        console.log("   - TenantMirror:", address(tenantMirror));
        console.log("   - PropertyMirror:", address(propertyMirror));
        console.log("");
        console.log("3. Test cross-chain sync:");
        console.log("   - Call: roomfiBridge.syncReputationToChain()");
        console.log("   - Monitor events on both chains");
        console.log("");
        console.log("===========================================");

        // Guardar addresses en archivo JSON
        string memory json = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "chainName": "', config.name, '",\n',
            '  "deployer": "', vm.toString(deployer), '",\n',
            '  "contracts": {\n',
            '    "TenantPassportMirror": "', vm.toString(address(tenantMirror)), '",\n',
            '    "PropertyRegistryMirror": "', vm.toString(address(propertyMirror)), '",\n',
            '    "ISMPMessageHandler": "', vm.toString(address(messageHandler)), '"\n',
            '  },\n',
            '  "hyperbridgeHost": "', vm.toString(messageHandler.host()), '",\n',
            '  "hyperbridgeHostNote": "Auto-detected by BaseIsmpModule",\n',
            '  "paseoChainId": ', vm.toString(config.sourceChainId), '\n',
            '}'
        ));

        string memory filename = string(abi.encodePacked(
            "deployments/",
            config.name,
            "-",
            vm.toString(block.chainid),
            ".json"
        ));

        vm.writeFile(filename, json);
        console.log("Deployment info saved to:", filename);
    }

    /**
     * @notice Obtiene configuración de la chain actual
     */
    function getChainConfig(uint256 chainId) internal pure returns (ChainConfig memory) {
        if (chainId == 1287) {
            // Moonbase Alpha Testnet
            return ChainConfig({
                name: "moonbase-alpha",
                paseoChainId: hex"70617365", // "paseo" en hex
                sourceChainId: 1000 // Paseo testnet
            });
        }
        else if (chainId == 1284) {
            // Moonbeam Mainnet
            return ChainConfig({
                name: "moonbeam",
                paseoChainId: hex"70617365",
                sourceChainId: 1000
            });
        }
        else if (chainId == 421614) {
            // Arbitrum Sepolia
            return ChainConfig({
                name: "arbitrum-sepolia",
                paseoChainId: hex"70617365",
                sourceChainId: 1000
            });
        }
        else if (chainId == 42161) {
            // Arbitrum One
            return ChainConfig({
                name: "arbitrum",
                paseoChainId: hex"70617365",
                sourceChainId: 1000
            });
        }
        else {
            // Chain no soportada, usar valores por defecto
            // NOTE: Will revert during deployment as BaseIsmpModule
            // only supports specific chains
            return ChainConfig({
                name: "unknown",
                paseoChainId: hex"70617365",
                sourceChainId: 1000
            });
        }
    }

    // NOTE: getEnvAddressOrDefault removed - no longer needed
    // as BaseIsmpModule auto-detects Hyperbridge Host by chainId
}

/**
 * @title DeployMoonbeam
 * @notice Script específico para Moonbeam/Moonbase
 */
contract DeployMoonbeam is DeployMirrors {
    function run() external override {
        require(
            block.chainid == 1284 || block.chainid == 1287,
            "This script is for Moonbeam/Moonbase only"
        );
        _run();
    }
}

/**
 * @title DeployArbitrum
 * @notice Script específico para Arbitrum
 */
contract DeployArbitrum is DeployMirrors {
    function run() external override {
        require(
            block.chainid == 42161 || block.chainid == 421614,
            "This script is for Arbitrum only"
        );
        _run();
    }
}
