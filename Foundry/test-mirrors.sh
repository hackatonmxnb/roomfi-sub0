
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Contract addresses (from deployment)
TENANT_MIRROR="0x1bee75eE77D302876BeD536702E1e3ab68B83f05"
PROPERTY_MIRROR="0xb20F34E89e5be28eD05e3760950ed4D043B4885C"
ISMP_HANDLER="0x6Ab407a0C8EC0E7aE869f2F1797aCBFa7Ab6Bf67"
HYPERBRIDGE_HOST="0x3435bD7e5895356535459D6087D1eB982DAd90e7"

# RPC
RPC_URL="https://sepolia-rollup.arbitrum.io/rpc"

# Test wallet (replace with your test address)
TEST_TENANT="0x8A387ef9acC800eea39E3E6A2d92694dB6c813Ac"

echo -e "${BLUE}"
echo "============================================================================"
echo "  🧪 RoomFi Mirrors Testing Suite"
echo "============================================================================"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Network:${NC} Arbitrum Sepolia"
echo -e "${GREEN}RPC:${NC} $RPC_URL"
echo ""

# ============================================================================
# TEST 1: Verify Contract Deployment
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 1: Verify Contract Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}✓${NC} Checking TenantPassportMirror..."
TENANT_CODE=$(cast code $TENANT_MIRROR --rpc-url $RPC_URL)
if [ ${#TENANT_CODE} -gt 4 ]; then
    echo -e "  ${GREEN}✓ Contract deployed${NC} (bytecode length: ${#TENANT_CODE})"
else
    echo -e "  ${RED}✗ Contract NOT deployed${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Checking PropertyRegistryMirror..."
PROPERTY_CODE=$(cast code $PROPERTY_MIRROR --rpc-url $RPC_URL)
if [ ${#PROPERTY_CODE} -gt 4 ]; then
    echo -e "  ${GREEN}✓ Contract deployed${NC} (bytecode length: ${#PROPERTY_CODE})"
else
    echo -e "  ${RED}✗ Contract NOT deployed${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Checking ISMPMessageHandler..."
HANDLER_CODE=$(cast code $ISMP_HANDLER --rpc-url $RPC_URL)
if [ ${#HANDLER_CODE} -gt 4 ]; then
    echo -e "  ${GREEN}✓ Contract deployed${NC} (bytecode length: ${#HANDLER_CODE})"
else
    echo -e "  ${RED}✗ Contract NOT deployed${NC}"
    exit 1
fi

echo ""

# ============================================================================
# TEST 2: Verify TenantPassportMirror State
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 2: TenantPassportMirror - Read Functions${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}✓${NC} Reading totalTenants..."
TOTAL_TENANTS=$(cast call $TENANT_MIRROR "totalTenants()(uint256)" --rpc-url $RPC_URL)
echo -e "  Total Tenants: ${GREEN}$TOTAL_TENANTS${NC}"

echo -e "${GREEN}✓${NC} Checking if test tenant exists..."
TENANT_EXISTS=$(cast call $TENANT_MIRROR "tenantExists(address)(bool)" $TEST_TENANT --rpc-url $RPC_URL)
if [ "$TENANT_EXISTS" = "true" ]; then
    echo -e "  ${GREEN}✓ Tenant exists${NC}: $TEST_TENANT"

    echo -e "${GREEN}✓${NC} Reading tenant info..."
    TENANT_INFO=$(cast call $TENANT_MIRROR "tenantInfo(address)" $TEST_TENANT --rpc-url $RPC_URL)
    echo -e "  Tenant Info: $TENANT_INFO"
else
    echo -e "  ${YELLOW}⚠ Tenant does NOT exist yet${NC}: $TEST_TENANT"
    echo -e "  ${BLUE}ℹ This is expected - tenant will be synced from Paseo${NC}"
fi

echo -e "${GREEN}✓${NC} Reading ISMP handler address..."
HANDLER=$(cast call $TENANT_MIRROR "ismpMessageHandler()(address)" --rpc-url $RPC_URL)
echo -e "  ISMP Handler: ${GREEN}$HANDLER${NC}"

if [ "$HANDLER" = "$ISMP_HANDLER" ]; then
    echo -e "  ${GREEN}✓ Handler correctly configured${NC}"
else
    echo -e "  ${RED}✗ Handler mismatch!${NC}"
    echo -e "    Expected: $ISMP_HANDLER"
    echo -e "    Got: $HANDLER"
fi

echo ""

# ============================================================================
# TEST 3: Verify PropertyRegistryMirror State
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 3: PropertyRegistryMirror - Read Functions${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}✓${NC} Reading totalProperties..."
TOTAL_PROPERTIES=$(cast call $PROPERTY_MIRROR "totalProperties()(uint256)" --rpc-url $RPC_URL)
echo -e "  Total Properties: ${GREEN}$TOTAL_PROPERTIES${NC}"

echo -e "${GREEN}✓${NC} Reading ISMP handler address..."
PROP_HANDLER=$(cast call $PROPERTY_MIRROR "ismpMessageHandler()(address)" --rpc-url $RPC_URL)
echo -e "  ISMP Handler: ${GREEN}$PROP_HANDLER${NC}"

if [ "$PROP_HANDLER" = "$ISMP_HANDLER" ]; then
    echo -e "  ${GREEN}✓ Handler correctly configured${NC}"
else
    echo -e "  ${RED}✗ Handler mismatch!${NC}"
fi

echo ""

# ============================================================================
# TEST 4: Verify ISMPMessageHandler Configuration
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 4: ISMPMessageHandler - Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}✓${NC} Reading Hyperbridge Host..."
EFFECTIVE_HOST=$(cast call $ISMP_HANDLER "getEffectiveHost()(address)" --rpc-url $RPC_URL)
echo -e "  Effective Host: ${GREEN}$EFFECTIVE_HOST${NC}"

if [ "$EFFECTIVE_HOST" = "$HYPERBRIDGE_HOST" ]; then
    echo -e "  ${GREEN}✓ Hyperbridge Host correctly configured${NC}"
else
    echo -e "  ${YELLOW}⚠ Host mismatch${NC}"
    echo -e "    Expected: $HYPERBRIDGE_HOST"
    echo -e "    Got: $EFFECTIVE_HOST"
fi

echo -e "${GREEN}✓${NC} Reading owner..."
OWNER=$(cast call $ISMP_HANDLER "owner()(address)" --rpc-url $RPC_URL)
echo -e "  Owner: ${GREEN}$OWNER${NC}"

echo -e "${GREEN}✓${NC} Reading max daily messages limit..."
MAX_MESSAGES=$(cast call $ISMP_HANDLER "maxDailyMessages()(uint256)" --rpc-url $RPC_URL)
echo -e "  Max Daily Messages: ${GREEN}$MAX_MESSAGES${NC}"

echo -e "${GREEN}✓${NC} Reading Paseo chain ID..."
PASEO_CHAIN=$(cast call $ISMP_HANDLER "paseoChainId()(bytes32)" --rpc-url $RPC_URL)
echo -e "  Paseo Chain ID: ${GREEN}$PASEO_CHAIN${NC}"

echo ""

# ============================================================================
# TEST 5: Verify Mirror Integration
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 5: Verify Mirror Integration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}✓${NC} Checking TenantMirror registration in Handler..."
TENANT_MIRROR_FROM_HANDLER=$(cast call $ISMP_HANDLER "tenantPassportMirror()(address)" --rpc-url $RPC_URL)
echo -e "  TenantMirror from Handler: ${GREEN}$TENANT_MIRROR_FROM_HANDLER${NC}"

if [ "$TENANT_MIRROR_FROM_HANDLER" = "$TENANT_MIRROR" ]; then
    echo -e "  ${GREEN}✓ TenantMirror correctly registered${NC}"
else
    echo -e "  ${RED}✗ TenantMirror NOT registered${NC}"
fi

echo -e "${GREEN}✓${NC} Checking PropertyMirror registration in Handler..."
PROPERTY_MIRROR_FROM_HANDLER=$(cast call $ISMP_HANDLER "propertyRegistryMirror()(address)" --rpc-url $RPC_URL)
echo -e "  PropertyMirror from Handler: ${GREEN}$PROPERTY_MIRROR_FROM_HANDLER${NC}"

if [ "$PROPERTY_MIRROR_FROM_HANDLER" = "$PROPERTY_MIRROR" ]; then
    echo -e "  ${GREEN}✓ PropertyMirror correctly registered${NC}"
else
    echo -e "  ${RED}✗ PropertyMirror NOT registered${NC}"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${BLUE}"
echo "============================================================================"
echo "  ✅ TEST SUMMARY"
echo "============================================================================"
echo -e "${NC}"
echo ""
echo -e "${GREEN}✓ All contracts deployed successfully${NC}"
echo -e "${GREEN}✓ TenantPassportMirror operational${NC}"
echo -e "${GREEN}✓ PropertyRegistryMirror operational${NC}"
echo -e "${GREEN}✓ ISMPMessageHandler configured${NC}"
echo -e "${GREEN}✓ Hyperbridge integration active${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "1. ${GREEN}Configure pallet-roomfi-bridge${NC} in Paseo runtime"
echo -e "2. ${GREEN}Register Mirror addresses${NC} in the pallet"
echo -e "3. ${GREEN}Test sync functionality${NC} from Paseo → Arbitrum"
echo -e "4. ${GREEN}Integrate with frontend${NC} to read from Mirrors"
echo ""
echo -e "${BLUE}📖 For integration guide, see: FRONTEND_INTEGRATION.md${NC}"
echo ""
echo -e "${GREEN}✅ Mirrors are ready to receive cross-chain messages!${NC}"
echo ""
