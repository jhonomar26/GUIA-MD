# Reglas — Ajustes al estado "Solucionado"

## Qué estaba roto

1. **Mensajes no reabrían el ticket.** Un ticket `Solucionado` sigue con `Estacerrada = true`
   y una ventana `Tiempolimitesolucionado`. Si el cliente o soporte seguían conversando, el
   mensaje ni se bloqueaba ni reabría nada — el ticket llegaba igual al cierre automático de
   `CierreDia` aunque hubiera actividad reciente.
2. **La edición normal podía tocar el estado Solucionado.** `ActualizarDatosSoporte` solo
   bloqueaba *entrar* a Solucionado desde el form de edición, pero no bloqueaba *salir* de
   Solucionado hacia cualquier otro estado — dejaba `Tiempolimitesolucionado`/`Fechacierre`
   desincronizados porque se saltaba el proceso de `MarcarComoSolucionado`/`ReabrirTicket`.
3. **UI del agente no se enteraba.** Cuando el ticket se reabría solo (por mensaje), no había
   ningún push al navegador del agente — los botones (`Marcar como resuelto` / `Marcar como
   solucionado` / `Reabrir Ticket`) quedaban con el estado que trajeron al cargar la página.
4. **Auditoría rota por FK.** `soporte_soporteauditoria.idusuario` tiene FK a `AspNetUsers`.
Pasar literales como `"sistema"` o `"cliente"` rompía el insert (no existen esos usuarios).

## Reglas correctas

- **Mensaje en ticket Solucionado** (cliente o soporte) → si la ventana sigue vigente, el
  ticket pasa a `Reabierto` automáticamente (`ReabrirPorMensaje`). Si la ventana ya venció,
  se cierra definitivo (`Escerradosincalificacion`) y el mensaje se rechaza.
- **El estado Solucionado solo cambia por botón**, en cualquier dirección:
  - Entrar → `MarcarComoSolucionado` (calcula la ventana).
  - Salir → `ReabrirTicket` (valida permiso/vigencia, limpia la ventana).
  - La edición normal del ticket (`ActualizarDatosSoporte`) tira `InvalidOperationException`
    si el form intenta cambiar el estado en cualquiera de los dos sentidos.
- **UI del agente se refresca sola.** Cuando `ReabrirPorMensaje` reabre el ticket, el
  controller que la llamó emite `cambioEstadoTicket` por el grupo SignalR `GrupoTicket(id)`
  (mismo grupo que ya usan los mensajes). El cliente hace `location.reload()` — mismo patrón
  que ya usan los popups de acciones manuales, sin reimplementar la lógica de habilitar/
  deshabilitar cada botón en JS.
- **Auditoría de cambios automáticos/de sistema**: pasar `idusuario = null` (columna nullable,
  `ON DELETE SET NULL`). El query de historial ya interpreta `idusuario` e `idportalusuario`
  ambos `NULL` como "Sistema" — nunca inventar un id de usuario que no exista en `AspNetUsers`.
  Cuando el mensaje viene del portal, se audita con el `idportalusuario` real (no con un
  string), porque esa columna sí tiene su propia FK a `soporte_soporteusuariosistema`.

## Decisiones descartadas

- Que el ticket Solucionado no cuente como cerrado (`Estacerrada = false`): se descartó
  porque `Estacerrada` se usa en todo el repo como señal de "excluir de listas activas"
  (dashboard del agente, listados de gestiones abiertas) — cambiarlo rompe esas vistas.
- Reimplementar en JS la lógica de qué botón mostrar/ocultar según el estado: se descartó por
  duplicar reglas de negocio que hoy solo viven en el `ViewBag` calculado en el controller.
  Se prefirió disparar un `location.reload()` vía push de SignalR, igual que los flujos
  manuales ya existentes.
