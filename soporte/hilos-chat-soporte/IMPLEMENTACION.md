# Implementación: Hilos "reply-in-thread" en chat de soporte

> Estado: **implementado y funcionando** en SIIAN (MVC/DevExtreme). Backend del portal
> cliente (React) ya expone los endpoints necesarios, pero el frontend React **aún no
> los consume** — ver sección final.

Plan original: [`PLAN.md`](./PLAN.md). Este documento describe **cómo quedó
implementado**, no el plan.

Commits: `778c98af6` → `bc13b6670` (rama `feat/tickets-nuevo-estado`), 7 commits:
```
778c98af6 feat: hilos de chat en soporte — fase 1-2-3-4-5 (entidad, vista, negocio, controllers, hub)
72a60ceed fix: métodos Dapper para hilos — ObtenerPrincipal* y ObtenerHilo* con filtros
43b2894c5 feat: fase 3.1 hilos - validar mensaje raiz y ObtenerHilo en Negocio/Soporte
f922a886b feat: envio de mensajes en hilo parte de soporte
0951c85a8 fix: contador de mensajes nuevos en pestaña del detalle de ticket
58156e037 feat: archivos en hilos de soporte (subida, listado separado, live push) + fix contador no leidos
52b921680 feat: archivos de hilo en portal cliente (endpoint gethilo, filtro privados)
bc13b6670 feat: archivos en hilos
```

## Modelo de datos

Sin tabla nueva. Columna self-FK nullable en dos tablas:

```
soporte_soportemensajes.idmensajeraiz  → int?, FK a soporte_soportemensajes(id)
soporte_soportearchivos.idmensajeraiz  → int?, FK a soporte_soportemensajes(id)
```

- `idmensajeraiz IS NULL` → mensaje/adjunto de la conversación **principal** (raíz).
- `idmensajeraiz = X` → respuesta que cuelga del hilo del mensaje `X`.
- Solo 1 nivel: una respuesta no puede ser raíz de otra (`ValidarMensajeRaiz` lo bloquea).
- Las vistas `soporte_soportevistamensajesticket` y `...cliente` ganaron `idmensajeraiz`
  + columna calculada `cantrespuestas` (para pintar "N respuestas" sin query extra).

## Capas tocadas

### Blip.Data/Soporte/ (entidades + Actor Dapper puro)

| Archivo | Rol |
|---|---|
| `SoporteMensajes.cs` | + `int? Idmensajeraiz` + nav lazy-load a su propio raíz |
| `SoporteMensajesActor.cs` | CRUD incluye `Idmensajeraiz`; + `ObtenerPorIdmensajeraiz` |
| `SoporteMensajesActorNegocio.cs` (partial Dapper) | Queries clave, ver abajo |
| `SoporteArchivos.cs` / `Actor.cs` | Mismo patrón que mensajes (espejo de columna) |
| `SoporteArchivosActorNegocio.cs` | Queries de adjuntos por raíz/portal, ver abajo |
| `SoporteVistaMensajesTicket*.cs` / `...Cliente*.cs` | Vistas + `Idmensajeraiz`/`Cantrespuestas` |

Queries base (`Blip.Data/Soporte/SoporteMensajesActorNegocio.cs`):

- **Principal**: `ObtenerPrincipalPorIdgestionPaginado(id, skip, take, esPortal)` →
  `WHERE idgestion=@id AND idmensajeraiz IS NULL [AND esprivado=false] ORDER BY fechaenvio DESC OFFSET/LIMIT`.
  Versión soporte (`...Soporte`) omite el filtro de privacidad.
- **Hilo**: `ObtenerHiloPorRaiz(idMensajeRaiz, esPortal)` →
  `WHERE (id=@raiz OR idmensajeraiz=@raiz) [AND esprivado=false] ORDER BY fechaenvio ASC`
  (trae cabecera + respuestas en una sola query). Versión `...Soporte` sin filtro privado.

Adjuntos (`SoporteArchivosActorNegocio.cs`):
- Principal: `ObtenerListaConNombreAutorPorIdgestion` (`AND idmensajeraiz IS NULL`).
- Hilo: `ObtenerListaConNombreAutorPorIdmensajeraiz(idMensajeRaiz)` (`WHERE idmensajeraiz=@raiz`).
- Twins `...Portal` agregan `AND esprivado = false` para ambos casos (R1/R2 del plan).

### Negocio/ (orquestación, sin Dapper)

- `Negocio/Soporte/SoporteMensajesActorNegocio.cs`: `ValidarMensajeRaiz(idGestion, idRaiz)`
  valida que el raíz exista, sea del mismo ticket y **sea raíz** (`Idmensajeraiz == null`)
  antes de registrar. `ObtenerHilo(idMensajeRaiz)` mapea a ViewModels para el endpoint soporte.
  `EnviarMensajeSoporte(...)` arma el DTO de push (no publica el hilo él mismo, delega al hub/controller).
- `Negocio/Soporte/SoporteArchivosActorNegocio.cs`: `SubirArchivo`/`SubirArchivoPortal` validan
  el raíz vía el método de mensajes antes de guardar. `ObtenerArchivosHiloPortal(idRaiz, idPortalUsuario)`
  resuelve el ticket dueño a partir del mensaje raíz y valida acceso del cliente antes de listar.
- `Negocio/Portal/PortalSoporteTicketActorNegocio.cs`: `ObtenerMensajesTicket` usa el query
  principal con `esPortal:true`. `RegistrarMensajeCliente(..., idMensajeRaiz)` valida antes de insertar.
- `Negocio/Portal/SoporteVistaMensajesTicketClienteActorNegocio.cs`: `ObtenerHilo(idRaiz, idPortalUsuario)`
  trae el hilo primero, deriva `idGestion` de la primera fila para autorizar (`TicketPertenececeACliente`),
  devuelve null si no autorizado o vacío.

### Controllers WebApi

| Controller | Qué agrega |
|---|---|
| `SoporteMensajesWebApiController` | `IdMensajeRaiz` en el DTO de envío; push incluye `Idmensajeraiz`; nuevo `GET ObtenerHilo(idMensajeRaiz)` (audiencia soporte, ve privados) |
| `SoporteArchivosWebApiController` | `SubirArchivo` acepta `idMensajeRaiz`; nuevo `GetArchivosHilo(idMensajeRaiz)` |
| `SoporteVistaMensajesTicketWebApiController` | `GetPrincipal` solo raíz + `Cantrespuestas` |
| `Portal/PortalTicketsWebApiController` | `EnviarMensaje` propaga `IdMensajeRaiz`; `GetMensajes` sigue solo-raíz |
| `Portal/PortalSoporteArchivosWebApiController` | nuevo `GetHilo(idMensajeRaiz)`; `SubirArchivo` acepta `idMensajeRaiz` |
| `Portal/SoporteVistaMensajesTicketClienteWebApiController` | nuevo `ObtenerHilo(idMensajeRaiz)` → ruta `hilo/{idMensajeRaiz:int}`, 404 si no autorizado/vacío |

### SignalR (`PruebaPostgreSQL/Hubs/SoporteHub.cs`)

- `EnviarMensajeCliente(idGestion, mensaje, idMensajeRaiz)` — nuevo parámetro, se propaga a `RegistrarMensajeCliente`.
- Payload `nuevoMensaje`/`nuevoArchivo` ahora incluye `Idmensajeraiz`. **No hay evento nuevo** —
  el mismo evento sirve para raíz y respuesta; el cliente decide qué hacer según ese campo.

### Frontend soporte (`PruebaPostgreSQL/Scripts/siian/tabMensajes.js` + `_TabMensajes.cshtml`)

- Estado `raizActiva` (null = timeline principal, id = hilo abierto).
- `crearFilaBurbuja`: si `cantRespuestas>0` pinta footer "💬 N respuestas · Ver hilo"; si 0, "Responder en hilo" (solo fuera de modo hilo).
- `abrirHilo(idRaiz)` / `volverAPrincipal()`: togglean `raizActiva`, recargan.
- `cargarHilo(idRaiz)`: pide `ObtenerHilo` + `GetArchivosHilo` en paralelo, merge en timeline del hilo.
- **Diferenciación en vivo** (`agregarMensajeEnVivo`/`agregarArchivoEnVivo`):
  - `idraiz != null` (respuesta) → si `raizActiva === idraiz`, se pinta en el hilo abierto; si no,
    solo sube el contador "N respuestas" de la burbuja raíz (`incrementarContadorRespuestas`), **no se pinta en la principal**.
  - `idraiz == null` (raíz) → se agrega a la principal solo si `raizActiva === null`.
- Uploader: URL de subida se extiende con `&idMensajeRaiz=` cuando hay hilo abierto (`construirUploadUrlArchivo`).
- Header de hilo (`#chat-hilo-header`, botón "Volver") en `_TabMensajes.cshtml`.

## Pendiente: portal cliente (React, `D:\proyectos\portal-siian`)

**No implementado del lado frontend.** Se buscó `types.ts`, `hooks/useMensajesChat.ts`,
`hooks/useHilo.ts`, `api/tickets.js` con soporte de hilos — no existen. El backend
(`PortalTicketsWebApiController`, `PortalSoporteArchivosWebApiController`,
`SoporteVistaMensajesTicketClienteWebApiController`, ruta `hilo/{idMensajeRaiz}`) ya está
listo para consumirse. Falta fase 7 del plan original: `useHilo.ts`, estado `raizAbierta`
en `DetalleTicket.tsx`, botón "Responder en hilo"/"💬 N respuestas" en `BurbujaMensaje.tsx`.

## Reglas de negocio vigentes (resumen)

1. Respuesta hereda `esprivado`; cliente nunca ve hilos/adjuntos privados ni su contador (R1/R2).
2. Ticket cerrado bloquea responder en hilo igual que en la principal (R3).
3. No leídos se cuentan a nivel ticket (incluye respuestas de hilo), sin trackeo por hilo (R4).
4. Sin hilo-de-hilo ni cross-ticket — validado en `ValidarMensajeRaiz` (Negocio, no en el controller).
5. `ON DELETE CASCADE`: borrar el raíz borra sus respuestas y adjuntos de hilo.
