# 🚀 Frontend Integration Checklist - RoomFi V2

**Fecha**: 2025-01-15  
**Status**: Contracts DEPLOYED ✅ | Frontend en MOCK_MODE ⏳

---

## 📋 ESTADO ACTUAL

### ✅ Completado
- [x] Contratos V2 desplegados en AssetHub Paseo
- [x] Addresses configuradas en `src/web3/config.ts`
- [x] ABIs básicos creados (TenantPassport, PropertyRegistry, RentalAgreement)
- [x] Sistema de MOCK_MODE implementado
- [x] PropertyRegistryPage creada
- [x] Sistema de wallet connection implementado (MetaMask/SubWallet/Google)

### ⏳ Pendiente
- [ ] ABIs faltantes (Factory, DisputeResolver, Vault)
- [ ] Actualizar mockData.ts con todas las funciones V2
- [ ] Componentes de RentalAgreement
- [ ] Componentes de Dispute Resolution
- [ ] Testing con contratos reales
- [ ] Cambiar MOCK_MODE = false

---

## 🎯 CHECKLIST DE INTEGRACIÓN

### Fase 1: ABIs y Configuración (2-3 horas)

#### 1.1 Crear ABIs Faltantes
Necesitamos extraer de los contratos compilados en Foundry:

```bash
# Ir al directorio de contratos
cd Foundry

# Extraer ABIs desde los artifacts
forge inspect RentalAgreementFactory abi > ../src/web3/abis/RENTAL_AGREEMENT_FACTORY_ABI.json
forge inspect DisputeResolver abi > ../src/web3/abis/DISPUTE_RESOLVER_ABI.json
forge inspect RoomFiVault abi > ../src/web3/abis/ROOMFI_VAULT_ABI.json
```

- [ ] `RENTAL_AGREEMENT_FACTORY_ABI.json`
- [ ] `DISPUTE_RESOLVER_ABI.json`
- [ ] `ROOMFI_VAULT_ABI.json`

#### 1.2 Actualizar config.ts

```typescript
// Agregar exports de nuevos ABIs
import RENTAL_AGREEMENT_FACTORY_ABI from './abis/RENTAL_AGREEMENT_FACTORY_ABI.json';
import DISPUTE_RESOLVER_ABI from './abis/DISPUTE_RESOLVER_ABI.json';
import ROOMFI_VAULT_ABI from './abis/ROOMFI_VAULT_ABI.json';

export {
    MXNB_ABI,
    TENANT_PASSPORT_ABI,
    PROPERTY_REGISTRY_ABI,
    RENTAL_AGREEMENT_ABI,
    RENTAL_AGREEMENT_FACTORY_ABI,  // NUEVO
    DISPUTE_RESOLVER_ABI,           // NUEVO
    ROOMFI_VAULT_ABI                // NUEVO
};
```

- [ ] Imports agregados
- [ ] Exports actualizados

---

### Fase 2: Mock Data Completo (3-4 horas)

#### 2.1 Actualizar mockData.ts

Agregar funciones mock para todas las operaciones V2:

```typescript
// src/web3/mockData.ts

// Property Registry Mocks
export async function mockRegisterProperty(propertyData: any): Promise<string> {
  console.log('🎭 [MOCK] Registering property:', propertyData);
  await simulateNetworkDelay(2000);
  const propertyId = `0x${Math.random().toString(16).substring(2, 66)}`;
  console.log('✅ [MOCK] Property registered with ID:', propertyId);
  return propertyId;
}

export async function mockGetProperty(propertyId: string): Promise<any> {
  // Retornar datos mock de una propiedad
}

export async function mockGetPropertiesByCity(city: string): Promise<string[]> {
  // Retornar array de property IDs
}

// Rental Agreement Mocks
export async function mockCreateAgreement(
  propertyId: string,
  tenant: string,
  monthlyRent: string,
  securityDeposit: string,
  duration: number
): Promise<string> {
  console.log('🎭 [MOCK] Creating rental agreement...');
  await simulateNetworkDelay(2500);
  const agreementAddress = `0x${Math.random().toString(16).substring(2, 42)}`;
  console.log('✅ [MOCK] Agreement created at:', agreementAddress);
  return agreementAddress;
}

export async function mockGetAgreement(agreementAddress: string): Promise<any> {
  // Retornar datos mock del agreement
}

export async function mockPayRent(agreementAddress: string, amount: string): Promise<void> {
  console.log('🎭 [MOCK] Paying rent:', amount);
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Rent paid successfully');
}

// Dispute Mocks
export async function mockCreateDispute(
  agreementAddress: string,
  reason: number,
  evidenceURI: string
): Promise<number> {
  console.log('🎭 [MOCK] Creating dispute...');
  await simulateNetworkDelay(2000);
  const disputeId = Math.floor(Math.random() * 1000);
  console.log('✅ [MOCK] Dispute created with ID:', disputeId);
  return disputeId;
}

// Vault Mocks
export async function mockDepositToVault(amount: string): Promise<void> {
  console.log('🎭 [MOCK] Depositing to vault:', amount);
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Deposited successfully');
}

export async function mockGetVaultBalance(address: string): Promise<string> {
  await simulateNetworkDelay(300);
  const balance = (Math.random() * 10000).toFixed(2);
  return balance;
}
```

- [ ] Property Registry mocks
- [ ] Rental Agreement mocks
- [ ] Dispute mocks
- [ ] Vault mocks
- [ ] Funciones de query (getters)

---

### Fase 3: Componentes Core (12-16 horas)

#### 3.1 Componente: CreateRentalAgreement.tsx

**Ubicación**: `src/components/CreateRentalAgreement.tsx`

**Funcionalidad**:
- Formulario para crear agreement
- Selección de propiedad
- Input de tenant address
- Configuración de renta y depósito
- Integración con MOCK_MODE

```typescript
const handleCreateAgreement = async () => {
  if (MOCK_MODE) {
    const agreementAddress = await mockCreateAgreement(
      propertyId, tenant, monthlyRent, securityDeposit, duration
    );
    // Guardar en estado local
  } else {
    const factoryContract = new ethers.Contract(
      CONTRACTS[activeNetwork].RENTAL_AGREEMENT_FACTORY_ADDRESS!,
      RENTAL_AGREEMENT_FACTORY_ABI,
      signer
    );
    
    const tx = await factoryContract.createAgreement(
      propertyId,
      tenant,
      ethers.parseUnits(monthlyRent, 6), // USDT 6 decimals
      ethers.parseUnits(securityDeposit, 6),
      duration
    );
    
    const receipt = await tx.wait();
    // Obtener agreementAddress de eventos
  }
};
```

- [ ] Componente creado
- [ ] Integrado con MOCK_MODE
- [ ] UI/UX implementado
- [ ] Validaciones

#### 3.2 Componente: RentalAgreementView.tsx

**Ubicación**: `src/components/RentalAgreementView.tsx`

**Funcionalidad**:
- Vista de agreement individual
- Firmas (landlord + tenant)
- Pago de security deposit
- Pago de renta mensual
- Raise dispute
- Estados del agreement

```typescript
const RentalAgreementView = ({ agreementAddress }: { agreementAddress: string }) => {
  const [agreement, setAgreement] = useState<any>(null);
  
  useEffect(() => {
    const fetchAgreement = async () => {
      if (MOCK_MODE) {
        const data = await mockGetAgreement(agreementAddress);
        setAgreement(data);
      } else {
        const contract = new ethers.Contract(
          agreementAddress,
          RENTAL_AGREEMENT_ABI,
          provider
        );
        
        const details = await contract.getAgreementDetails();
        setAgreement(details);
      }
    };
    
    fetchAgreement();
  }, [agreementAddress]);
  
  // UI con tabs:
  // - Details
  // - Payment Schedule
  // - Actions (sign, pay, dispute)
};
```

- [ ] Componente creado
- [ ] Vista de detalles
- [ ] Integración de firma
- [ ] Sistema de pagos
- [ ] Raise dispute

#### 3.3 Componente: DisputeManager.tsx

**Funcionalidad**:
- Vista de disputas activas
- Crear nueva disputa
- Subir evidencia (IPFS)
- Votar (para árbitros)
- Ver resultado

- [ ] Componente creado
- [ ] Formulario de disputa
- [ ] Upload a IPFS
- [ ] Panel de árbitro

---

### Fase 4: Integración con App.tsx (4-6 horas)

#### 4.1 Actualizar funciones existentes

```typescript
// App.tsx

// Actualizar getOrCreateTenantPassport para usar red correcta
const getOrCreateTenantPassport = useCallback(async (userAddress: string) => {
  if (MOCK_MODE) {
    // ... código mock existente
  } else {
    // USAR PASEO, NO ARBITRUM
    const passportContract = new ethers.Contract(
      CONTRACTS.paseo.TENANT_PASSPORT_ADDRESS,  // Cambio crítico
      TENANT_PASSPORT_ABI,
      provider
    );
    
    const hasPassport = await passportContract.hasPassport(userAddress);
    
    if (!hasPassport) {
      const tx = await passportContract.mintForSelf();
      await tx.wait();
    }
    
    const tokenId = await passportContract.getTokenIdByAddress(userAddress);
    const info = await passportContract.getTenantInfo(tokenId);
    
    // Mapear a estructura del frontend
    return {
      tokenId,
      reputation: info.reputation,
      paymentsMade: info.paymentsMade,
      paymentsMissed: info.paymentsMissed,
      // ... resto de campos
    };
  }
}, [provider]);
```

- [ ] Actualizar red de TenantPassport (Paseo)
- [ ] Funciones de Property Registry
- [ ] Funciones de Rental Agreement
- [ ] Funciones de Vault

#### 4.2 Agregar nuevas rutas

```typescript
// App.tsx - Routing

<Routes>
  <Route path="/" element={<LandingPage />} />
  <Route path="/app" element={<MainApp />} />
  <Route path="/register" element={<RegisterPage />} />
  <Route path="/properties" element={<PropertyRegistryPage />} />
  
  {/* NUEVAS RUTAS */}
  <Route path="/agreements" element={<MyAgreementsPage />} />
  <Route path="/agreement/:address" element={<RentalAgreementView />} />
  <Route path="/disputes" element={<DisputesPage />} />
  <Route path="/dispute/:id" element={<DisputeView />} />
  
  <Route path="/dashboard" element={<DashboardPage />} />
  <Route path="/create-pool" element={<CreatePoolPage />} /> {/* Deprecar */}
</Routes>
```

- [ ] Rutas agregadas
- [ ] Navegación actualizada

---

### Fase 5: Testing con Contratos Reales (6-8 horas)

#### 5.1 Setup de Testing

```bash
# 1. Obtener PAS tokens del faucet
# https://faucet.polkadot.io/?parachain=1000

# 2. Obtener MockUSDT de prueba
cast send 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8 \
  "mint(address,uint256)" \
  TU_ADDRESS 10000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://testnet-passet-hub-eth-rpc.polkadot.io \
  --legacy

# 3. Conectar wallet al frontend
# - Agregar AssetHub Paseo a MetaMask/SubWallet
# - Network: AssetHub Paseo Testnet
# - RPC: https://testnet-passet-hub-eth-rpc.polkadot.io
# - Chain ID: 420420422
# - Symbol: PAS
```

#### 5.2 Tests a Realizar

- [ ] **TenantPassport**
  - [ ] Mint passport
  - [ ] Visualizar datos del passport
  - [ ] Ver badges

- [ ] **PropertyRegistry**
  - [ ] Registrar propiedad
  - [ ] Solicitar verificación
  - [ ] Buscar propiedades por ciudad

- [ ] **RentalAgreement**
  - [ ] Crear agreement
  - [ ] Firma de landlord
  - [ ] Firma de tenant
  - [ ] Pago de security deposit
  - [ ] Pago de renta
  - [ ] Completar agreement

- [ ] **Dispute**
  - [ ] Crear disputa
  - [ ] Subir evidencia
  - [ ] Verificar estado

- [ ] **Vault**
  - [ ] Depositar USDT
  - [ ] Ver balance
  - [ ] Ver intereses generados
  - [ ] Retirar fondos

#### 5.3 Cambiar a Modo Producción

Una vez que todos los tests pasen:

```typescript
// src/web3/mockData.ts

export const MOCK_MODE = false; // ✅ CAMBIO CRÍTICO
```

- [ ] Todos los tests pasan
- [ ] MOCK_MODE = false
- [ ] Verificación en producción

---

### Fase 6: Optimizaciones y Polish (4-6 horas)

#### 6.1 UX Improvements

- [ ] Loading states en todas las transacciones
- [ ] Error handling robusto
- [ ] Confirmaciones de transacción
- [ ] Notificaciones mejoradas

#### 6.2 UI Polish

- [ ] Badges visuales para TenantPassport
- [ ] Timeline de payment schedule
- [ ] Status indicators para agreements
- [ ] Property cards mejoradas

#### 6.3 Performance

- [ ] Cacheo de queries frecuentes
- [ ] Optimización de re-renders
- [ ] Lazy loading de componentes

---

## 📊 ESTIMACIÓN DE TIEMPO

| Fase | Tiempo Estimado | Prioridad |
|------|----------------|-----------|
| Fase 1: ABIs y Config | 2-3 horas | 🔴 CRÍTICO |
| Fase 2: Mock Data | 3-4 horas | 🔴 CRÍTICO |
| Fase 3: Componentes Core | 12-16 horas | 🔴 CRÍTICO |
| Fase 4: Integración App | 4-6 horas | 🟡 ALTO |
| Fase 5: Testing Real | 6-8 horas | 🟡 ALTO |
| Fase 6: Polish | 4-6 horas | 🟢 MEDIO |
| **TOTAL** | **31-43 horas** | **~1 semana** |

---

## 🚨 CRÍTICO: Antes de MOCK_MODE = false

### Checklist Pre-Switch

- [ ] Todos los ABIs creados e importados
- [ ] Todas las addresses verificadas en config.ts
- [ ] Red activa en frontend = "paseo" (no "arbitrum")
- [ ] MetaMask/SubWallet configurado con AssetHub Paseo
- [ ] Suficientes PAS tokens para gas
- [ ] MockUSDT en wallet para testing
- [ ] TenantPassport minted
- [ ] Al menos 1 propiedad registrada para testing
- [ ] Todos los componentes V2 funcionan con mocks

### Verificación de Configuración

```typescript
// Verificar que usas Paseo por defecto
// src/App.tsx
const [activeNetwork, setActiveNetwork] = useState<EvmNetwork>('paseo'); // ✅

// Verificar addresses
console.log('TenantPassport:', CONTRACTS.paseo.TENANT_PASSPORT_ADDRESS);
// Debe ser: 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3

console.log('PropertyRegistry:', CONTRACTS.paseo.PROPERTY_REGISTRY_ADDRESS);
// Debe ser: 0x752A5e16899f0849e2B632eA7F7446B2D11d1e17

console.log('RentalFactory:', CONTRACTS.paseo.RENTAL_AGREEMENT_FACTORY_ADDRESS);
// Debe ser: 0x1514e3cCC72bc2FdcA2E7a6d52303917a133E5ae
```

---

## 📝 NOTAS IMPORTANTES

### Diferencias V1 vs V2

1. **V1 (Arbitrum) - DEPRECADO**:
   - Property Interest Pools
   - Sistema de fondeo colectivo
   - No hay rental agreements individuales

2. **V2 (Paseo) - ACTUAL**:
   - PropertyRegistry (NFTs de propiedades)
   - RentalAgreement individuales
   - Sistema de disputas
   - Vault con yield farming

### Red por Defecto

**CAMBIO CRÍTICO**: El frontend debe usar Paseo por defecto, NO Arbitrum.

```typescript
// src/App.tsx
const [activeNetwork, setActiveNetwork] = useState<EvmNetwork>('paseo'); // Cambio
```

### Token Decimals

- **MockUSDT (Paseo)**: 6 decimals (como USDT real)
- **MXNBT (Arbitrum V1)**: 18 decimals

```typescript
// Siempre usar el correcto
const decimals = activeNetwork === 'paseo' ? 6 : 18;
ethers.parseUnits(amount, decimals);
```

---

## ✅ CRITERIOS DE ÉXITO

El frontend está listo cuando:

1. ✅ Todos los ABIs importados sin errores
2. ✅ MOCK_MODE puede ser false sin crashes
3. ✅ TenantPassport funciona end-to-end
4. ✅ PropertyRegistry permite registrar y buscar
5. ✅ RentalAgreement permite crear, firmar, pagar
6. ✅ Disputes pueden ser creadas
7. ✅ Vault permite depósito/retiro
8. ✅ Todas las transacciones se confirman en blockchain

---

## 🎯 PRÓXIMOS PASOS INMEDIATOS

### HOY (Prioridad Máxima)

1. **Extraer ABIs faltantes** (30 min)
   ```bash
   cd Foundry
   forge inspect RentalAgreementFactory abi > ../src/web3/abis/RENTAL_AGREEMENT_FACTORY_ABI.json
   forge inspect DisputeResolver abi > ../src/web3/abis/DISPUTE_RESOLVER_ABI.json
   forge inspect RoomFiVault abi > ../src/web3/abis/ROOMFI_VAULT_ABI.json
   ```

2. **Actualizar config.ts** (15 min)
   - Agregar imports de ABIs
   - Exportarlos

3. **Completar mockData.ts** (2-3 horas)
   - Agregar todas las funciones mock necesarias

### MAÑANA

4. **Crear componentes core** (1 día)
   - CreateRentalAgreement.tsx
   - RentalAgreementView.tsx
   - DisputeManager.tsx

5. **Integrar con App.tsx** (medio día)
   - Actualizar rutas
   - Conectar componentes

### PRÓXIMA SEMANA

6. **Testing exhaustivo** (1-2 días)
7. **MOCK_MODE = false** (cuando todo funcione)
8. **Polish final** (1 día)

---

**¿Listo para empezar? 🚀**
