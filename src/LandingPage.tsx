import React from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Card,
  Stack,
  alpha,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import GroupsIcon from '@mui/icons-material/Groups';
import SecurityIcon from '@mui/icons-material/Security';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import MapIcon from '@mui/icons-material/Map';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';

const LandingPage = () => {
  const navigate = useNavigate();

  const features = [
    {
      icon: <GroupsIcon sx={{ fontSize: 48, color: '#1976d2' }} />,
      title: 'Find Roommates',
      description: 'Search for compatible roommates with advanced filters and verified profiles.',
    },
    {
      icon: <VerifiedUserIcon sx={{ fontSize: 48, color: '#66bb6a' }} />,
      title: 'Verified Identity',
      description: 'Your reputation as a tenant is recorded in an NFT that stays with you forever.',
    },
    {
      icon: <SecurityIcon sx={{ fontSize: 48, color: '#ff9800' }} />,
      title: 'Secure Payments',
      description: 'Smart contracts that guarantee transparency and security in every transaction.',
    },
    {
      icon: <AccountBalanceWalletIcon sx={{ fontSize: 48, color: '#9c27b0' }} />,
      title: 'Payments with MXNB',
      description: 'Use MXNB tokens for fast, secure payments without banking intermediaries.',
    },
    {
      icon: <TrendingUpIcon sx={{ fontSize: 48, color: '#f44336' }} />,
      title: 'Generate Yields',
      description: 'Property owners can deposit funds and generate interest automatically.',
    },
    {
      icon: <MapIcon sx={{ fontSize: 48, color: '#00bcd4' }} />,
      title: 'Interactive Map',
      description: 'Visualize properties on the map and find your ideal location easily.',
    },
  ];

  const steps = [
    {
      number: '01',
      title: 'Create your account',
      description: 'Sign up with Google or connect your MetaMask wallet in seconds.',
    },
    {
      number: '02',
      title: 'Get your Tenant Passport',
      description: 'Receive your identity NFT that will record your history as a tenant.',
    },
    {
      number: '03',
      title: 'Search or Publish',
      description: 'Find roommates or publish your property with complete transparency.',
    },
    {
      number: '04',
      title: 'Make Payments',
      description: 'Pay or receive rent with MXNB securely and automatically.',
    },
  ];

  return (
    <Box sx={{ 
      bgcolor: '#ffffff',
      minHeight: '100vh',
    }}>
      {/* Navbar */}
      <Box
        component="nav"
        sx={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bgcolor: 'rgba(255, 255, 255, 0.95)',
          backdropFilter: 'blur(10px)',
          boxShadow: '0 2px 20px rgba(0, 0, 0, 0.08)',
          zIndex: 1000,
          py: 2,
        }}
      >
        <Container maxWidth="lg">
          <Stack direction="row" alignItems="center" justifyContent="space-between">
            <Box
              component="img"
              src="/roomfilogo2transp.png"
              alt="RoomFi Logo"
              sx={{
                height: { xs: '40px', sm: '50px' },
                width: 'auto',
                cursor: 'pointer',
              }}
              onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
            />
            <Button
              variant="contained"
              onClick={() => navigate('/app')}
              sx={{
                bgcolor: '#1976d2',
                color: 'white',
                px: 3,
                py: 1,
                fontSize: '1rem',
                fontWeight: 600,
                borderRadius: 2,
                textTransform: 'none',
                '&:hover': {
                  bgcolor: '#1565c0',
                },
              }}
            >
              Enter App
            </Button>
          </Stack>
        </Container>
      </Box>

      {/* Hero Section */}
      <Box
        sx={{
          position: 'relative',
          minHeight: { xs: '60vh', md: '65vh' },
          display: 'flex',
          alignItems: 'center',
          pt: { xs: 14, md: 16 },
          pb: { xs: 6, md: 10 },
          overflow: 'hidden',
          backgroundImage: 'url(/nychero.jpg)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            right: 0,
            bottom: 0,
            left: 0,
            background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.65) 0%, rgba(255, 255, 255, 0.65) 100%)',
            backdropFilter: 'blur(2px)',
            zIndex: 1,
          }
        }}
      >
        <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 2 }}>
          <Grid container spacing={4} alignItems="center" justifyContent="center">
            <Grid item xs={12} md={8}>
              <Stack spacing={3} alignItems={{ xs: 'center', md: 'flex-start' }} textAlign={{ xs: 'center', md: 'left' }}>
                <Typography
                  variant="h1"
                  sx={{
                    fontSize: { xs: '2.5rem', sm: '3.5rem', md: '4rem' },
                    fontWeight: 800,
                    color: '#2c3e50',
                    lineHeight: 1.1,
                    letterSpacing: '-0.02em',
                    textShadow: '0 2px 10px rgba(255, 255, 255, 0.8)',
                  }}
                >
                  Your ideal home{' '}
                  <Box
                    component="span"
                    sx={{
                      color: '#1976d2',
                    }}
                  >
                    starts here
                  </Box>
                </Typography>
                
                <Typography
                  variant="h5"
                  sx={{
                    fontSize: { xs: '1.1rem', sm: '1.3rem', md: '1.5rem' },
                    color: '#2c3e50',
                    lineHeight: 1.6,
                    fontWeight: 400,
                    textShadow: '0 1px 3px rgba(255, 255, 255, 0.8)',
                  }}
                >
                  Find reliable roommates and share a home with the security and transparency of blockchain technology.
                </Typography>

                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mt: 4 }}>
                  <Button
                    variant="contained"
                    size="large"
                    onClick={() => navigate('/app')}
                    sx={{
                      bgcolor: '#1976d2',
                      color: 'white',
                      px: 4,
                      py: 1.5,
                      fontSize: '1.1rem',
                      fontWeight: 600,
                      borderRadius: 3,
                      textTransform: 'none',
                      boxShadow: '0 8px 24px rgba(25, 118, 210, 0.25)',
                      '&:hover': {
                        bgcolor: '#1565c0',
                        transform: 'translateY(-2px)',
                        boxShadow: '0 12px 32px rgba(25, 118, 210, 0.35)',
                      },
                      transition: 'all 0.3s ease',
                    }}
                  >
                    Get Started
                  </Button>
                  <Button
                    variant="outlined"
                    size="large"
                    onClick={() => {
                      document.getElementById('how-it-works')?.scrollIntoView({ behavior: 'smooth' });
                    }}
                    sx={{
                      borderColor: '#1976d2',
                      color: '#1976d2',
                      px: 4,
                      py: 1.5,
                      fontSize: '1.1rem',
                      fontWeight: 600,
                      borderRadius: 3,
                      textTransform: 'none',
                      borderWidth: 2,
                      '&:hover': {
                        borderWidth: 2,
                        bgcolor: '#ffffff',
                        transform: 'translateY(-2px)',
                      },
                      transition: 'all 0.3s ease',
                    }}
                  >
                    See How It Works
                  </Button>
                </Stack>
              </Stack>
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ py: { xs: 8, md: 12 } }}>
        <Stack spacing={2} alignItems="center" sx={{ mb: 8 }}>
          <Typography
            variant="h2"
            sx={{
              fontSize: { xs: '2rem', md: '3rem' },
              fontWeight: 700,
              color: '#2c3e50',
              textAlign: 'center',
            }}
          >
            Why RoomFi?
          </Typography>
          <Typography
            variant="h6"
            sx={{
              fontSize: { xs: '1rem', md: '1.2rem' },
              color: '#7f8c8d',
              textAlign: 'center',
              maxWidth: 600,
            }}
          >
            A complete platform that combines the best of blockchain technology with the simplicity you need.
          </Typography>
        </Stack>

        <Grid container spacing={4}>
          {features.map((feature, index) => (
            <Grid item xs={12} sm={6} md={4} key={index}>
              <Card
                elevation={0}
                sx={{
                  height: '100%',
                  p: 3,
                  borderRadius: 4,
                  border: '1px solid',
                  borderColor: alpha('#2c3e50', 0.08),
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'translateY(-8px)',
                    boxShadow: `0 16px 48px ${alpha('#2c3e50', 0.12)}`,
                    borderColor: alpha('#1976d2', 0.3),
                  },
                }}
              >
                <Stack spacing={2}>
                  <Box
                    sx={{
                      width: 72,
                      height: 72,
                      borderRadius: 3,
                      bgcolor: alpha(feature.icon.props.sx.color, 0.1),
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    {feature.icon}
                  </Box>
                  <Typography
                    variant="h5"
                    sx={{
                      fontSize: '1.4rem',
                      fontWeight: 600,
                      color: '#2c3e50',
                    }}
                  >
                    {feature.title}
                  </Typography>
                  <Typography
                    variant="body1"
                    sx={{
                      color: '#7f8c8d',
                      lineHeight: 1.7,
                    }}
                  >
                    {feature.description}
                  </Typography>
                </Stack>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* How It Works Section */}
      <Box
        id="how-it-works"
        sx={{
          bgcolor: alpha('#1976d2', 0.02),
          py: { xs: 8, md: 12 },
        }}
      >
        <Container maxWidth="lg">
          <Stack spacing={2} alignItems="center" sx={{ mb: 8 }}>
            <Typography
              variant="h2"
              sx={{
                fontSize: { xs: '2rem', md: '3rem' },
                fontWeight: 700,
                color: '#2c3e50',
                textAlign: 'center',
              }}
            >
              How It Works
            </Typography>
            <Typography
              variant="h6"
              sx={{
                fontSize: { xs: '1rem', md: '1.2rem' },
                color: '#7f8c8d',
                textAlign: 'center',
                maxWidth: 600,
              }}
            >
              Just four simple steps to start your RoomFi experience
            </Typography>
          </Stack>

          <Grid container spacing={4}>
            {steps.map((step, index) => (
              <Grid item xs={12} sm={6} md={3} key={index}>
                <Stack spacing={2} alignItems="center" textAlign="center">
                  <Box
                    sx={{
                      width: 80,
                      height: 80,
                      borderRadius: '50%',
                      bgcolor: 'white',
                      border: '3px solid',
                      borderColor: '#1976d2',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '2rem',
                      fontWeight: 700,
                      color: '#1976d2',
                      boxShadow: `0 8px 24px ${alpha('#1976d2', 0.2)}`,
                    }}
                  >
                    {step.number}
                  </Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontSize: '1.3rem',
                      fontWeight: 600,
                      color: '#2c3e50',
                    }}
                  >
                    {step.title}
                  </Typography>
                  <Typography
                    variant="body1"
                    sx={{
                      color: '#7f8c8d',
                      lineHeight: 1.6,
                    }}
                  >
                    {step.description}
                  </Typography>
                </Stack>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* Benefits Section */}
      <Container maxWidth="lg" sx={{ py: { xs: 8, md: 12 } }}>
        <Grid container spacing={6} alignItems="center">
          <Grid item xs={12} md={6}>
            <Stack spacing={3}>
              <Typography
                variant="h2"
                sx={{
                  fontSize: { xs: '2rem', md: '3rem' },
                  fontWeight: 700,
                  color: '#2c3e50',
                }}
              >
                Build your digital reputation
              </Typography>
              <Typography
                variant="body1"
                sx={{
                  fontSize: '1.1rem',
                  color: '#7f8c8d',
                  lineHeight: 1.8,
                }}
              >
                With RoomFi, every payment you make improves your on-chain reputation. Your Tenant Passport is more than an NFT: it's your verified history as a responsible tenant.
              </Typography>
              <Stack spacing={2} sx={{ mt: 2 }}>
                {[
                  'Immutable and transparent payment history',
                  'Verifiable reputation that stays with you always',
                  'Access to better housing opportunities',
                  'No need for traditional guarantors',
                ].map((benefit, index) => (
                  <Stack direction="row" spacing={2} alignItems="center" key={index}>
                    <CheckCircleIcon sx={{ color: '#66bb6a', fontSize: 28 }} />
                    <Typography variant="body1" sx={{ color: '#2c3e50', fontSize: '1rem' }}>
                      {benefit}
                    </Typography>
                  </Stack>
                ))}
              </Stack>
            </Stack>
          </Grid>
          <Grid item xs={12} md={6}>
            <Box
              sx={{
                p: 4,
                borderRadius: 4,
                bgcolor: alpha('#66bb6a', 0.05),
                border: '2px solid',
                borderColor: alpha('#66bb6a', 0.2),
              }}
            >
              <Stack spacing={3}>
                <VerifiedUserIcon sx={{ fontSize: 80, color: '#66bb6a' }} />
                <Typography variant="h5" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                  Your verified digital identity
                </Typography>
                <Typography variant="body1" sx={{ color: '#7f8c8d', lineHeight: 1.7 }}>
                  The Tenant Passport NFT securely and privately stores your payment history and reputation as a tenant on the blockchain, giving you total control of your information.
                </Typography>
              </Stack>
            </Box>
          </Grid>
        </Grid>
      </Container>

      {/* CTA Section */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #1976d2 0%, #66bb6a 100%)',
          py: { xs: 8, md: 10 },
          position: 'relative',
          overflow: 'hidden',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            right: 0,
            bottom: 0,
            left: 0,
            background: 'url("data:image/svg+xml,%3Csvg width=\'60\' height=\'60\' viewBox=\'0 0 60 60\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cg fill=\'none\' fill-rule=\'evenodd\'%3E%3Cg fill=\'%23ffffff\' fill-opacity=\'0.05\'%3E%3Cpath d=\'M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z\'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")',
          },
        }}
      >
        <Container maxWidth="md">
          <Stack spacing={4} alignItems="center" textAlign="center" sx={{ position: 'relative', zIndex: 1 }}>
            <Typography
              variant="h2"
              sx={{
                fontSize: { xs: '2rem', md: '3rem' },
                fontWeight: 700,
                color: 'white',
              }}
            >
              Ready to find your ideal roommate?
            </Typography>
            <Typography
              variant="h6"
              sx={{
                fontSize: { xs: '1.1rem', md: '1.3rem' },
                color: 'rgba(255, 255, 255, 0.9)',
                maxWidth: 600,
              }}
            >
              Join RoomFi today and discover a new way to share a home with confidence and security.
            </Typography>
            <Button
              variant="contained"
              size="large"
              onClick={() => navigate('/app')}
              sx={{
                bgcolor: 'white',
                color: '#1976d2',
                px: 6,
                py: 2,
                fontSize: '1.2rem',
                fontWeight: 700,
                borderRadius: 3,
                textTransform: 'none',
                boxShadow: '0 8px 32px rgba(0, 0, 0, 0.2)',
                '&:hover': {
                  bgcolor: '#f5f5f5',
                  transform: 'translateY(-4px)',
                  boxShadow: '0 16px 48px rgba(0, 0, 0, 0.3)',
                },
                transition: 'all 0.3s ease',
              }}
            >
              Start Free
            </Button>
          </Stack>
        </Container>
      </Box>

      {/* Footer */}
      <Box
        sx={{
          bgcolor: '#2c3e50',
          color: 'white',
          py: 6,
          textAlign: 'center',
        }}
      >
        <Container maxWidth="lg">
          <Stack spacing={3} alignItems="center">
            <Box
              component="img"
              src="/roomfilogo2transp.png"
              alt="RoomFi Logo"
              sx={{
                height: { xs: '60px', sm: '70px' },
                width: 'auto',
                mb: 2,
              }}
            />
            <Typography variant="body2" sx={{ color: 'rgba(255, 255, 255, 0.7)' }}>
              Sharing homes with confidence and transparency from the blockchain
            </Typography>
            <Typography variant="body2" sx={{ color: 'rgba(255, 255, 255, 0.5)', fontSize: '0.875rem' }}>
              © 2025 RoomFi. Built with ❤️ for the Sub0 Hackathon
            </Typography>
          </Stack>
        </Container>
      </Box>
    </Box>
  );
};

export default LandingPage;
