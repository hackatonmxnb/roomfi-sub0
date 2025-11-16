# MILESTONE 2 PLAN: RoomFi - Cross-Chain Rental Reputation Protocol

**Team:** RoomFi Labs
**Track:** [X] SHIP-A-TON [ ] IDEA-TON
**Date:** November 16, 2025

---

## 📍 WHERE WE ARE NOW

**What we built/validated this weekend:**
- **11 production-ready smart contracts** deployed on Paseo testnet (7,421 lines of Solidity)
  - Core: TenantPassportV2, PropertyRegistry, RentalAgreementFactory, RoomFiVault, DisputeResolver, AcalaYieldStrategy
  - Mirrors: Cross-chain read-only contracts on Arbitrum Sepolia via Hyperbridge ISMP
- **Substrate pallet** (`pallet-roomfi-bridge`, 464 lines Rust) that reads PolkaVM contracts and dispatches ISMP messages
- **Live frontend** at [roomfi.netlify.app/app](https://roomfi.netlify.app/app) with wallet integration (Polkadot.js)
- **Legal framework validation** - contracts are legally binding under Mexican, Colombian, and Argentine law (Art. 89 Código de Comercio MX, Ley 527/1999 CO, Ley 25.506 AR)
- **Cross-chain sync proof-of-concept** - tenant reputation syncs from Polkadot → Arbitrum via Hyperbridge

**What's working:**
- ✅ TenantPassport minting and reputation tracking (0-100 score, 14 badge types)
- ✅ Property registration with GPS anti-fraud verification
- ✅ Rental agreement factory (gas-efficient clone pattern)
- ✅ Security deposit vault with Acala yield routing (6-12% APY design)
- ✅ Cross-chain message handling (ISMP integration functional)
- ✅ Frontend can read/write to all core contracts
- ✅ Mirror contracts successfully receive and store synced data

**What still needs work:**
- **Testing coverage** - Only basic compilation tests exist, need comprehensive unit/integration/fuzz tests
- **Pallet runtime integration** - Pallet code is written but NOT integrated into Paseo runtime yet
- **End-to-end cross-chain flow** - Haven't tested full cycle: Polkadot transaction → Pallet read → ISMP dispatch → Arbitrum update → Frontend verification
- **Production frontend** - Current UI is functional but needs UX polish, mobile optimization, error handling
- **Security hardening** - No formal audit, gas optimization needed, attack vector analysis pending
- **Real user validation** - Zero external users have tested the system

**Blockers or hurdles we hit:**
- **PolkaVM documentation gaps** - Struggled to find examples of pallets reading EVM contract state via PolkaVM
- **Hyperbridge relayer setup** - Configuration complexity for testnet message routing
- **Acala integration** - YieldStrategy contract needs actual Acala testnet deployment and testing (currently mock)
- **Test infrastructure** - Setting up local Paseo fork with integrated pallet is time-intensive

---

## 🚀 WHAT WE'LL SHIP IN 30 DAYS

**Our MVP will do this:**

A production-ready rental reputation system where a tenant in Mexico City can mint a TenantPassport NFT, make on-time rent payments tracked on-chain, and have their reputation instantly verifiable by landlords in Buenos Aires via cross-chain sync—all without lawyers, centralized databases, or API calls. Security deposits earn 6-12% APY through Acala DeFi strategies, and disputes are resolved by decentralized arbitration in <14 days for $50 instead of $800 lawyers.

### Features We'll Build (5 core deliverables)

**Week 1: Production-Grade Testing & Security (Nov 16-23)**
- **Feature:** Comprehensive test suite with 90%+ code coverage
  - 50+ unit tests (TenantPassport: mint, reputation updates, badge verification)
  - 30+ integration tests (RentalAgreement ↔ Vault ↔ PropertyRegistry flows)
  - 20+ edge case tests (negative reputation, extreme APY, out-of-order messages)
  - Fuzz testing on reputation algorithm and vault math
  - Gas optimization analysis (target: <$2 per passport mint, <$5 per rental agreement)
- **Why it matters:** Can't launch to real users with money at stake without bulletproof contracts. Need confidence that vault math is correct (users' deposits) and reputation can't be gamed.
- **Who builds it:** @firrton (Smart contracts) + External auditor consultation
- **Success metric:** ✅ 90% test coverage, 0 critical vulnerabilities, gas report published

**Week 2: Pallet Runtime Integration & Local Testnet (Nov 24-30)**
- **Feature:** Get `pallet-roomfi-bridge` running on local Paseo runtime fork
  - Fork Paseo runtime, add pallet to `Cargo.toml` and `runtime/lib.rs`
  - Implement PolkaVM contract state reads (query TenantPassport reputation via PolkaVM)
  - Configure ISMP message construction and dispatch
  - Deploy local node with pallet, test extrinsics (sync_reputation, sync_property)
  - Document integration process for other parachains
- **Why it matters:** This is the breakthrough. No other rental platform has done cross-chain reputation via cryptographic proofs. This proves RoomFi isn't just multi-chain—it's **portable**.
- **Who builds it:** @firrton (Substrate/Rust) + Hyperbridge support channel
- **Success metric:** ✅ Pallet compiles with runtime, 10+ successful local test syncs, <60s avg latency

**Week 3: End-to-End Cross-Chain Demo (Dec 1-7)**
- **Feature:** Full cross-chain flow working on testnets
  - Deploy relayer monitoring Paseo ↔ Arbitrum Sepolia
  - Test: Mint passport on Polkadot → Pallet reads via PolkaVM → ISMP message → Arbitrum mirror update → Verify on Arbiscan
  - Test: Make rent payment → Reputation +5 → Sync to Arbitrum → Query from frontend
  - Measure: Success rate (target 95%+), latency (target <90s), cost (target <$0.50 per sync)
  - Create monitoring dashboard (pending syncs, failed messages, avg latency)
- **Why it matters:** This is our demo for investors/users. "María in Mexico pays rent, landlord in Argentina sees update in 60 seconds." Without this, we're just another multi-chain dApp.
- **Who builds it:** @firrton (Integration) + DevOps support
- **Success metric:** ✅ 20+ successful cross-chain syncs, video demo recorded, <90s latency

**Week 4: Production Frontend & Mobile UX (Dec 8-14)**
- **Feature:** Ship polished, mobile-first user interface
  - **Tenant Dashboard:** View passport (reputation, badges, payment history chart), browse properties (map view with filters), sign rental agreements (1-click flow), track deposit yield (real-time APY display)
  - **Landlord Dashboard:** Search/verify tenants (input address → see cross-chain history), list properties (GPS verification, photo uploads), view active agreements, analytics (default risk score)
  - **Cross-chain proof:** Side-by-side data comparison (Polkadot source vs Arbitrum mirror), live sync status indicator ("Syncing to Arbitrum... Done! ✓")
  - **Wallet integration:** Polkadot.js (Paseo + Moonbeam), MetaMask (Arbitrum Sepolia), network auto-detection and switching
  - **Mobile optimization:** Responsive design (Tailwind CSS), <2s page load (Next.js 14 SSR), works on iOS Safari + Android Chrome
  - **Error handling:** User-friendly messages ("Transaction failed, please try again"), loading states, empty states
- **Why it matters:** 70% of LATAM users are mobile-first. If María can't use this on her iPhone in Condesa, we fail. Needs to feel like Airbnb, not a crypto dApp.
- **Who builds it:** @firrton (Frontend) + UX feedback from beta testers
- **Success metric:** ✅ <2s page load, >95% wallet connection success, mobile-responsive all screens

**Week 5: Real Users Beta Program (Dec 15-20)**
- **Feature:** Recruit and onboard 20 real users to test end-to-end flows
  - **Cohort 1: 12 Tenants** - Crypto-native renters in CDMX/Buenos Aires/Bogotá
    - Tasks: (1) Mint TenantPassport, (2) Verify 1 KYC badge, (3) Sign test rental agreement, (4) Provide feedback
    - Incentive: $30 USDT + "Early Adopter" badge (+10 permanent reputation)
  - **Cohort 2: 5 Landlords** - Property owners open to crypto
    - Tasks: (1) List 1 property, (2) Verify 3 tenant passports, (3) Create rental agreement, (4) Provide feedback
    - Incentive: Free 3-month SaaS subscription ($150 value)
  - **Cohort 3: 3 Developers** - Substrate/Polkadot builders
    - Tasks: (1) Deploy RoomFi contracts locally, (2) Integrate pallet into test runtime, (3) Document setup pain points
    - Incentive: $100 + recognition in docs
  - **Data collection:** Completion rate (target 80%+), time to first passport (target <3 min), bugs found, NPS score (target 50+)
  - **Content creation:** 3-min demo video (María's journey Mexico → Argentina), 3 case studies, technical blog post
- **Why it matters:** We can't know if this works until non-technical people use it. Need to find bugs before mainnet. Need testimonials for investors.
- **Who builds it:** Full team (recruitment, onboarding, support, content)
- **Success metric:** ✅ 20 users recruited, 16+ complete all tasks (80%), NPS >50, 0 critical bugs

---

### Team Breakdown

**@firrton - Full-Stack Builder** | 40 hrs/week
- Owns: Smart contract testing (Week 1), Pallet runtime integration (Week 2), Cross-chain testing (Week 3), Frontend polish (Week 4), Beta program execution (Week 5)
- Expertise: Solidity, Substrate/Rust, React/Next.js, Hyperbridge ISMP

**External Support (Mentors/Contractors):**
- **Security Auditor** (Week 1, 10 hrs): Preliminary audit, security checklist review
- **DevOps Engineer** (Week 2-3, 15 hrs): Relayer setup, monitoring dashboard, testnet infrastructure
- **UX Designer** (Week 4, 8 hrs): Mobile UX review, component design system

---

### Mentoring & Expertise We Need

**Areas where we need support:**
1. **PolkaVM contract integration best practices** - How to efficiently read EVM contract storage from Substrate pallets
2. **Hyperbridge relayer optimization** - Configuration for production-level reliability (99%+ uptime)
3. **Acala DeFi integration** - Technical contact for deploying YieldStrategy on Acala testnet
4. **Security audit connections** - Introduction to Code4rena, OpenZeppelin, or Trail of Bits for Milestone 3 audit
5. **Legal framework validation** - Lawyer familiar with blockchain + rental law in LATAM to review smart contract enforceability claims

**Specific expertise we're looking for:**
- **Substrate pallet developer** with PolkaVM experience (2-3 mentoring sessions)
- **Hyperbridge core contributor** for relayer setup guidance (1-2 sessions)
- **UX designer** with Web3 onboarding experience (review our flows, suggest improvements)
- **Growth advisor** for LATAM crypto community (help us find first 100 users in CDMX/Buenos Aires)

---

## 🎯 WHAT HAPPENS AFTER

**When M2 is done, we plan to...**
- **Launch mainnet MVP (Week 6-8)** - Deploy to Polkadot AssetHub, Moonbeam, and Arbitrum One with real USDT deposits
- **Recruit 500 TenantPassports** - Partner with Polkadot LATAM communities, digital nomad groups, crypto Twitter
- **Onboard 50 landlords** - Reach out to property managers in target cities (CDMX, Buenos Aires, Bogotá) with pitch: "Reduce defaults from 12% to 3% with on-chain verification"
- **Apply for Polkadot Treasury Grant** - Request $35K for external security audit (Code4rena) and 6-month runway
- **Content blitz** - Publish technical deep-dive blog post on Polkadot Forum, demo video on YouTube (target 10K+ views), case studies on Medium/Mirror
- **Iterate based on beta feedback** - Fix all medium/low priority bugs, add requested features (e.g., multi-sig agreements, payment plans)

**And 6 months out we see our project achieve:**
- **$500K in deposits under management** (250 rental agreements × $2K avg deposit)
- **2,500 TenantPassports minted** (capturing 0.4% of 585K crypto-native LATAM renters)
- **150 landlords onboarded** across 5 cities
- **50% non-crypto-native users** via fiat onramp integration (Moonpay/Transak)
- **Expansion to 2 more EVM chains** (Base, Optimism) via Hyperbridge
- **$80K annual recurring revenue** from vault management fees (4% on $500K at 50% utilization = $10K/quarter)
- **Partnership with traditional real estate platform** (Vivanuncios, ZonaProp) for distribution
- **Legal enforceability case study** - At least 1 real rental dispute resolved using RoomFi smart contract as evidence in court
- **First-ever portable rental reputation** recognized across 3+ chains (Polkadot, Moonbeam, Arbitrum, Base)

---

## 💪 WHY WE'LL SUCCEED

**What makes RoomFi different:**
1. **We're solving a $1.26B problem** (12M people move between LATAM countries yearly, $2,100 avg deposit)
2. **We're not vaporware** - 11 contracts live, pallet written, frontend functional, legal framework validated
3. **We're technically ambitious** - First rental platform to use cryptographic state proofs for cross-chain reputation (Hyperbridge ISMP)
4. **We have real users in mind** - María exists. 585K crypto-native renters in LATAM need this. We're building for them, not for hackathon judges.
5. **We're shipping, not pitching** - In 30 days: production tests, cross-chain demo, real users, video proof. No slides.

**Our unfair advantages:**
- Legal framework already validated (smart contracts enforceable in Mexico, Colombia, Argentina)
- Hyperbridge integration working (cross-chain sync proven)
- Deep LATAM market knowledge (target cities, user personas, pricing)
- Willingness to grind (40 hrs/week for 5 weeks straight)

---

## 📊 SUCCESS METRICS (30-Day Checkpoint)

| Metric | Target | How We Measure |
|--------|--------|----------------|
| **Test Coverage** | 90%+ | Foundry coverage report |
| **Security Vulnerabilities** | 0 critical, <5 medium | Auditor checklist + Slither analysis |
| **Pallet Integration** | Compiles with Paseo runtime | Local node runs with pallet |
| **Cross-Chain Syncs** | 20+ successful, 95%+ success rate | ISMP message logs |
| **Cross-Chain Latency** | <90s average | Relayer analytics |
| **Frontend Performance** | <2s page load | Lighthouse score |
| **Beta Users** | 20 recruited, 16+ complete (80%) | User analytics dashboard |
| **User Satisfaction** | NPS >50 | Post-beta survey |
| **Critical Bugs Found** | 0 | Bug tracker (GitHub Issues) |
| **Demo Video Views** | 1,000+ | YouTube analytics |
| **Technical Blog Engagement** | 200+ reads, 50+ upvotes | Medium/Polkadot Forum stats |

---

## 💰 BUDGET (30 Days)

| Category | Details | Cost |
|----------|---------|------|
| **Development** | @firrton × 160 hrs @ $50/hr | $8,000 |
| **Security Audit** | Preliminary review (pre-mainnet) | $2,000 |
| **DevOps** | Relayer setup, RPC nodes, hosting | $800 |
| **Design** | UX review, component design | $1,000 |
| **Beta Incentives** | 20 users × $30-100 avg | $1,200 |
| **Content Creation** | Video editing, blog writing | $500 |
| **Contingency** | 10% buffer | $1,350 |
| **Total** | - | **$14,850** |

**Funding sources:**
- Sub0 Hackathon prize (expected): $5,000-$10,000
- Personal investment: $5,000
- Polkadot Treasury micro-grant application: $5,000

---

## 🔥 THE STAKES

If we hit all 11 success metrics in 30 days, we're **production-ready**.

That means:
- Contracts secure enough for real money ($500K deposits in 6 months)
- Cross-chain sync reliable enough for real landlords (95%+ success rate)
- UX smooth enough for non-technical users (<3 min to passport)
- Market validation from real users (NPS >50)

If we miss, we pivot or pause before mainnet. **No launching with security risks or bad UX.**

But we won't miss. We have:
- Working code (7,421 lines already written)
- Clear plan (5 features, 5 weeks, 1 builder + contractors)
- Real problem (María exists, 12M people need this)
- Hunger (we're building this whether we win or not)

**30 days. Let's ship.**

---

*"The goal is not to control people through technology but to empower them to use it as a tool for independent thought and self-sovereign living."* — **Gavin Wood**

María shouldn't need a lawyer to rent in Buenos Aires. Her reputation should follow her. RoomFi makes that real.

**Let's build.**
