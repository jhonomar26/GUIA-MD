# Hilos "reply-in-thread" — chat de soporte

| Doc | Contenido |
|---|---|
| [PLAN.md](./PLAN.md) | Plan original por fases (0–7): BD, entidad, negocio, controllers, SignalR, frontend soporte, frontend portal |
| [ADR.md](./ADR.md) | Por qué se decidió self-FK sin tabla nueva, alternativas descartadas, consecuencias |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Cómo quedó implementado: archivo por archivo (Blip.Data/Negocio/Controllers/SignalR/JS), queries clave, qué falta (portal React) |

## Scripts SQL

`C:\Users\User\DataGripProjects\fix-soporte-tickets\entregables\1-09-2026-entregable\hilos-mensajes\`
- `1-soporte-referencia.sql` — columnas `idmensajeraiz` + índices + vista soporte
- `2-vista-mensajes-cliente.sql` — vista filtrada para el cliente (excluye privados)

Verificados contra las entidades C# (`SoporteVistaMensajesTicket.cs` / `...Cliente.cs`):
orden y nombres de columnas coinciden exactamente.

## Código relevante (repo SIIAN)

- Commits: `778c98af6`..`bc13b6670` en `feat/tickets-nuevo-estado`
