# Inicio de sesión de terceros — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDA: superpowers:subagent-driven-development o superpowers:executing-plans. Casillas `- [ ]` para seguimiento. Por la GUIA de notas, cada tarea pasa por `EXPLICACION.md` + entrevista **antes** de escribir código.

**Objetivo:** que el acceso al portal de tickets dependa en vivo de la lista de contactos del tercero, con una cuenta por persona y empresa, sin preguntar nunca la empresa.

**Arquitectura (v4, 2026-10-08):** la cuenta se identifica por `(idtercero, idempresa)`. Una única condición SQL, "acceso vigente" (existe una fila **activa** de `terceros_tercerocontacto` con `idtercerocontacto = cuenta.idtercero` e `idtercero = cuenta.idempresa`), se evalúa en el login y dentro de `PortalJwtHelper.ValidarToken`, que comparten la API y el chat. El correo de login sale de esa fila **activa**; las filas inactivas nunca dan acceso (solo sirven para el mensaje de suspensión). `soporte_soporteusuariosistema.email` queda como "último correo conocido". No se toca la tabla de contactos (la comparten otros módulos): el correo repetido se valida en el código. Las cuentas con empresa nunca cambian de empresa, tampoco en la migración (R-A, H10). Las cuentas sin empresa se asocian una vez en la migración, o al iniciar sesión, si la persona es contacto activo de **una sola** empresa.

**Descartado:** marca `esportalsoporte` en los contactos, índices únicos de correo, pantalla/vista de diagnóstico y script de activación por cuenta (ver `ANALISIS.md` §5). Se descartó derivar la empresa del contacto sin guardarla, porque los tickets se moverían con la persona.

**Stack:** .NET 4.6.2, WebAPI 2, Dapper, PostgreSQL 11, Npgsql 2.2.7. Front `portal-siian` en React, Mantine y react-hook-form + zod.

**Spec:** [`ANALISIS.md`](./ANALISIS.md) v4 (regla central, H1-H11, R-A a R-D).

**Ramas:** SIIAN `feature/login-usuario-soporte` (actual). `portal-siian`: rama nueva `feature/login-usuario-soporte`.

**Scripts SQL** (se trabajan en `DataGripProjects/fix-soporte-tickets/scratch/soporte/` y pasan al terminar a `.../entregables/08-10-2026-entregable/inicio-sesion-terceros/`).

## Restricciones globales

- **Capas:** SQL/Dapper solo en `Blip.Data/Soporte/SoporteUsuarioSistemaActorNegocio.cs`. `Negocio/` sin Dapper. SQL con campos estáticos (`TerceroContacto.EsactivoCampo`, `SoporteUsuarioSistema.IdempresaCampo`…), nunca literales. `catch (Exception) { throw; }`.
- **Correos:** comparar siempre `LOWER(TRIM(contacto.email)) = @email`, con `@email` ya en `Trim().ToLower()` (como hoy en `PortalAuthWebApiController`).
- **R-A:** el código nunca cambia `idempresa` de una cuenta que ya la tiene. Solo la escribe al crearla (registro) y al completar una cuenta con `idempresa` NULL (login).
- **Un contacto = (persona, empresa):** dos filas activas de la misma persona en la misma empresa cuentan como **uno** (dedupe). Un correo con más de un contacto distinto es ambiguo.
- **Mensajes exactos** (sin tildes, como el resto del controlador):

  | Clave | Texto |
  |---|---|
  | `MSG_SIN_CONTACTO` | `"El correo ingresado no corresponde a un contacto activo. Contacte a soporte."` |
  | `MSG_CORREO_AMBIGUO` | `"El correo esta asignado a mas de un contacto activo. Contacte a soporte."` |
  | `MSG_YA_TIENE_CUENTA` | `"Ya tiene una cuenta registrada para esta empresa. Use la opcion de recuperar contrasena."` |
  | `MSG_PENDIENTE_REGISTRO` | `"Ya tiene una cuenta registrada pendiente de asociar a una empresa. Contacte a soporte e indique la empresa a la que pertenece."` |
  | `MSG_PENDIENTE_LOGIN` | `"Su cuenta no esta asociada a ninguna empresa. Contacte a soporte e indique la empresa a la que pertenece."` |
  | `MSG_SIN_ACCESO` | `"Su acceso al portal fue deshabilitado. Contacte a soporte."` |

- **Verificación:** sin tests automáticos. Cada tarea cierra con `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug` + casos Dado/Cuando/Entonces (Postman/SQL). La evidencia va en `IMPLEMENTACION.md → ## Verificación` antes de tildar (GUIA).

## Foco de revisión

1. **Correo viejo tras crear una fila nueva (H11):** la fila vieja, inactiva, conserva `a@`; la nueva, activa, tiene `c@`. El login con `a@` debe dar 401. Se prueba en la Tarea 3, caso 6.
2. **Correo movido entre personas:** la fila de A, inactiva, tiene `x@`, y la de B, activa, también. El login con `x@` debe dar la cuenta de **B**. Se prueba en la Tarea 3, caso 10.
3. **Sesión abierta en el chat (SignalR) después de inactivar:** no debe poder reconectar ni recibir. Se prueba en la Tarea 3, caso 7.
4. **Correo de cambio de estado a una persona con dos cuentas (dos empresas):** llega solo al dueño del ticket, y no llega si está suspendido. Se prueba en la Tarea 3, caso 12.
5. **Cuenta sin empresa:** se asocia sola solo con un contacto único; no se crea un duplicado si intenta registrarse. Se prueba en la Tarea 2, caso 5 y en la Tarea 3, casos 3 y 4.
6. **Correo con mayúsculas o espacios en el contacto** (`" A@X.co "`): registro y login funcionan con `a@x.co`. Se prueba en la Tarea 2, caso 4 y en la Tarea 3, caso 1.

---

### Tarea 1: BD + capa de datos

No cambia ninguna columna: la entidad `SoporteUsuarioSistema` **no se regenera**. Solo cambian restricciones y se agregan métodos.

**Archivos:**
- Crear scripts:
  - `1-cuentas-por-persona-empresa.sql`
  - `2-migracion-empresa-cuentas.sql`
- **No** se toca `SoporteUsuarioSistemaActor.cs` (codigo generado de la plantilla): el correo vigente va en un SELECT propio del ActorNegocio.
- Modificar: `Blip.Data/Soporte/SoporteUsuarioSistemaActorNegocio.cs`

**Interfaces que produce** (todas en `SoporteUsuarioSistemaActor`, partial de `Blip.Data`):
- `string SqlAccesoVigente()`: el fragmento `EXISTS (SELECT 1 FROM terceros_tercerocontacto WHERE idtercerocontacto = soporte_soporteusuariosistema.idtercero AND idtercero = soporte_soporteusuariosistema.idempresa AND esactivo)`. Es el **único** lugar donde se define la regla.
- `bool TieneAccesoVigente(int idUsuario)`: cuenta `activo = true` AND `SqlAccesoVigente()`.
- `List<TerceroContacto> ObtenerContactosActivosPorCorreo(string email)`: filas **activas** con ese correo (el que llama las reduce a contactos distintos por `(persona, empresa)`).
- `SoporteUsuarioSistema ObtenerSinAccesoPorCorreo(string email)`: cuenta **sin acceso vigente** (incluye `idempresa` NULL) cuyo correo guardado es `@email`, o cuyo `(persona, empresa)` tiene una fila, activa o no, con ese correo. Primera coincidencia o null. No concede acceso: sirve para los mensajes 403.
- `SoporteUsuarioSistema ObtenerPorIdterceroyIdempresa(int idTercero, int? idEmpresa)`: cambia la firma de `int` a `int?` y usa `IS NOT DISTINCT FROM @idEmpresa`.
- `bool AsociarEmpresa(int idUsuario, int idEmpresa)`: `UPDATE ... SET idempresa = @idEmpresa WHERE id = @idUsuario AND idempresa IS NULL AND` existe una fila activa de esa persona en `@idEmpresa`. Devuelve `true` si afectó 1 fila.
- `void GuardarCorreoConocido(int idUsuario, string email)`: `UPDATE ... SET email = @email WHERE id = @idUsuario AND email IS DISTINCT FROM @email`.

- [x] **Paso 1, script 1:**
  - `DROP CONSTRAINT soporte_soporteusuariosistema_idtercero_key`
  - `DROP CONSTRAINT soporte_soporteusuariosistema_email_key`
  - `ADD CONSTRAINT soporte_soporteusuariosistema_tercero_empresa_key UNIQUE (idtercero, idempresa)`
- [x] **Paso 2, script 2 (migración de una vez, idempotente):** un `UPDATE` solo sobre cuentas con `idempresa IS NULL`: si la persona es contacto activo de **una sola** empresa y no tiene ya otra cuenta en ella (respeta `UNIQUE (idtercero, idempresa)`), `idempresa` = esa empresa; si no, sigue NULL (R-B). Las cuentas con empresa no se tocan (R-A, H10) y no hay tabla de respaldo. También borra la vista de diagnóstico `soporte_soportevistacuentassinacceso`, probada en demo y que ya no se usa. Y recrea `soporte_soportevistaticketoscliente` (H12): quita el `LATERAL` sobre `terceros_tercerocontacto` y toma `sus.idempresa` y el nombre de la empresa con `LEFT JOIN terceros_terceromaestro emp ON emp.id = sus.idempresa`, igual que la vista del detalle. Mismas columnas y en el mismo orden (`CREATE OR REPLACE VIEW`).
- [x] **Paso 3, `CrearSelectConCorreoVigente()` y `ObtenerPorIdConCorreoVigente(id)`** (en el ActorNegocio, `CrearSelect()` no cambia): igual que `CrearSelect()` pero con `COALESCE((SELECT email de la fila activa de persona+empresa ORDER BY id DESC LIMIT 1), email) AS email`. Los metodos nuevos de esta tarea lo usan, y las notificaciones y la recuperacion de la Tarea 3 cargan la cuenta con `ObtenerPorIdConCorreoVigente`.
- [x] **Paso 4:** implementar los métodos del bloque Interfaces.
- [x] **Paso 5, `ObtenerParaReasignacion`:** agregar `AND ` + `SqlAccesoVigente()`. El `Email` sale de la fila de contacto (JOIN a la fila activa).
- [x] **Paso 6, verificar:** build OK. En demo:
  - El script 1 corre. El 2 corre dos veces sin error. Con los datos de demo al 2026-10-08: la 13 queda en la empresa 210; ninguna cuenta con empresa cambia (1, 4, 12, 16, 19, 22); las demás NULL siguen en NULL (sin contacto activo).
  - Para cada ticket, `soporte_soportevistaticketoscliente.idempresa` = `soporte_soportevistaticketdetallecliente.idempresa` (0 filas distintas al comparar las dos vistas por `id`).
  - `SELECT` con `CrearSelectConCorreoVigente` de la cuenta de la persona 7: devuelve `info@siian.com.co`.
  - Cada método nuevo devuelve lo esperado con un caso en SQL (guardar la consulta y el resultado en `IMPLEMENTACION.md`).

### Tarea 2: Registro sin empresa

**Archivos:**
- Modificar: `Negocio/Soporte/SoporteUsuarioSistemaActorNegocio.cs` (`SoporteRegitroActorNegocio.RegistrarUsuarioPortal`)
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalAuthWebApiController.cs` (`Registro`; borrar `Empresas`)
- Modificar: `Blip.Entities/Soporte.ViewModels/RegistroPortalViewModel.cs` (quitar `IdEmpresa`)

**Interfaces:**
- Usa: `ObtenerContactosActivosPorCorreo` y `ObtenerPorIdterceroyIdempresa` (Tarea 1).
- Produce: `ResultadoRegistro RegistrarUsuarioPortal(string identificacion, string email, string passwordHash)`.

- [x] **Paso 1, orden de validación** (el primer fallo corta):
  1. `contactos = ObtenerContactosActivosPorCorreo(email)`, reducidos a `(persona, empresa)` distintos. Ninguno → `MSG_SIN_CONTACTO`. Más de uno → `MSG_CORREO_AMBIGUO`. Queda `contacto`.
  2. `tercero = ObtenerPorIdentificacionSinVerificarExistencia(identificacion)`. Si es null o `tercero.Id != contacto.Idtercerocontacto` → `MSG_SIN_CONTACTO`. Es el mismo mensaje a propósito, para no revelar de quién es el correo.
  3. `EstaAutorizado(tercero.Id)` → mensaje actual.
  4. `ObtenerPorIdterceroyIdempresa(tercero.Id, null) != null` → `MSG_PENDIENTE_REGISTRO`.
  5. `ObtenerPorIdterceroyIdempresa(tercero.Id, contacto.Idtercero) != null` → `MSG_YA_TIENE_CUENTA`.
  6. `Insert`, con `Idempresa = contacto.Idtercero` y `Email = email`.
- [x] **Paso 2:** borrar `GET api/portal/auth/empresas` y quitar `IdEmpresa` del ViewModel y de la llamada.
- [ ] **Paso 3, verificar** (`POST api/portal/auth/registro`):
  1. Dado un contacto activo de SIIAN (doc X, `a@x.co`), cuando se registra con X + `a@x.co`, entonces 200 y la cuenta tiene `idempresa` = SIIAN.
  2. Dado X como contacto activo de DCAPITAL con `b@x.co`, cuando se registra con X + `b@x.co`, entonces 200 y hay una segunda cuenta (H1 resuelto).
  3. Cuando el correo no está en ningún contacto activo, o el doc no es el del contacto, entonces 400 `MSG_SIN_CONTACTO`.
  4. Dado un contacto con `" A@X.co "`, cuando se registra con `a@x.co`, entonces 200.
  5. Dada una cuenta vieja de X con `idempresa` NULL, entonces 400 `MSG_PENDIENTE_REGISTRO`, y no se creó otra cuenta (SQL `count(*)` igual).
  6. Si repite el caso 1, entonces 400 `MSG_YA_TIENE_CUENTA`.
  7. Dado `z@x.co` activo en dos contactos distintos, entonces 400 `MSG_CORREO_AMBIGUO`. Dado `z@x.co` en dos filas de la misma persona y empresa, entonces 200.

  > **Estado 2026-10-13, casos pasados en demo:** 1, 3, 4, 6, 7 (7a). **Pendientes:** 2 (R2), 5 (R5), 7b (R7b): necesitan filas de contacto nuevas, ver `PRUEBAS.md`.

### Tarea 3: Login, token, recuperación y notificaciones

**Archivos:**
- Modificar: `Negocio/Soporte/SoporteUsuarioSistemaActorNegocio.cs` (agregar `ResolverCuentaPorCorreo`, lógica sin Dapper)
- Modificar: `PruebaPostgreSQL/Helpers/PortalCredencialesHelper.cs`
- Modificar: `PruebaPostgreSQL/Helpers/PortalJwtHelper.cs` (`ValidarToken`)
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalAuthWebApiController.cs` (`Login`)
- Modificar: `Negocio/Soporte/SoporteRecuperarPasswordActorNegocio.cs:26`, `Negocio/Soporte/SoporteRecuperarPasswordNumeroActorNegocio.cs:24,101`
- Modificar: `Negocio/Crm/GestionMaestroCRMActorNegocio.cs:201-204` (`EnviarCorreoCambioEstado`)
- Borrar:
  - `PortalUsuarioWebApiController.SeleccionarEmpresa`
  - `SoporteRegitroActorNegocio.SeleccionarEmpresa`
  - `SeleccionarEmpresaDto.cs` (y su `<Compile>` en el csproj de Entities)
  - `RequiereEmpresa` y `Empresas` de `LoginResponseDto`
  - `ExisteEmail`

**Interfaces:**
- Usa: `ObtenerContactosActivosPorCorreo`, `ObtenerSinAccesoPorCorreo`, `ObtenerPorIdterceroyIdempresa`, `AsociarEmpresa`, `GuardarCorreoConocido` y `TieneAccesoVigente` (Tarea 1).
- Produce: `ResolverCuentaPorCorreo(string email)` → la cuenta que corresponde, o un resultado "ambiguo", o null. La usan el login y la recuperación, para que la regla viva en un solo lugar.

- [x] **Paso 1, `ResolverCuentaPorCorreo(email)`:**
  1. `contactos` = `ObtenerContactosActivosPorCorreo(email)` reducidos a `(persona, empresa)` distintos.
  2. Más de uno → resultado **ambiguo** (el login responde 403 `MSG_CORREO_AMBIGUO`).
  3. Exactamente uno → cuenta = `ObtenerPorIdterceroyIdempresa(persona, empresa)`; si no existe, la cuenta de esa persona sin empresa (`ObtenerPorIdterceroyIdempresa(persona, null)`). Marca que el correo vino de un contacto activo.
  4. Ninguno → `ObtenerSinAccesoPorCorreo(email)`.
- [x] **Paso 2, `ValidarCredenciales(email, password)`:** cuenta = `ResolverCuentaPorCorreo(email)`. El resto queda igual: si es null, si `Activo != true` o si la contraseña no coincide → `Thread.Sleep(1500)` y null.
- [x] **Paso 3, `Login`:** después de validar credenciales:
  - Si `Idempresa == null`: si el correo vino de un contacto activo (paso 1, punto 3), `AsociarEmpresa(usuario.Id, contacto.Idtercero)`; si devuelve `true`, sigue. Si el correo no vino de un contacto activo, o devuelve `false` → **403** `MSG_PENDIENTE_LOGIN`. La empresa la decide el correo, no cuántas empresas tenga la persona.
  - Si no `TieneAccesoVigente(usuario.Id)` → **403** `MSG_SIN_ACCESO`.
  - Si el correo vino de un contacto activo (paso 1, punto 3): `GuardarCorreoConocido(usuario.Id, email)`.
  - Si no, token. Borrar la rama `RequiereEmpresa`.
- [x] **Paso 4, `ValidarToken`:** después de validar la firma, `id = ObtenerPortalId(principal)`. Devuelve `null` si `id` es null, si no `TieneAccesoVigente(id, email)` (cuenta sin contacto activo, o el correo del token ya no es el de ese contacto porque lo cambiaron), o si `CorreoEsAmbiguo(email)` (el correo está hoy en más de un contacto activo). Así quedan cubiertos `PortalApiAuthorizeAttribute`, que responde 401 y el interceptor de `portal-siian/src/api/client.js:16` cierra la sesión, y `SoporteHub.ObtenerPrincipal`.
- [x] **Paso 5, recuperación:** las 3 llamadas a `ObtenerPorEmailSinVerificarExistencia` pasan a `ResolverCuentaPorCorreo`. Solo se envía si la cuenta existe y `TieneAccesoVigente`; si no (incluye ambiguo y sin empresa), se responde el mismo mensaje genérico de hoy ("no revelar si existe").
- [x] **Paso 6, `EnviarCorreoCambioEstado`:** buscar la cuenta por `gestion.Idportalusuario` (`ObtenerPorIdSinVerificarExistencia`), no por la persona. Si es null o no `TieneAccesoVigente` → no enviar (Zendesk tampoco notifica a suspendidos).
- [x] **Paso 7:** borrar lo listado. `rg "SeleccionarEmpresa|RequiereEmpresa|ExisteEmail"` → 0 resultados. (`ObtenerEmpresasDeTercero` queda sin uso en el portal; no se borra, por si otro módulo lo usa: revisar con `rg`.)
- [ ] **Paso 8, verificar** (Postman + SQL):
  1. Dada la cuenta de la Tarea 2, caso 4, cuando hace login con `a@x.co`, entonces 200 con token.
  2. Con la contraseña mal → 401 "Credenciales incorrectas".
  3. Dada una cuenta con `idempresa` NULL cuya persona es contacto activo de **una** empresa: login con el correo guardado y la contraseña correcta → 200, y SQL muestra `idempresa` = esa empresa y los mismos tickets.
  4. Cuenta con `idempresa` NULL que entra con un correo que no es de ningún contacto activo → 403 `MSG_PENDIENTE_LOGIN`, y `idempresa` sigue NULL. Si la persona es contacto de dos empresas y entra con el correo de una → 200 y la cuenta queda en esa empresa.
  5. Se cambia el correo de la fila a `c@x.co` en el grid: login con `c@x.co` y la misma contraseña → 200 (y la columna `email` de la cuenta queda en `c@x.co`); con `a@x.co` → 401.
  6. Se crea una fila nueva con `c@x.co` y se inactiva la que tenía `a@x.co`: login con `c@x.co` → 200; con `a@x.co` → 401.
  7. Con un token vigente se inactiva la fila: `GET` de tickets → 401, el chat no reconecta. Se reactiva: el mismo token vuelve a funcionar. Se borra la fila y se recrea (misma empresa, mismo doc): login 200, misma cuenta (mismo `id`).
  8. Con la fila inactiva, login con su último correo y la contraseña correcta → 403 `MSG_SIN_ACCESO`; con la contraseña mal → 401.
  9. `z@x.co` activo en dos contactos distintos → login 403 `MSG_CORREO_AMBIGUO`. En dos filas de la misma persona y empresa → 200.
  10. Fila de A inactiva con `x@` y fila de B activa con `x@`: login `x@` con la contraseña de B → cuenta de B.
  11. Cuenta con empresa cuya persona ya no es contacto de ella, pero sí de otra: login 403 `MSG_SIN_ACCESO` y `idempresa` no cambia. Soporte la vuelve a cargar como contacto de su empresa: login 200 con sus tickets de antes.
  12. Persona con cuentas en SIIAN y DCAPITAL: un cambio de estado en un ticket de DCAPITAL notifica solo al correo de DCAPITAL. Con su fila inactiva, no notifica.
  13. Compañero con la fila inactiva: no aparece en los destinos de reasignación.
  14. Los tickets de las cuentas suspendidas siguen en `crm_gestionmaestrocrm` (`count(*)` igual antes y después).
  15. Con sesión abierta, otro contacto activo recibe el mismo correo del token: la siguiente petición → 401, vuelve a `/login`, y el login con ese correo da 403 `MSG_CORREO_AMBIGUO` hasta que soporte lo corrija.

  > **Estado 2026-10-13, casos pasados en demo:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15. **Pendiente:** 12 (avisos por correo: solo se comprobó a qué dirección apuntan, no el envío). Evidencia en `PRUEBAS.md` seccion 5.

### Tarea 4: Front `portal-siian`

**Archivos (repo `D:\proyectos\portal-siian`, rama nueva):**
- `src/pages/Registro/Registro.tsx`: quitar el select de empresa, `fetchEmpresas` y los estados `empresas*`.
- `src/pages/Login/Login.tsx`: quitar `pendiente`, la pantalla "Selecciona tu empresa" y `handleSeleccionarEmpresa`.
- `src/api/auth.js`: `registro(identificacion, email, password)`; borrar `getEmpresas` y `seleccionarEmpresa`.
- `src/schemas/auth.ts`: quitar `idempresa` del schema de registro.
- `src/shared/types/auth.ts`: `LoginResult` queda como `{ token, usuario }`; borrar `EmpresaAsociada` si queda sin uso.

- [x] **Paso 1:** aplicar los cambios.
- [x] **Paso 2, verificar** (`npm run build` sin errores + navegador):
  1. Registro: solo documento, correo y contraseña.
  2. Login entra directo a `/tickets`.
  3. Login de una cuenta pendiente, suspendida o con correo ambiguo: el alert muestra `MSG_PENDIENTE_LOGIN` / `MSG_SIN_ACCESO` / `MSG_CORREO_AMBIGUO`.
  4. Con la sesión abierta, se inactiva la fila en SIIAN y se navega: vuelve a `/login`.

  > **Estado 2026-10-13:** `pnpm build` sin errores y los 4 casos probados en demo y en el portal (F1 a F4). Ver `PRUEBAS.md` secciones 3 y 5.

### Tarea 5: Datos y salida a producción (sin código)

- [ ] Script 1 en todas las instalaciones donde exista la tabla del portal.
- [ ] Script 2 (migración) al desplegar. No depende del orden: lo que no asocie el script lo asocia el login.
- [ ] Desplegar SIIAN y `portal-siian` **juntos**: el front viejo llama a `/auth/empresas` y `seleccionar-empresa`, que se borran.
- [ ] Correos activos repetidos (R-C), antes de desplegar, pasar a soporte para que los corrijan (en demo al 2026-10-09: `hernanbolanos@siian.com.co`, 2 personas en 2 empresas):
  ```sql
  SELECT lower(trim(email)) AS correo, count(DISTINCT (idtercerocontacto, idtercero)) AS contactos
    FROM terceros_tercerocontacto
   WHERE esactivo AND coalesce(trim(email), '') <> ''
   GROUP BY 1 HAVING count(DISTINCT (idtercerocontacto, idtercero)) > 1;
  ```
- [ ] Avisar a soporte, con la lista: cuentas con empresa cuya persona no es contacto activo de ella (quedan sin acceso, H10) y cuentas que siguen sin empresa (R-B). Cuando la persona escriba, soporte revisa sus contactos y la persona vuelve a iniciar sesión.
- [x] `IMPLEMENTACION.md` con el mapa de archivos y la evidencia de verificación de las tareas 1-4.
