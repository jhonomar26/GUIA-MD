# Implementación — Ajustes tickets de soporte (SLA y estados)

> Ver [`PLAN.md`](./PLAN.md) para el diagnóstico y el detalle de cada fase.
> Este documento es el mapa de lo que quedó construido, archivo por archivo.

## Caso 1 — SLA cuenta tiempo en fin de semana → resuelto (Fases 1-3)

Commits: `559bb319f` (feat: calculo de horas restantes), `683087f71` (fix: tiempo sla tickets).

**Fase 1 — Base de datos**

- `soporte_soportevistaticketdetalle` (vista): columna `horasrestantes` pasa a `NULL::numeric`
  fijo — deja de calcularse en reloj de pared. `estadosla` no cambia.
- Script entregado: `DataGripProjects/fix-soporte-tickets/entregables/17-09-2026-entregable/1-vista-dashboard.sql`.

**Fase 2 — Cálculo de horas hábiles**

- `Negocio/Soporte/SoporteCalendarioActorNegocio.cs`: método nuevo
  `CalcularHorasHabilesEntre(desde, hasta)` + sobrecarga
  `CalcularHorasHabilesEntre(desde, hasta, semana, excepciones)` con calendario precargado
  (para no recargar por fila al iterar una lista). Reusa los privados existentes
  `ObtenerJornada` y `ConstruirFranjas`.

**Fase 3 — Consumo en el ViewModel**

- `Negocio/Soporte/SoporteVistaTicketDetalleSlaActorNegocio.cs` (**nuevo**, registrado en
  `Negocio.csproj`): `ObtenerListaPorPermiso` y `ObtenerListaPorGestor`. Trae filas vía
  `SoporteVistaTicketDetalleActor` (Blip.Data), proyecta con `CrearViewModel`, calcula
  `Horasrestantes` con `SoporteCalendarioActorNegocio.CalcularHorasHabilesEntre` (semana
  cargada una vez por request). Si `Estadosla == null` (ticket cerrado/solucionado),
  `Horasrestantes` queda `null`.
- `Blip.Data/Soporte/SoporteVistaTicketDetalleActorNegocio.cs`: se mantiene como
  proyección pura (`CrearViewModel`/`CrearListaViewModel`), sin calendario — `Blip.Data` no
  puede importar `Negocio` (rompería la dirección de dependencias del proyecto).
- `PruebaPostgreSQL/Controllers/WebApi/SoporteVistaTicketDetalleWebApiController.cs`:
  `Get` y `GetIdGestor` llaman a `SoporteVistaTicketDetalleSlaActorNegocio` (Negocio) en vez
  de `SoporteVistaTicketDetalleActor` (Blip.Data) directo.
- `PruebaPostgreSQL/Views/SoporteVistaDashboard/_GridTickets.cshtml`: columna `Fechalimite`
  ahora muestra fecha + hora (`HH:mm`), antes solo fecha — necesario para leer el vencimiento
  del SLA en horas, no solo el día.

**Verificado:** grid interno un lunes → ticket abierto el viernes no descontó sáb/dom;
orden por `Horasrestantes` funciona; sin ciclos de proyecto.

## Caso 2 — Solucionado no pasa a cerrado → pendiente (Fase 4)

No se abordó en este ciclo. Requiere investigación + definición de negocio (ver
`PLAN.md`, Fase 4): estado final esperado, dónde se dispara hoy la transición, y la regla
de cierre (días hábiles sin respuesta / calificación del cliente / manual). Ya existe
`cierre-ticket-solucionado/` en este módulo — revisar esa carpeta antes de arrancar Fase 4,
puede ser la misma funcionalidad y no ameritar una carpeta nueva.

## Deuda anotada (fuera de alcance)

- Los Actor de esta entidad usan `catch (Exception ex) { throw ex; }` (pierde stack trace),
  contra convención del proyecto. No se tocó por no ser parte del pedido.
