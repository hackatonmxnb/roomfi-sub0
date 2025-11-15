# Análisis: Integración PolkaVM en pallet-roomfi-bridge

**Autor**: RoomFi Team - Firrton
**Fecha**: 2025-01-11
**Estado**: Evaluación de opciones

---

## Contexto

El **pallet-roomfi-bridge** necesita leer datos de reputación del contrato **TenantPassportV2.sol** deployado en **Paseo PolkaVM** para sincronizarlos cross-chain via Hyperbridge ISMP.

**Desafío**: ¿Cómo leer storage de contratos Solidity en PolkaVM desde un pallet Substrate?

---

## 🎯 Opciones Evaluadas

### ✅ **OPCIÓN 1: Storage Access Directo via PolkaVM API** (RECOMENDADO)

**Descripción**:
Usar APIs de PolkaVM para leer el storage del contrato directamente desde el pallet.

**Implementación**:
```rust
// En pallet-roomfi-bridge/src/lib.rs

use pallet_revive::ContractInfoOf; // PolkaVM contract interface

impl<T: Config> Pallet<T> {
    fn read_tenant_reputation(
        tenant: H160,
        passport_address: H160,
    ) -> Result<TenantReputationData, DispatchError> {

        // 1. Obtener contract info de PolkaVM
        let contract_info = ContractInfoOf::<T>::get(&passport_address)
            .ok_or(Error::<T>::TenantPassportNotConfigured)?;

        // 2. Construir storage key para tenantInfo[tokenId]
        let token_id = Self::derive_token_id(tenant);
        let storage_key = Self::build_storage_key(
            b"tenantInfo",
            token_id
        );

        // 3. Leer del storage del contrato
        let raw_data = pallet_revive::Pallet::<T>::read_contract_storage(
            passport_address,
            storage_key,
        )?;

        // 4. Decodificar según ABI de Solidity
        let tenant_info = Self::decode_tenant_info(raw_data)?;

        // 5. Mapear a TenantReputationData
        Ok(TenantReputationData {
            tenant_address: tenant,
            reputation: tenant_info.reputation,
            payments_made: tenant_info.payments_made,
            disputes_count: tenant_info.disputes_count,
            // ... etc
        })
    }

    fn build_storage_key(mapping_name: &[u8], key: u256) -> Vec<u8> {
        // Solidity storage layout para mappings:
        // keccak256(abi.encode(key, slot))
        let slot = Self::get_mapping_slot(mapping_name); // slot 0 para tenantInfo

        // Encodear según reglas de Solidity
        let mut encoded = Vec::new();
        encoded.extend_from_slice(&key.to_be_bytes());
        encoded.extend_from_slice(&slot.to_be_bytes());

        sp_io::hashing::keccak_256(&encoded).to_vec()
    }

    fn decode_tenant_info(raw: Vec<u8>) -> Result<TenantInfo, DispatchError> {
        // Decodificar según struct layout de Solidity
        // TenantInfo tiene ~12 campos uint32/uint256

        ensure!(raw.len() >= 384, Error::<T>::InvalidReputationData); // 12 * 32 bytes

        // Extraer campos (cada uno en slot de 32 bytes)
        let reputation = u32::from_be_bytes(
            raw[28..32].try_into().unwrap()
        );
        let payments_made = u32::from_be_bytes(
            raw[60..64].try_into().unwrap()
        );
        // ... etc

        Ok(TenantInfo {
            reputation,
            payments_made,
            // ...
        })
    }
}
```

**Ventajas**:
- ✅ No requiere cambios en contratos
- ✅ Lectura directa y confiable
- ✅ No depende de servicios externos
- ✅ Gas-free (lectura desde runtime)

**Desventajas**:
- ❌ Requiere conocer storage layout exacto de Solidity
- ❌ Frágil si cambia estructura del contrato
- ❌ Necesita mantenerse sincronizado con ABI

**Complejidad**: Media-Alta
**Confiabilidad**: Alta
**Dependencias**: pallet-revive (PolkaVM)

---

### 🔄 **OPCIÓN 2: Event-Driven Sync (Escuchar eventos del contrato)**

**Descripción**:
El contrato emite eventos cuando cambia reputación, y el pallet los escucha.

**Implementación**:
```rust
// Modificar TenantPassportV2.sol para emitir más eventos
event ReputationChanged(
    address indexed tenant,
    uint32 newReputation,
    uint32 paymentsMade,
    uint32 disputesCount,
    uint256 totalRentPaid
);

// En el pallet, escuchar eventos
impl<T: Config> Pallet<T> {
    fn on_finalize(n: BlockNumberFor<T>) {
        // Leer logs de PolkaVM del bloque
        let logs = pallet_revive::Pallet::<T>::contract_events(n);

        for log in logs {
            if log.address == TenantPassportAddress::<T>::get() {
                // Parsear evento ReputationChanged
                if Self::is_reputation_event(&log) {
                    let data = Self::decode_reputation_event(log.data);

                    // Trigger sync cross-chain
                    Self::trigger_cross_chain_sync(data)?;
                }
            }
        }
    }
}
```

**Ventajas**:
- ✅ Push-based (más eficiente que polling)
- ✅ Solo sincroniza cuando hay cambios reales
- ✅ Más fácil de mantener que storage reads

**Desventajas**:
- ❌ Requiere modificar contratos para emitir eventos completos
- ❌ Depende de indexing de eventos
- ❌ No puede hacer queries on-demand

**Complejidad**: Media
**Confiabilidad**: Alta
**Dependencias**: Event indexing de PolkaVM

---

### 🌐 **OPCIÓN 3: Off-Chain Worker + Oracle**

**Descripción**:
Usar un Off-Chain Worker (OCW) que lee datos del contrato y los envía al pallet.

**Implementación**:
```rust
// En pallet-roomfi-bridge/src/lib.rs

#[pallet::hooks]
impl<T: Config> Hooks<BlockNumberFor<T>> for Pallet<T> {
    fn offchain_worker(block_number: BlockNumberFor<T>) {
        // OCW se ejecuta cada N bloques
        if block_number % 10u32.into() != 0u32.into() {
            return;
        }

        // Leer datos del contrato via RPC
        let passport_address = TenantPassportAddress::<T>::get()
            .expect("TenantPassport configured");

        // Obtener tenants que necesitan sync
        let pending_syncs = PendingSyncs::<T>::get();

        for tenant in pending_syncs {
            // Hacer call a getTenantInfo() via eth_call
            let result = Self::ocw_read_tenant_reputation(
                passport_address,
                tenant
            );

            if let Ok(data) = result {
                // Enviar transacción signed/unsigned al pallet
                Self::ocw_submit_sync_data(data);
            }
        }
    }
}

impl<T: Config> Pallet<T> {
    fn ocw_read_tenant_reputation(
        contract: H160,
        tenant: H160,
    ) -> Result<TenantReputationData, Error> {
        // Construir eth_call para getTenantInfo(address)
        let call_data = Self::encode_function_call(
            "getTenantInfo(address)",
            tenant
        );

        // Hacer HTTP request a PolkaVM JSON-RPC
        let response = sp_runtime::offchain::http_request_start(
            http::Method::Post,
            "http://localhost:9944", // PolkaVM RPC
            &[]
        )?;

        // Parsear response
        let result = Self::decode_tenant_info_response(response)?;

        Ok(result)
    }
}
```

**Ventajas**:
- ✅ No modifica contratos
- ✅ Flexible y extensible
- ✅ Puede agregar validación adicional

**Desventajas**:
- ❌ Requiere infraestructura off-chain
- ❌ Posible centralización (quién corre el OCW?)
- ❌ Mayor complejidad operativa

**Complejidad**: Alta
**Confiabilidad**: Media
**Dependencias**: Off-chain workers, RPC endpoints

---

### 📊 **OPCIÓN 4: Indexer Externo + On-Chain Oracle**

**Descripción**:
Un servicio externo (indexer) monitorea el contrato y pushea datos al pallet.

**Implementación**:
```typescript
// Indexer (TypeScript/Node.js)
import { ApiPromise, WsProvider } from '@polkadot/api';
import { ethers } from 'ethers';

class RoomFiBridge {
    async watchTenantPassport() {
        const tenantPassport = new ethers.Contract(
            TENANT_PASSPORT_ADDRESS,
            TENANT_PASSPORT_ABI,
            provider
        );

        // Escuchar eventos
        tenantPassport.on('ReputationUpdated', async (tokenId, oldRep, newRep) => {
            const tenant = ethers.utils.getAddress(tokenId);

            // Leer datos completos
            const info = await tenantPassport.getTenantInfo(tokenId);

            // Enviar al pallet via extrinsic
            await this.submitToPallet({
                tenant,
                reputation: info.reputation,
                paymentsMade: info.paymentsMade,
                // ...
            });
        });
    }

    async submitToPallet(data: TenantData) {
        const api = await ApiPromise.create({
            provider: new WsProvider('ws://paseo-node:9944')
        });

        // Enviar extrinsic al pallet
        await api.tx.roomfiBridge
            .oracleSubmitTenantData(data)
            .signAndSend(oracleSigner);
    }
}
```

**Ventajas**:
- ✅ Muy flexible
- ✅ Puede agregar lógica compleja off-chain
- ✅ Fácil de desarrollar y testear

**Desventajas**:
- ❌ Centralización (confianza en el indexer)
- ❌ Requiere infraestructura externa
- ❌ Latencia adicional

**Complejidad**: Alta
**Confiabilidad**: Media-Baja (depende del uptime del indexer)
**Dependencias**: Node.js service, base de datos

---

### 🚧 **OPCIÓN 5: Mock Data + Implementación Futura**

**Descripción**:
Por ahora, usar datos mock en el pallet, y implementar la integración real cuando PolkaVM madure.

**Implementación**:
```rust
impl<T: Config> Pallet<T> {
    fn read_tenant_reputation(
        tenant: H160,
        _passport_address: H160,
    ) -> Result<TenantReputationData, DispatchError> {
        // TODO: Implementar lectura real de PolkaVM
        // Por ahora, retornar mock data

        Ok(TenantReputationData {
            tenant_address: tenant,
            reputation: 85,
            payments_made: 12,
            disputes_count: 0,
            properties_rented: 2,
            total_rent_paid: 24_000_000_000_000_000_000u128,
            last_updated: Self::current_timestamp(),
        })
    }
}
```

**Ventajas**:
- ✅ Permite continuar desarrollo sin bloqueo
- ✅ Muy simple de implementar
- ✅ No requiere infraestructura adicional

**Desventajas**:
- ❌ No funcional en producción
- ❌ Requiere trabajo adicional después

**Complejidad**: Muy Baja
**Confiabilidad**: N/A (solo para desarrollo)
**Dependencias**: Ninguna

---

## 📋 Matriz de Comparación

| Opción | Complejidad | Confiabilidad | Descentralización | Producción Ready | Esfuerzo |
|--------|-------------|---------------|-------------------|------------------|----------|
| **1. Storage Directo** | Media-Alta | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Sí | Alto |
| **2. Event-Driven** | Media | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Sí | Medio |
| **3. Off-Chain Worker** | Alta | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⚠️ Con validación | Alto |
| **4. Indexer Externo** | Alta | ⭐⭐ | ⭐⭐ | ⚠️ Centralizado | Muy Alto |
| **5. Mock Data** | Muy Baja | N/A | N/A | ❌ No | Muy Bajo |

---

## 🎯 Recomendación Final

### Para Hackathon (corto plazo):

**Usar OPCIÓN 5 (Mock Data) + OPCIÓN 2 (Event-Driven) básica**

**Razón**:
- Permite demostrar el flujo completo sin bloquearse
- Event-driven es relativamente fácil de implementar
- Puedes mostrar el concepto funcionando end-to-end

**Implementación sugerida**:
```rust
// Fase 1: Mock data por defecto
fn read_tenant_reputation(...) -> Result<TenantReputationData> {
    #[cfg(feature = "mock-polkavm")]
    {
        // Retornar mock data
        Ok(TenantReputationData { ... })
    }

    #[cfg(not(feature = "mock-polkavm"))]
    {
        // Implementación real con eventos
        Self::read_from_polkavm_events(tenant)
    }
}
```

---

### Para Producción (largo plazo):

**Usar OPCIÓN 1 (Storage Directo) + OPCIÓN 2 (Event-Driven) como fallback**

**Razón**:
- Storage directo es la solución más confiable y descentralizada
- Event-driven como redundancia y para triggers automáticos
- No depende de infraestructura externa

**Roadmap de implementación**:

1. **Q1 2025**: Implementar Event-Driven básico
   - Modificar contratos para emitir eventos completos
   - Pallet escucha eventos de PolkaVM

2. **Q2 2025**: Implementar Storage Access Directo
   - Integrar con pallet-revive APIs
   - Implementar decodificadores de storage layout
   - Testing exhaustivo

3. **Q3 2025**: Optimizaciones
   - Caching de datos leídos
   - Batch reads para eficiencia
   - Monitoring y alertas

---

## 🔧 Próximos Pasos Inmediatos

1. **Modificar TenantPassportV2.sol** para emitir eventos más completos:
```solidity
event TenantReputationSnapshot(
    address indexed tenant,
    uint32 reputation,
    uint32 paymentsMade,
    uint32 paymentsMissed,
    uint32 propertiesRented,
    uint32 disputesCount,
    uint256 totalRentPaid,
    uint256 timestamp
);

// Emitir en updateTenantInfo()
emit TenantReputationSnapshot(
    tenant,
    info.reputation,
    info.paymentsMade,
    info.paymentsMissed,
    info.propertiesRented,
    info.disputesCount,
    info.totalRentPaid,
    block.timestamp
);
```

2. **Implementar listener básico en el pallet** que capture estos eventos

3. **Para el hackathon**, usar feature flag con mock data si no da tiempo la integración completa

---

## 📚 Referencias

- **Polkadot PolkaVM Docs**: https://wiki.polkadot.network/docs/build-smart-contracts
- **pallet-revive (PolkaVM runtime)**: https://github.com/paritytech/polkadot-sdk/tree/master/substrate/frame/revive
- **Solidity Storage Layout**: https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
- **Substrate Off-Chain Workers**: https://docs.substrate.io/learn/offchain-operations/

---

**Conclusión**: Para avanzar rápido en el hackathon, usa mock data con feature flags. Para producción, implementa Storage Directo + Event-Driven como solución robusta y descentralizada.
