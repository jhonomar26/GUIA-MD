# Plan: Refrescar UI del agente cuando el ticket se reabre automáticamente por mensaje  
  
## Contexto  
  
Las 3 acciones manuales de estado (Marcar como resuelto, Marcar como solucionado, Reabrir ticket) ya funcionan bien: sus popups (`_PopupMarcarResuelto.cshtml`, `_PopupMarcarSolucionado.cshtml`, `_PopupReabrirTicket.cshtml`) hacen `location.reload()` tras el POST exitoso — es la convención ya establecida en el proyecto (usada también en `_PopupEditarTicket.cshtml` y `formUtils.js:52`).  
  
El bug real es solo el 4to caso: `GestionMaestroCRMActorNegocio.ReabrirPorMensaje` (agregado para reabrir el ticket Solucionado cuando llega un mensaje) cambia el estado en servidor pero **no hay ningún trigger que le avise al navegador del agente** — no es una acción de popup en esa misma pestaña, sino un efecto lateral de que el cliente mandó un mensaje. Los botones (`Marcar como resuelto` / `Marcar como solucionado` / `Reabrir Ticket`) quedan con el `.Disabled(...)` que trajeron al cargar la página (`Views/SoporteDetalle/Index.cshtml:122-164`, valores fijados server-side vía `ViewBag.TicketEsCerrado` / `ViewBag.TicketPuedeReabrirse` / `ViewBag.PuedeReabrir`), desincronizados del estado real hasta que alguien recargue manualmente.  
  
Mejor opción: reusar la misma convención A (`location.reload()`) que ya usan los otros 3 flujos, pero disparada por un push de SignalR — el mismo hub/grupo que ya existe para mensajes (`SoporteHub`, grupo `GrupoTicket(id)`, al que la página ya está unida vía `UnirseATicket`). Se descarta reimplementar la lógica de habilitar/deshabilitar cada botón en JS (duplicaría las reglas de negocio que hoy solo viven en el `ViewBag` calculado en el controller — riesgo de que se desincronicen) y se descarta forzar reload de todos los flujos existentes (fuera de alcance, ya funcionan).  
  
## Fase 1 — `ReabrirPorMensaje` devuelve si reabrió  
  
Archivo: `Negocio/Crm/GestionMaestroCRMActorNegocio.cs`  
  
Cambiar el tipo de retorno de `void` a `bool`:  
- `return false` en el early-return (`!estadoActual.Essolucionado`).  
- En el caso de ventana vencida (no reabre, cierra definitivo): también cambia estado, así que se recomienda `return true` (ver Fase 4, verificación).  
- `return true` cuando efectivamente reabre a "Reabierto".  
  
Los 3 callers necesitan este valor para decidir si notifican por hub (Negocio no conoce SignalR, así que el broadcast se hace afuera).  
  
## Fase 2 — Broadcast del cambio en los call sites  
  
Archivos:  
- `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs` (`EnviarMensaje`, ~línea 179)  
- `PruebaPostgreSQL/Hubs/SoporteHub.cs` (`EnviarMensajeCliente`, ~línea 89)  
- `PruebaPostgreSQL/Controllers/WebApi/SoporteMensajesWebApiController.cs` (`EnviarMensajeSoporte`)  
  
Después de llamar `ReabrirPorMensaje(id, ...)`, si devolvió `true`:  
  
```csharp  
GlobalHost.ConnectionManager.GetHubContext<SoporteHub>()  
    .Clients.Group(SoporteHubActorNegocio.GrupoTicket(id))    .cambioEstadoTicket();  
```  
  
En `SoporteHub.cs` (ya estamos dentro del hub) se usa `Clients.Group(...)` directo, sin `GetHubContext`.  
  
Nota: `ReabrirPorMensaje` también se llama hoy desde `PortalSoporteTicketActorNegocio.RegistrarMensajeCliente` (Negocio puro) y de forma duplicada desde el controller REST del portal — duplicidad ya señalada como redundante pero inofensiva. El broadcast solo se agrega donde el hub es accesible (los 3 puntos de arriba).  
  
## Fase 3 — Cliente escucha el evento  
  
Archivo: `Views/SoporteDetalle/Index.cshtml`, bloque de conexión al hub (líneas ~275-312).  
  
Agregar junto a los handlers existentes (`actualizarBadgeMensajes`, etc.):  
  
```javascript  
soporteHub.client.cambioEstadoTicket = function () {  
    location.reload();};  
```  
  
Mismo patrón (`location.reload()`) que ya usan los popups — consistente, sin lógica nueva de estado en el cliente. El grupo `GrupoTicket(idGestion)` ya existe y la página ya está unida a él vía `UnirseATicket`, no se necesita infraestructura nueva de grupos.  
  
## Fase 4 — Verificación  
  
- Abrir el detalle de un ticket en estado Solucionado en el panel de soporte (agente), y desde el portal del cliente (u otra pestaña) mandar un mensaje a ese ticket.  
- La pestaña del agente debe recargar sola y mostrar los botones ya actualizados (Reabrir Ticket desaparece, Marcar como resuelto/solucionado vuelven a estar habilitados).  
- Confirmar que el reload NO se dispara cuando `ReabrirPorMensaje` no hizo nada (ticket no estaba Solucionado) — no debe recargar en el flujo normal de mensajería.  
- Probar el caso de ventana vencida (mensaje llega tarde, ticket ya no se reabre sino que se cierra definitivo): el evento también debe dispararse, porque el estado igual cambió.