import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { Box, Container, Typography, Button, Card, CardContent, CardMedia, Grid, TextField, Select, MenuItem, FormControl, InputLabel, Chip, Stack, Paper, Tabs, Tab, FormControlLabel, Checkbox, Snackbar, Dialog, DialogTitle, DialogContent, DialogActions, Divider, IconButton } from '@mui/material';
import AddHomeIcon from '@mui/icons-material/AddHome';
import HomeIcon from '@mui/icons-material/Home';
import ApartmentIcon from '@mui/icons-material/Apartment';
import MeetingRoomIcon from '@mui/icons-material/MeetingRoom';
import BedIcon from '@mui/icons-material/Bed';
import BathtubIcon from '@mui/icons-material/Bathtub';
import SquareFootIcon from '@mui/icons-material/SquareFoot';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import VerifiedIcon from '@mui/icons-material/Verified';
import CloseIcon from '@mui/icons-material/Close';
import { CONTRACTS, PROPERTY_REGISTRY_ABI } from './web3/config';
import { MOCK_MODE } from './web3/mockData';
import Header from './Header';

const PROPERTY_TYPES = [
  { value: 0, label: 'Casa', icon: <HomeIcon /> },
  { value: 1, label: 'Departamento', icon: <ApartmentIcon /> },
  { value: 2, label: 'Habitación', icon: <MeetingRoomIcon /> },
  { value: 3, label: 'Estudio', icon: <BedIcon /> },
  { value: 4, label: 'Loft', icon: <ApartmentIcon /> },
  { value: 5, label: 'Cuarto Compartido', icon: <BedIcon /> },
];

const VERIFICATION_STATUS = {
  0: { label: 'Borrador', color: 'default' as const },
  1: { label: 'Pendiente', color: 'warning' as const },
  2: { label: 'Verificada', color: 'success' as const },
  3: { label: 'Rechazada', color: 'error' as const },
  4: { label: 'Expirada', color: 'default' as const },
  5: { label: 'Suspendida', color: 'error' as const },
};

interface PropertyData { id: number; name: string; propertyType: number; fullAddress: string; city: string; state: string; neighborhood: string; bedrooms: number; bathrooms: number; squareMeters: number; hasParking: boolean; petsAllowed: boolean; description: string; monthlyRent: string; securityDeposit: string; landlord: string; verificationStatus: number; currentReputation: number; isAvailableForRent: boolean; }

interface PropertyRegistryPageProps { account: string | null; provider: ethers.BrowserProvider | null; activeNetwork: 'paseo' | 'arbitrum'; onNetworkChange: (network: 'paseo' | 'arbitrum') => void; onDisconnect: () => void; onConnectMetaMask: () => void; tokenBalance: number; tenantPassportData: any; }

export default function PropertyRegistryPage({ account, provider, activeNetwork, onNetworkChange, onDisconnect, onConnectMetaMask, tokenBalance, tenantPassportData }: PropertyRegistryPageProps) {
  const [tabValue, setTabValue] = useState(0);
  const [properties, setProperties] = useState<PropertyData[]>([]);
  const [loading, setLoading] = useState(false);
  const [showRegisterDialog, setShowRegisterDialog] = useState(false);
  const [notification, setNotification] = useState<{ open: boolean; message: string; severity: 'success' | 'error' | 'info' }>({ open: false, message: '', severity: 'info' });
  const [formData, setFormData] = useState({ name: '', propertyType: 1, fullAddress: '', city: '', state: '', postalCode: '', neighborhood: '', latitude: '', longitude: '', bedrooms: 1, bathrooms: 1, squareMeters: '', hasParking: false, petsAllowed: false, smokingAllowed: false, description: '', amenities: '', monthlyRent: '', securityDeposit: '', minLeaseDuration: 6, maxLeaseDuration: 12 });

  const fetchProperties = React.useCallback(async () => {
    if (MOCK_MODE) {
      setProperties([
        { id: 1, name: 'Departamento Moderno en Condesa', propertyType: 1, fullAddress: 'Av. Amsterdam 123', city: 'Ciudad de México', state: 'CDMX', neighborhood: 'Condesa', bedrooms: 2, bathrooms: 2, squareMeters: 85, hasParking: true, petsAllowed: true, description: 'Hermoso departamento con acabados de lujo', monthlyRent: '25000', securityDeposit: '50000', landlord: account || '0x...', verificationStatus: 2, currentReputation: 950, isAvailableForRent: true },
        { id: 2, name: 'Casa Espaciosa en Polanco', propertyType: 0, fullAddress: 'Calle Horacio 456', city: 'Ciudad de México', state: 'CDMX', neighborhood: 'Polanco', bedrooms: 3, bathrooms: 3, squareMeters: 150, hasParking: true, petsAllowed: false, description: 'Casa moderna con jardín', monthlyRent: '45000', securityDeposit: '90000', landlord: '0x1234567890123456789012345678901234567890', verificationStatus: 2, currentReputation: 880, isAvailableForRent: true },
        { id: 3, name: 'Estudio en Roma Norte', propertyType: 3, fullAddress: 'Av. Álvaro Obregón 234', city: 'Ciudad de México', state: 'CDMX', neighborhood: 'Roma Norte', bedrooms: 0, bathrooms: 1, squareMeters: 35, hasParking: false, petsAllowed: true, description: 'Estudio compacto perfecto para jóvenes profesionales', monthlyRent: '12000', securityDeposit: '24000', landlord: '0x2345678901234567890123456789012345678901', verificationStatus: 1, currentReputation: 750, isAvailableForRent: true }
      ]);
      return;
    }
    // Lógica real para cargar del contrato (omitida por brevedad)
  }, [account, provider, activeNetwork]);

  useEffect(() => { 
    if (account && provider) {
      fetchProperties(); 
    }
  }, [account, provider, activeNetwork, fetchProperties]);

  const handleRegisterProperty = React.useCallback(async () => {
    if (!provider || !account) { setNotification({ open: true, message: 'Conecta tu wallet primero', severity: 'error' }); return; }
    if (MOCK_MODE) {
      setNotification({ open: true, message: '🎭 [MOCK] Propiedad registrada', severity: 'success' });
      setShowRegisterDialog(false);
      setProperties([{ id: properties.length + 1, ...formData, squareMeters: Number(formData.squareMeters), landlord: account, verificationStatus: 0, currentReputation: 500, isAvailableForRent: false }, ...properties]);
      return;
    }
    // Lógica real omitida
  }, [provider, account, formData, properties]);

  const PropertyCard = ({ property }: { property: PropertyData }) => {
    const verificationInfo = VERIFICATION_STATUS[property.verificationStatus as keyof typeof VERIFICATION_STATUS];
    return (
      <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column', '&:hover': { boxShadow: 6 } }}>
        <CardMedia component="div" sx={{ height: 200, bgcolor: 'primary.light', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
          <HomeIcon sx={{ fontSize: 80, color: 'white', opacity: 0.9 }} />
        </CardMedia>
        <CardContent sx={{ flexGrow: 1 }}>
          <Stack spacing={1.5}>
            <Box display="flex" justifyContent="space-between" alignItems="start">
              <Typography variant="h6" sx={{ fontWeight: 'bold', flex: 1 }}>{property.name}</Typography>
              {property.verificationStatus === 2 && <VerifiedIcon color="success" />}
            </Box>
            <Chip label={verificationInfo.label} color={verificationInfo.color} size="small" sx={{ width: 'fit-content' }} />
            <Box display="flex" gap={1} alignItems="center">
              <LocationOnIcon fontSize="small" color="action" />
              <Typography variant="body2" color="text.secondary">{property.neighborhood}, {property.city}</Typography>
            </Box>
            <Typography variant="body2" color="text.secondary" sx={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', minHeight: 40 }}>{property.description}</Typography>
            <Divider />
            <Stack direction="row" spacing={2}>
              <Box display="flex" alignItems="center" gap={0.5}><BedIcon fontSize="small" color="action" /><Typography variant="body2">{property.bedrooms} rec</Typography></Box>
              <Box display="flex" alignItems="center" gap={0.5}><BathtubIcon fontSize="small" color="action" /><Typography variant="body2">{property.bathrooms} baños</Typography></Box>
              <Box display="flex" alignItems="center" gap={0.5}><SquareFootIcon fontSize="small" color="action" /><Typography variant="body2">{property.squareMeters}m²</Typography></Box>
            </Stack>
            {(property.hasParking || property.petsAllowed) && (
              <Stack direction="row" spacing={1}>
                {property.hasParking && <Chip label="🚗 Parking" size="small" variant="outlined" />}
                {property.petsAllowed && <Chip label="🐕 Pets OK" size="small" variant="outlined" />}
              </Stack>
            )}
            <Divider />
            <Box>
              <Box display="flex" alignItems="center" gap={0.5} mb={0.5}>
                <AttachMoneyIcon fontSize="small" color="primary" />
                <Typography variant="h6" color="primary" sx={{ fontWeight: 'bold' }}>${parseFloat(property.monthlyRent).toLocaleString()}/mes</Typography>
              </Box>
              <Typography variant="caption" color="text.secondary">Depósito: ${parseFloat(property.securityDeposit).toLocaleString()} USDT</Typography>
            </Box>
            {property.currentReputation > 0 && (
              <Box sx={{ bgcolor: 'success.light', px: 1.5, py: 0.5, borderRadius: 1 }}>
                <Typography variant="caption" sx={{ fontWeight: 'medium' }}>⭐ Reputación: {property.currentReputation}/1000</Typography>
              </Box>
            )}
            <Button variant={property.isAvailableForRent ? "contained" : "outlined"} fullWidth disabled={!property.isAvailableForRent}>
              {property.isAvailableForRent ? 'Ver Detalles' : 'No Disponible'}
            </Button>
          </Stack>
        </CardContent>
      </Card>
    );
  };

  return (
    <Box sx={{ bgcolor: '#f5f5f5', minHeight: '100vh' }}>
      <Header account={account} tokenBalance={tokenBalance} onFundingModalOpen={() => {}} onConnectGoogle={() => {}} onConnectMetaMask={onConnectMetaMask} onDisconnect={onDisconnect} onViewNFTClick={() => {}} onMintNFTClick={() => {}} onViewMyPropertiesClick={() => {}} onSavingsClick={() => {}} onHowItWorksClick={() => {}} tenantPassportData={tenantPassportData} setShowOnboarding={() => {}} showOnboarding={false} activeNetwork={activeNetwork} onNetworkChange={onNetworkChange} />
      <Container maxWidth="xl" sx={{ py: 4 }}>
        <Paper elevation={3} sx={{ p: 3, mb: 3, background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', color: 'white' }}>
          <Box display="flex" justifyContent="space-between" alignItems="center" flexWrap="wrap" gap={2}>
            <Box>
              <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>🏠 Property Registry V2</Typography>
              <Typography variant="body1">Registra y explora propiedades • Red: <strong>{activeNetwork === 'paseo' ? 'Paseo' : 'Arbitrum'}</strong></Typography>
            </Box>
            {account && (<Button variant="contained" size="large" startIcon={<AddHomeIcon />} onClick={() => setShowRegisterDialog(true)} sx={{ bgcolor: 'white', color: 'primary.main', '&:hover': { bgcolor: 'grey.100' } }}>Registrar Propiedad</Button>)}
          </Box>
        </Paper>
        <Paper elevation={2} sx={{ mb: 3 }}>
          <Tabs value={tabValue} onChange={(e, v) => setTabValue(v)}>
            <Tab label={`📋 Todas (${properties.filter(p => p.isAvailableForRent).length})`} />
            <Tab label={`🏡 Mis Propiedades (${properties.filter(p => account && p.landlord.toLowerCase() === account.toLowerCase()).length})`} disabled={!account} />
          </Tabs>
        </Paper>
        {!account ? (
          <Paper elevation={2} sx={{ p: 6, textAlign: 'center' }}>
            <Typography variant="h5" gutterBottom sx={{ fontWeight: 'bold' }}>🔐 Conecta tu wallet</Typography>
            <Button variant="contained" size="large" onClick={onConnectMetaMask} sx={{ mt: 2 }}>Conectar Wallet</Button>
          </Paper>
        ) : properties.length === 0 ? (
          <Paper elevation={2} sx={{ p: 6, textAlign: 'center' }}>
            <Typography variant="h5" gutterBottom>🏗️ No hay propiedades aún</Typography>
            <Button variant="contained" size="large" startIcon={<AddHomeIcon />} onClick={() => setShowRegisterDialog(true)}>Registrar Primera Propiedad</Button>
          </Paper>
        ) : (
          <Grid container spacing={3}>
            {properties.filter(p => tabValue === 0 ? p.isAvailableForRent : account && p.landlord.toLowerCase() === account.toLowerCase()).map(property => (
              <Grid item xs={12} sm={6} md={4} key={property.id}><PropertyCard property={property} /></Grid>
            ))}
          </Grid>
        )}
      </Container>
      <Dialog open={showRegisterDialog} onClose={() => setShowRegisterDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle><Box display="flex" justifyContent="space-between" alignItems="center"><Typography variant="h5">🏠 Registrar Propiedad</Typography><IconButton onClick={() => setShowRegisterDialog(false)}><CloseIcon /></IconButton></Box></DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            <TextField label="Nombre" fullWidth value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} />
            <FormControl fullWidth><InputLabel>Tipo</InputLabel><Select value={formData.propertyType} onChange={(e) => setFormData({ ...formData, propertyType: Number(e.target.value) })} label="Tipo">{PROPERTY_TYPES.map(type => (<MenuItem key={type.value} value={type.value}><Box display="flex" gap={1}>{type.icon} {type.label}</Box></MenuItem>))}</Select></FormControl>
            <TextField label="Dirección" fullWidth value={formData.fullAddress} onChange={(e) => setFormData({ ...formData, fullAddress: e.target.value })} />
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Ciudad" fullWidth value={formData.city} onChange={(e) => setFormData({ ...formData, city: e.target.value })} /></Grid>
              <Grid item xs={6}><TextField label="Estado" fullWidth value={formData.state} onChange={(e) => setFormData({ ...formData, state: e.target.value })} /></Grid>
              <Grid item xs={6}><TextField label="CP" fullWidth value={formData.postalCode} onChange={(e) => setFormData({ ...formData, postalCode: e.target.value })} /></Grid>
              <Grid item xs={6}><TextField label="Colonia" fullWidth value={formData.neighborhood} onChange={(e) => setFormData({ ...formData, neighborhood: e.target.value })} /></Grid>
            </Grid>
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Latitud" fullWidth type="number" value={formData.latitude} onChange={(e) => setFormData({ ...formData, latitude: e.target.value })} /></Grid>
              <Grid item xs={6}><TextField label="Longitud" fullWidth type="number" value={formData.longitude} onChange={(e) => setFormData({ ...formData, longitude: e.target.value })} /></Grid>
            </Grid>
            <Grid container spacing={2}>
              <Grid item xs={4}><TextField label="Recámaras" fullWidth type="number" value={formData.bedrooms} onChange={(e) => setFormData({ ...formData, bedrooms: Number(e.target.value) })} /></Grid>
              <Grid item xs={4}><TextField label="Baños" fullWidth type="number" value={formData.bathrooms} onChange={(e) => setFormData({ ...formData, bathrooms: Number(e.target.value) })} /></Grid>
              <Grid item xs={4}><TextField label="m²" fullWidth type="number" value={formData.squareMeters} onChange={(e) => setFormData({ ...formData, squareMeters: e.target.value })} /></Grid>
            </Grid>
            <Stack direction="row" spacing={2}>
              <FormControlLabel control={<Checkbox checked={formData.hasParking} onChange={(e) => setFormData({ ...formData, hasParking: e.target.checked })} />} label="🚗 Parking" />
              <FormControlLabel control={<Checkbox checked={formData.petsAllowed} onChange={(e) => setFormData({ ...formData, petsAllowed: e.target.checked })} />} label="🐕 Pets" />
            </Stack>
            <TextField label="Descripción" fullWidth multiline rows={2} value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} />
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Renta Mensual (USDT)" fullWidth type="number" value={formData.monthlyRent} onChange={(e) => setFormData({ ...formData, monthlyRent: e.target.value })} /></Grid>
              <Grid item xs={6}><TextField label="Depósito (USDT)" fullWidth type="number" value={formData.securityDeposit} onChange={(e) => setFormData({ ...formData, securityDeposit: e.target.value })} /></Grid>
            </Grid>
          </Stack>
        </DialogContent>
        <DialogActions><Button onClick={() => setShowRegisterDialog(false)}>Cancelar</Button><Button variant="contained" onClick={handleRegisterProperty} disabled={!formData.name || !formData.monthlyRent}>Registrar</Button></DialogActions>
      </Dialog>
      <Snackbar open={notification.open} autoHideDuration={6000} onClose={() => setNotification({ ...notification, open: false })} message={notification.message} />
    </Box>
  );
}