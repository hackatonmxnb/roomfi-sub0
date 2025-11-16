# 🔐 Configuración de Subwallet para RoomFi

## Problema Común: "Source has not been authorized yet"

Este error aparece cuando intentas conectar Subwallet en producción (Netlify) pero funciona bien en localhost.

---

## ✅ Solución para Usuarios

### Opción 1: Autorizar el sitio manualmente (Recomendado)

1. **Abre la extensión Subwallet** en tu navegador

2. **Ve a Configuración** (ícono de engranaje ⚙️)

3. **Busca "Manage Website Access"** o "Gestionar Acceso de Sitios"

4. **Agrega el dominio:**
   ```
   https://roomfi.netlify.app
   ```
   
5. **Intenta conectar de nuevo** desde RoomFi

### Opción 2: Conectar desde el popup de Subwallet

1. Abre Subwallet
2. Clic en el botón "Connect to DApp" 
3. Pega la URL: `https://roomfi.netlify.app`
4. Autoriza la conexión
5. Recarga la página de RoomFi

---

## 🛠️ Para Desarrolladores

### ¿Por qué pasa esto?

- **Localhost** (`http://localhost:3000`) tiene permisos automáticos en la mayoría de wallets
- **Dominios de producción** requieren autorización explícita por seguridad
- Subwallet es más estricto que MetaMask en este aspecto

### Diferencias entre Subwallet y MetaMask

| Feature | MetaMask | Subwallet |
|---------|----------|-----------|
| Auto-autoriza localhost | ✅ Sí | ✅ Sí |
| Auto-autoriza dominios HTTPS | ✅ Sí | ❌ No |
| Requiere autorización manual | ❌ No | ✅ Sí |
| Integración con Polkadot | ❌ No | ✅ Sí |

### Código ya implementado

El error ahora se maneja con instrucciones claras:

```typescript
if (error.message && error.message.includes('not been authorized')) {
  errorMessage = '🔐 Subwallet necesita autorizar este sitio. Por favor:\n\n' +
                '1. Abre Subwallet\n' +
                '2. Ve a Configuración > Manage Website Access\n' +
                '3. Agrega "' + window.location.origin + '"\n' +
                '4. Intenta conectar de nuevo';
}
```

---

## 📝 Configuración de Netlify

Archivos creados para optimizar la experiencia:

### `netlify.toml`
- Configuración de build
- Headers de seguridad
- Caché optimizado

### `public/_redirects`
- SPA routing correcto
- Previene errores 404 en rutas

---

## 🧪 Testing

### Localhost (siempre funciona)
```bash
npm start
# http://localhost:3000
```

### Netlify Deploy Preview
```bash
netlify deploy --prod
```

---

## 🆘 Troubleshooting

### Error persiste después de autorizar

1. **Cierra y abre Subwallet** completamente
2. **Recarga la página** de RoomFi (Ctrl+Shift+R / Cmd+Shift+R)
3. **Verifica la red** - debe ser Paseo o Arbitrum Sepolia
4. **Intenta con otro navegador** para descartar caché

### Alternativa temporal: Usar MetaMask

Si necesitas demo rápido y Subwallet no coopera:

1. Instala MetaMask
2. Importa tu seed phrase de Subwallet (solo para demo)
3. Conecta con MetaMask (funciona sin configuración extra)
4. Para producción real, educa a usuarios sobre la autorización

---

## 📚 Referencias

- [Subwallet Documentation](https://docs.subwallet.app/)
- [Web3 Provider Documentation](https://docs.metamask.io/wallet/concepts/provider-api/)
- [Netlify SPA Configuration](https://docs.netlify.com/routing/redirects/rewrites-proxies/#history-pushstate-and-single-page-apps)
