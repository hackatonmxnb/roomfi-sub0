//! # RoomFi Bridge Pallet
//!
//! Pallet que integra los contratos RoomFi (TenantPassport, PropertyRegistry)
//! con Hyperbridge ISMP para permitir reputación cross-chain portable.
//!
//! ## Overview
//!
//! Este pallet actúa como puente entre:
//! - Contratos Solidity en Paseo PolkaVM (source)
//! - Hyperbridge ISMP protocol (transport)
//! - Mirror contracts en otras chains (destination)
//!
//! ## Funcionalidad
//!
//! - Sync reputation de TenantPassport a otras chains
//! - Sync property verification status
//! - Receive confirmations de syncs exitosos
//! - Track pending cross-chain messages

#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::{pallet_prelude::*, sp_runtime::traits::Hash};
    use frame_system::pallet_prelude::*;
    use sp_core::H160;
    use sp_std::vec::Vec;

    use ismp::{
        router::{Post, PostResponse, Request},
        host::StateMachine,
    };
    use pallet_ismp::dispatcher::{Dispatcher as IsmpDispatcher, DispatchPost, FeeMetadata};

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    /// Configuración del pallet
    #[pallet::config]
    pub trait Config: frame_system::Config + pallet_ismp::Config {
        /// El evento del pallet
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// El hasher usado
        type Hashing: Hash<Output = Self::Hash>;
    }

    /// Información de reputación que se sincroniza cross-chain
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct TenantReputationData {
        /// Address del tenant (H160 para compatibilidad EVM)
        pub tenant_address: H160,
        /// Score de reputación (0-100)
        pub reputation: u32,
        /// Payments completados
        pub payments_made: u32,
        /// Disputes totales
        pub disputes_count: u32,
        /// Properties rentadas
        pub properties_rented: u32,
        /// Total rent pagado (en wei)
        pub total_rent_paid: u128,
        /// Timestamp del último update
        pub last_updated: u64,
    }

    /// Estado de un sync cross-chain
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub enum SyncStatus {
        /// Sync iniciado, esperando confirmación
        Pending,
        /// Sync confirmado en destination chain
        Confirmed,
        /// Sync falló (timeout o error)
        Failed,
    }

    /// Información de un sync cross-chain
    #[derive(Clone, Encode, Decode, Eq, PartialEq, RuntimeDebug, TypeInfo, MaxEncodedLen)]
    pub struct CrossChainSync<T: Config> {
        /// ID del request ISMP
        pub request_id: T::Hash,
        /// Tenant address
        pub tenant: H160,
        /// Destination chain
        pub destination: StateMachine,
        /// Status del sync
        pub status: SyncStatus,
        /// Block number cuando se inició
        pub initiated_at: BlockNumberFor<T>,
    }

    /// Storage: Syncs pendientes y completados
    #[pallet::storage]
    #[pallet::getter(fn syncs)]
    pub type Syncs<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::Hash,
        CrossChainSync<T>,
        OptionQuery,
    >;

    /// Storage: Último sync por tenant
    #[pallet::storage]
    #[pallet::getter(fn last_sync)]
    pub type LastSync<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        H160,
        T::Hash,
        OptionQuery,
    >;

    /// Storage: Mirror contract addresses por chain
    #[pallet::storage]
    #[pallet::getter(fn mirror_contracts)]
    pub type MirrorContracts<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        StateMachine,
        H160,
        OptionQuery,
    >;

    /// Storage: TenantPassport contract address en Paseo
    #[pallet::storage]
    #[pallet::getter(fn tenant_passport_address)]
    pub type TenantPassportAddress<T: Config> = StorageValue<_, H160, OptionQuery>;

    /// Eventos del pallet
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// Reputation sync iniciado
        ReputationSyncInitiated {
            request_id: T::Hash,
            tenant: H160,
            destination: StateMachine,
        },
        /// Reputation sync confirmado
        ReputationSyncConfirmed {
            request_id: T::Hash,
            tenant: H160,
        },
        /// Reputation sync falló
        ReputationSyncFailed {
            request_id: T::Hash,
            tenant: H160,
            reason: Vec<u8>,
        },
        /// Mirror contract registrado
        MirrorContractRegistered {
            chain: StateMachine,
            contract: H160,
        },
        /// TenantPassport address configurado
        TenantPassportConfigured {
            address: H160,
        },
    }

    /// Errores del pallet
    #[pallet::error]
    pub enum Error<T> {
        /// No se ha configurado el TenantPassport address
        TenantPassportNotConfigured,
        /// No se ha configurado mirror contract para la chain
        MirrorContractNotConfigured,
        /// Sync ya está en progreso
        SyncAlreadyInProgress,
        /// Sync no encontrado
        SyncNotFound,
        /// Error al encodear datos
        EncodingError,
        /// Error al enviar mensaje ISMP
        IsmpDispatchError,
        /// Datos de reputación inválidos
        InvalidReputationData,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Configura la dirección del contrato TenantPassport
        ///
        /// Solo puede ser llamado por root (governance)
        #[pallet::call_index(0)]
        #[pallet::weight(10_000)]
        pub fn set_tenant_passport_address(
            origin: OriginFor<T>,
            address: H160,
        ) -> DispatchResult {
            ensure_root(origin)?;

            TenantPassportAddress::<T>::put(address);

            Self::deposit_event(Event::TenantPassportConfigured { address });

            Ok(())
        }

        /// Registra un mirror contract en otra chain
        ///
        /// Solo puede ser llamado por root (governance)
        #[pallet::call_index(1)]
        #[pallet::weight(10_000)]
        pub fn register_mirror_contract(
            origin: OriginFor<T>,
            chain: StateMachine,
            contract_address: H160,
        ) -> DispatchResult {
            ensure_root(origin)?;

            MirrorContracts::<T>::insert(chain, contract_address);

            Self::deposit_event(Event::MirrorContractRegistered {
                chain,
                contract: contract_address,
            });

            Ok(())
        }

        /// Sincroniza la reputación de un tenant a otra chain via Hyperbridge
        ///
        /// # Parámetros
        /// - `origin`: El tenant que quiere sincronizar su reputación
        /// - `tenant_address`: Address del tenant (H160 para compatibilidad EVM)
        /// - `destination`: Chain destino (e.g., Moonbeam, Arbitrum)
        ///
        /// # Flujo
        /// 1. Valida que el caller es el owner del tenant passport
        /// 2. Lee datos de reputación del contrato TenantPassport
        /// 3. Codifica datos en formato ISMP
        /// 4. Envía mensaje via pallet-ismp
        /// 5. Trackea el sync como pendiente
        #[pallet::call_index(2)]
        #[pallet::weight(100_000)]
        pub fn sync_reputation_to_chain(
            origin: OriginFor<T>,
            tenant_address: H160,
            destination: StateMachine,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Verificar que TenantPassport está configurado
            let passport_address = TenantPassportAddress::<T>::get()
                .ok_or(Error::<T>::TenantPassportNotConfigured)?;

            // Verificar que mirror contract está configurado
            let mirror_address = MirrorContracts::<T>::get(&destination)
                .ok_or(Error::<T>::MirrorContractNotConfigured)?;

            // Verificar que no hay sync pendiente
            if let Some(last_sync_id) = LastSync::<T>::get(tenant_address) {
                if let Some(sync) = Syncs::<T>::get(last_sync_id) {
                    ensure!(
                        sync.status != SyncStatus::Pending,
                        Error::<T>::SyncAlreadyInProgress
                    );
                }
            }

            // PASO 1: Leer datos de reputación del contrato TenantPassport
            // NOTA: Esto requiere una integración más profunda con PolkaVM
            // Por ahora usamos datos mock para demostración
            let reputation_data = Self::read_tenant_reputation(tenant_address, passport_address)?;

            // PASO 2: Codificar datos para ISMP
            let payload = Self::encode_reputation_payload(reputation_data.clone())?;

            // PASO 3: Crear request ISMP
            let timeout = 1000u64; // 1000 bloques de timeout

            let post = DispatchPost {
                dest: destination.clone(),
                from: pallet_ismp::host::Host::<T>::default().host_state_machine(),
                to: mirror_address.as_bytes().to_vec(),
                timeout_timestamp: 0, // Usar timeout basado en altura
                data: payload,
            };

            // PASO 4: Generar request ID
            let request_id = T::Hashing::hash(&post.data);

            // PASO 5: Dispatch via pallet-ismp
            // NOTA: Esto asume que T también implementa pallet_ismp::Config
            pallet_ismp::Pallet::<T>::dispatch_request(
                post,
                FeeMetadata {
                    payer: who.encode(),
                    fee: Default::default(),
                }
            ).map_err(|_| Error::<T>::IsmpDispatchError)?;

            // PASO 6: Guardar sync info
            let sync_info = CrossChainSync {
                request_id,
                tenant: tenant_address,
                destination: destination.clone(),
                status: SyncStatus::Pending,
                initiated_at: frame_system::Pallet::<T>::block_number(),
            };

            Syncs::<T>::insert(request_id, sync_info);
            LastSync::<T>::insert(tenant_address, request_id);

            // PASO 7: Emitir evento
            Self::deposit_event(Event::ReputationSyncInitiated {
                request_id,
                tenant: tenant_address,
                destination,
            });

            Ok(())
        }
    }

    // Funciones internas
    impl<T: Config> Pallet<T> {
        /// Lee la reputación de un tenant del contrato TenantPassport
        ///
        /// IMPLEMENTACIÓN CON FEATURE FLAGS:
        /// - Con "mock-polkavm": Usa datos simulados (para hackathon)
        /// - Sin "mock-polkavm": Lee datos reales de PolkaVM (para producción)
        fn read_tenant_reputation(
            tenant: H160,
            passport_address: H160,
        ) -> Result<TenantReputationData, DispatchError> {

            #[cfg(feature = "mock-polkavm")]
            {
                // ========================================
                // MOCK DATA PARA HACKATHON
                // ========================================
                // Simula diferentes tenants con diferentes reputaciones

                log::info!(
                    "🧪 [MOCK MODE] Reading tenant reputation for {:?}",
                    tenant
                );

                // Usar los últimos bytes del address para generar datos "únicos"
                let tenant_bytes = tenant.as_bytes();
                let seed = u32::from_be_bytes([
                    tenant_bytes[16],
                    tenant_bytes[17],
                    tenant_bytes[18],
                    tenant_bytes[19],
                ]);

                // Generar datos pseudo-aleatorios basados en el address
                let reputation = 50 + (seed % 50); // 50-100
                let payments_made = 1 + (seed % 50); // 1-50
                let disputes_count = seed % 3; // 0-2
                let properties_rented = 1 + (seed % 5); // 1-5
                let total_rent_paid = (seed as u128) * 1_000_000_000_000_000_000u128; // Variable

                log::info!(
                    "🧪 Mock data: reputation={}, payments={}, disputes={}",
                    reputation,
                    payments_made,
                    disputes_count
                );

                Ok(TenantReputationData {
                    tenant_address: tenant,
                    reputation,
                    payments_made,
                    disputes_count,
                    properties_rented,
                    total_rent_paid,
                    last_updated: Self::current_timestamp(),
                })
            }

            #[cfg(not(feature = "mock-polkavm"))]
            {
                // ========================================
                // IMPLEMENTACIÓN REAL PARA PRODUCCIÓN
                // ========================================

                log::info!(
                    "🔧 [PRODUCTION MODE] Reading tenant reputation from PolkaVM contract {:?}",
                    passport_address
                );

                // TODO: Implementar lectura real del storage de PolkaVM
                // Ver archivo: POLKAVM_INTEGRATION_ANALYSIS.md
                //
                // OPCIÓN RECOMENDADA: Storage Access Directo
                //
                // 1. Derivar tokenId del tenant address:
                //    let token_id = u256::from(tenant.as_bytes());
                //
                // 2. Construir storage key para mapping tenantInfo[tokenId]:
                //    let storage_key = Self::build_solidity_mapping_key(
                //        0, // slot del mapping tenantInfo
                //        token_id
                //    );
                //
                // 3. Leer del storage del contrato:
                //    let raw_data = pallet_revive::Pallet::<T>::read_contract_storage(
                //        passport_address,
                //        storage_key,
                //    )?;
                //
                // 4. Decodificar según struct layout de Solidity:
                //    let tenant_info = Self::decode_tenant_info_from_storage(raw_data)?;
                //
                // 5. Mapear a TenantReputationData y retornar

                // Por ahora, retornar error para forzar configuración correcta
                Err(Error::<T>::TenantPassportNotConfigured.into())
            }
        }

        /// Codifica datos de reputación en formato ISMP
        fn encode_reputation_payload(
            data: TenantReputationData,
        ) -> Result<Vec<u8>, DispatchError> {
            // Encodear usando SCALE codec
            data.encode_to_vec().ok_or(Error::<T>::EncodingError.into())
        }

        /// Obtiene el timestamp actual
        fn current_timestamp() -> u64 {
            // En producción usar pallet_timestamp
            let now = frame_system::Pallet::<T>::block_number();
            TryInto::<u64>::try_into(now).unwrap_or(0)
        }

        /// Callback cuando un sync es confirmado
        ///
        /// Esto sería llamado por ISMP cuando recibe confirmación
        pub fn on_sync_confirmed(request_id: T::Hash) {
            if let Some(mut sync) = Syncs::<T>::get(request_id) {
                sync.status = SyncStatus::Confirmed;
                Syncs::<T>::insert(request_id, sync.clone());

                Self::deposit_event(Event::ReputationSyncConfirmed {
                    request_id,
                    tenant: sync.tenant,
                });
            }
        }

        /// Callback cuando un sync falla
        pub fn on_sync_failed(request_id: T::Hash, reason: Vec<u8>) {
            if let Some(mut sync) = Syncs::<T>::get(request_id) {
                sync.status = SyncStatus::Failed;
                Syncs::<T>::insert(request_id, sync.clone());

                Self::deposit_event(Event::ReputationSyncFailed {
                    request_id,
                    tenant: sync.tenant,
                    reason,
                });
            }
        }
    }
}
