# 🗺️ Rutas de la Aplicación RoomFi

Última actualización: 2025-01-15

---

## 📋 Estructura de Rutas

### 🏠 Páginas Públicas

| Ruta | Componente | Descripción |
|------|-----------|-------------|
| `/` | LandingPage | Página de inicio |
| `/register` | RegisterPage | Registro de usuario con Google |

---

### 🔐 Aplicación Principal (`/app`)

| Ruta | Componente | Descripción | Requiere Wallet |
|------|-----------|-------------|-----------------|
| `/app` | MainApp | Dashboard principal con búsqueda | No |
| `/app/properties` | PropertyRegistryPage | Registro y gestión de propiedades | Sí |
| `/app/agreements` | MyAgreementsPage | Lista de rental agreements | Sí |
| `/app/agreement/:address` | RentalAgreementView | Vista individual de agreement | Sí |

---

### 🏗️ Páginas de Gestión

| Ruta | Componente | Descripción | Requiere Wallet |
|------|-----------|-------------|-----------------|
| `/dashboard` | DashboardPage | Dashboard de landlord/tenant | Sí |
| `/create-pool` | CreatePoolPage | Crear pool de inversión (V1 - deprecado) | Sí |

---

## 🔄 Flujos de Navegación

### Para Landlords

```
1. Conectar wallet
2. /app/properties → Registrar propiedad
3. /app/agreements → Crear nuevo agreement
4. /app/agreement/:address → Ver y gestionar agreement
```

### Para Tenants

```
1. Conectar wallet
2. /app/agreements → Ver agreements asignados
3. /app/agreement/:address → Firmar, pagar depósito, pagar renta
```

---

## 🎯 URLs Completas (Desarrollo)

### Base URL
```
http://localhost:3000
```

### Ejemplos
```
# Landing
http://localhost:3000/

# App principal
http://localhost:3000/app

# Propiedades
http://localhost:3000/app/properties

# Lista de Agreements
http://localhost:3000/app/agreements

# Agreement específico
http://localhost:3000/app/agreement/0x1234567890abcdef...

# Dashboard
http://localhost:3000/dashboard
```

---

## 📱 Navegación en el Header

### Desktop (Wallet Conectada)
- **Crear Pool** → `/create-pool`
- **Mis Propiedades** → `/app/properties`
- **Bóveda** → Modal (no ruta)
- **Como funciona** → Modal (no ruta)

### Mobile (Drawer)
- **Como funciona** → Modal (no ruta)
- **Conectar** → Abre modal de wallet

---

## 🔗 Links Programáticos

### En App.tsx
```typescript
// Ver propiedades
navigate('/app/properties');
```

### En MyAgreementsPage.tsx
```typescript
// Después de crear agreement
navigate(`/app/agreement/${agreementAddress}`);

// Ver detalles de agreement
navigate(`/app/agreement/${agreement.agreementAddress}`);
```

### En RentalAgreementView.tsx
```typescript
// Volver a lista
navigate(-1); // o navigate('/app/agreements');
```

---

## 🚧 Rutas Deprecadas (V1)

Estas rutas están en el código pero son de la versión 1:

| Ruta | Status | Alternativa V2 |
|------|--------|----------------|
| `/create-pool` | 🟡 Deprecado | `/app/properties` + `/app/agreements` |
| Property Pools (no ruta) | ❌ Eliminado | `/app/agreements` |

---

## 🎨 Convenciones

### Estructura
- **Públicas**: Raíz `/`
- **App Principal**: `/app/*`
- **Gestión**: Raíz o `/dashboard`

### Parámetros
- `:address` - Dirección Ethereum del agreement (0x...)
- `:id` - ID numérico (no usado actualmente)

### Query Params
No se usan query params actualmente.

---

## 🔮 Futuras Rutas (Planeadas)

Posibles adiciones cuando se implementen:

```
/app/disputes           → Lista de disputas
/app/dispute/:id        → Vista de disputa individual
/app/profile           → Perfil de usuario
/app/passport          → TenantPassport detallado
/app/property/:id      → Vista pública de propiedad
```

---

## 💡 Buenas Prácticas

### Para Agregar Nuevas Rutas

1. **Agregar en App.tsx**:
   ```typescript
   <Route path="/app/nueva-ruta" element={<NuevoComponente />} />
   ```

2. **Actualizar este documento**

3. **Agregar navegación en Header si es necesario**

4. **Usar prefijo `/app` para rutas de aplicación**

---

## ✅ Checklist de Migración (Completado)

- [x] `/properties` → `/app/properties`
- [x] `/agreements` → `/app/agreements`
- [x] `/agreement/:address` → `/app/agreement/:address`
- [x] Actualizar `handleViewMyProperties()` en App.tsx
- [x] Actualizar navegación en MyAgreementsPage
- [x] Actualizar navegación en CreateRentalAgreement
- [x] Documentar nuevas rutas

---

**Última verificación**: 2025-01-15  
**Status**: ✅ Todas las rutas funcionando
