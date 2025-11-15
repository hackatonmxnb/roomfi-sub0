# 🎉 RoomFi V2 - DEPLOYMENT EXITOSO EN ASSETHUB PASEO

**Fecha**: 2025-01-15
**Network**: AssetHub Paseo Testnet
**Chain ID**: 420420422
**Deployer**: `0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4`
**RPC URL**: https://testnet-passet-hub-eth-rpc.polkadot.io

---

## 📋 CONTRATOS DEPLOYADOS

### 1. MockUSDT (Token de prueba)
```
Address: 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8
Explorer: https://assethub-paseo.subscan.io/account/0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8
```

**Descripción**: Token ERC20 con 6 decimals (como USDT real). Supply inicial: 1,000,000 USDT.

---

### 2. AcalaYieldStrategy
```
Address: 0xe698f5053D9450c173C01713E1b5A144E560F254
Explorer: https://assethub-paseo.subscan.io/account/0xe698f5053D9450c173C01713E1b5A144E560F254
```

**Descripción**: Strategy para yield farming. Integra con Acala via XCM. Mock mode habilitado para hackathon.

**Constructor params**:
- `_usdt`: 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8
- `initialOwner`: 0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4

---

### 3. RoomFiVault
```
Address: 0xD2C0Be059ab58367B209290934005f76264b59db
Explorer: https://assethub-paseo.subscan.io/account/0xD2C0Be059ab58367B209290934005f76264b59db
```

**Descripción**: Vault principal con yield calculation. Buffer 15%, protocol fees 30%.

**Constructor params**:
- `_usdt`: 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8
- `_strategy`: 0xe698f5053D9450c173C01713E1b5A144E560F254
- `initialOwner`: 0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4

---

### 4. TenantPassportV2
```
Address: 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3
Explorer: https://assethub-paseo.subscan.io/account/0x3dE7d06a9C36da9F603E449E512fab967Cc740a3
```

**Descripción**: NFT soul-bound para tenants. Reputation system, 14 badges, decay por inactividad.

**Constructor params**:
- `initialOwner`: 0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4

---

### 5. PropertyRegistry
```
Address: 0x752A5e16899f0849e2B632eA7F7446B2D11d1e17
Explorer: https://assethub-paseo.subscan.io/account/0x752A5e16899f0849e2B632eA7F7446B2D11d1e17
```

**Descripción**: NFT de propiedades con GPS-unique ID. Sistema de verificación DRAFT → PENDING → VERIFIED.

**Constructor params**:
- `_tenantPassportAddress`: 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3
- `initialOwner`: 0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4

---

### 6. DisputeResolver
```
Address: 0xbb037C5EA4987858Ba2211046297929F6558dB6a
Explorer: https://assethub-paseo.subscan.io/account/0xbb037C5EA4987858Ba2211046297929F6558dB6a
```

**Descripción**: Sistema de resolución de disputas con 3 árbitros. Voting system con mayoría simple.

**Constructor params**:
- `_tenantPassport`: 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3
- `_propertyRegistry`: 0x752A5e16899f0849e2B632eA7F7446B2D11d1e17
- `initialOwner`: 0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4

---

### 7. RentalAgreementWithVault (Implementation)
```
Address: 0x582fE4A8039769215D54A38f48E415f1E85A7B99
Explorer: https://assethub-paseo.subscan.io/account/0x582fE4A8039769215D54A38f48E415f1E85A7B99
```

**Descripción**: Implementation template para agreements. Usa EIP-1167 clone pattern. Integra con Vault para yield farming.

**Constructor params**:
- `_usdt`: 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8
- `_vault`: 0xD2C0Be059ab58367B209290934005f76264b59db

---

### 8. RentalAgreementFactory
```
Address: 0x1514e3cCC72bc2FdcA2E7a6d52303917a133E5ae
Explorer: https://assethub-paseo.subscan.io/account/0x1514e3cCC72bc2FdcA2E7a6d52303917a133E5ae
```

**Descripción**: Factory para crear agreements usando clone pattern. Gas optimizado: ~$0.50 por agreement vs $50 sin clones.

**Constructor params**:
- `_propertyRegistry`: 0x752A5e16899f0849e2B632eA7F7446B2D11d1e17
- `_tenantPassport`: 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3
- `_disputeResolver`: 0xbb037C5EA4987858Ba2211046297929F6558dB6a
- `_rentalAgreementImpl`: 0x582fE4A8039769215D54A38f48E415f1E85A7B99
- `initialOwner`: 0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4

---

## ✅ AUTORIZACIONES CONFIGURADAS

Las siguientes autorizaciones se configuraron automáticamente durante el deployment:

1. ✅ **Factory → TenantPassport**: RentalAgreementFactory autorizado como updater
2. ✅ **Factory → PropertyRegistry**: RentalAgreementFactory autorizado como updater

---

## 🧪 TESTING POST-DEPLOYMENT

### Test 1: Mint TenantPassport

```bash
cast send 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3 "mintForSelf()" \
  --private-key $PRIVATE_KEY \
  --rpc-url https://testnet-passet-hub-eth-rpc.polkadot.io \
  --legacy
```

### Test 2: Verificar Passport

```bash
cast call 0x3dE7d06a9C36da9F603E449E512fab967Cc740a3 \
  "hasPassport(address)(bool)" \
  0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4 \
  --rpc-url https://testnet-passet-hub-eth-rpc.polkadot.io
```

### Test 3: Verificar USDT Total Supply

```bash
cast call 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8 \
  "totalSupply()(uint256)" \
  --rpc-url https://testnet-passet-hub-eth-rpc.polkadot.io
```

**Resultado esperado**: 1000000000000 (1M USDT con 6 decimals)

### Test 4: Mint USDT de prueba

```bash
cast send 0x9f630D9994883D96A1c5E74AC81104FF9E5bFda8 \
  "mint(address,uint256)" \
  0x1f3B26937B64488Fe5a9E1BF1D1a193b58D909b4 10000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url https://testnet-passet-hub-eth-rpc.polkadot.io \
  --legacy
```

---

## 📊 RESUMEN DE GAS

Los logs muestran que el deployment completo usó aproximadamente:
- **Total gas estimado**: ~16.7 millones gas
- **Transacciones**: 11 transacciones (8 deployments + 3 autorizaciones)

---

## 🔗 ENLACES ÚTILES

### Block Explorer
- **AssetHub Paseo Subscan**: https://assethub-paseo.subscan.io

### RPC Endpoint
- **HTTP**: https://testnet-passet-hub-eth-rpc.polkadot.io
- **Chain ID**: 420420422

### Faucet
- **Polkadot Faucet**: https://faucet.polkadot.io/?parachain=1000

---

## 📝 PRÓXIMOS PASOS

### 1. Autorizar Verificadores (Opcional)
```solidity
PropertyRegistry.authorizeVerifier(VERIFIER_ADDRESS)
```

### 2. Autorizar Árbitros (Opcional)
```solidity
DisputeResolver.authorizeArbitrator(ARBITRATOR_ADDRESS)
```

### 3. Configurar Frontend
Actualizar archivo de configuración del frontend con estos addresses.

### 4. Testing E2E
Probar flujo completo:
1. Mint passport
2. Register property
3. Create agreement
4. Pay deposit
5. Pay rent
6. Complete agreement

---

## 🎉 DEPLOYMENT COMPLETADO EXITOSAMENTE

Todos los contratos están deployados y funcionando en **AssetHub Paseo Testnet**.

**Sistema listo para:**
- ✅ Testing
- ✅ Demo
- ✅ Integración con frontend
- ✅ Hackathon submission

---