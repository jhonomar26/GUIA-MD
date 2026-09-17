# Plan: Reabrir ticket Solucionado al recibir mensaje  
  
## Contexto  
  
Ticket en estado `Solucionado` queda `Estacerrada = true` con ventana `Tiempolimitesolucionado`. Si nadie hace nada, `CierreDia` lo cierra definitivo al vencer la ventana. Regla acordada: si el ticket está Solucionado y llega un mensaje (de cliente o de soporte), el ticket **pasa a Reabierto** automáticamente, reusando el mismo camino de reapertura que ya usa `ReabrirTicket` manual.  
  
Se descarta la opción de dejar que "no corra el tiempo" (no marcar `Estacerrada` en Solucionado): ese flag se usa en todo el repo como señal de "excluir de listas activas" (`VistaGestionCrmController.cs:186`, `GestionMaestoNegocioViewModel.cs:61`); cambiarlo rompe esas vistas.  
  
De paso corrige un bug real encontrado: el endpoint portal bloquea con 400 cualquier mensaje si `Estacerrada` (sin excepción para Solucionado) — contradice `ObtenerEstadoCierre`, que ya calcula `mensajesDeshabilitados` excluyendo Solucionado. El lado soporte (`EnviarMensajeSoporte`) no valida nada hoy: deja mandar mensajes hasta en tickets cerrados definitivos.  
  
## Fase 1 — Método de reapertura reusable  
  
Archivo: `Negocio/Crm/GestionMaestroCRMActorNegocio.cs`  
  
Agregar `ReabrirPorMensaje(int idGestion)`:  
- Si el estado actual no es Solucionado (`Essolucionado`), no hace nada.  
- Si es Solucionado: obtiene el estado "Abierto" (mismo que usa hoy `ReabrirTicket` manual — confirmar cuál método/valor de `EstadoGestionCRMActor` corresponde), setea `Idestado`, `Estacerrada = false`, `Fechacierre = null`, `Tiempolimitesolucionado = null`.  
- Audita con `SoporteAuditoriaActor.ActualizarGestionTiket(...)` usando `"sistema"` como usuario (mismo patrón que `CerrarTicketsVencidosSinCalificarSolucion`).  
- Llama `EnviarCorreoCambioEstado` para notificar el cambio de estado al cliente.  
- No replica el chequeo de ventana vencida de `ReabrirTicket`: si la ventana ya venció, `CierreDia` habrá cerrado el ticket antes de que llegue el mensaje.  
  
Invocar skill `siian-actor-dapper-metodos` antes de escribir este método (es lógica de negocio en `Negocio/`, sin Dapper).  
  
## Fase 2 — Portal (cliente)  
  
Archivo: `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs:160-220`, acción `EnviarMensaje`.  
  
- Reemplazar el guard `if (ticket.Estacerrada)` (línea 173) por chequeo de `GestionMaestroCRMActorNegocio.ObtenerEstadoCierre(id).mensajesDeshabilitados` (ya excluye Solucionado del bloqueo).  
- Antes de llamar `RegistrarMensajeCliente`, invocar `GestionMaestroCRMActorNegocio.ReabrirPorMensaje(id)`.  
  
## Fase 3 — Soporte (agente)  
  
Archivo: `Negocio/Soporte/SoporteMensajesActorNegocio.cs`, método `EnviarMensajeSoporte` (línea 190).  
  
- Agregar el mismo guard: bloquear si `mensajesDeshabilitados` es true (hoy no valida nada).  
- Antes de `RegistrarMensajeSoporte`, invocar `GestionMaestroCRMActorNegocio.ReabrirPorMensaje(idGestion)`.  
  
## Fase 4 — Verificación  
  
- Ticket Solucionado → cliente o soporte manda mensaje → ticket pasa a estado Abierto, `Estacerrada = false`, reaparece en el dashboard del agente (`VistaGestionCrmController`).  
- Ticket ya cerrado definitivo (`Escerradoconcalificacion` / `Escerradosincalificacion`) → mensaje rechazado en ambos lados (portal ya lo hacía; soporte no lo hacía — queda corregido).  
- Probar manualmente vía la vista/portal, no hay suite de tests automatizada en el proyecto.