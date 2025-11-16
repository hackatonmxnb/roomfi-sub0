import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Container,
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  Chip,
  Divider,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  CircularProgress,
  Tab,
  Tabs,
  LinearProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Paper
} from '@mui/material';
import HomeIcon from '@mui/icons-material/Home';
import PersonIcon from '@mui/icons-material/Person';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PendingIcon from '@mui/icons-material/Pending';
import ErrorIcon from '@mui/icons-material/Error';
import GavelIcon from '@mui/icons-material/Gavel';
import DescriptionIcon from '@mui/icons-material/Description';
import PaymentIcon from '@mui/icons-material/Payment';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { ethers } from 'ethers';
import Header from '../Header';
import { CONTRACTS, RENTAL_AGREEMENT_ABI, MXNB_ABI } from '../web3/config';
import {
  MOCK_MODE,
  mockGetAgreement,
  mockSignAgreement,
  mockPayDeposit,
  mockPayRent,
  MockAgreementData
} from '../web3/mockData';
import type { EvmNetwork } from '../web3/config';

interface RentalAgreementViewProps {
  provider: ethers.Provider | null;
  signer: ethers.Signer | null;
  account: string | null;
  activeNetwork: EvmNetwork;
  onDisconnect: () => void;
  setShowOnboarding: React.Dispatch<React.SetStateAction<boolean>>;
}

const RentalAgreementView: React.FC<RentalAgreementViewProps> = ({
  provider,
  signer,
  account,
  activeNetwork,
  onDisconnect,
  setShowOnboarding
}) => {
  const { address } = useParams<{ address: string }>();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [agreementData, setAgreementData] = useState<MockAgreementData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  
  // Modals
  const [showSignDialog, setShowSignDialog] = useState(false);
  const [showPayDialog, setShowPayDialog] = useState(false);
  const [showDisputeDialog, setShowDisputeDialog] = useState(false);
  
  // Transaction states
  const [txLoading, setTxLoading] = useState(false);
  const [txError, setTxError] = useState<string | null>(null);
  
  // Form data
  const [paymentAmount, setPaymentAmount] = useState('');
  const [disputeReason, setDisputeReason] = useState(0);
  const [disputeEvidence, setDisputeEvidence] = useState('');

  useEffect(() => {
    if (address && provider) {
      fetchAgreementData();
    }
  }, [address, provider, account]);

  const fetchAgreementData = async () => {
    if (!address) return;
    
    setLoading(true);
    setError(null);

    try {
      if (MOCK_MODE) {
        const data = await mockGetAgreement(address);
        setAgreementData(data);
        setPaymentAmount(data.monthlyRent);
      } else {
        if (!provider) throw new Error('No provider available');

        const contract = new ethers.Contract(address, RENTAL_AGREEMENT_ABI, provider);

        // Obtener datos del agreement
        const details = await contract.getAgreementDetails();
        const status = await contract.status();
        const tenantSigned = await contract.tenantSigned();
        const landlordSigned = await contract.landlordSigned();
        const depositPaid = await contract.depositPaid();

        setAgreementData({
          agreementAddress: address,
          propertyId: details.propertyId,
          landlord: details.landlord,
          tenant: details.tenant,
          monthlyRent: ethers.formatUnits(details.monthlyRent, 6), // USDT 6 decimals
          securityDeposit: ethers.formatUnits(details.securityDeposit, 6),
          duration: Number(details.duration),
          status: Number(status),
          tenantSigned,
          landlordSigned,
          depositPaid,
          paymentsMade: Number(details.paymentsMade || 0),
          nextPaymentDue: Number(details.nextPaymentDue || 0)
        });

        setPaymentAmount(ethers.formatUnits(details.monthlyRent, 6));
      }
    } catch (err: any) {
      console.error('Error fetching agreement:', err);
      setError(err.message || 'Error al cargar el agreement');
    } finally {
      setLoading(false);
    }
  };

  const handleSign = async () => {
    if (!account || !agreementData) return;

    setTxLoading(true);
    setTxError(null);

    try {
      const isLandlord = account.toLowerCase() === agreementData.landlord.toLowerCase();

      if (MOCK_MODE) {
        await mockSignAgreement(address!, isLandlord);
      } else {
        if (!signer) throw new Error('No signer available');

        const contract = new ethers.Contract(address!, RENTAL_AGREEMENT_ABI, signer);
        
        const tx = isLandlord 
          ? await contract.landlordSign()
          : await contract.tenantSign();
        
        await tx.wait();
      }

      setShowSignDialog(false);
      await fetchAgreementData();
    } catch (err: any) {
      console.error('Error signing agreement:', err);
      setTxError(err.message || 'Error al firmar el agreement');
    } finally {
      setTxLoading(false);
    }
  };

  const handlePayDeposit = async () => {
    if (!account || !agreementData) return;

    setTxLoading(true);
    setTxError(null);

    try {
      if (MOCK_MODE) {
        await mockPayDeposit(address!, agreementData.securityDeposit);
      } else {
        if (!signer) throw new Error('No signer available');

        const usdtAddress = CONTRACTS[activeNetwork].MXNBT_ADDRESS;
        const usdtContract = new ethers.Contract(usdtAddress, MXNB_ABI, signer);
        const agreementContract = new ethers.Contract(address!, RENTAL_AGREEMENT_ABI, signer);

        const depositAmount = ethers.parseUnits(agreementData.securityDeposit, 6);

        // 1. Approve USDT
        console.log('Approving USDT...');
        const approveTx = await usdtContract.approve(address, depositAmount);
        await approveTx.wait();

        // 2. Pay deposit
        console.log('Paying deposit...');
        const payTx = await agreementContract.paySecurityDeposit();
        await payTx.wait();
      }

      setShowPayDialog(false);
      await fetchAgreementData();
    } catch (err: any) {
      console.error('Error paying deposit:', err);
      setTxError(err.message || 'Error al pagar el depósito');
    } finally {
      setTxLoading(false);
    }
  };

  const handlePayRent = async () => {
    if (!account || !agreementData || !paymentAmount) return;

    setTxLoading(true);
    setTxError(null);

    try {
      if (MOCK_MODE) {
        await mockPayRent(address!, paymentAmount);
      } else {
        if (!signer) throw new Error('No signer available');

        const usdtAddress = CONTRACTS[activeNetwork].MXNBT_ADDRESS;
        const usdtContract = new ethers.Contract(usdtAddress, MXNB_ABI, signer);
        const agreementContract = new ethers.Contract(address!, RENTAL_AGREEMENT_ABI, signer);

        const rentAmount = ethers.parseUnits(paymentAmount, 6);

        // 1. Approve USDT
        console.log('Approving USDT...');
        const approveTx = await usdtContract.approve(address, rentAmount);
        await approveTx.wait();

        // 2. Pay rent
        console.log('Paying rent...');
        const payTx = await agreementContract.payRent();
        await payTx.wait();
      }

      setShowPayDialog(false);
      await fetchAgreementData();
    } catch (err: any) {
      console.error('Error paying rent:', err);
      setTxError(err.message || 'Error al pagar la renta');
    } finally {
      setTxLoading(false);
    }
  };

  const getStatusChip = (status: number) => {
    const statusMap: Record<number, { label: string; color: any; icon: any }> = {
      0: { label: 'Pending Signatures', color: 'warning', icon: <PendingIcon /> },
      1: { label: 'Active', color: 'success', icon: <CheckCircleIcon /> },
      2: { label: 'Completed', color: 'info', icon: <CheckCircleIcon /> },
      3: { label: 'Terminated', color: 'error', icon: <ErrorIcon /> },
      4: { label: 'In Dispute', color: 'error', icon: <GavelIcon /> }
    };

    const s = statusMap[status] || statusMap[0];
    return (
      <Chip
        label={s.label}
        color={s.color}
        icon={s.icon}
        variant="filled"
      />
    );
  };

  const isLandlord = account?.toLowerCase() === agreementData?.landlord.toLowerCase();
  const isTenant = account?.toLowerCase() === agreementData?.tenant.toLowerCase();
  const canSign = (isLandlord && !agreementData?.landlordSigned) || (isTenant && !agreementData?.tenantSigned);
  const canPayDeposit = isTenant && !agreementData?.depositPaid && agreementData?.tenantSigned && agreementData?.landlordSigned;
  const canPayRent = isTenant && agreementData?.depositPaid && agreementData?.status === 1;

  if (loading) {
    return (
      <Box>
        <Header
          account={account}
          onDisconnect={onDisconnect}
          setShowOnboarding={setShowOnboarding}
          activeNetwork={activeNetwork}
        />
        <Container sx={{ mt: 4, textAlign: 'center' }}>
          <CircularProgress />
          <Typography variant="body2" sx={{ mt: 2 }}>
            Cargando agreement...
          </Typography>
        </Container>
      </Box>
    );
  }

  if (error || !agreementData) {
    return (
      <Box>
        <Header
          account={account}
          onDisconnect={onDisconnect}
          setShowOnboarding={setShowOnboarding}
          activeNetwork={activeNetwork}
        />
        <Container sx={{ mt: 4 }}>
          <Alert severity="error">{error || 'Agreement no encontrado'}</Alert>
          <Button startIcon={<ArrowBackIcon />} onClick={() => navigate(-1)} sx={{ mt: 2 }}>
            Volver
          </Button>
        </Container>
      </Box>
    );
  }

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      <Header
        account={account}
        onDisconnect={onDisconnect}
        setShowOnboarding={setShowOnboarding}
        activeNetwork={activeNetwork}
      />

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => navigate(-1)} sx={{ mb: 2 }}>
          Volver
        </Button>

        {/* Header Card */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Box>
                <Typography variant="h4" gutterBottom>
                  Rental Agreement
                </Typography>
                <Typography variant="caption" color="text.secondary" sx={{ wordBreak: 'break-all' }}>
                  {address}
                </Typography>
              </Box>
              {getStatusChip(agreementData.status)}
            </Box>

            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Box display="flex" alignItems="center" mb={1}>
                  <HomeIcon sx={{ mr: 1, color: 'text.secondary' }} />
                  <Box>
                    <Typography variant="caption" color="text.secondary">
                      Landlord
                    </Typography>
                    <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
                      {agreementData.landlord}
                      {isLandlord && <Chip label="You" size="small" color="primary" sx={{ ml: 1 }} />}
                    </Typography>
                  </Box>
                </Box>
              </Grid>
              <Grid item xs={12} md={6}>
                <Box display="flex" alignItems="center" mb={1}>
                  <PersonIcon sx={{ mr: 1, color: 'text.secondary' }} />
                  <Box>
                    <Typography variant="caption" color="text.secondary">
                      Tenant
                    </Typography>
                    <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
                      {agreementData.tenant}
                      {isTenant && <Chip label="You" size="small" color="primary" sx={{ ml: 1 }} />}
                    </Typography>
                  </Box>
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* Signatures Status */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              📝 Estado de Firmas
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={6}>
                <Box display="flex" alignItems="center">
                  {agreementData.landlordSigned ? (
                    <CheckCircleIcon color="success" sx={{ mr: 1 }} />
                  ) : (
                    <PendingIcon color="warning" sx={{ mr: 1 }} />
                  )}
                  <Typography variant="body2">
                    Landlord {agreementData.landlordSigned ? 'firmó' : 'pendiente'}
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6}>
                <Box display="flex" alignItems="center">
                  {agreementData.tenantSigned ? (
                    <CheckCircleIcon color="success" sx={{ mr: 1 }} />
                  ) : (
                    <PendingIcon color="warning" sx={{ mr: 1 }} />
                  )}
                  <Typography variant="body2">
                    Tenant {agreementData.tenantSigned ? 'firmó' : 'pendiente'}
                  </Typography>
                </Box>
              </Grid>
            </Grid>

            {canSign && (
              <Button
                variant="contained"
                fullWidth
                onClick={() => setShowSignDialog(true)}
                sx={{ mt: 2 }}
                startIcon={<DescriptionIcon />}
              >
                Firmar Agreement
              </Button>
            )}
          </CardContent>
        </Card>

        {/* Tabs */}
        <Paper sx={{ mb: 3 }}>
          <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)}>
            <Tab label="Detalles" />
            <Tab label="Pagos" />
            <Tab label="Disputas" />
          </Tabs>
        </Paper>

        {/* Tab: Detalles */}
        {activeTab === 0 && (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Términos del Contrato
              </Typography>
              <Grid container spacing={3}>
                <Grid item xs={12} md={4}>
                  <AttachMoneyIcon color="primary" />
                  <Typography variant="caption" color="text.secondary" display="block">
                    Renta Mensual
                  </Typography>
                  <Typography variant="h6">
                    ${parseFloat(agreementData.monthlyRent).toLocaleString()} USDT
                  </Typography>
                </Grid>
                <Grid item xs={12} md={4}>
                  <AttachMoneyIcon color="primary" />
                  <Typography variant="caption" color="text.secondary" display="block">
                    Depósito de Seguridad
                  </Typography>
                  <Typography variant="h6">
                    ${parseFloat(agreementData.securityDeposit).toLocaleString()} USDT
                  </Typography>
                  {agreementData.depositPaid && (
                    <Chip label="Pagado" color="success" size="small" sx={{ mt: 0.5 }} />
                  )}
                </Grid>
                <Grid item xs={12} md={4}>
                  <CalendarTodayIcon color="primary" />
                  <Typography variant="caption" color="text.secondary" display="block">
                    Duración
                  </Typography>
                  <Typography variant="h6">{agreementData.duration} meses</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="body2" color="text.secondary">
                    Property ID
                  </Typography>
                  <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
                    {agreementData.propertyId}
                  </Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        )}

        {/* Tab: Pagos */}
        {activeTab === 1 && (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Historial de Pagos
              </Typography>
              
              <Box sx={{ mb: 3 }}>
                <Typography variant="body2" color="text.secondary">
                  Progreso de Pagos
                </Typography>
                <Box display="flex" alignItems="center" sx={{ mt: 1 }}>
                  <Box sx={{ width: '100%', mr: 1 }}>
                    <LinearProgress
                      variant="determinate"
                      value={(agreementData.paymentsMade / agreementData.duration) * 100}
                    />
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    {agreementData.paymentsMade} / {agreementData.duration}
                  </Typography>
                </Box>
              </Box>

              {canPayDeposit && (
                <Alert severity="warning" sx={{ mb: 2 }}>
                  <Typography variant="body2">
                    Debes pagar el depósito de seguridad antes de activar el contrato.
                  </Typography>
                  <Button
                    variant="contained"
                    size="small"
                    onClick={() => setShowPayDialog(true)}
                    sx={{ mt: 1 }}
                  >
                    Pagar Depósito (${agreementData.securityDeposit} USDT)
                  </Button>
                </Alert>
              )}

              {canPayRent && (
                <Button
                  variant="contained"
                  fullWidth
                  onClick={() => setShowPayDialog(true)}
                  startIcon={<PaymentIcon />}
                  sx={{ mb: 2 }}
                >
                  Pagar Renta Mensual (${agreementData.monthlyRent} USDT)
                </Button>
              )}

              <List>
                {Array.from({ length: agreementData.paymentsMade }).map((_, i) => (
                  <ListItem key={i}>
                    <ListItemIcon>
                      <CheckCircleIcon color="success" />
                    </ListItemIcon>
                    <ListItemText
                      primary={`Pago ${i + 1}`}
                      secondary={`$${agreementData.monthlyRent} USDT - Pagado`}
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        )}

        {/* Tab: Disputas */}
        {activeTab === 2 && (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Resolución de Disputas
              </Typography>
              <Alert severity="info" sx={{ mb: 2 }}>
                Si hay un conflicto con el landlord/tenant, puedes crear una disputa que será
                resuelta por árbitros autorizados.
              </Alert>
              <Button
                variant="outlined"
                color="error"
                startIcon={<GavelIcon />}
                onClick={() => setShowDisputeDialog(true)}
                disabled={agreementData.status !== 1}
              >
                Crear Disputa
              </Button>
            </CardContent>
          </Card>
        )}
      </Container>

      {/* Dialog: Firmar */}
      <Dialog open={showSignDialog} onClose={() => setShowSignDialog(false)}>
        <DialogTitle>Firmar Agreement</DialogTitle>
        <DialogContent>
          <Typography variant="body2" gutterBottom>
            Al firmar, aceptas los términos del contrato. Una vez que ambas partes firmen, el
            agreement quedará activo.
          </Typography>
          {txError && <Alert severity="error" sx={{ mt: 2 }}>{txError}</Alert>}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowSignDialog(false)} disabled={txLoading}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            onClick={handleSign}
            disabled={txLoading}
            startIcon={txLoading && <CircularProgress size={20} />}
          >
            {txLoading ? 'Firmando...' : 'Firmar'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Pagar */}
      <Dialog open={showPayDialog} onClose={() => setShowPayDialog(false)}>
        <DialogTitle>
          {canPayDeposit ? 'Pagar Depósito de Seguridad' : 'Pagar Renta'}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" gutterBottom>
            Monto a pagar: <strong>${canPayDeposit ? agreementData.securityDeposit : agreementData.monthlyRent} USDT</strong>
          </Typography>
          <Alert severity="info" sx={{ mt: 2, mb: 2 }}>
            Se requerirán 2 transacciones: 1) Approve USDT, 2) Pagar
          </Alert>
          {txError && <Alert severity="error">{txError}</Alert>}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowPayDialog(false)} disabled={txLoading}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            onClick={canPayDeposit ? handlePayDeposit : handlePayRent}
            disabled={txLoading}
            startIcon={txLoading && <CircularProgress size={20} />}
          >
            {txLoading ? 'Procesando...' : 'Pagar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RentalAgreementView;
