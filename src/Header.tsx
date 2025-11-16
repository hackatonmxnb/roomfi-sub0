import React, { useState } from 'react';
import {
  AppBar, Toolbar, Typography, Button, Box, IconButton, Drawer, List, ListItem, ListItemButton, ListItemText, Paper, Select, MenuItem, FormControl
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import { Link as RouterLink } from 'react-router-dom';
import type { SelectChangeEvent } from '@mui/material/Select';

interface HeaderProps {
  account?: string | null;
  tokenBalance?: number;
  onFundingModalOpen?: () => void;
  onDisconnect: () => void;
  onViewNFTClick?: () => void;
  onMintNFTClick?: () => void;
  onViewMyPropertiesClick?: () => void;
  onSavingsClick?: () => void;
  onHowItWorksClick?: () => void;
  tenantPassportData?: any;
  isCreatingWallet?: boolean;
  setShowOnboarding: React.Dispatch<React.SetStateAction<boolean>>;
  showOnboarding?: boolean;
  activeNetwork: 'paseo' | 'arbitrum';
  onNetworkChange?: (network: 'paseo' | 'arbitrum') => void;
}

export default function Header({ account, tokenBalance, onFundingModalOpen, onDisconnect, onViewNFTClick, onMintNFTClick, onViewMyPropertiesClick, onSavingsClick, onHowItWorksClick, tenantPassportData, isCreatingWallet, setShowOnboarding, showOnboarding, activeNetwork, onNetworkChange }: HeaderProps) {
  const [drawerMenuOpen, setDrawerMenuOpen] = useState(false);
  const isMobile = window.innerWidth < 900;

  const handleOpenOnboarding = () => setShowOnboarding(true);
  const handleCloseOnboarding = () => setShowOnboarding(false);

  const handleNetworkChange = (event: SelectChangeEvent<string>) => {
    onNetworkChange?.(event.target.value as 'paseo' | 'arbitrum');
  };

  const handleDisconnect = () => {
    onDisconnect();
    setDrawerMenuOpen(false);
  };

  return (
    <>
      <AppBar position="static" elevation={0} sx={{ bgcolor: 'white', color: 'primary.main', boxShadow: 'none', borderBottom: '1px solid #e0e0e0' }}>
        <Toolbar sx={{ px: { xs: 1, sm: 2 } }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mr: 1 }}>
            <RouterLink to="/" style={{ display: 'block', textDecoration: 'none' }}>
              <img
                src="/roomfilogo2.png"
                alt="RoomFi Logo"
                style={{ height: '50px', objectFit: 'contain', display: 'block', cursor: 'pointer' }}
              />
            </RouterLink>
          </Box>
          <FormControl size="small" sx={{ minWidth: 120, mr: 2 }}>
            <Select
              value={activeNetwork}
              onChange={handleNetworkChange}
              displayEmpty
              sx={{
                bgcolor: 'background.paper',
                '& .MuiOutlinedInput-notchedOutline': {
                  borderColor: 'divider',
                },
              }}
            >
              <MenuItem value="paseo">Paseo (Polkadot)</MenuItem>
              <MenuItem value="arbitrum">Arbitrum</MenuItem>
            </Select>
          </FormControl>
          {!isMobile && (
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexGrow: 1 }}>
              {/* Botones que solo aparecen si la wallet está conectada */}
              {account && (
                <>
                  <Button component={RouterLink} to="/create-pool" sx={{ color: 'primary.main', fontWeight: 600 }}>Crear Pool</Button>
                  <Button onClick={() => onViewMyPropertiesClick?.()} sx={{ color: 'primary.main', fontWeight: 600 }}>Mis Propiedades</Button>
                  <Button onClick={() => onSavingsClick?.()} sx={{ color: 'primary.main', fontWeight: 600 }}>Bóveda</Button>
                </>
              )}
              {/* Botones que siempre son visibles en desktop */}
              <Button onClick={() => onHowItWorksClick?.()} sx={{ color: 'primary.main', fontWeight: 600 }}>Como funciona</Button>
              <Button sx={{ color: 'primary.main', fontWeight: 600 }}>Verifica roomie</Button>
              <Button sx={{ color: 'primary.main', fontWeight: 600 }}>Para empresas</Button>
            </Box>
          )}
          {isMobile && <Box sx={{ flexGrow: 1 }} />}
          {isMobile ? (
            <>
              <IconButton
                size="large"
                aria-label="menu"
                onClick={() => setDrawerMenuOpen(true)}
                sx={{ color: 'primary.main' }}
              >
                <MenuIcon />
              </IconButton>
              <Drawer anchor="left" open={drawerMenuOpen} onClose={() => setDrawerMenuOpen(false)}>
                <Box
                  sx={{ width: 250 }}
                  role="presentation"
                  onClick={() => setDrawerMenuOpen(false)}
                  onKeyDown={() => setDrawerMenuOpen(false)}
                >
                  <List>
                    <ListItem disablePadding>
                      <ListItemButton><ListItemText primary="Como funciona" /></ListItemButton>
                    </ListItem>
                    <ListItem disablePadding>
                      <ListItemButton><ListItemText primary="Verifica roomie" /></ListItemButton>
                    </ListItem>
                    <ListItem disablePadding>
                      <ListItemButton><ListItemText primary="Para empresas" /></ListItemButton>
                    </ListItem>
                    <ListItem disablePadding>
                      <ListItemButton onClick={handleOpenOnboarding}><ListItemText primary="Conectar" /></ListItemButton>
                    </ListItem>
                  </List>
                </Box>
              </Drawer>
            </>
          ) : (
            <>
              {account ? (
                <Paper elevation={2} sx={{ p: 1, display: 'flex', alignItems: 'center', gap: 1, borderRadius: 2 }}>
                  <Box sx={{ textAlign: 'right' }}>
                    <Typography variant="body2" sx={{ fontWeight: 'bold' }}>{tokenBalance?.toFixed(2)} MXNB</Typography>
                    <Typography variant="caption" sx={{ color: 'text.secondary' }}>{`${account?.substring(0, 6)}...${account?.substring(account.length - 4)}`}</Typography>
                  </Box>
                  <Button variant="contained" size="small" onClick={() => onFundingModalOpen?.()}>Añadir Fondos</Button>
                  <Button variant="outlined" size="small" onClick={() => onViewNFTClick?.()}>Ver mi NFT</Button>
                  <Button variant="text" size="small" onClick={handleDisconnect} color="error">Desconectar</Button>
                </Paper>
              ) : (
                <Button
                  color="primary"
                  variant="contained"
                  onClick={handleOpenOnboarding}
                  sx={{ ml: 2, bgcolor: 'primary.main', color: 'white', '&:hover': { bgcolor: 'primary.dark' } }}
                >
                  Conectar
                </Button>
              )}
            </>
          )}
        </Toolbar>
      </AppBar>
      {/* El modal de conexión ahora se renderiza en App.tsx con WalletConnectModal */}
    </>
  );
} 