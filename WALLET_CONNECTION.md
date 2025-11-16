# 🔗 Conexión de Wallets en RoomFi

## Sistema de Conexión Simplificado

RoomFi utiliza un enfoque directo para conectar wallets, similar al implementado en roomlen. Este sistema detecta automáticamente las extensiones instaladas en el navegador.

## ✨ Wallets Soportadas

### 1. MetaMask
- Detecta automáticamente `window.ethereum`
- La wallet más popular del ecosistema
- Compatible con redes EVM

### 2. SubWallet
- Detecta automáticamente `window.SubWallet`
- Wallet especializada en Polkadot y redes EVM
- Soporta múltiples chains simultáneamente

### 3. Google (Portal)
- Crea una wallet automáticamente usando Google OAuth
- Ideal para usuarios nuevos sin experiencia en crypto
- Gestiona claves privadas de forma segura

---

## 🚀 Cómo Funciona

### Para el Usuario

1. **Hacer clic en "Conectar"**
2. **Elegir wallet:**
   - MetaMask (extensión)
   - SubWallet (extensión)
   - Google (crea wallet automática)
3. **Aprobar conexión** en la wallet
4. **¡Listo!** Ya estás conectado

### Flujo Técnico

```typescript
// 1. El usuario elige el tipo de wallet
connectWithWallet('metamask' | 'subwallet')

// 2. Se detecta el provider correspondiente
const walletProvider = walletType === 'metamask' 
  ? window.ethereum 
  : window.SubWallet

// 3. Se solicita conexión
const browserProvider = new ethers.BrowserProvider(walletProvider)
const accounts = await browserProvider.send('eth_requestAccounts', [])

// 4. Se guarda el estado
setAccount(accounts[0])
setProvider(browserProvider)
localStorage.setItem('walletType', walletType)
```

---

## 🔧 Implementación

### Componentes Clave

1. **`WalletModal.tsx`**
   - Modal con opciones de conexión
   - Interfaz limpia y clara
   - Maneja la selección del usuario

2. **`App.tsx`**
   - Función `connectWithWallet(walletType)`
   - Función `disconnectWallet()`
   - Gestión del estado de conexión

3. **`Header.tsx`**
   - Botón "Conectar"
   - Display de cuenta conectada
   - Botón "Desconectar"

### Estados Principales

```typescript
const [account, setAccount] = useState<string | null>(null)
const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null)
const [showOnboarding, setShowOnboarding] = useState(false)
```

---

## 🆚 Ventajas vs WalletConnect

| Característica | Nuestro Sistema | WalletConnect |
|---------------|-----------------|---------------|
| **Configuración** | ✅ Ninguna | ❌ Requiere Project ID |
| **Dependencias** | ✅ Solo ethers.js | ❌ Múltiples paquetes |
| **Tamaño bundle** | ✅ Pequeño | ❌ ~500KB extra |
| **Complejidad** | ✅ Simple | ❌ Complejo |
| **Wallets móviles** | ❌ No (extensión solo) | ✅ Sí (via QR) |
| **Polkadot/SubWallet** | ✅ Sí | ❌ Limitado |

---

## 🛠️ Instalación

No se requiere configuración adicional. Solo asegúrate de tener:

```json
{
  "dependencies": {
    "ethers": "^6.x.x",
    "@portal-hq/web": "^3.x.x" // Para Google login
  }
}
```

---

## 📱 Para Usuarios Móviles

Si quieres soportar wallets móviles en el futuro, puedes:

1. **Usar WalletConnect** (requiere Project ID gratuito)
2. **Usar deep linking** directo a las wallets
3. **Crear versión móvil nativa** con React Native

---

## 🐛 Troubleshooting

### "No se encontró [wallet]"

**Causa**: La extensión no está instalada

**Solución**: 
- MetaMask: https://metamask.io/download/
- SubWallet: https://www.subwallet.app/download.html

### "Conexión rechazada por el usuario"

**Causa**: El usuario canceló en la wallet

**Solución**: Simplemente vuelve a intentar

### "Red incorrecta"

**Causa**: La wallet está en otra red

**Solución**: El sistema intenta cambiar automáticamente con `switchToNetwork()`

---

## 🔐 Seguridad

1. **Nunca almacenamos claves privadas**
2. **El localStorage solo guarda el tipo de wallet** (no datos sensibles)
3. **Todas las transacciones requieren aprobación** del usuario en su wallet
4. **El código es open source** y auditable

---

## 🎯 Próximos Pasos

Para mejorar la experiencia:

1. ✅ Reconexión automática (via localStorage)
2. ✅ Cambio automático de red
3. ⏳ Soporte para Ledger
4. ⏳ Soporte para WalletConnect (opcional)
5. ⏳ Deep linking para wallets móviles

---

**¡Sistema listo para usar! No requiere configuración adicional.** 🎉
