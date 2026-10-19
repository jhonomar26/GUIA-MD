# Implementación — Prioridades por SLA

Reglas y alcance: [`REQUERIMIENTO.md`](./REQUERIMIENTO.md), [`ANALISIS.md`](./ANALISIS.md). Plan: [`PLAN.md`](./PLAN.md).

Resultado: el portal solo ofrece prioridades con SLA activo para el motivo elegido. Sin SLA activo no se crea el ticket (se eliminó el tiempo de 72 h).

## Archivos por capa

**`Blip.Data/Soporte/SoportePrioridadActorNegocio.cs`** — `SoportePrioridadActor.ObtenerActivasPorMotivo(int)`: prioridades activas con `EXISTS` de una fila activa de `soporte_soportesla` para el motivo. Orden por nombre. Lista vacía si no hay; nunca `null`.

**`Negocio/Soporte/SoporteSlaActorNegocio.cs`** — `ObtenerFechaLimiteSLA(DateTime, int, int)`: busca con LINQ la fila `Idprioridad == idPrioridadCliente && Activo`; si no hay, `throw new Exception("No hay parametrizacion de SLA para este motivo. Comuniquese con soporte.")`. Se quitaron `horasDefault`, el `try/catch` y el atajo de `idPrioridadCliente <= 0`. Un fallo del calendario se propaga. Único llamador: `SoporteTicketsActorNegocio.cs:44`, sin cambios.

**`PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs`** — `GET api/portal/tickets/opciones/prioridades?idMotivo=` (`GetPrioridadesPorMotivo`) devuelve `[{ Id, Nombre }]`. `GET opciones` ya no incluye `prioridades`.

**`portal-siian`** (`D:\proyectos\portal-siian`):
- `src/api/tickets.js` — `getPrioridadesPorMotivo(idMotivo)`.
- `src/api/queryKeys.ts` — `prioridadesMotivo`.
- `src/pages/NuevoTicket/hooks/usePrioridadesMotivo.ts` — hook nuevo.
- `src/pages/NuevoTicket/hooks/useOpciones.ts` — sin `prioridades`.
- `src/pages/NuevoTicket/NuevoTicket.tsx` — sección Prioridad según motivo: 0 → `Alert` y no se envía; 1 → valor derivado, solo lectura; 2+ → `Select` obligatorio sin `clearable`; al cambiar de motivo se limpia la prioridad.

**`DataGripProjects/fix-soporte-tickets/entregables/14-10-2026-prioridades-sla/motivos-sin-sla.sql`** — consulta de solo lectura de motivos de soporte activos sin SLA activo con prioridad activa.

## Verificación

Resultado obtenido, no el esperado (`GUIA.md`, "Verificación").

| Caso | Resultado |
|---|---|
| T1/T3 — prioridades por motivo (SQL equivalente, demo, 2026-10-14) | Motivo 5 → INMEDIATA; 6, 7, 8 → ALTA; 9 → BAJA, MEDIA; 10 → MEDIA; 11 → BAJA. Cada motivo trae solo sus prioridades parametrizadas. |
| T5 — `motivos-sin-sla.sql` en demo | 0 filas (7 motivos de soporte activos, 8 SLA activos). |
| T5 — `motivos-sin-sla.sql` en producción | **No ejecutado.** Pendiente. |
| T4 — `npm run build` en `portal-siian` | Compila (`✓ built in 28.86s`), solo aviso de tamaño de chunks. |
| T1/T2/T3 — build de la solución (`msbuild`) | **No corrido en esta sesión.** Pendiente de asentar. |
| T2 — `POST /api/portal/tickets` (SLA ok, prioridad 0, prioridad de otro motivo, SLA activo + inactivo, calendario roto) | Probado manualmente por el usuario; **resultado por caso sin asentar**. |
| T3 — Postman `opciones/prioridades` y `opciones` | Probado manualmente por el usuario; **resultado sin asentar**. |
| T4 — navegador (1, varias, 0 prioridades, cambio de motivo) | Probado manualmente por el usuario; **resultado sin asentar**. |

## Pendiente antes de desplegar

- Correr `motivos-sin-sla.sql` en producción y pasar la lista a soporte: cada motivo listado queda bloqueado hasta que se parametrice o se inactive.
- Asentar los resultados manuales y el build de la solución en la tabla de arriba.
- Riesgo conocido: petición manual con prioridad vacía y motivo con SLA recibe el mensaje de falta de parametrización, que no describe bien la causa. Solo se alcanza saltándose el front.
