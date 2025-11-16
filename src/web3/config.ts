import MXNB_ABI from './abis/MXNB_ABI.json';
import TENANT_PASSPORT_ABI from './abis/TENANT_PASSPORT_ABI.json';
import PROPERTY_INTEREST_POOL_ABI from './abis/PROPERTY_INTEREST_POOL_ABI.json';
import INTEREST_GENERATOR_ABI from './abis/INTEREST_GENERATOR_ABI.json';
import PROPERTY_REGISTRY_ABI from './abis/PROPERTY_REGISTRY_ABI.json';

export type EvmNetwork = 'paseo' | 'arbitrum';

export const NETWORKS_CONFIG: Record<EvmNetwork, { rpcUrl: string; chainId: number; chainName: string }> = {
  paseo: {
    rpcUrl: "https://testnet-passet-hub-eth-rpc.polkadot.io",
    chainId: 420420422,
    chainName: 'AssetHub Paseo Testnet',
  },
  arbitrum: {
    rpcUrl: "https://sepolia-rollup.arbitrum.io/rpc",
    chainId: 421614,
    chainName: "Arbitrum Sepolia",
  },
};

export const CONTRACTS: Record<EvmNetwork, {
  MXNBT_ADDRESS: string;
  TENANT_PASSPORT_ADDRESS: string;
  PROPERTY_INTEREST_POOL_ADDRESS: string;
  INTEREST_GENERATOR_ADDRESS: string;
  PROPERTY_REGISTRY_ADDRESS?: string;
  RENTAL_AGREEMENT_FACTORY_ADDRESS?: string;
  DISPUTE_RESOLVER_ADDRESS?: string;
  VAULT_ADDRESS?: string;
}> = {
  paseo: {
    // V2 Contracts on Paseo (AssetHub)
    MXNBT_ADDRESS: "0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8", // MockUSDT
    TENANT_PASSPORT_ADDRESS: "0x3dE7d06a9C36da9F603E449E512fab967Cc740a3", // TenantPassportV2
    PROPERTY_INTEREST_POOL_ADDRESS: "", // Not used in V2
    INTEREST_GENERATOR_ADDRESS: "0xD2C0Be059ab58367B209290934005f76264b59db", // RoomFiVault
    PROPERTY_REGISTRY_ADDRESS: "0x752A5e16899f0849e2B632eA7F7446B2D11d1e17",
    RENTAL_AGREEMENT_FACTORY_ADDRESS: "0x1514e3cCC72bc2FdcA2E7a6d52303917a133E5ae",
    DISPUTE_RESOLVER_ADDRESS: "0xbb037C5EA4987858Ba2211046297929F6558dB6a",
    VAULT_ADDRESS: "0xD2C0Be059ab58367B209290934005f76264b59db", // RoomFiVault
  },
  arbitrum: {
    // V1 Contracts on Arbitrum Sepolia
    MXNBT_ADDRESS: "0x82B9e52b26A2954E113F94Ff26647754d5a4247D",
    TENANT_PASSPORT_ADDRESS: "0x674687e09042452C0ad3D5EC06912bf4979bFC33",
    PROPERTY_INTEREST_POOL_ADDRESS: "0xeD9018D47ee787C5d84A75A42Df786b8540cC75b",
    INTEREST_GENERATOR_ADDRESS: "0xF8F626afB4AadB41Be7D746e53Ff417735b1C289",
  },
};

export const NETWORK_CONFIG = NETWORKS_CONFIG.arbitrum;

// Legacy exports para código V1 (solo para Arbitrum)
export const MXNBT_ADDRESS = CONTRACTS.arbitrum.MXNBT_ADDRESS;
export const TENANT_PASSPORT_ADDRESS = CONTRACTS.arbitrum.TENANT_PASSPORT_ADDRESS;
export const PROPERTY_INTEREST_POOL_ADDRESS = CONTRACTS.arbitrum.PROPERTY_INTEREST_POOL_ADDRESS;
export const INTEREST_GENERATOR_ADDRESS = CONTRACTS.arbitrum.INTEREST_GENERATOR_ADDRESS;
export const VAULT_ADDRESS = CONTRACTS.arbitrum.INTEREST_GENERATOR_ADDRESS; // V1 usa INTEREST_GENERATOR como vault

// --- Contract ABIs (Imported from JSON files) ---
export {
    MXNB_ABI,
    TENANT_PASSPORT_ABI,
    PROPERTY_INTEREST_POOL_ABI,
    INTEREST_GENERATOR_ABI,
    PROPERTY_REGISTRY_ABI
};