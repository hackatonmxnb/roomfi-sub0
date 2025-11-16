import React from 'react';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Typography, Box, Stepper, Step, StepLabel, StepContent, Alert } from '@mui/material';
import SecurityIcon from '@mui/icons-material/Security';
import SettingsIcon from '@mui/icons-material/Settings';
import LinkIcon from '@mui/icons-material/Link';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';

interface SubwalletAuthModalProps {
  open: boolean;
  onClose: () => void;
  domain: string;
}

export default function SubwalletAuthModal({ open, onClose, domain }: SubwalletAuthModalProps) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        <Box display="flex" alignItems="center" gap={1}>
          <SecurityIcon color="warning" />
          <Typography variant="h6">Autorización de Subwallet Requerida</Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent dividers>
        <Alert severity="info" sx={{ mb: 3 }}>
          <strong>¿Por qué veo esto?</strong><br />
          Subwallet requiere que autorices explícitamente cada sitio web por tu seguridad.
          Esto solo lo harás una vez.
        </Alert>

        <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', mb: 2 }}>
          Sigue estos pasos para conectar:
        </Typography>

        <Stepper orientation="vertical">
          <Step active>
            <StepLabel icon={<SettingsIcon />}>
              <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                Abre la extensión Subwallet
              </Typography>
            </StepLabel>
            <StepContent>
              <Typography variant="body2" color="text.secondary">
                Haz clic en el ícono de Subwallet en tu navegador
              </Typography>
            </StepContent>
          </Step>

          <Step active>
            <StepLabel icon="⚙️">
              <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                Ve a Configuración
              </Typography>
            </StepLabel>
            <StepContent>
              <Typography variant="body2" color="text.secondary">
                Busca el ícono de engranaje (⚙️) y haz clic
              </Typography>
            </StepContent>
          </Step>

          <Step active>
            <StepLabel icon={<LinkIcon />}>
              <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                Busca "Manage Website Access"
              </Typography>
            </StepLabel>
            <StepContent>
              <Typography variant="body2" color="text.secondary">
                Puede estar en la sección de Seguridad o Conexiones
              </Typography>
            </StepContent>
          </Step>

          <Step active>
            <StepLabel icon="➕">
              <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                Agrega este dominio
              </Typography>
            </StepLabel>
            <StepContent>
              <Box sx={{ bgcolor: 'grey.100', p: 1.5, borderRadius: 1, mb: 1 }}>
                <Typography variant="body2" sx={{ fontFamily: 'monospace', fontWeight: 'bold' }}>
                  {domain}
                </Typography>
              </Box>
              <Typography variant="caption" color="text.secondary">
                Copia y pega esta dirección exacta
              </Typography>
            </StepContent>
          </Step>

          <Step active>
            <StepLabel icon={<CheckCircleIcon />}>
              <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                Intenta conectar de nuevo
              </Typography>
            </StepLabel>
            <StepContent>
              <Typography variant="body2" color="text.secondary">
                Recarga esta página y haz clic en "Conectar Wallet"
              </Typography>
            </StepContent>
          </Step>
        </Stepper>

        <Box sx={{ mt: 3, p: 2, bgcolor: 'info.light', borderRadius: 1 }}>
          <Typography variant="body2">
            <strong>💡 Tip:</strong> Este es un paso de seguridad estándar. 
            Solo necesitas hacerlo una vez por sitio.
          </Typography>
        </Box>

        <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
          <Typography variant="caption" color="text.secondary">
            <strong>¿Prefieres usar MetaMask?</strong><br />
            MetaMask no requiere este paso adicional y funciona directamente.
          </Typography>
        </Box>
      </DialogContent>
      
      <DialogActions sx={{ p: 2 }}>
        <Button onClick={onClose} variant="outlined">
          Cerrar
        </Button>
        <Button 
          onClick={() => {
            window.open('https://docs.subwallet.app/', '_blank');
          }}
          variant="text"
        >
          Ver Documentación
        </Button>
        <Button onClick={onClose} variant="contained">
          Entendido
        </Button>
      </DialogActions>
    </Dialog>
  );
}
