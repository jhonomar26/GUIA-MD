# Implementación — Reasignación de tickets entre usuarios cliente

> Reference: qué quedó construido, archivo por archivo. Refleja el código en `feat/tickets-nuevo-estado` (repo `SIIAN`) y `portal-siian` (repo aparte, `D:\proyectos\portal-siian`). Se actualiza si el código cambia — no es historia, es estado actual.

Desarrollo terminado (backend + portal + historial soporte interno).

## Base de datos

- Tabla `soporte_soporteticketreasignacion` (`idgestion`, `idusuarioanterior` nullable, `idusuarionuevo`, `idportalusuarioejecutor`, `observacion`, `fecha`) — igual al DDL del plan. No versionada como `.sql` en el repo, corrida directo en BD.
- Vista `soporte_vistareasignacionesticket` — resuelve nombres (usuario anterior/nuevo/ejecutor) vía join contra `soporte_soporteusuariosistema` + `terceros_terceromaestro`, para no repetir la resolución de nombres en cada Actor que consume el historial (portal y soporte interno comparten la vista).

## Backend — SIIAN (`D:\soporte\SIIAN`)

| Archivo | Contenido |
|---|---|
| `Blip.Data/Soporte/SoporteTicketReasignacion.cs` | Entidad de la tabla de historial. |
| `Blip.Data/Soporte/SoporteTicketReasignacionActor.cs` | Actor: `Insert`, `ObtenerPorIdgestion`. |
| `Blip.Data/Soporte/VistaReasignacionesTicket.cs` + `VistaReasignacionesTicketActor.cs` | Entidad/Actor de solo lectura sobre la vista SQL (nombres resueltos). |
| `Blip.Data/Soporte/SoporteTicketReasignacionActorNegocio.cs` | Delgado — delega a `PortalSoporteTicketActorNegocio`. |
| `Blip.Data/Soporte/VistaReasignacionesTicketActorNegocio.cs` | Query de historial reusada por los dos controllers (portal y soporte interno). |
| `Blip.Data/Soporte/SoporteUsuarioSistemaActorNegocio.cs` → `ObtenerParaReasignacion(idEmpresa, idExcluir)` | Lista usuarios destino: misma empresa, activos, excluye al ejecutor. Join directo en SQL (evita N+1 de navegación lazy). |
| `Negocio/Portal/PortalSoporteTicketActorNegocio.cs` → `ReasignarTicket(idGestion, idPortalUsuarioEjecutor, idUsuarioDestino, observacion)` | Orquestación completa: ticket existe y es de soporte → no cerrado (`GestionMaestroCRMActorNegocio.EstaCerradoDefinitivamente`) → ejecutor es el propietario actual (`ticket.Idportalusuario`) → no-op si destino = ejecutor → destino existe y activo → misma empresa que el ejecutor → aplica `Update` sobre el ticket → inserta historial → envía correo al destino en try/catch propio (no revierte la reasignación si falla). `catch (Exception) { throw; }` preserva stack. |
| `Blip.Entities/Crm.ViewModels/ReasignarTicketDto.cs` | `{ IdUsuarioDestino, Observacion }` — body del POST. |
| `Blip.Entities/Soporte.ViewModels/UsuarioReasignacionViewModel.cs` | `{ Id, Nombre, Email }` — para el selector del portal. |
| `Blip.Entities/Soporte.ViewModels/VistaReasignacionesTicketViewModel.cs` | Historial para grid de **soporte interno**. |
| `Blip.Entities/Soporte.ViewModels/VistaReasignacionesTicketPortalViewModel.cs` | Historial para el **portal** — mismo dato, shape/nombres propios para ese consumidor. |
| `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs` → `ReasignarTicket(id, dto)` | `POST api/portal/tickets/{id}/reasignar`. Errores de negocio → `BadRequest { mensaje }`; éxito → `OK { mensaje }`. |
| `PruebaPostgreSQL/Controllers/WebApi/Portal/SoporteUsuarioSistemaWebApiController.cs` → `GetUsuariosReasignacion` | `GET api/portal/tickets/{id}/usuarios-reasignacion`. Valida `TicketPertenececeACliente` antes de listar. |
| `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalReasignacionesTicketWebApiController.cs` | `GET api/portal/tickets/{id}/reasignaciones` — historial paginado (DevExtreme `DataSourceLoadOptions`) para el portal. |
| `PruebaPostgreSQL/Controllers/WebApi/VistaReasignacionesTicketWebApiController.cs` | `GET` interno para el grid de soporte (no requiere pertenencia de cliente, es vista de soporte). |
| `PruebaPostgreSQL/Views/SoporteDetalle/_TabHistorialCliente.cshtml` + `Index.cshtml` | Tab "Historial cliente" en el detalle de ticket de soporte interno — grid DevExtreme contra `VistaReasignacionesTicketWebApiController`, filtrado por `Idgestion`. |

**Endpoints portal expuestos:**
- `GET /api/portal/tickets/{id}/usuarios-reasignacion`
- `POST /api/portal/tickets/{id}/reasignar` → `{ idUsuarioDestino, observacion? }`
- `GET /api/portal/tickets/{id}/reasignaciones`

## Frontend — portal (`D:\proyectos\portal-siian`)

| Archivo | Contenido |
|---|---|
| `src/api/tickets.js` → `reasignarTicket(id, idUsuarioDestino, observacion)` | Wrapper del POST. Los dos GET (usuarios y reasignaciones) **no** pasan por `api/tickets.js`: los componentes usan `createStore` de `devextreme-aspnet-data-nojquery` apuntando directo a la URL (`/api/portal/tickets/{id}/usuarios-reasignacion` y `/reasignaciones`), con el JWT inyectado en `onBeforeSend`. Da paginado/filtro DevExtreme gratis en el DataGrid/SelectBox, a costa de no tiparse en `tickets.ts`. |
| `src/pages/DetalleTicket/hooks/useReasignarTicket.ts` | Hook: estado del modal (`opened`, `idUsuarioDestino`, `observacion`), `usuariosDataSource` (DevExtreme store), `useMutation` de react-query para `reasignarTicket`, notificación de éxito/error. |
| `src/pages/DetalleTicket/components/ModalReasignar.tsx` | Modal Mantine: alerta de aviso ("perderás acceso al ticket"), `SelectBox` de usuarios (búsqueda por nombre/email), `Textarea` de observación opcional, botones cancelar/confirmar. |
| `src/pages/DetalleTicket/components/SeccionHistorialReasignaciones.tsx` | `DataGrid` DevExtreme (paginado 5) con columnas fecha/de/a/ejecutado por/observación, dentro de un tab "Historial" en el detalle. |
| `src/pages/DetalleTicket/DetalleTicket.tsx` | Botón "Reasignar ticket" (visible solo si `esPropio && !cerrado`), tab "Historial" agregado a los tabs existentes (Detalles/Gestor), monta `ModalReasignar`. |

**Resolución del punto abierto en el plan (`esPropio` tras reasignar):** al confirmar, `useReasignarTicket` navega a `/tickets` (`navigate('/tickets')`) en vez de hacer `refetch()` en la misma pantalla — evita mostrar por un instante un detalle donde el usuario ya perdió `esPropio` (chat/adjuntos se habrían bloqueado in-place).

## Desviaciones vs. `1-PLAN-IMPLEMENTACION.md`

- Vista SQL (`soporte_vistareasignacionesticket`) en vez de resolver nombres a mano en cada ActorNegocio.
- Endpoint de usuarios-destino vive en un controller propio (`SoporteUsuarioSistemaWebApiController`), no dentro de `PortalTicketsWebApiController` — mismo `RoutePrefix`, distinto archivo.
- Dos ViewModels de historial (uno para portal, otro para soporte interno) en vez de uno compartido.
- No se agregaron tipos a `shared/types/tickets.ts` para usuarios/historial — esas dos pantallas usan DevExtreme `createStore` directo contra el endpoint, sin pasar por capa de tipos TS.
- Tras reasignar, el portal navega fuera del detalle en vez de hacer `refetch()` in-place.

## Pendiente

- Confirmar que el DDL (tabla + vista) esté aplicado en BD de producción, no solo en pruebas (no está versionado en git).
