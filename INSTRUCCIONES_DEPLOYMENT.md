# 🚀 Instrucciones de Deployment - RoomFi V2

## 📋 Estado Actual

**Frontend:** ✅ COMPLETO y listo  
**Contratos:** ❌ Pendientes de deployment en Paseo/Arbitrum  
**Modo Actual:** 🎭 **MOCK MODE ACTIVADO** (datos simulados)

---

## 🎯 Para Deployment en Paseo

### Requisitos Previos
- ✅ Fondos PAS en testnet (~1-2 PAS para gas)
- ✅ Foundry instalado
- ✅ Private key de wallet con fondos

### Paso 1: Instalar Foundry (si no está instalado)
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Paso 2: Configurar Private Key
```bash
cd Foundry
echo 'PRIVATE_KEY=tu_private_key_aqui' > .env
```

⚠️ **IMPORTANTE:** Nunca subir el archivo `.env` a Git

### Paso 3: Desplegar Contratos en Paseo
```bash
forge script script/DeployRoomFiV2.s.sol \
  --rpc-url https://testnet-passet-hub-eth-rpc.polkadot.io \
  --broadcast \
  --legacy \
  -vvvv
```

**Tiempo estimado:** 5-10 minutos

### Paso 4: Guardar Addresses Desplegadas
El script generará un archivo `deployment-addresses.json` con:
- `TenantPassportV2`
- `PropertyRegistry`
- `DisputeResolver`
- `RentalAgreementFactory`
- `RoomFiVault`
- `AcalaYieldStrategy`
- `MockUSDT`

**Copia este archivo y guárdalo en un lugar seguro.**

---

## 🔧 Actualizar Frontend con Addresses

### Opción A: Actualización Manual

Edita `/src/web3/config.ts`:

```typescript
export const CONTRACTS = {
  paseo: {
    TENANT_PASSPORT_ADDRESS: "0xNUEVA_ADDRESS_AQUI",
    PROPERTY_REGISTRY_ADDRESS: "0xNUEVA_ADDRESS_AQUI",
    RENTAL_FACTORY_ADDRESS: "0xNUEVA_ADDRESS_AQUI",
    DISPUTE_RESOLVER_ADDRESS: "0xNUEVA_ADDRESS_AQUI",
    VAULT_ADDRESS: "0xNUEVA_ADDRESS_AQUI",
    MXNBT_ADDRESS: "0xNUEVA_ADDRESS_USDT_AQUI",
  },
  // ...
};
```

### Opción B: Script Automático

```bash
# Desde la raíz del proyecto
node scripts/updateAddresses.js deployment-addresses.json
```

---

## 🎭 Desactivar Modo Mock

Una vez desplegados los contratos y actualizadas las addresses:

En `/src/web3/mockData.ts`, cambia:
```typescript
export const MOCK_MODE = true;  // ← Cambiar a false
```

A:
```typescript
export const MOCK_MODE = false;  // ← Usar contratos reales
```

---

## ✅ Verificar que Todo Funciona

### 1. Verificar Deployment en Explorer
```
https://assethub-paseo.subscan.io/account/TU_ADDRESS_AQUI
```
- Debe mostrar "Contract" como tipo
- Debe tener transacciones
- Nonce > 0

### 2. Verificar via RPC
```bash
curl -X POST https://testnet-passet-hub-eth-rpc.polkadot.io \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getCode","params":["TU_ADDRESS_AQUI", "latest"],"id":1}'
```
- Si `"result":"0x..."` (código largo) → ✅ Contrato desplegado
- Si `"result":"0x"` → ❌ No hay contrato

### 3. Probar Frontend
```bash
cd /Users/jazz/projects/MXNB/roomfisub0
npm start
```

1. Conectar Subwallet en Paseo
2. Clic en "Ver mi NFT"
3. Si no hay passport, se minteará automáticamente
4. Verificar que el modal muestra datos reales (no mock)

---

## 🚨 Troubleshooting

### Error: "missing revert data" o "could not decode result"
**Causa:** La address del contrato está vacía o incorrecta  
**Solución:** Verificar que el contrato esté desplegado y la address sea correcta

### Error: "insufficient funds"
**Causa:** No hay fondos PAS para gas  
**Solución:** Obtener más PAS del faucet

### Error: "nonce too low"
**Causa:** La transacción ya fue procesada  
**Solución:** Reintentar con `--force` o esperar 1 minuto

### Error: Forge no encontrado
**Causa:** Foundry no instalado o no en PATH  
**Solución:** 
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc  # o ~/.zshrc
foundryup
```

---

## 📊 Alternativa: Deployment en Arbitrum Sepolia

Si no consigues PAS, puedes desplegar en Arbitrum Sepolia:

### 1. Obtener ETH Sepolia
Faucets:
- https://faucet.quicknode.com/arbitrum/sepolia
- https://www.alchemy.com/faucets/arbitrum-sepolia

### 2. Desplegar
```bash
forge script script/DeployRoomFiV2.s.sol \
  --rpc-url https://sepolia-rollup.arbitrum.io/rpc \
  --broadcast \
  --legacy
```

### 3. Actualizar Config
Actualiza `CONTRACTS.arbitrum` en `/src/web3/config.ts` con las nuevas addresses

### 4. Cambiar Red por Defecto
En `/src/App.tsx` línea 234:
```typescript
const [activeNetwork, setActiveNetwork] = useState<EvmNetwork>('arbitrum');
```

---

## 📝 Checklist Final

Antes de considerar el deployment completo:

- [ ] Contratos desplegados exitosamente
- [ ] Addresses guardadas en `deployment-addresses.json`
- [ ] `src/web3/config.ts` actualizado con nuevas addresses
- [ ] `MOCK_MODE = false` en `src/web3/mockData.ts`
- [ ] Frontend testeado y funcional
- [ ] Mint de Tenant Passport funciona
- [ ] Balance de tokens se muestra correctamente
- [ ] Explorer de Paseo muestra los contratos

---

## 🎯 Siguiente Fase

Una vez completado el deployment:

1. ✅ TenantPassportV2 funcional
2. 🔄 Implementar PropertyRegistry UI
3. 🔄 Implementar RentalAgreement UI
4. 🔄 Implementar DisputeResolver UI
5. 🎨 Pulir UI/UX

---

## 📞 Contacto

Si hay dudas sobre el deployment o configuración del frontend, contactar a Jazz (frontend dev).

**¡Buena suerte con el deployment! 🚀**
