# Cierre manual de tickets vencidos (respetando el calendario)

Continuación de [`../soporte-ajustes-dias`](../soporte-ajustes-dias/) (Caso 2 del requerimiento
original: "solucionados que no cambian de estado a cerrado").

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Decisión acordada con soporte: proceso manual, respeta calendario, sin parámetro de fecha |
| [PLAN.md](./PLAN.md) | Diseño técnico y fases: `EsDiaLaboral`, orquestación con telemetría, eliminación del bloque en Cierre de Día, botón manual, ventana en días hábiles |
| [VALIDACION-ESTADO-CIERRE.md](./VALIDACION-ESTADO-CIERRE.md) | Auditoría de `Fechacierre` y filtrado por estado origen en `SoporteCalificacionActorNegocio.cs` — sin cambios de código, comportamiento ya correcto |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Diagramas de flujo (dependencias, ciclo de vida del ticket, ejecución del botón) + mapa archivo por archivo: calendario hábil, orquestación, botón manual, transacción atómica |
| [EXPLICACION.md](./EXPLICACION.md) | Por qué resultó más complejo de lo que parecía — para quien no va a leer código |

Implementado — las 5 fases del plan, más la transacción atómica en auditoría/update (hallazgo
posterior, ver `IMPLEMENTACION.md`).
