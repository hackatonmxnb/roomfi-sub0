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
