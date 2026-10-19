# Implementación — Tiempo de respuesta en el SLA

Reglas y alcance: [`REQUERIMIENTO.md`](./REQUERIMIENTO.md), [`ANALISIS.md`](./ANALISIS.md). Plan: [`PLAN.md`](./PLAN.md).

## Fase 1 (Tarea 1): columna y suma en la fecha límite

Resultado: el SLA guarda `horasrespuesta` y la fecha límite del ticket se calcula con respuesta + resolución en horas hábiles.

### Archivos

**`DataGripProjects/fix-soporte-tickets/scratch/soporte/3-horasrespuesta-sla.sql`** — `ADD COLUMN IF NOT EXISTS horasrespuesta integer NOT NULL DEFAULT 0` y un `SELECT` de verificación.

**`Blip.Data/Soporte/SoporteSla.cs`** — propiedad `Horasrespuesta`, estáticos `HorasrespuestaCampo`/`HorasrespuestaTipo` y parámetro `p_horasrespuesta` al final del constructor.

**`Blip.Data/Soporte/SoporteSlaActor.cs`** — `CrearSelect`, `Insert` y `Update` incluyen la columna.

**`Negocio/Soporte/SoporteSlaActorNegocio.cs`** — `ObtenerFechaLimiteSLA(DateTime, int, int)` pasa `sla.Horasrespuesta + sla.Horasmaximo` a `CalcularFechaLimiteHabil`.

**`PruebaPostgreSQL/Controllers/WebApi/SoporteSlaWebApiController.cs`** — constructor de `SoporteSla` y de `SoporteSlaViewModel` con el argumento nuevo, y los dos bloques del `Put`. Esto es trabajo de la Tarea 2, adelantado.

### Verificación

Resultado obtenido, no el esperado (`GUIA.md`, "Verificación").

| Caso | Resultado |
|---|---|
| Paso 1/7 — script aplicado en demo y `SELECT` de `soporte_soportesla` (2026-10-14) | Columna existe. 9 de 9 filas con `horasrespuesta = 0`. |
| Paso 5 — build de `Negocio.csproj` (incluye `Blip.Data`) | 0 errores. |
| Paso 6 — `verificar-constructores.ps1 -Entidad SoporteSla` | **No corrido.** El script tiene una ruta fija (`D:\GITREP3\SIIAN\`) que no existe en esta máquina. |
| Paso 8 — ticket de incidente alto (2026-10-14, creado desde el portal) | Creación 14/10/2026 09:47, estimado de respuesta 15/10/2026 11:47. El usuario verificó que coincide con el horario hábil y con las horas guardadas en la BD. Horas del SLA no anotadas aquí. |
| Paso 8 — SLA con respuesta 0 (criterio 2) y caso que cruza la jornada/fin de semana (Foco 2) | **No probado.** Pendiente. |
| Build de la solución completa | **No corrido.** |

## Fase 2 (Tarea 2): pantalla de parametrización

**`Blip.Entities/Soporte.ViewModels/SoporteSlaViewModel.cs`** (Windows-1252) — `Horasrespuesta` con `[Range(0, int.MaxValue)]`, parámetro final del constructor y etiqueta "Horas resolución" en `Horasmaximo`.

**`SoporteSlaWebApiController.cs`** — `Get`, `Post` y los dos bloques del `Put` con la columna. `Post` vuelve a pasar `DateTime.Now` como fecha de creación.

**`_TabSla.cshtml`** — columnas "Horas de respuesta", "Horas resolución" y "Total horas" (calculada en JS, solo lectura, fuera del formulario).

| Caso | Resultado |
|---|---|
**Extra (pedido aparte):** en todas las pestañas de `Views/SoporteParametros/_Tab*.cshtml` se fija a la derecha la columna de Editar/Eliminar y se habilita el scroll horizontal (`ColumnAutoWidth(false)`, `ColumnMinWidth(150)`, `ColumnHidingEnabled(false)`). Quedan sin columna fija las de edición por lote (jornada semanal) y sin botones (Calendario, primer grid).

| Paso 4 — build de `PruebaPostgreSQL.csproj` (2026-10-14) | 0 errores. |
| Columna fija y scroll en las 11 pestañas — navegador | **No probado.** Las vistas Razor no las valida el build. |
| Paso 5 — pruebas en navegador (columnas, alta 2 + 4, editar solo "Activo", respuesta -1, ticket previo) | **No probado.** Pendiente. |

## Pendiente

- Pasos 6 y 8 de la Tarea 1 (arriba).
- Aplicar el script en producción **antes** de publicar el código.
- Cliente que borra el valor de "Horas de respuesta" en la grilla: puede llegar `null` a un `int` y fallar el `Post`/`Put`. Verlo en la prueba del navegador.
