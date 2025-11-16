import React from 'react';
import { ApiPromise, WsProvider } from '@polkadot/api';

interface PolkadotContextType {
  api: ApiPromise | null;
  isConnected: boolean;
}

export const PolkadotContext = React.createContext<PolkadotContextType>({
  api: null,
  isConnected: false,
});

interface PolkadotProviderProps {
  children: React.ReactNode;
  wsEndpoint?: string;
}

export function PolkadotProvider({ 
  children, 
  wsEndpoint = 'wss://paseo-asset-hub-rpc.polkadot.io' 
}: PolkadotProviderProps) {
  const [api, setApi] = React.useState<ApiPromise | null>(null);
  const [isConnected, setIsConnected] = React.useState(false);

  React.useEffect(() => {
    let mounted = true;

    async function connect() {
      try {
        console.log('🔗 Connecting to Paseo AssetHub...');
        const wsProvider = new WsProvider(wsEndpoint);
        const apiInstance = await ApiPromise.create({ provider: wsProvider });

        if (mounted) {
          setApi(apiInstance);
          setIsConnected(true);
          console.log('✅ Connected to Paseo AssetHub');
        }
      } catch (error) {
        console.error('❌ Error connecting to Polkadot:', error);
        if (mounted) {
          setIsConnected(false);
        }
      }
    }

    connect();

    return () => {
      mounted = false;
      if (api) {
        api.disconnect();
      }
    };
  }, [wsEndpoint]);

  return (
    <PolkadotContext.Provider value={{ api, isConnected }}>
      {children}
    </PolkadotContext.Provider>
  );
}

export function usePolkadot() {
  const context = React.useContext(PolkadotContext);
  if (!context) {
    throw new Error('usePolkadot must be used within PolkadotProvider');
  }
  return context;
}
