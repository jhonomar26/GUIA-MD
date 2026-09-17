# Plan ejecutado — Ajustes al estado "Solucionado"

Se ejecutó en dos planes separados (dos sesiones de plan mode). Implementación real:
[`IMPLEMENTACION.md`](./IMPLEMENTACION.md).

## Plan 1 — Reabrir ticket Solucionado al recibir mensaje

**Contexto:** ver [`REGLAS.md`](./REGLAS.md) → "Qué estaba roto" (puntos 1, 2 y 4).

**Fases:**
1. `ReabrirPorMensaje(int idGestion)` en `GestionMaestroCRMActorNegocio.cs` — reabre si el
   ticket está Solucionado y la ventana no venció; si venció, cierra definitivo y rechaza.
2. Portal (`PortalTicketsWebApiController.EnviarMensaje`) — bloquear mensaje si cerrado
   definitivo, reabrir si Solucionado.
3. Soporte (`SoporteMensajesActorNegocio.EnviarMensajeSoporte`) — mismo guard, mismo reabrir.
4. Verificación manual: mensaje en ticket Solucionado reabre; mensaje en cerrado definitivo
   se rechaza en ambos lados.

Se desvió del plan original en la implementación final: la llamada a `ReabrirPorMensaje` se
movió de la capa de Negocio (`RegistrarMensajeCliente`/`EnviarMensajeSoporte`) al controller,
porque el controller es quien necesita el valor de retorno (`bool`) para decidir si emite el
evento de SignalR — eso se resolvió en el Plan 2.

Durante la revisión de este plan también se corrigió `ActualizarDatosSoporte`: el guard
original solo bloqueaba *entrar* a Solucionado por edición, no *salir* — hueco real
encontrado en el camino, no estaba en el plan original.

## Plan 2 — Refrescar UI del agente cuando el ticket se reabre automáticamente

**Contexto:** las 3 acciones manuales (Marcar como resuelto/solucionado, Reabrir Ticket) ya
refrescaban bien vía `location.reload()` en sus popups. El hueco era solo la reapertura
automática por mensaje (Plan 1): no había ningún trigger que avisara al navegador del agente.

**Fases:**
1. `ReabrirPorMensaje` cambia de `void` a `bool` (ver arriba).
2. Broadcast `cambioEstadoTicket` por `SoporteHubActorNegocio.GrupoTicket(id)` en los 3
   call-sites donde se conoce el hub (portal, soporte, y el hub mismo — este último se
   eliminó en la implementación final, ver `IMPLEMENTACION.md`).
3. Cliente (`Index.cshtml`) escucha `cambioEstadoTicket` → `location.reload()`.
4. Verificación manual: abrir el detalle en una pestaña, mandar mensaje desde otra
   (portal/soporte), confirmar que la primera recarga sola con los botones actualizados.

En la implementación se encontró que la página nunca se unía al grupo del ticket
(`UnirseATicket` no se invocaba) — sin eso el listener nunca se hubiera disparado. Se agregó
esa llamada faltante (ver `IMPLEMENTACION.md` → commit `273608ad1`).

## Hallazgo adicional (fuera de los dos planes)

Al revisar el guard de edición se encontró que `soporte_soporteauditoria.idusuario` tiene FK
a `AspNetUsers`, y `SoporteCalificacionActorNegocio` (cierre automático por `CierreDia`)
pasaba el literal `"sistema"` — rompía el insert de auditoría. Corregido en un commit aparte
(`6d1964788`), ver `REGLAS.md` → "Auditoría rota por FK".
