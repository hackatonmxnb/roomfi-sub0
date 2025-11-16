import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Container,
  Box,
  Typography,
  Card,
  CardContent,
  CardActions,
  Grid,
  Button,
  Chip,
  CircularProgress,
  Alert,
  Tabs,
  Tab,
  Divider
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import VisibilityIcon from '@mui/icons-material/Visibility';
import HomeIcon from '@mui/icons-material/Home';
import PersonIcon from '@mui/icons-material/Person';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PendingIcon from '@mui/icons-material/Pending';
import ErrorIcon from '@mui/icons-material/Error';
import { ethers } from 'ethers';
import Header from '../Header';
import CreateRentalAgreement from './CreateRentalAgreement';
import {
  MOCK_MODE,
  mockGetTenantAgreements,
  mockGetLandlordAgreements,
  mockGetAgreement,
  MockAgreementData
} from '../web3/mockData';
import { CONTRACTS, RENTAL_AGREEMENT_FACTORY_ABI } from '../web3/config';
import type { EvmNetwork } from '../web3/config';

interface MyAgreementsPageProps {
  provider: ethers.Provider | null;
  signer: ethers.Signer | null;
  account: string | null;
  activeNetwork: EvmNetwork;
  onDisconnect: () => void;
  setShowOnboarding: React.Dispatch<React.SetStateAction<boolean>>;
}

const MyAgreementsPage: React.FC<MyAgreementsPageProps> = ({
  provider,
  signer,
  account,
  activeNetwork,
  onDisconnect,
  setShowOnboarding
}) => {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState(0); // 0 = Tenant, 1 = Landlord
  const [loading, setLoading] = useState(true);
  const [agreements, setAgreements] = useState<MockAgreementData[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [showCreateDialog, setShowCreateDialog] = useState(false);

  useEffect(() => {
    if (account && provider) {
      fetchAgreements();
    }
  }, [account, provider, activeTab]);

  const fetchAgreements = async () => {
    if (!account) return;

    setLoading(true);
    setError(null);

    try {
      let agreementAddresses: string[] = [];

      if (MOCK_MODE) {
        // Obtener agreements según el tab activo
        if (activeTab === 0) {
          agreementAddresses = await mockGetTenantAgreements(account);
        } else {
          agreementAddresses = await mockGetLandlordAgreements(account);
        }
      } else {
        if (!provider) throw new Error('No provider available');

        const factoryAddress = CONTRACTS[activeNetwork].RENTAL_AGREEMENT_FACTORY_ADDRESS;
        if (!factoryAddress) {
          throw new Error('Factory no disponible en esta red');
        }

        const factoryContract = new ethers.Contract(
          factoryAddress,
          RENTAL_AGREEMENT_FACTORY_ABI,
          provider
        );

        // Obtener agreements del usuario
        if (activeTab === 0) {
          agreementAddresses = await factoryContract.getTenantAgreements(account);
        } else {
          agreementAddresses = await factoryContract.getLandlordAgreements(account);
        }
      }

      // Obtener detalles de cada agreement
      const agreementsData: MockAgreementData[] = [];
      for (const addr of agreementAddresses) {
        try {
          const data = await mockGetAgreement(addr);
          agreementsData.push(data);
        } catch (err) {
          console.error('Error fetching agreement:', addr, err);
        }
      }

      setAgreements(agreementsData);
    } catch (err: any) {
      console.error('Error fetching agreements:', err);
      setError(err.message || 'Error al cargar los agreements');
    } finally {
      setLoading(false);
    }
  };

  const getStatusChip = (status: number) => {
    const statusMap: Record<number, { label: string; color: any; icon: any }> = {
      0: { label: 'Pending', color: 'warning', icon: <PendingIcon fontSize="small" /> },
      1: { label: 'Active', color: 'success', icon: <CheckCircleIcon fontSize="small" /> },
      2: { label: 'Completed', color: 'info', icon: <CheckCircleIcon fontSize="small" /> },
      3: { label: 'Terminated', color: 'error', icon: <ErrorIcon fontSize="small" /> },
      4: { label: 'In Dispute', color: 'error', icon: <ErrorIcon fontSize="small" /> }
    };

    const s = statusMap[status] || statusMap[0];
    return <Chip label={s.label} color={s.color} icon={s.icon} size="small" />;
  };

  const handleCreateSuccess = (agreementAddress: string) => {
    setShowCreateDialog(false);
    fetchAgreements();
    navigate(`/agreement/${agreementAddress}`);
  };

  if (!account) {
    return (
      <Box>
        <Header
          account={account}
          onDisconnect={onDisconnect}
          setShowOnboarding={setShowOnboarding}
          activeNetwork={activeNetwork}
        />
        <Container sx={{ mt: 4 }}>
          <Alert severity="warning">
            Conecta tu wallet para ver tus agreements
          </Alert>
          <Button
            variant="contained"
            onClick={() => setShowOnboarding(true)}
            sx={{ mt: 2 }}
          >
            Conectar Wallet
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
        {/* Header */}
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Box>
            <Typography variant="h4" gutterBottom>
              Mis Rental Agreements
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {MOCK_MODE && '🎭 Modo Mock'}
            </Typography>
          </Box>
          {activeTab === 1 && (
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => setShowCreateDialog(true)}
            >
              Nuevo Agreement
            </Button>
          )}
        </Box>

        {/* Tabs */}
        <Card sx={{ mb: 3 }}>
          <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} variant="fullWidth">
            <Tab
              label={
                <Box display="flex" alignItems="center" gap={1}>
                  <PersonIcon fontSize="small" />
                  Como Tenant
                </Box>
              }
            />
            <Tab
              label={
                <Box display="flex" alignItems="center" gap={1}>
                  <HomeIcon fontSize="small" />
                  Como Landlord
                </Box>
              }
            />
          </Tabs>
        </Card>

        {/* Loading */}
        {loading && (
          <Box textAlign="center" py={4}>
            <CircularProgress />
            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Cargando agreements...
            </Typography>
          </Box>
        )}

        {/* Error */}
        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        {/* Empty State */}
        {!loading && agreements.length === 0 && (
          <Card>
            <CardContent sx={{ textAlign: 'center', py: 6 }}>
              <Typography variant="h6" color="text.secondary" gutterBottom>
                {activeTab === 0
                  ? 'No tienes agreements como tenant'
                  : 'No tienes agreements como landlord'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                {activeTab === 0
                  ? 'Cuando un landlord te agregue a un agreement, aparecerá aquí'
                  : 'Crea tu primer agreement para empezar'}
              </Typography>
              {activeTab === 1 && (
                <Button
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={() => setShowCreateDialog(true)}
                >
                  Crear Primer Agreement
                </Button>
              )}
            </CardContent>
          </Card>
        )}

        {/* Agreements Grid */}
        {!loading && agreements.length > 0 && (
          <Grid container spacing={3}>
            {agreements.map((agreement) => (
              <Grid item xs={12} md={6} lg={4} key={agreement.agreementAddress}>
                <Card
                  sx={{
                    height: '100%',
                    display: 'flex',
                    flexDirection: 'column',
                    '&:hover': {
                      boxShadow: 6,
                      transform: 'translateY(-4px)',
                      transition: 'all 0.3s'
                    }
                  }}
                >
                  <CardContent sx={{ flexGrow: 1 }}>
                    {/* Status */}
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                      {getStatusChip(agreement.status)}
                      <Typography variant="caption" color="text.secondary">
                        {agreement.paymentsMade}/{agreement.duration} pagos
                      </Typography>
                    </Box>

                    {/* Property ID */}
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Property
                    </Typography>
                    <Typography
                      variant="caption"
                      sx={{
                        display: 'block',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        mb: 2
                      }}
                    >
                      {agreement.propertyId}
                    </Typography>

                    <Divider sx={{ my: 2 }} />

                    {/* Financial Info */}
                    <Box mb={1}>
                      <Typography variant="caption" color="text.secondary">
                        Renta Mensual
                      </Typography>
                      <Typography variant="h6">
                        ${parseFloat(agreement.monthlyRent).toLocaleString()} USDT
                      </Typography>
                    </Box>

                    <Box mb={1}>
                      <Typography variant="caption" color="text.secondary">
                        Duración
                      </Typography>
                      <Typography variant="body2">
                        {agreement.duration} meses
                      </Typography>
                    </Box>

                    {/* Signatures */}
                    <Box mt={2} display="flex" gap={1}>
                      <Chip
                        label="L"
                        color={agreement.landlordSigned ? 'success' : 'default'}
                        size="small"
                        title={
                          agreement.landlordSigned
                            ? 'Landlord firmó'
                            : 'Landlord pendiente'
                        }
                      />
                      <Chip
                        label="T"
                        color={agreement.tenantSigned ? 'success' : 'default'}
                        size="small"
                        title={
                          agreement.tenantSigned ? 'Tenant firmó' : 'Tenant pendiente'
                        }
                      />
                      {agreement.depositPaid && (
                        <Chip
                          label="💰"
                          color="success"
                          size="small"
                          title="Depósito pagado"
                        />
                      )}
                    </Box>

                    {/* Counterpart */}
                    <Box mt={2}>
                      <Typography variant="caption" color="text.secondary">
                        {activeTab === 0 ? 'Landlord' : 'Tenant'}
                      </Typography>
                      <Typography
                        variant="caption"
                        sx={{
                          display: 'block',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap'
                        }}
                      >
                        {activeTab === 0 ? agreement.landlord : agreement.tenant}
                      </Typography>
                    </Box>
                  </CardContent>

                  <CardActions>
                    <Button
                      fullWidth
                      variant="contained"
                      startIcon={<VisibilityIcon />}
                      onClick={() => navigate(`/agreement/${agreement.agreementAddress}`)}
                    >
                      Ver Detalles
                    </Button>
                  </CardActions>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Container>

      {/* Dialog: Crear Agreement */}
      <CreateRentalAgreement
        open={showCreateDialog}
        onClose={() => setShowCreateDialog(false)}
        provider={provider}
        signer={signer}
        account={account}
        activeNetwork={activeNetwork}
        onSuccess={handleCreateSuccess}
      />
    </Box>
  );
};

export default MyAgreementsPage;
