# Implementación — Login/Registro con selección de empresa

> Backend en repo `D:\soporte\SIIAN` (plan detallado en
> `PruebaPostgreSQL/docs/1-plan-login-empresa.md`, `1.6-seleccion-empresa-login.md`).
> Frontend en repo `D:\proyectos\portal-siian` (plan detallado en
> `1.4-registro-selector-empresa.md`, `1.6-seleccion-empresa-login-frontend.md`, mismos
> nombres dentro de `PruebaPostgreSQL/docs/` del repo backend). Ambos con estado
> **IMPLEMENTADO**.

## Qué se construyó

Cada usuario del portal queda identificado con su **empresa** (`idempresa`), disponible
en el JWT y en la respuesta de login. La empresa la elige/confirma el propio usuario,
nunca se asigna en silencio:

- **Usuarios nuevos:** eligen empresa en el registro.
- **Usuarios existentes con varias empresas asociadas** (backfill ambiguo, quedaron con
  `idempresa = NULL`): pantalla de selección una vez, en el login, antes de emitir token.
- Sin empresa no se emite token — mientras `idempresa` sea nulo no hay sesión útil.

## Backend (`D:\soporte\SIIAN`)

| Pieza | Archivo | Qué hace |
|---|---|---|
| Migración BD | `soporte_soporteusuariosistema.idempresa` (FK a `terceros_terceromaestro`) | Backfill automático solo de los usuarios cuya persona tiene **exactamente una** empresa activa en `terceros_tercerocontacto`; el resto queda `NULL` y selecciona luego. Script `.sql` original no localizado en este repo ni en `DataGripProjects` al documentar — la query de backfill queda citada en `1-plan-login-empresa.md`. |
| Entidad/Actor | `Blip.Data/Soporte/SoporteUsuarioSistema.cs` + `SoporteUsuarioSistemaActor.cs` | Propiedad `Idempresa` (`int?`), incluida en INSERT/UPDATE/SELECT |
| Consulta de empresas | `Blip.Data/Soporte/SoporteUsuarioSistemaActorNegocio.cs` → `ObtenerEmpresasDeTercero(idTercero)` | `SELECT` con `JOIN` a `terceros_terceromaestro`, filtra `terceros_tercerocontacto.esactivo = true`. Reusado en registro y en login |
| Registro | `PortalAuthWebApiController.Registro` + `RegistroPortalViewModel.IdEmpresa` | Valida que `idEmpresa` pertenezca a las empresas asociadas del tercero (no confía en el front) antes de crear el usuario |
| JWT | `Helpers/PortalJwtHelper.cs` | `GenerarToken(...)` agrega claim `portal_empresa`; `ObtenerEmpresaId(ClaimsPrincipal)` lo lee |
| Login | `Controllers/WebApi/Portal/PortalAuthWebApiController.cs` | Si `Idempresa == null`: sin token, responde `LoginResponseDto { RequiereEmpresa = true, Empresas = [...] }` (o `400` "contacte a soporte" si no tiene ninguna asociada). Si tiene empresa: responde `{ Token, Usuario }` como siempre |
| Selección de empresa | `Controllers/WebApi/Portal/PortalUsuarioWebApiController.cs` (nuevo) → `POST api/portal/usuario/seleccionar-empresa` | Ver decisiones abajo |
| Validación credenciales compartida | `Helpers/PortalCredencialesHelper.cs` (nuevo) | `ValidarCredenciales(email, password)`, extraído de `PortalAuthWebApiController` porque ahora lo usan 2 controllers |
| DTOs | `Blip.Entities/Soporte.ViewModels/LoginResponseDto.cs`, `SeleccionarEmpresaDto.cs` (nuevos) | Sufijo `Dto` (convención del repo) para payloads puros de API — reemplazan objetos anónimos y un `AuthResponseViewModel` viejo sin usar que exponía `Passwordhash` |
| Lógica de negocio | `Negocio/Soporte/SoporteUsuarioSistemaActorNegocio.cs` (clase `SoporteRegitroActorNegocio`) → `SeleccionarEmpresa(idUsuario, idEmpresa)` | Rechaza si el usuario ya tiene `idempresa` (selección definitiva) o si `idEmpresa` no pertenece al tercero; si pasa, persiste y devuelve el usuario actualizado |

### Decisiones tomadas (distintas al plan original)

- **Autenticación del paso `seleccionar-empresa`: reenviar credenciales completas, no
  token temporal.** El plan original recomendaba un JWT temporal de un solo uso
  (`portal_pendiente_empresa=true`); se descartó para no crear un tipo de token nuevo ni
  lógica de claims extra. `Login` con `idempresa = NULL` no emite ninguna sesión, solo la
  lista de empresas — el segundo paso vuelve a validar email+password igual que un login
  normal.
- **Endpoint en un controller nuevo (`PortalUsuarioWebApiController`), no en
  `PortalAuthWebApiController`.** Mantiene `Auth` enfocado en emitir sesión
  (login/registro/recuperar password); las operaciones sobre la cuenta en proceso de
  completarse van aparte. De ahí que la validación de credenciales se compartiera vía
  `PortalCredencialesHelper` en vez de duplicarse.
- **Selección de empresa es definitiva.** Un usuario no puede cambiar de empresa después
  por este endpoint; cambio solo por soporte (UPDATE manual).

## Frontend (`D:\proyectos\portal-siian`)

Cuando el login responde sin token (`{ requiereEmpresa: true, empresas: [...] }`),
`Login.tsx` ya no lo trata como error genérico — muestra un selector y completa el flujo:

| Archivo | Qué se agregó |
|---|---|
| `src/shared/types/auth.ts` | `EmpresaAsociada`, `RequiereEmpresaResponse`, `LoginResult = AuthResponse \| RequiereEmpresaResponse` (union discriminado por `requiereEmpresa`) |
| `src/api/auth.js` | `seleccionarEmpresa(email, password, idEmpresa)` → `POST /api/portal/usuario/seleccionar-empresa`; también `getEmpresas(identificacion)` y `registro(...)` con `idempresa` para el flujo de registro |
| `src/pages/Registro/Registro.tsx` | Selector de empresa obligatorio tras escribir la identificación (`Select` de Mantine + `Controller` de react-hook-form, patrón con resolver zod) |
| `src/pages/Login/Login.tsx` | Manejo del caso `requiereEmpresa`, UI del selector, submit de selección (detalle abajo) |

### Cómo funciona (`Login.tsx`)

1. **Detección** (`onSubmit`): castea la respuesta a `LoginResult` y usa
   `'requiereEmpresa' in res` para discriminar el union — TS no deja leer
   `res.requiereEmpresa` directo porque `AuthResponse` no declara esa key. Si es el caso
   especial, guarda `{ email, password, empresas }` en el estado `pendiente` y corta con
   `return` (no navega, no tira error). Si no, sigue el camino normal de siempre.

2. **Pantalla alternativa**: `if (pendiente) { return (...) }` antes del `return`
   normal — si `pendiente` tiene datos, en vez del form de credenciales se pinta otra
   pantalla (mismo `AuthLayout`) con un `Select` de Mantine (mismo patrón que
   `Registro.tsx`, sin `Controller`/react-hook-form porque es un paso secundario simple)
   y un botón "Continuar" (deshabilitado sin selección).

3. **Submit de selección** (`handleSeleccionarEmpresa`): llama
   `seleccionarEmpresa(pendiente.email, pendiente.password, idEmpresaSeleccionada)`
   **reenviando las credenciales completas** — coherente con la decisión de backend de no
   usar token temporal. Si responde bien, `guardarSesion(res.token, res.usuario)` + navega
   a `/tickets` (misma forma de respuesta que un login exitoso). Si falla, guarda el
   mensaje en `errorSeleccion` sin navegar; la lista de empresas se conserva para
   reintentar.

No se tocó `AuthContext.jsx` — `guardarSesion`/`cerrarSesion` ya sirven igual para la
respuesta de `seleccionar-empresa`.

## Pendiente / no resuelto en esta pasada

- Backend: `LoginResponseDto.RequiereEmpresa` (`bool?` con `NullValueHandling.Ignore` en
  `Blip.Entities/Soporte.ViewModels/LoginResponseDto.cs`) nunca manda `false` explícito,
  solo se omite. Quedó planteado (no implementado) mandar `RequiereEmpresa = false`
  explícito en la rama de login exitoso para que el frontend valide el booleano en vez de
  la presencia de la key — hoy funciona porque el union type nunca declara
  `requiereEmpresa` en `AuthResponse`, pero es un contrato implícito.
- Migración de BD: no se localizó el `.sql` original de esta pasada; si hace falta
  reproducir el backfill, reconstruir con la query citada en `1-plan-login-empresa.md`.

## Verificación end-to-end

- Usuario con `idempresa` asignada → login directo a `/tickets`, sin cambios.
- Usuario con `idempresa = NULL` y empresas asociadas → aparece selector; elegir una y
  confirmar entra a `/tickets` con `portal_token`/`portal_usuario` en localStorage,
  `idempresa` queda persistido en backend.
- Botón "Continuar" deshabilitado sin empresa seleccionada.
- `seleccionar-empresa` falla (red/backend caído) → error visible, no navega, lista de
  empresas se conserva.
- Usuario sin ninguna empresa asociada → cae en el `catch` de `onSubmit` (mensaje de
  backend "contacte a soporte"), sin código nuevo de por medio.
- Selección de empresa ajena al tercero → rechazo (`400`).
- Selección repetida sobre un usuario que ya tiene `idempresa` → rechazo (selección
  definitiva).
