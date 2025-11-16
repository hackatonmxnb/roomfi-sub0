"use client";

import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  Button,
  Typography,
  Box,
  Stack
} from '@mui/material';

// Define supported wallet types
export type WalletType = 'metamask' | 'subwallet';

interface WalletModalProps {
  open: boolean;
  onClose: () => void;
  onConnect: (wallet: WalletType) => void;
  onConnectGoogle: () => void;
  isCreatingWallet?: boolean;
}

export default function WalletModal({
  open,
  onClose,
  onConnect,
  onConnectGoogle,
  isCreatingWallet
}: WalletModalProps) {
  const handleConnect = (wallet: WalletType) => {
    onConnect(wallet);
    onClose();
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        <Typography variant="h5" component="h2" fontWeight="bold" textAlign="center">
          Conecta tu Wallet
        </Typography>
        <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mt: 1 }}>
          Elige tu proveedor de wallet preferido
        </Typography>
      </DialogTitle>

      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          {/* MetaMask */}
          <Button
            variant="outlined"
            size="large"
            fullWidth
            onClick={() => handleConnect('metamask')}
            startIcon={
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/3/36/MetaMask_Fox.svg"
                alt="MetaMask"
                style={{ width: 32, height: 32 }}
              />
            }
            sx={{
              py: 2,
              justifyContent: 'flex-start',
              textTransform: 'none',
              fontSize: '1.1rem',
              fontWeight: 600,
              borderWidth: 2,
              '&:hover': {
                borderWidth: 2,
                bgcolor: 'rgba(0,0,0,0.04)'
              }
            }}
          >
            MetaMask
          </Button>

          {/* SubWallet */}
          <Button
            variant="outlined"
            size="large"
            fullWidth
            onClick={() => handleConnect('subwallet')}
            startIcon={
              <Box
                sx={{
                  width: 32,
                  height: 32,
                  borderRadius: '50%',
                  bgcolor: '#000',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'white',
                  fontWeight: 'bold',
                  fontSize: '0.9rem'
                }}
              >
                SW
              </Box>
            }
            sx={{
              py: 2,
              justifyContent: 'flex-start',
              textTransform: 'none',
              fontSize: '1.1rem',
              fontWeight: 600,
              borderWidth: 2,
              '&:hover': {
                borderWidth: 2,
                bgcolor: 'rgba(0,0,0,0.04)'
              }
            }}
          >
            SubWallet
          </Button>

          <Box sx={{ position: 'relative', my: 2 }}>
            <Box sx={{ position: 'absolute', width: '100%', height: '1px', bgcolor: 'divider', top: '50%' }} />
            <Typography
              variant="caption"
              sx={{
                position: 'relative',
                display: 'inline-block',
                bgcolor: 'background.paper',
                px: 2,
                left: '50%',
                transform: 'translateX(-50%)',
                color: 'text.secondary'
              }}
            >
              o usa
            </Typography>
          </Box>

          {/* Google / Portal */}
          <Button
            variant="outlined"
            size="large"
            fullWidth
            onClick={() => {
              onConnectGoogle();
              onClose();
            }}
            disabled={isCreatingWallet}
            startIcon={
              <img
                src="https://developers.google.com/identity/images/g-logo.png"
                alt="Google"
                style={{ width: 24, height: 24 }}
              />
            }
            sx={{
              py: 2,
              justifyContent: 'flex-start',
              textTransform: 'none',
              fontSize: '1.1rem',
              fontWeight: 600,
              borderWidth: 2,
              '&:hover': {
                borderWidth: 2,
                bgcolor: 'rgba(0,0,0,0.04)'
              }
            }}
          >
            {isCreatingWallet ? 'Creando wallet...' : 'Iniciar sesión con Google'}
          </Button>

          {/* Información adicional */}
          <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 2 }}>
            <Typography variant="caption" color="text.secondary">
              <strong>💡 Tip:</strong> Si no tienes una wallet, MetaMask y SubWallet son gratuitas y fáciles de instalar.
            </Typography>
          </Box>
        </Stack>
      </DialogContent>
    </Dialog>
  );
}
