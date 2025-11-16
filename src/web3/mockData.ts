/**
 * Mock data para desarrollo sin contratos desplegados
 * Simula respuestas de TenantPassportV2 y otros contratos
 */

export const MOCK_MODE = true; // Cambiar a false cuando haya contratos desplegados

export interface MockTenantPassportData {
  tokenId: bigint;
  reputation: number;
  totalPaymentsMade: number;
  paymentsMissed: number;
  activeDisputes: number;
  resolvedDisputes: number;
  depositBalance: number;
  monthsAsResident: number;
  totalAmountPaid: number;
  currentStreak: number;
  longestStreak: number;
  isKYCVerified: boolean;
  mintingWalletAddress: string;
  badges: {
    // KYC Badges
    KYC_ID_VERIFIED: boolean;
    KYC_INCOME_VERIFIED: boolean;
    KYC_EMPLOYMENT_VERIFIED: boolean;
    KYC_STUDENT_VERIFIED: boolean;
    KYC_PROFESSIONAL_VERIFIED: boolean;
    KYC_CREDIT_SCORE: boolean;
    // Performance Badges
    EARLY_ADOPTER: boolean;
    RELIABLE_TENANT: boolean;
    LONG_TERM_TENANT: boolean;
    ZERO_DISPUTES: boolean;
    NO_DAMAGE_HISTORY: boolean;
    FAST_RESPONDER: boolean;
    HIGH_VALUE: boolean;
    MULTI_PROPERTY: boolean;
  };
}

/**
 * Genera datos mock para un tenant passport
 */
export function getMockTenantPassport(address: string): MockTenantPassportData {
  // Datos realistas para la demo
  return {
    tokenId: BigInt(1),
    reputation: 850, // De 0-1000
    totalPaymentsMade: 12,
    paymentsMissed: 1,
    activeDisputes: 0,
    resolvedDisputes: 0,
    depositBalance: 1500, // En USDT (6 decimals)
    monthsAsResident: 12,
    totalAmountPaid: 18000, // $18,000 pagados en total
    currentStreak: 8, // 8 pagos consecutivos
    longestStreak: 10,
    isKYCVerified: true,
    mintingWalletAddress: address,
    badges: {
      // KYC - Todos verificados para la demo
      KYC_ID_VERIFIED: true,
      KYC_INCOME_VERIFIED: true,
      KYC_EMPLOYMENT_VERIFIED: true,
      KYC_STUDENT_VERIFIED: false,
      KYC_PROFESSIONAL_VERIFIED: true,
      KYC_CREDIT_SCORE: true,
      // Performance
      EARLY_ADOPTER: true,
      RELIABLE_TENANT: true,
      LONG_TERM_TENANT: true,
      ZERO_DISPUTES: true,
      NO_DAMAGE_HISTORY: true,
      FAST_RESPONDER: true,
      HIGH_VALUE: true,
      MULTI_PROPERTY: false,
    }
  };
}

/**
 * Simula delay de red
 */
export async function simulateNetworkDelay(ms: number = 1000): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Mock: Mintear un passport
 */
export async function mockMintPassport(address: string): Promise<MockTenantPassportData> {
  console.log('🎭 [MOCK] Minting passport for:', address);
  await simulateNetworkDelay(2000); // Simula espera de transacción
  console.log('✅ [MOCK] Passport minted successfully');
  return getMockTenantPassport(address);
}

/**
 * Mock: Obtener passport existente
 */
export async function mockGetPassport(address: string): Promise<MockTenantPassportData | null> {
  console.log('🎭 [MOCK] Getting passport for:', address);
  await simulateNetworkDelay(500);
  
  // Simula que algunos usuarios ya tienen passport
  const hasPassport = Math.random() > 0.3; // 70% de chance
  
  if (hasPassport) {
    console.log('✅ [MOCK] Passport found');
    return getMockTenantPassport(address);
  } else {
    console.log('ℹ️ [MOCK] No passport found');
    return null;
  }
}

/**
 * Mock: Balance de tokens
 */
export async function mockGetTokenBalance(address: string): Promise<number> {
  console.log('🎭 [MOCK] Getting token balance for:', address);
  await simulateNetworkDelay(300);
  const balance = 1000 + Math.random() * 9000; // Entre 1000-10000
  console.log('✅ [MOCK] Balance:', balance.toFixed(2));
  return balance;
}

// ============================================
// PROPERTY REGISTRY MOCKS
// ============================================

export interface MockPropertyData {
  propertyId: string;
  landlord: string;
  name: string;
  propertyType: number;
  fullAddress: string;
  city: string;
  state: string;
  bedrooms: number;
  bathrooms: number;
  squareMeters: number;
  monthlyRent: string;
  securityDeposit: string;
  verificationStatus: number; // 0=DRAFT, 1=PENDING, 2=VERIFIED
  isActive: boolean;
  isCurrentlyRented: boolean;
  propertyReputation: number;
}

/**
 * Mock: Registrar propiedad
 */
export async function mockRegisterProperty(propertyData: Partial<MockPropertyData>): Promise<string> {
  console.log('🎭 [MOCK] Registering property:', propertyData.name);
  await simulateNetworkDelay(2000);
  const propertyId = `0x${Math.random().toString(16).substring(2, 66)}`;
  console.log('✅ [MOCK] Property registered with ID:', propertyId);
  return propertyId;
}

/**
 * Mock: Obtener propiedad por ID
 */
export async function mockGetProperty(propertyId: string): Promise<MockPropertyData> {
  console.log('🎭 [MOCK] Getting property:', propertyId);
  await simulateNetworkDelay(500);
  return {
    propertyId,
    landlord: '0x1234567890123456789012345678901234567890',
    name: 'Departamento Moderno en Condesa',
    propertyType: 1, // APARTMENT
    fullAddress: 'Av. Amsterdam 123, Condesa, CDMX',
    city: 'Ciudad de México',
    state: 'CDMX',
    bedrooms: 2,
    bathrooms: 2,
    squareMeters: 85,
    monthlyRent: '25000',
    securityDeposit: '50000',
    verificationStatus: 2, // VERIFIED
    isActive: true,
    isCurrentlyRented: false,
    propertyReputation: 850
  };
}

/**
 * Mock: Buscar propiedades por ciudad
 */
export async function mockGetPropertiesByCity(city: string): Promise<string[]> {
  console.log('🎭 [MOCK] Searching properties in:', city);
  await simulateNetworkDelay(800);
  // Retornar algunos property IDs de ejemplo
  return [
    `0x${Math.random().toString(16).substring(2, 66)}`,
    `0x${Math.random().toString(16).substring(2, 66)}`,
    `0x${Math.random().toString(16).substring(2, 66)}`
  ];
}

// ============================================
// RENTAL AGREEMENT MOCKS
// ============================================

export interface MockAgreementData {
  agreementAddress: string;
  propertyId: string;
  landlord: string;
  tenant: string;
  monthlyRent: string;
  securityDeposit: string;
  duration: number; // meses
  status: number; // 0=PENDING, 1=ACTIVE, 2=COMPLETED, etc
  tenantSigned: boolean;
  landlordSigned: boolean;
  depositPaid: boolean;
  paymentsMade: number;
  nextPaymentDue: number; // timestamp
}

/**
 * Mock: Crear rental agreement
 */
export async function mockCreateAgreement(
  propertyId: string,
  tenant: string,
  monthlyRent: string,
  securityDeposit: string,
  duration: number
): Promise<string> {
  console.log('🎭 [MOCK] Creating rental agreement...');
  console.log('  Property:', propertyId);
  console.log('  Tenant:', tenant);
  console.log('  Monthly Rent:', monthlyRent);
  console.log('  Duration:', duration, 'months');
  await simulateNetworkDelay(2500);
  const agreementAddress = `0x${Math.random().toString(16).substring(2, 42)}`;
  console.log('✅ [MOCK] Agreement created at:', agreementAddress);
  return agreementAddress;
}

/**
 * Mock: Obtener datos de agreement
 */
export async function mockGetAgreement(agreementAddress: string): Promise<MockAgreementData> {
  console.log('🎭 [MOCK] Getting agreement:', agreementAddress);
  await simulateNetworkDelay(500);
  return {
    agreementAddress,
    propertyId: `0x${Math.random().toString(16).substring(2, 66)}`,
    landlord: '0x1234567890123456789012345678901234567890',
    tenant: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
    monthlyRent: '25000',
    securityDeposit: '50000',
    duration: 12,
    status: 1, // ACTIVE
    tenantSigned: true,
    landlordSigned: true,
    depositPaid: true,
    paymentsMade: 3,
    nextPaymentDue: Date.now() + 30 * 24 * 60 * 60 * 1000 // +30 días
  };
}

/**
 * Mock: Firmar agreement (landlord o tenant)
 */
export async function mockSignAgreement(agreementAddress: string, asLandlord: boolean): Promise<void> {
  console.log('🎭 [MOCK] Signing agreement as:', asLandlord ? 'Landlord' : 'Tenant');
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Agreement signed successfully');
}

/**
 * Mock: Pagar security deposit
 */
export async function mockPayDeposit(agreementAddress: string, amount: string): Promise<void> {
  console.log('🎭 [MOCK] Paying security deposit:', amount);
  await simulateNetworkDelay(2000);
  console.log('✅ [MOCK] Deposit paid successfully');
}

/**
 * Mock: Pagar renta mensual
 */
export async function mockPayRent(agreementAddress: string, amount: string): Promise<void> {
  console.log('🎭 [MOCK] Paying rent:', amount);
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Rent paid successfully');
}

/**
 * Mock: Obtener agreements del tenant
 */
export async function mockGetTenantAgreements(tenantAddress: string): Promise<string[]> {
  console.log('🎭 [MOCK] Getting agreements for tenant:', tenantAddress);
  await simulateNetworkDelay(600);
  return [
    `0x${Math.random().toString(16).substring(2, 42)}`,
    `0x${Math.random().toString(16).substring(2, 42)}`
  ];
}

/**
 * Mock: Obtener agreements del landlord
 */
export async function mockGetLandlordAgreements(landlordAddress: string): Promise<string[]> {
  console.log('🎭 [MOCK] Getting agreements for landlord:', landlordAddress);
  await simulateNetworkDelay(600);
  return [
    `0x${Math.random().toString(16).substring(2, 42)}`,
    `0x${Math.random().toString(16).substring(2, 42)}`,
    `0x${Math.random().toString(16).substring(2, 42)}`
  ];
}

// ============================================
// DISPUTE RESOLVER MOCKS
// ============================================

export interface MockDisputeData {
  disputeId: number;
  agreementAddress: string;
  initiator: string;
  respondent: string;
  reason: number;
  evidenceURI: string;
  status: number; // 0=PENDING_RESPONSE, 1=IN_ARBITRATION, 2=RESOLVED
  votesForInitiator: number;
  votesForRespondent: number;
}

/**
 * Mock: Crear disputa
 */
export async function mockCreateDispute(
  agreementAddress: string,
  reason: number,
  evidenceURI: string,
  amountInDispute: string
): Promise<number> {
  console.log('🎭 [MOCK] Creating dispute...');
  console.log('  Agreement:', agreementAddress);
  console.log('  Reason code:', reason);
  console.log('  Evidence:', evidenceURI);
  await simulateNetworkDelay(2000);
  const disputeId = Math.floor(Math.random() * 1000);
  console.log('✅ [MOCK] Dispute created with ID:', disputeId);
  return disputeId;
}

/**
 * Mock: Obtener datos de disputa
 */
export async function mockGetDispute(disputeId: number): Promise<MockDisputeData> {
  console.log('🎭 [MOCK] Getting dispute:', disputeId);
  await simulateNetworkDelay(500);
  return {
    disputeId,
    agreementAddress: `0x${Math.random().toString(16).substring(2, 42)}`,
    initiator: '0x1234567890123456789012345678901234567890',
    respondent: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
    reason: 1, // PROPERTY_DAMAGE
    evidenceURI: 'ipfs://QmExampleHash...',
    status: 1, // IN_ARBITRATION
    votesForInitiator: 1,
    votesForRespondent: 0
  };
}

/**
 * Mock: Responder a disputa
 */
export async function mockSubmitResponse(disputeId: number, responseURI: string): Promise<void> {
  console.log('🎭 [MOCK] Submitting response to dispute:', disputeId);
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Response submitted');
}

/**
 * Mock: Votar en disputa (solo árbitros)
 */
export async function mockVoteOnDispute(disputeId: number, forInitiator: boolean): Promise<void> {
  console.log('🎭 [MOCK] Voting on dispute:', disputeId);
  console.log('  Vote for:', forInitiator ? 'Initiator' : 'Respondent');
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Vote submitted');
}

// ============================================
// VAULT MOCKS
// ============================================

/**
 * Mock: Depositar en vault
 */
export async function mockDepositToVault(amount: string): Promise<void> {
  console.log('🎭 [MOCK] Depositing to vault:', amount);
  await simulateNetworkDelay(1500);
  console.log('✅ [MOCK] Deposited successfully');
}

/**
 * Mock: Retirar de vault
 */
export async function mockWithdrawFromVault(amount: string): Promise<void> {
  console.log('🎭 [MOCK] Withdrawing from vault:', amount);
  await simulateNetworkDelay(1800);
  console.log('✅ [MOCK] Withdrawn successfully');
}

/**
 * Mock: Obtener balance en vault
 */
export async function mockGetVaultBalance(address: string): Promise<string> {
  console.log('🎭 [MOCK] Getting vault balance for:', address);
  await simulateNetworkDelay(300);
  const balance = (Math.random() * 10000).toFixed(2);
  console.log('✅ [MOCK] Vault balance:', balance);
  return balance;
}

/**
 * Mock: Obtener intereses generados
 */
export async function mockGetVaultInterest(address: string): Promise<string> {
  console.log('🎭 [MOCK] Getting vault interest for:', address);
  await simulateNetworkDelay(300);
  const interest = (Math.random() * 500).toFixed(2);
  console.log('✅ [MOCK] Interest earned:', interest);
  return interest;
}
