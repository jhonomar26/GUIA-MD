# Implementación

## Causa raíz

`StateStoring` de DevExtreme persiste el estado **completo** del grid en `localStorage`,
incluyendo `filterValue`/`filterPanel`/`searchText` (no solo columnas/orden/agrupamiento). En
algún momento se filtró la columna "Estado" con el texto `"EN TRAMITE"` (sin tilde, mayúsculas)
y quedó guardado — se reaplicaba solo en cada carga, sin interacción del usuario. El backend
(`PortalVistaTicketosClienteWebApiController.Get`, filtra con `DataSourceLoader.Load` de
`DevExtreme.AspNet.Data` sobre la lista en memoria) hace comparación de string exacta y
sensible a mayúsculas/tildes contra el valor real en BD, `"En Trámite"` → 0 filas.

Se descartó el backend como causa: `PortalEstadosTicketWebApiController` /
`EstadoGestionCRMActorNegocio.ObtenerEstadoTramite()` resuelven el id por flag booleano
(`estramite = true`), no por nombre, sin riesgo de typo ahí.

## Archivo tocado

- `src/pages/Tickets/Tickets.tsx:285-295` — bloque `<StateStoring>`.

### Cambio

- `storageKey` pasa de `ticketsGridState` a `ticketsGridStateV2` (invalida el estado corrupto
  guardado en el navegador de los usuarios afectados).
- `type="localStorage"` → `type="custom"` con `customLoad`/`customSave`: `customSave` recorta
  `filterValue`, `filterPanel` y `searchText` antes de guardar, así el grid sigue persistiendo
  layout (columnas, orden, agrupamiento) pero nunca vuelve a persistir un criterio de
  filtro/búsqueda.

## Verificación

- `pnpm build` — sin errores.
- `pnpm typecheck` — mismos errores preexistentes de `Tickets.tsx` ya documentados como deuda
  en `docs/arquitectura-general.md` (no relacionados con este cambio).
- Pendiente: prueba manual en navegador con sesión real (filtrar columna Estado, refrescar,
  confirmar que el filtro no persiste; click en cada StatCard de estado y confirmar que trae
  filas).
