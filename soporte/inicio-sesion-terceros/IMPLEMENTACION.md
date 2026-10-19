# Inicio de sesión de terceros: implementación

Estado al **2026-10-13**: implementado y verificado en demo en lo esencial. Quedan 4 casos de prueba sin ejecutar (ver [Pendiente](#pendiente)). Plan: [`PLAN.md`](./PLAN.md). Spec: [`ANALISIS.md`](./ANALISIS.md). Casos y resultados: [`PRUEBAS.md`](./PRUEBAS.md).

## Qué hace

El acceso al portal de tickets depende **en vivo** de la lista de contactos del tercero. Una cuenta es una persona en una empresa `(idtercero, idempresa)`. Tiene acceso mientras exista una fila **activa** de `terceros_tercerocontacto` de esa persona en esa empresa. El correo de login es el de esa fila activa. Nunca se pregunta la empresa.

## Mapa de archivos

**SIIAN** (rama `feature/login-usuario-soporte`; commits `d924856b3` y `3b5c9b52e`)

| Archivo | Qué cambió |
|---|---|
| `Blip.Data/Soporte/SoporteUsuarioSistemaActorNegocio.cs` | Todo el SQL/Dapper: `SqlAccesoVigente`, `SqlCorreoVigente`, `TieneAccesoVigente`, `ObtenerContactosActivosPorCorreo`, `ObtenerSinAccesoPorCorreo`, `AsociarEmpresa`, `GuardarCorreoConocido`, `ObtenerPorIdConCorreoVigente`, `ObtenerParaReasignacion` con acceso vigente |
| `Negocio/Soporte/SoporteUsuarioSistemaActorNegocio.cs` | Lógica sin Dapper: `RegistrarUsuarioPortal` (orden de validación), `ResolverCuentaPorCorreo`, `ObtenerCuentaConAcceso`, `CorreoEsAmbiguo`, mensajes `Msg*` |
| `PruebaPostgreSQL/Helpers/PortalCredencialesHelper.cs` | `ValidarCredenciales` usa `ResolverCuentaPorCorreo` |
| `PruebaPostgreSQL/Helpers/PortalJwtHelper.cs` | `ValidarToken` rechaza si no hay acceso vigente con el correo del token o si el correo hoy es ambiguo (cubre la API y el chat) |
| `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalAuthWebApiController.cs` | `Login` (asocia empresa a cuentas NULL, 403 con mensajes) y `Registro` sin empresa |
| `Negocio/Soporte/SoporteRecuperarPasswordActorNegocio.cs`, `...NumeroActorNegocio.cs` | La recuperación pasa por `ObtenerCuentaConAcceso` |
| `Negocio/Crm/GestionMaestroCRMActorNegocio.cs` | `EnviarCorreoCambioEstado` busca la cuenta dueña del ticket y no avisa si no tiene acceso vigente |
| `Blip.Entities/Soporte.ViewModels/RegistroPortalViewModel.cs` | Se quitó `IdEmpresa` |

Borrado: `SeleccionarEmpresa` (controlador y negocio), `RequiereEmpresa`/`Empresas` de `LoginResponseDto`, `ExisteEmail` y el endpoint `auth/empresas`. `rg "SeleccionarEmpresa|RequiereEmpresa|ExisteEmail"` da 0 resultados.

**Scripts SQL** (`DataGripProjects/fix-soporte-tickets/entregables/08-10-2026-entregable/inicio-sesion-terceros/`): `1-cuentas-por-persona-empresa.sql`, `2-migracion-empresa-cuentas.sql`, `3-verificar-updates-tarea1.sql`.

**portal-siian** (rama `feature/login-usuario-soporte`; commit `07fe004`): `src/api/auth.js`, `src/pages/Login/Login.tsx`, `src/pages/Registro/Registro.tsx`, `src/schemas/auth.ts`, `src/shared/types/auth.ts`. `pnpm build` compila sin errores.

## Verificación

Detalle caso por caso en `PRUEBAS.md` (sección 5, corrida del 2026-10-13, demo `25.44.200.158`, portal en `localhost:5173`).

| Tarea | Pasaron | Sin ejecutar |
|---|---|---|
| 1. BD y datos | todos | |
| 2. Registro | R1, R3a, R3b, R4, R6a, R6b, R7a | R2, R5, R7b |
| 3. Login y token | L1 a L11, L13 a L17 | L12 |
| 4. Front | F1 a F6 | |

Notas de la verificación:

- La API se probó con `curl` (login, registro, GET/POST de tickets con token) y la BD con consultas de solo lectura. Los cambios de datos se hicieron en el grid de contactos de SIIAN (`TerceroMaestro/Editar/{id}` → Información Tributaria).
- L16 y F6: con el token abierto, cambiar el correo del contacto hace que GET y POST de tickets den 401 y el portal vuelva a `/login`. No se vio el 401 en la red, se dedujo del redirect.
- L14: 72 tickets con `idportalusuario` en total y 15 de la cuenta 13, antes y después de inactivar su contacto.
- Los avisos por correo (L12, L17) solo se comprobaron a nivel de consulta (a qué dirección apuntan), no el envío.
- Los casos marcados con `x` por Omar antes del 2026-10-13 (L2, L3, L4a, L6 a L9a) no se repitieron en esta corrida.

## Hallazgos

1. **Correo repetido entre empresas de la misma persona:** si el mismo correo está activo en dos empresas, el login da 403 `MSG_CORREO_AMBIGUO` aunque sea la misma persona. Es consecuencia de R-C. Cada empresa debe tener correos distintos.
2. **El registro exige autorización previa:** `EstaAutorizado` consulta `soporte_soporteportalautorizacion` (pantalla Parámetros de soporte → Portal Autorización). Una persona con contacto activo pero sin esa fila recibe "El tercero no cuenta con autorizacion para acceder al portal de clientes". No es nuevo en este cambio, pero ninguna prueba lo mencionaba.
3. **Dos filas activas de la misma persona y empresa** son un alias: ambos correos entran a la misma cuenta, y la recuperación y los avisos van a la fila activa con mayor `id`. Para quitar el acceso hay que inactivar **todas** las filas activas de la persona en esa empresa (pendiente de pasar al manual de soporte).
4. **Guardar en SIIAN falla en demo:** `ERROR: 42703: no existe la columna terceros_telefono.prefijo`. Los contactos se guardan antes del error, pero la pantalla lo muestra. Ajeno a esta funcionalidad.
5. **Grid de contactos con la herramienta de pruebas:** el primer clic en una celda solo la enfoca; hace falta un segundo para editar. Los selectores de persona del grid no respondieron de forma fiable a clics automáticos.

## Pendiente

- **Casos sin ejecutar:** R2, R5, R7b y L12. R2, R5 y R7b necesitan filas de contacto nuevas (la persona 214 ya quedó autorizada en demo). Preparación:
  ```sql
  INSERT INTO terceros_tercerocontacto
    (idtercero, idtipocontacto, idtercerocontacto, telefono, email, esprincipal, esactivo) VALUES
  (266, 2, 214, '3331133221', 'jh.r4@x.co',    false, true),  -- R7b: misma persona y empresa que la fila 10
  (1,   2, 214, '3331133221', 'r2.siian@x.co', false, true),  -- R2: misma persona, otra empresa
  (1,   2, 24,  '3000000000', 'r5.pend@x.co',  false, true);  -- R5: la persona 24 tiene la cuenta 6 sin empresa
  ```
  Registros a probar (`POST api/portal/auth/registro`): doc `1085344848` con `jh.r4@x.co` y luego con `r2.siian@x.co` (esperado 200 y 200, dos cuentas), y doc `1085257774` con `r5.pend@x.co` (esperado 400 `MSG_PENDIENTE_REGISTRO`, sin cuenta nueva).
- **Tarea 5 (salida a producción):** sin hacer. Script 1 en todas las instalaciones, script 2 al desplegar, desplegar SIIAN y `portal-siian` juntos, y pasar a soporte la lista de correos activos repetidos y de cuentas sin acceso.
- **Manual de soporte:** documentar el punto 3 de los hallazgos.
- **Datos de demo sin devolver:** lista al final de la sección 5 de `PRUEBAS.md`.
