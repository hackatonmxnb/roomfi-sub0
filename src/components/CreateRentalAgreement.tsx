import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Box,
  Typography,
  Alert,
  Stepper,
  Step,
  StepLabel,
  CircularProgress,
  Grid,
  Card,
  CardContent,
  Chip
} from '@mui/material';
import HomeIcon from '@mui/icons-material/Home';
import PersonIcon from '@mui/icons-material/Person';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { ethers } from 'ethers';
import { CONTRACTS, RENTAL_AGREEMENT_FACTORY_ABI } from '../web3/config';
import { MOCK_MODE, mockCreateAgreement, MockPropertyData } from '../web3/mockData';
import type { EvmNetwork } from '../web3/config';

interface CreateRentalAgreementProps {
  open: boolean;
  onClose: () => void;
  provider: ethers.Provider | null;
  signer: ethers.Signer | null;
  account: string | null;
  activeNetwork: EvmNetwork;
  propertyId?: string;
  propertyData?: MockPropertyData;
  onSuccess?: (agreementAddress: string) => void;
}

const steps = ['Seleccionar Propiedad', 'Datos del Tenant', 'Términos Económicos', 'Confirmar'];

const CreateRentalAgreement: React.FC<CreateRentalAgreementProps> = ({
  open,
  onClose,
  provider,
  signer,
  account,
  activeNetwork,
  propertyId: initialPropertyId,
  propertyData: initialPropertyData,
  onSuccess
}) => {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  
  // Form data
  const [propertyId, setPropertyId] = useState(initialPropertyId || '');
  const [tenantAddress, setTenantAddress] = useState('');
  const [monthlyRent, setMonthlyRent] = useState('');
  const [securityDeposit, setSecurityDeposit] = useState('');
  const [duration, setDuration] = useState(12); // meses
  const [startDate, setStartDate] = useState('');
  
  // Property preview
  const [selectedProperty, setSelectedProperty] = useState<MockPropertyData | null>(
    initialPropertyData || null
  );

  useEffect(() => {
    if (initialPropertyId) {
      setPropertyId(initialPropertyId);
    }
    if (initialPropertyData) {
      setSelectedProperty(initialPropertyData);
      setMonthlyRent(initialPropertyData.monthlyRent);
      setSecurityDeposit(initialPropertyData.securityDeposit);
    }
  }, [initialPropertyId, initialPropertyData]);

  const handleNext = () => {
    setError(null);
    
    if (activeStep === 0) {
      // Validar property ID
      if (!propertyId || !ethers.isHexString(propertyId)) {
        setError('Ingresa un Property ID válido');
        return;
      }
    }
    
    if (activeStep === 1) {
      // Validar tenant address
      if (!tenantAddress || !ethers.isAddress(tenantAddress)) {
        setError('Ingresa una dirección de tenant válida');
        return;
      }
      if (tenantAddress.toLowerCase() === account?.toLowerCase()) {
        setError('El tenant no puede ser el mismo que el landlord');
        return;
      }
    }
    
    if (activeStep === 2) {
      // Validar términos
      if (!monthlyRent || parseFloat(monthlyRent) <= 0) {
        setError('Ingresa una renta mensual válida');
        return;
      }
      if (!securityDeposit || parseFloat(securityDeposit) <= 0) {
        setError('Ingresa un depósito de seguridad válido');
        return;
      }
      if (!duration || duration < 1 || duration > 60) {
        setError('La duración debe estar entre 1 y 60 meses');
        return;
      }
    }
    
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setError(null);
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleCreateAgreement = async () => {
    if (!account) {
      setError('Conecta tu wallet primero');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      let agreementAddress: string;

      if (MOCK_MODE) {
        // Modo mock
        console.log('🎭 [MOCK] Creating rental agreement...');
        agreementAddress = await mockCreateAgreement(
          propertyId,
          tenantAddress,
          monthlyRent,
          securityDeposit,
          duration
        );
      } else {
        // Modo real
        if (!signer || !provider) {
          throw new Error('No hay signer disponible');
        }

        const factoryAddress = CONTRACTS[activeNetwork].RENTAL_AGREEMENT_FACTORY_ADDRESS;
        if (!factoryAddress) {
          throw new Error('Factory no disponible en esta red');
        }

        const factoryContract = new ethers.Contract(
          factoryAddress,
          RENTAL_AGREEMENT_FACTORY_ABI,
          signer
        );

        // Convertir valores a formato correcto (USDT tiene 6 decimales en Paseo)
        const decimals = activeNetwork === 'paseo' ? 6 : 18;
        const rentAmount = ethers.parseUnits(monthlyRent, decimals);
        const depositAmount = ethers.parseUnits(securityDeposit, decimals);

        console.log('📝 Creating rental agreement...');
        const tx = await factoryContract.createAgreement(
          propertyId,
          tenantAddress,
          rentAmount,
          depositAmount,
          duration
        );

        console.log('⏳ Waiting for confirmation...');
        const receipt = await tx.wait();
        
        // Obtener el address del agreement del evento
        const event = receipt.logs.find((log: any) => {
          try {
            const parsed = factoryContract.interface.parseLog(log);
            return parsed?.name === 'AgreementCreated';
          } catch {
            return false;
          }
        });

        if (event) {
          const parsed = factoryContract.interface.parseLog(event);
          agreementAddress = parsed?.args.agreementAddress;
        } else {
          throw new Error('No se pudo obtener la dirección del agreement');
        }
      }

      console.log('✅ Agreement created at:', agreementAddress);
      setSuccess(true);
      
      setTimeout(() => {
        onSuccess?.(agreementAddress);
        handleClose();
      }, 2000);

    } catch (err: any) {
      console.error('❌ Error creating agreement:', err);
      setError(err.message || 'Error al crear el agreement');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setActiveStep(0);
    setPropertyId(initialPropertyId || '');
    setTenantAddress('');
    setMonthlyRent('');
    setSecurityDeposit('');
    setDuration(12);
    setStartDate('');
    setError(null);
    setSuccess(false);
    onClose();
  };

  const getStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Box>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              Ingresa el Property ID (hash de 32 bytes)
            </Typography>
            <TextField
              fullWidth
              label="Property ID"
              value={propertyId}
              onChange={(e) => setPropertyId(e.target.value)}
              placeholder="0x..."
              disabled={!!initialPropertyId}
              margin="normal"
              helperText={
                initialPropertyId
                  ? 'Property preseleccionada'
                  : 'Obtén el Property ID desde PropertyRegistry'
              }
            />
            {selectedProperty && (
              <Card sx={{ mt: 2, bgcolor: 'background.paper' }}>
                <CardContent>
                  <Typography variant="subtitle2" gutterBottom>
                    <HomeIcon fontSize="small" sx={{ mr: 1, verticalAlign: 'middle' }} />
                    Property Preview
                  </Typography>
                  <Typography variant="body2">{selectedProperty.name}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {selectedProperty.fullAddress}
                  </Typography>
                  <Box sx={{ mt: 1 }}>
                    <Chip
                      label={`${selectedProperty.bedrooms} beds`}
                      size="small"
                      sx={{ mr: 0.5 }}
                    />
                    <Chip
                      label={`${selectedProperty.squareMeters}m²`}
                      size="small"
                    />
                  </Box>
                </CardContent>
              </Card>
            )}
          </Box>
        );

      case 1:
        return (
          <Box>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              Dirección Ethereum del tenant (debe tener TenantPassport)
            </Typography>
            <TextField
              fullWidth
              label="Tenant Address"
              value={tenantAddress}
              onChange={(e) => setTenantAddress(e.target.value)}
              placeholder="0x..."
              margin="normal"
              InputProps={{
                startAdornment: <PersonIcon sx={{ mr: 1, color: 'text.secondary' }} />
              }}
            />
            <Alert severity="info" sx={{ mt: 2 }}>
              <Typography variant="caption">
                El tenant debe tener un TenantPassport válido. Se verificará automáticamente al
                crear el agreement.
              </Typography>
            </Alert>
          </Box>
        );

      case 2:
        return (
          <Box>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Renta Mensual (USDT)"
                  type="number"
                  value={monthlyRent}
                  onChange={(e) => setMonthlyRent(e.target.value)}
                  margin="normal"
                  InputProps={{
                    startAdornment: <AttachMoneyIcon sx={{ mr: 1, color: 'text.secondary' }} />
                  }}
                  helperText="Cantidad en USDT"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Depósito de Seguridad (USDT)"
                  type="number"
                  value={securityDeposit}
                  onChange={(e) => setSecurityDeposit(e.target.value)}
                  margin="normal"
                  helperText="Generalmente 1-2 meses de renta"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  select
                  label="Duración (meses)"
                  value={duration}
                  onChange={(e) => setDuration(Number(e.target.value))}
                  margin="normal"
                  InputProps={{
                    startAdornment: <CalendarTodayIcon sx={{ mr: 1, color: 'text.secondary' }} />
                  }}
                >
                  {[6, 12, 18, 24, 36, 48].map((months) => (
                    <MenuItem key={months} value={months}>
                      {months} meses {months === 12 && '(Recomendado)'}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Fecha de Inicio (opcional)"
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  margin="normal"
                  InputLabelProps={{
                    shrink: true
                  }}
                  helperText="Dejar vacío = hoy"
                />
              </Grid>
            </Grid>

            <Card sx={{ mt: 2, bgcolor: 'primary.light', color: 'primary.contrastText' }}>
              <CardContent>
                <Typography variant="subtitle2" gutterBottom>
                  💰 Resumen Financiero
                </Typography>
                <Typography variant="body2">
                  Renta total durante el contrato:{' '}
                  <strong>${(parseFloat(monthlyRent || '0') * duration).toLocaleString()} USDT</strong>
                </Typography>
                <Typography variant="body2">
                  Depósito de seguridad: <strong>${parseFloat(securityDeposit || '0').toLocaleString()} USDT</strong>
                </Typography>
              </CardContent>
            </Card>
          </Box>
        );

      case 3:
        return (
          <Box>
            {success ? (
              <Box textAlign="center" py={4}>
                <CheckCircleIcon color="success" sx={{ fontSize: 80, mb: 2 }} />
                <Typography variant="h5" gutterBottom>
                  ¡Agreement Creado Exitosamente!
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Redirigiendo...
                </Typography>
              </Box>
            ) : (
              <>
                <Alert severity="warning" sx={{ mb: 3 }}>
                  <Typography variant="body2">
                    Revisa todos los datos antes de crear el agreement. Una vez creado, algunos
                    campos no podrán modificarse.
                  </Typography>
                </Alert>

                <Card variant="outlined" sx={{ mb: 2 }}>
                  <CardContent>
                    <Typography variant="subtitle1" gutterBottom color="primary">
                      📋 Resumen del Agreement
                    </Typography>
                    
                    <Box sx={{ mt: 2 }}>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Typography variant="caption" color="text.secondary">
                            Property ID
                          </Typography>
                          <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
                            {propertyId}
                          </Typography>
                        </Grid>
                        <Grid item xs={12}>
                          <Typography variant="caption" color="text.secondary">
                            Tenant Address
                          </Typography>
                          <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
                            {tenantAddress}
                          </Typography>
                        </Grid>
                        <Grid item xs={6}>
                          <Typography variant="caption" color="text.secondary">
                            Renta Mensual
                          </Typography>
                          <Typography variant="body2">
                            ${parseFloat(monthlyRent).toLocaleString()} USDT
                          </Typography>
                        </Grid>
                        <Grid item xs={6}>
                          <Typography variant="caption" color="text.secondary">
                            Depósito
                          </Typography>
                          <Typography variant="body2">
                            ${parseFloat(securityDeposit).toLocaleString()} USDT
                          </Typography>
                        </Grid>
                        <Grid item xs={6}>
                          <Typography variant="caption" color="text.secondary">
                            Duración
                          </Typography>
                          <Typography variant="body2">{duration} meses</Typography>
                        </Grid>
                        <Grid item xs={6}>
                          <Typography variant="caption" color="text.secondary">
                            Total del Contrato
                          </Typography>
                          <Typography variant="body2">
                            ${(parseFloat(monthlyRent) * duration).toLocaleString()} USDT
                          </Typography>
                        </Grid>
                      </Grid>
                    </Box>
                  </CardContent>
                </Card>

                {MOCK_MODE && (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    🎭 MODO MOCK: Se simulará la creación del agreement
                  </Alert>
                )}
              </>
            )}
          </Box>
        );

      default:
        return 'Unknown step';
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Typography variant="h5">Crear Rental Agreement</Typography>
        <Typography variant="caption" color="text.secondary">
          {MOCK_MODE ? '🎭 Modo Mock' : '⚡ Modo Real'}
        </Typography>
      </DialogTitle>

      <DialogContent>
        <Stepper activeStep={activeStep} sx={{ pt: 3, pb: 5 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {getStepContent(activeStep)}
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={handleClose} disabled={loading}>
          Cancelar
        </Button>
        <Box sx={{ flex: '1 1 auto' }} />
        {activeStep !== 0 && (
          <Button onClick={handleBack} disabled={loading}>
            Atrás
          </Button>
        )}
        {activeStep === steps.length - 1 ? (
          <Button
            variant="contained"
            onClick={handleCreateAgreement}
            disabled={loading || success}
            startIcon={loading && <CircularProgress size={20} />}
          >
            {loading ? 'Creando...' : 'Crear Agreement'}
          </Button>
        ) : (
          <Button variant="contained" onClick={handleNext} disabled={loading}>
            Siguiente
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default CreateRentalAgreement;
