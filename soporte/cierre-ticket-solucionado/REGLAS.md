# Reglas de negocio — Cierre de tickets en estado "Solucionado"

Commit: `59fefab0405e995c3ba513224e7b659f5dffcf2b` — feat: cierre de tickets para
tickets en estado solucionado.

## Contexto

Ya existía "Marcar como resuelto" (`MarcarComoResuelto`): cierra el ticket, opcionalmente
con ventana de calificación del cliente (`Tiempocalificacion`). Este commit agrega una
**segunda vía de cierre**, "Marcar como solucionado", pensada para cuando soporte
considera el problema resuelto pero quiere darle al cliente una ventana para reabrir
antes de cerrar en definitiva — sin pedirle calificación.

## Flujo

1. Soporte hace clic en **"Marcar como solucionado"** sobre un ticket abierto.
2. Popup de confirmación con un checkbox **"Esperar ventana de reapertura"**:
   - **Marcado** → el ticket pasa a estado `Solucionado` (`Essolucionado = true`),
     `Estacerrada = true`, con un límite `Tiempolimitesolucionado = hoy + N días`
     (`N` = `SoporteConfiguracion.Diasventanasolucionado`; si es 0 o no configurado,
     no hay límite — `null`).
   - **Desmarcado** → el ticket pasa directo a `Cerrado sin calificación`
     (`Escerradosincalificacion`), `Fechacierre = ahora`, sin ventana.
3. Mientras el ticket está en `Solucionado` y dentro de la ventana, el cliente/soporte
   puede **reabrirlo** (`ReabrirTicket`) igual que cualquier otro ticket cerrado no
   definitivo.
4. **Cierre de Día** (`CierreDiaViewModel`) corre
   `SoporteCalificacionActorNegocio.CerrarTicketsVencidosSinCalificarSolucion()`:
   recorre los tickets en estado `Solucionado` cuya `Tiempolimitesolucionado` ya venció
   y los pasa a `Cerrado sin calificación` (`Fechacierre = ahora`, ventana limpiada).
   Un fallo por ticket no detiene el resto (`catch` vacío dentro del `foreach`).
5. Si alguien intenta reabrir un ticket `Solucionado` cuya ventana **ya venció** (caso
   borde: el Cierre de Día aún no corrió), `ReabrirTicket` lo cierra en el momento
   (`Cerrado sin calificación`) y lanza `InvalidOperationException` — no permite reabrir.

## Reglas / validaciones

- No se puede marcar como solucionado un ticket ya cerrado (`Estacerrada`).
- No se puede marcar como solucionado un ticket que ya está en estado `Solucionado`.
- No se puede marcar como solucionado si hay mensajes sin leer por soporte
  (`ContarMensajesNoLeidosPorSoporte > 0`) — misma regla que `MarcarComoResuelto`.
- Requiere que existan configurados en BD los estados `Essolucionado = true` y
  `Escerradosincalificacion = true` (`EstadoGestionCRM`); si no existen, error explícito.
- El estado `Solucionado` no puede asignarse manualmente desde la edición normal del
  ticket — mensaje guía al usuario a usar "Marcar como Solucionado" (igual patrón que
  el estado `Cerrado`).
- Un ticket `Escerradoconcalificacion` o `Escerradosincalificacion` es definitivo, no
  se puede reabrir (regla ya existente, reutilizada).

## Diferencia con "Marcar como resuelto"

| | Marcar como resuelto | Marcar como solucionado |
|---|---|---|
| Pide calificación del cliente | Sí (opcional) | No |
| Ventana | `Tiempocalificacion` | `Tiempolimitesolucionado` |
| Config de días | `Diasventanacalificacion` | `Diasventanasolucionado` |
| Envía correo de cambio de estado | Sí (`EnviarCorreoCambioEstado`) | Sí (`EnviarCorreoCambioEstado`) |
| Estado destino si no hay ventana/calificación | `Escerradosincalificacion` | `Escerradosincalificacion` |

## Resuelto

`MarcarComoSolucionado` no enviaba correo al cliente — resuelto en commit
`6b3931d3875578e52c8bf3c31fd87e8d1873e5d0`, documentado en
[`../notificacion-cambio-estado`](../notificacion-cambio-estado/).
