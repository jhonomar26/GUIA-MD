# Implementación — Ajustes al estado "Solucionado"

Reglas de negocio: [`REGLAS.md`](./REGLAS.md).

## Commit `dca1a1b2f` — fix principal

**Negocio/Crm/GestionMaestroCRMActorNegocio.cs**
- `ActualizarDatosSoporte` — nuevo guard: si `estadoActual.Essolucionado` y el estado
  seleccionado es distinto al actual, `throw InvalidOperationException` ("debe usar Reabrir
  Ticket"). Se simplifica la asignación de `gestion.Idestado` (ya no hace falta el ternario
  que ignoraba el valor del form silenciosamente, el throw corta antes de llegar ahí).
- `ReabrirPorMensaje(int idGestion, string idUsuario, int? idPortalUsuario = null)` — cambia
  de `void` a `bool` (indica si efectivamente reabrió, lo necesitan los callers para decidir
  si emiten el evento de SignalR). Si la ventana venció, audita y cierra definitivo con
  `idPortalUsuario` también pasado a `ActualizarGestionTiket` (antes solo mandaba `idUsuario`).
- `ObtenerEstadoCierre` — comentario aclarando que el estado en sí nunca cambia desde la
  edición, solo por botón.

**Negocio/Portal/PortalSoporteTicketActorNegocio.cs**
- `RegistrarMensajeCliente` — se saca la llamada a `ReabrirPorMensaje` de acá: pasa al
  controller, porque el controller es quien necesita el resultado (`bool`) para decidir el
  broadcast del hub.
- `ReabrirTicket` (reapertura manual del **cliente** desde el portal, distinta de la del
  agente) — bonus fix encontrado en el camino: no estaba auditando los cambios de estado
  (ni el cierre por ventana vencida ni la reapertura exitosa). Se agregan los
  `SoporteAuditoriaActor.ActualizarGestionTiket(...)` correspondientes, con `idPortalUsuario`.

**Negocio/Soporte/SoporteMensajesActorNegocio.cs**
- `EnviarMensajeSoporte` — mismo movimiento: se saca `ReabrirPorMensaje` de acá, pasa al
  controller.

**PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs**
- `EnviarMensaje` — ahora llama `ReabrirPorMensaje(id, null, IdPortalUsuario)` **después** de
  registrar el mensaje (con `idUsuario = null`, porque el usuario que escribe es del portal,
  no de `AspNetUsers`; se audita con `IdPortalUsuario` en su lugar). Si `seReabrio`, emite
  `cambioEstadoTicket` por `SoporteHubActorNegocio.GrupoTicket(id)` antes del `nuevoMensaje`.
  De paso: el broadcast de `nuevoMensaje` usaba un string armado a mano (`"ticket-" + id`) en
  vez de `SoporteHubActorNegocio.GrupoTicket(id)` — quedó unificado al mismo grupo real.

**PruebaPostgreSQL/Controllers/WebApi/SoporteMensajesWebApiController.cs**
- `EnviarMensajeSoporte` — mismo patrón: llama `ReabrirPorMensaje(idGestion, userId)` después
  de registrar el mensaje, emite `cambioEstadoTicket` si `seReabrio`.

**PruebaPostgreSQL/Hubs/SoporteHub.cs**
- Se elimina el método `EnviarMensajeCliente` (envío de mensaje de cliente por SignalR).
  Quedaba duplicado con el endpoint REST del portal y sin ninguna de las validaciones nuevas
  (cerrado definitivo, reapertura por mensaje) — un cliente conectado por el hub podía mandar
  mensajes a un ticket cerrado sin que nada lo evitara. El hub queda solo para push
  (`nuevoMensaje`, `actualizarBadgeMensajes`, `cambioEstadoTicket`), el envío real es por REST.

**Blip.Data/Soporte/SoporteAuditoria\*.cs, Blip.Entities/Soporte.ViewModels/SoporteAuditoria\*.cs**
- Cambios de una feature de auditoría en paralelo (historial de cambios con nombre de
  usuario resuelto, `SoporteAuditoriaConNombreViewModel`, `ObtenerListaConNombrePorIdgestion`)
  — no es parte de este fix puntual, pero `ActualizarGestionTiket` gana el parámetro opcional
  `int? idportalusuario = null` ahí, que es lo que este fix necesita para auditar los cambios
  automáticos originados por el cliente del portal.

## Commit `273608ad1` — solo el fragmento de SignalR (el resto es de "asesor predeterminado", feature no relacionada)

**PruebaPostgreSQL/Views/SoporteDetalle/Index.cshtml**
- + `soporteHub.on("cambioEstadoTicket", function () { location.reload(); })` — listener nuevo,
  mismo patrón `location.reload()` que ya usan los popups de acciones manuales.
- Bug encontrado: la página nunca invocaba `soporteHub.invoke("UnirseATicket", idTicket)` —
  solo se unía al dashboard (`UnirseAlDashboard`), nunca al grupo del ticket individual. Sin
  esto el listener de arriba jamás se hubiera disparado (el broadcast va al grupo del ticket,
  no al del dashboard). Se agrega el `invoke` que faltaba.

## Commit `6d1964788` — corrección de la FK rota en auditoría

**Negocio/Soporte/SoporteCalificacionActorNegocio.cs**
- `CerrarTicketsVencidosSinCalificar()` y `CerrarTicketsVencidosSinCalificarSolucion()`
  (ambas corridas desde `CierreDia`) pasaban `"sistema"` como `idusuario` a
  `ActualizarGestionTiket`. Esa columna tiene FK a `AspNetUsers` — `"sistema"` no existe ahí,
  el insert de auditoría fallaba. Se cambia a `null` (columna nullable, `ON DELETE SET NULL`;
  el query de historial ya interpreta `idusuario`/`idportalusuario` ambos `NULL` como
  "Sistema").
- Nota: este commit vino con los comentarios de esos dos métodos con mojibake
  (`ó`→`�`, etc.) — efecto colateral de un hook local (`.claude/settings.local.json`,
  conversión UTF-8→ISO-8859-1 post-edit), no un cambio intencional. No se corrigió en este
  fix, queda para una limpieza aparte si molesta.

**Blip.Data/Soporte/SoporteAuditoriaActorNegocio.cs**
- Solo reordena las constantes privadas (`SinPrioridad`, `Cerrada`, etc.) arriba del archivo,
  sin cambios funcionales.

## Qué falta / no cubierto

- El mojibake introducido en `SoporteCalificacionActorNegocio.cs` por el hook local sigue ahí.
- No hay test automatizado (el proyecto no tiene suite) — la verificación fue manual, ver
  [PLAN.md](./PLAN.md) → sección de verificación de cada fase.
