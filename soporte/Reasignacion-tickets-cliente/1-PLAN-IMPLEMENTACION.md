# Plan de implementación — Reasignación de tickets entre usuarios cliente

> Complementa a [`PLAN.md`](./PLAN.md) (reglas de negocio). Este documento es el **cómo**, fase por fase, de BD → backend SIIAN → portal React.
>
> **Regla base:** solo el **propietario actual** de un ticket lo reasigna, y únicamente a otro usuario del portal **de su misma empresa**. Si el ejecutor no es el propietario, si no es misma empresa, o si el destino está inactivo → error. Ticket cerrado no se reasigna. Reasignar al mismo usuario = no-op.

---

## Mapa de archivos reales (anclas verificadas)

| Pieza | Ubicación | Estado |
|---|---|---|
| Tabla portal usuarios | `soporte_soporteusuariosistema` (tiene `idempresa`, `activo`) | Existe |
| Ticket | `crm_gestionmaestrocrm.idportalusuario` | Existe |
| Listar usuarios por empresa | `SoporteUsuarioSistemaActor.ObtenerPorIdempresa(int? idempresa)` | Existe — se reusa |
| Correo | `EnviarCorreoActorNegocio.EnviarCorreo(para, asunto, mensaje, isHtml)` | Existe — se reusa |
| Controller portal tickets | `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs` | Existe — se extiende |
| Lógica negocio portal | `Negocio/Portal/PortalSoporteTicketActorNegocio.cs` | Existe — se extiende |
| API portal (axios) | `portal-siian/src/api/tickets.js` | Existe — se extiende |
| Tipos ticket | `portal-siian/src/shared/types/tickets.ts` | Existe — se extiende |
| Detalle ticket UI | `portal-siian/src/pages/DetalleTicket/DetalleTicket.tsx` | Existe — se extiende |
| Grid interno soporte | `PruebaPostgreSQL/Views/SoporteVistaDashboard/_GridTickets.cshtml` | Existe — historial (fase opcional) |

---

## Fase 0 — Base de datos

Crear tabla dedicada de historial de reasignaciones.

```sql
create table soporte_soporteticketreasignacion
(
    id                      serial primary key,
    idgestion               integer not null
        references crm_gestionmaestrocrm on delete cascade,
    idusuarioanterior       integer
        references soporte_soporteusuariosistema on delete set null,
    idusuarionuevo          integer not null
        references soporte_soporteusuariosistema on delete set null,
    idportalusuarioejecutor integer not null
        references soporte_soporteusuariosistema on delete set null,
    observacion             text,
    fecha                   timestamp default now() not null
);

create index idxreasignacion_gestion on soporte_soporteticketreasignacion (idgestion);
create index idxreasignacion_fecha   on soporte_soporteticketreasignacion (fecha);
```

- `idusuarioanterior` nullable: cubre ticket que aún no tenía usuario asignado.
- `on delete cascade` en `idgestion`: si se borra el ticket, se va su historial.
- **Verificación:** correr el DDL en la BD de pruebas, confirmar tabla e índices.

---

## Fase 1 — Entidad + Actor (Blip.Data)

Invocar skill `siian-actor-pattern` antes de escribir.

**Archivos nuevos** en `Blip.Data/Soporte/`:
1. `SoporteTicketReasignacion.cs` — POCO + metadata estática (`NombreTabla`, `{Prop}Campo`, `{Prop}Tipo`) + constructores. Sigue el patrón de las demás entidades soporte.
2. `SoporteTicketReasignacionActor.cs` — `partial static`, con los métodos que realmente se usan (no los 12 completos si no hacen falta):
   - `Insert(item)` — registra la reasignación.
   - `ObtenerPorIdgestion(int idgestion)` — historial de un ticket, orden `fecha DESC`, para mostrar en portal y/o soporte.

**Registrar** ambos `.cs` en `Data.csproj` (`<Compile Include="..." />`) — obligatorio en este proyecto.

- **Verificación:** compila la solución.

---

## Fase 2 — Lógica de negocio (ActorNegocio)

Invocar skill `siian-actor-dapper-metodos`. Método nuevo en `Negocio/Portal/PortalSoporteTicketActorNegocio.cs`:

```
public static void ReasignarTicket(int idGestion, int idPortalUsuarioEjecutor,
                                   int idUsuarioDestino, string observacion)
```

Orquestación (lógica de negocio pura, sin Dapper directo):

1. **Cargar ticket** `GestionMaestroCRMActor.ObtenerPorIdSinVerificarExistencia(idGestion)`.
   - Null / `Esticketsoporte != true` → `throw "Ticket no encontrado"`.
2. **Ticket cerrado:** `GestionMaestroCRMActorNegocio.EstaCerradoDefinitivamente(idGestion)` → `throw "No se puede reasignar un ticket cerrado"`.
3. **Pertenencia (decisión final):** el ejecutor debe ser el **propietario actual** del ticket — `ticket.Idportalusuario != idPortalUsuarioEjecutor` → `throw "Solo el propietario del ticket puede reasignarlo"`. No basta con pertenecer a la misma empresa; debe ser quien lo tiene asignado hoy.
4. **No-op:** `idPortalUsuarioEjecutor == idUsuarioDestino` → `return` silencioso (sin log ni correo).
5. **Misma empresa (regla core):**
   - `ejecutor = SoporteUsuarioSistemaActor.ObtenerPorIdSinVerificarExistencia(idPortalUsuarioEjecutor)`.
   - `destino = SoporteUsuarioSistemaActor.ObtenerPorIdSinVerificarExistencia(idUsuarioDestino)`.
   - Null → `throw "Usuario destino no existe"`.
   - `destino.Idempresa != ejecutor.Idempresa` → `throw "Solo puedes reasignar a usuarios de tu misma empresa"`.
6. **Destino activo:** `destino.Activo != true` → `throw "El usuario destino está inactivo"`.
7. **Aplicar cambio:**
   - `idUsuarioAnterior = ticket.Idportalusuario`.
   - `ticket.Idportalusuario = idUsuarioDestino`.
   - `GestionMaestroCRMActor.Update(ticket)`.
8. **Registrar historial:** `SoporteTicketReasignacionActor.Insert(...)` con anterior/nuevo/ejecutor/observacion.
9. **Correo (best-effort):** obtener email del destino (`destino.Email`) y enviar aviso con `EnviarCorreoActorNegocio.EnviarCorreo(...)`. Envolver en try/catch propio para que un fallo de correo **no** revierta la reasignación (o loguear y continuar).

`catch (Exception) { throw; }` en el método externo (preserva stack).

- **Verificación:** compila; prueba manual vía endpoint (fase 3).

---

## Fase 3 — Endpoints WebApi portal

Extender `PortalTicketsWebApiController.cs` (`[PortalApiAuthorize]`, ya expone `IdPortalUsuario` / `IdTercero`).

**3.1 — Listar usuarios destino** (para poblar el selector, ya filtrado por empresa y excluyendo al actual):
```
GET  api/portal/tickets/{id:int}/usuarios-reasignacion
```
- Escopado al ticket (no global) — valida `TicketPertenececeACliente` primero, igual que `GetMensajes`/`GetCalificacion`.
- El filtro de permisos (empresa + activo + excluir al ejecutor) vive en SQL, no en LINQ en memoria: `SoporteUsuarioSistemaActor.ObtenerParaReasignacion(idEmpresa, idExcluir)` (en `Blip.Data/Soporte/SoporteUsuarioSistemaActorNegocio.cs`) hace `JOIN` directo contra `terceros_terceromaestro` y proyecta a `UsuarioReasignacionViewModel { Id, Nombre, Email }` — evita el N+1 de la navegación lazy.
- El controller recibe `DataSourceLoadOptions loadOptions` y pasa la lista ya filtrada por `DataSourceLoader.Load(...)` (mismo patrón que `SoporteVistaTicketDetalleWebApiController.Get`), aprovechando el paginado/orden que DevExtreme ya soporta sin código adicional.

**3.2 — Ejecutar reasignación:**
```
POST api/portal/tickets/{id:int}/reasignar
body: { idUsuarioDestino: int, observacion?: string }
```
- Llama `PortalSoporteTicketActorNegocio.ReasignarTicket(id, IdPortalUsuario, dto.IdUsuarioDestino, dto.Observacion)`.
- Errores de negocio → `BadRequest` con `{ mensaje }`; éxito → `OK { mensaje: "Ticket reasignado" }`.
- Patrón try/catch idéntico a los demás métodos del controller.

**3.3 — Historial de reasignaciones** (opcional en portal, útil también en soporte):
```
GET  api/portal/tickets/{id:int}/reasignaciones
```
- Valida pertenencia, llama `SoporteTicketReasignacionActor.ObtenerPorIdgestion(id)`, mapea a `{ usuarioanterior, usuarionuevo, ejecutor, observacion, fecha }` (nombres resueltos vía tercero).

Nuevo DTO `ReasignarTicketDto { int IdUsuarioDestino; string Observacion; }` en el proyecto de ViewModels correspondiente.

- **Verificación:** probar los 3 endpoints con token de portal (Postman / navegador). Confirmar validación de empresa distinta devuelve error.

---

## Fase 4 — Capa API portal (React)

`portal-siian/src/api/tickets.js` — agregar:
```js
export const getUsuariosReasignacion = (id) =>
  client.get(`/tickets/${id}/usuarios-reasignacion`).then(r => r.data)

export const reasignarTicket = (id, idUsuarioDestino, observacion = "") =>
  client.post(`/tickets/${id}/reasignar`, { idUsuarioDestino, observacion }).then(r => r.data)

export const getReasignaciones = (id) =>
  client.get(`/tickets/${id}/reasignaciones`).then(r => r.data)   // si se muestra historial
```

`portal-siian/src/shared/types/tickets.ts` — agregar tipos:
```ts
export interface UsuarioReasignacion { id: number; nombre: string; email: string }
export interface Reasignacion {
  usuarioanterior: string | null
  usuarionuevo: string
  ejecutor: string
  observacion: string | null
  fecha: string
}
```

- **Verificación:** typecheck del portal (`tsc` / build).

---

## Fase 5 — UI portal (DetalleTicket.tsx)

Invocar reglas de patrones React del portal (Mantine). Piezas:

1. **Hook** `useReasignarTicket(id, onSuccess)` en `pages/DetalleTicket/hooks/` — carga usuarios destino (react-query), maneja `SelectBox` + observación, ejecuta `reasignarTicket`, muestra `notifications`, refetch del ticket al terminar.
2. **Modal / sección** de reasignación:
   - Botón "Reasignar ticket" — visible solo si `!cerrado` (reusa `estaCerrado`). Colocarlo cerca de la sección "Gestor Asignado" o en el header.
   - Modal Mantine: `Select` de usuarios de la empresa (data del hook), `Textarea` observación (opcional), botón confirmar.
   - Al confirmar → `reasignarTicket` → notificación de éxito → `refetch()` (el ticket ya reflejará el nuevo `idportalusuario`, cambiando `esPropio`).
3. **Consideración `esPropio`:** hoy `esPropio = ticket.idportalusuario === usuario?.id` gobierna quién puede escribir en el chat / subir archivos. Tras reasignar a otro, el ejecutor deja de ser `esPropio` → coherente con la regla (el ticket pasa a otro dueño). Confirmar que esto es el comportamiento deseado; si el cliente debe poder reasignar aunque no sea el dueño, la visibilidad del botón se basa en "misma empresa", no en `esPropio`.
4. *(Opcional)* Sección de historial de reasignaciones usando `getReasignaciones`.

- **Verificación:** correr el portal, reasignar un ticket a un usuario de la misma empresa (éxito + correo), intentar a otra empresa (error), verificar que el ticket cerrado no muestra el botón.

---

## Fase 6 — Visibilidad en soporte interno (opcional)

`_GridTickets.cshtml` ya tiene un popup "verHistorial" (auditoría genérica). Si soporte necesita ver también las reasignaciones de cliente:
- Agregar botón/tab que consuma un WebApi interno equivalente a `ObtenerPorIdgestion`, o
- Incluir las reasignaciones dentro del popup de historial existente.

Se deja como fase separada porque no bloquea el flujo del cliente y depende de si soporte lo pide.

---

## Orden de ejecución y verificación incremental

1. Fase 0 (BD) → verificar tabla.
2. Fase 1 (entidad+actor) → compila.
3. Fase 2 (negocio) → compila.
4. Fase 3 (endpoints) → probar con token, incluida la validación de empresa.
5. Fase 4 (api+tipos) → typecheck.
6. Fase 5 (UI) → prueba end-to-end en portal.
7. Fase 6 (soporte) → solo si se requiere.

Cada fase se verifica antes de pasar a la siguiente (planes incrementales).
