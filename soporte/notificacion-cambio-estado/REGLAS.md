# Reglas de negocio — Correo al cliente por cambio de estado de ticket

Commit: `6b3931d3875578e52c8bf3c31fd87e8d1873e5d0` — feat: envio de correo electronico
cliente en caso de cambio de estado ticket.

## Regla central

Cada vez que un ticket cambia de `Idestado`, se envía un correo al cliente dueño del
ticket con el estado anterior y el nuevo. Un solo método centraliza esto:
`GestionMaestroCRMActorNegocio.EnviarCorreoCambioEstado(gestion, gestionAnterior)`.

## Trigger

- Compara `gestionAnterior.Idestado` vs `gestion.Idestado` (ambos ya con el nuevo valor
  aplicado en memoria, **antes** de este chequeo). Si son iguales, no envía nada — no
  hay "cambio de estado" real.
- Se llama **después** de `GestionMaestroCRMActor.Update(gestion)` en cada punto donde
  el ticket cambia de estado (ver Implementación para la lista completa de puntos).

## Destinatario

- `SoporteUsuarioSistemaActor.ObtenerPorIdtercero(gestion.Terceros_terceromaestroIdtercero.Id)`
  → el usuario portal asociado al tercero dueño del ticket.
- Si no existe usuario portal o no tiene `Email`, **no se envía** (silencioso, sin error).
- No hay distinción de audiencia: siempre es el cliente, nunca el gestor/soporte.

## Contenido

- Asunto: `Cambio de estado para ticket {numeroticket}`.
- Cuerpo HTML fijo: nombre del estado anterior y del nuevo (`EstadoGestionCRM.Nombre`),
  sin plantilla configurable, sin otros datos del ticket (no incluye descripción,
  motivo, ni quién hizo el cambio).

## Dónde dispara (todos los flujos que cambian `Idestado`)

1. **Edición normal del ticket** (`ActualizarDatosSoporte`) — cualquier cambio de estado
   hecho por soporte desde el formulario de edición (dentro de los estados permitidos,
   no cerrados/solucionado).
2. **Marcar como resuelto** (`MarcarComoResuelto`).
3. **Marcar como solucionado** (`MarcarComoSolucionado`) — resuelve el pendiente que
   había quedado documentado en
   [`../cierre-ticket-solucionado/REGLAS.md`](../cierre-ticket-solucionado/REGLAS.md).
4. **Reabrir ticket** (`ReabrirTicket`) — en las dos ramas de auto-cierre por ventana
   vencida (calificación vencida / solucionado vencido), se envía correo del cierre
   automático **antes** de lanzar la excepción que bloquea la reapertura. La reapertura
   exitosa normal también dispara el correo (cambia de estado cerrado a abierto).
5. **Cierre de Día** (`SoporteCalificacionActorNegocio`):
   - `CerrarTicketsVencidosSinCalificar()` — cierre automático por vencimiento de
     ventana de calificación.
   - `CerrarTicketsVencidosSinCalificarSolucion()` — cierre automático por vencimiento
     de ventana de "Solucionado".
   - Usuario de auditoría `"sistema"` en ambos, correo se envía igual que si lo hiciera
     una persona.

## No cubierto por esta regla

- No se notifica al **gestor/soporte** en ningún caso, solo al cliente.
- No hay reglas de privacidad aquí (a diferencia de mensajes/hilos) — el cambio de
  estado siempre es visible para el cliente, no hay "cambio de estado privado".
- Fallos de envío de correo (`EnviarCorreoActorNegocio.EnviarCorreo` retorna `bool`) no
  se validan ni loguean explícitamente en `EnviarCorreoCambioEstado` — si el SMTP falla,
  el cambio de estado igual queda guardado (el correo es best-effort, no transaccional).
- En los cierres automáticos por lote (Cierre de Día), si `EnviarCorreoCambioEstado`
  lanzara una excepción no controlada, el `catch` vacío del `foreach` la traga — no
  detiene el cierre de los demás tickets, pero tampoco queda registro de que el correo
  falló para ese ticket puntual.
