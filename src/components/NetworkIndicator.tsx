import React, { useEffect, useState } from 'react';
import { Box, Chip, Tooltip, Typography, CircularProgress } from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import { usePolkadot } from '../providers/PolkadotProvider';

interface NetworkIndicatorProps {
  showBlockNumber?: boolean;
  showLogo?: boolean;
  variant?: 'default' | 'compact';
}

export default function NetworkIndicator({
  showBlockNumber = true,
  showLogo = true,
  variant = 'default'
}: NetworkIndicatorProps) {
  const { api, isConnected } = usePolkadot();
  const [blockNumber, setBlockNumber] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!api || !isConnected) {
      setIsLoading(!isConnected);
      return;
    }

    let unsubscribe: (() => void) | null = null;

    async function subscribeToBlocks() {
      try {
        setIsLoading(false);
        unsubscribe = await api.rpc.chain.subscribeFinalizedHeads((header) => {
          setBlockNumber(header.number.toNumber());
        });
      } catch (error) {
        console.error('Error subscribing to blocks:', error);
        setIsLoading(false);
      }
    }

    subscribeToBlocks();

    return () => {
      if (unsubscribe) {
        unsubscribe();
      }
    };
  }, [api, isConnected]);

  const getStatusColor = () => {
    if (isLoading) return 'default';
    if (isConnected) return 'success';
    return 'error';
  };

  const getStatusIcon = () => {
    if (isLoading) {
      return <CircularProgress size={14} />;
    }
    if (isConnected) {
      return <CheckCircleIcon sx={{ fontSize: 16 }} />;
    }
    return <ErrorIcon sx={{ fontSize: 16 }} />;
  };

  const getStatusText = () => {
    if (isLoading) return 'Connecting...';
    if (isConnected) return 'Connected to Paseo AssetHub';
    return 'Disconnected from Paseo';
  };

  return (
    <Tooltip title={getStatusText()} arrow>
      <Box
        sx={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 1,
          px: variant === 'compact' ? 1 : 1.5,
          py: variant === 'compact' ? 0.5 : 0.75,
          borderRadius: 2,
          bgcolor: isConnected ? 'success.lighter' : 'grey.100',
          border: '1px solid',
          borderColor: isConnected ? 'success.main' : 'grey.300',
          transition: 'all 0.2s ease-in-out',
          cursor: 'default',
          '&:hover': {
            boxShadow: 1
          }
        }}
      >
        {/* Logo de Polkadot */}
        {showLogo && (
          <Box
            component="img"
            src="https://polkadot.js.org/apps/static/polkadot-circle.1eea8b47..svg"
            alt="Polkadot"
            sx={{
              width: variant === 'compact' ? 16 : 20,
              height: variant === 'compact' ? 16 : 20,
              opacity: isConnected ? 1 : 0.5
            }}
          />
        )}

        {/* Status Icon */}
        <Box sx={{ display: 'flex', alignItems: 'center', color: getStatusColor() }}>
          {getStatusIcon()}
        </Box>

        {/* Network Name */}
        <Typography
          variant={variant === 'compact' ? 'caption' : 'body2'}
          sx={{
            fontWeight: 600,
            color: isConnected ? 'success.dark' : 'text.secondary',
            fontSize: variant === 'compact' ? '0.75rem' : '0.875rem'
          }}
        >
          Paseo
        </Typography>

        {/* Block Number */}
        {showBlockNumber && blockNumber !== null && (
          <>
            <Box
              sx={{
                width: 1,
                height: variant === 'compact' ? 12 : 16,
                bgcolor: 'divider'
              }}
            />
            <Typography
              variant={variant === 'compact' ? 'caption' : 'body2'}
              sx={{
                fontFamily: 'monospace',
                color: 'text.secondary',
                fontSize: variant === 'compact' ? '0.7rem' : '0.8rem',
                minWidth: variant === 'compact' ? 50 : 60,
                textAlign: 'right'
              }}
            >
              #{blockNumber.toLocaleString()}
            </Typography>
          </>
        )}
      </Box>
    </Tooltip>
  );
}
