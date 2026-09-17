# Plan: Hilos "reply-in-thread" en chat de soporte (self-reference, sin tabla nueva)

## Contexto

Hoy el chat de un ticket (`soporte_soportemensajes` → `crm_gestionmaestrocrm`) es una
**lista plana** de mensajes. Se agrega la capacidad de **responder a un mensaje concreto**
(estilo Discord/WhatsApp): la conversación principal se mantiene intacta y las respuestas
se agrupan alrededor de un **mensaje raíz**.

No se crea ninguna entidad `Hilo`: el hilo **no tiene atributos propios** (ni título, ni
autor, ni estado). Es una **vista lógica** = `mensaje raíz + todos los mensajes cuyo
idmensajeraiz apunta a él`. Es una modificación pequeña sobre lo que ya existe, no una
nueva arquitectura de conversaciones.

### Modelo de datos: una sola columna self-FK
```
soporte_soportemensajes
  ...
  idmensajeraiz integer NULL  → self-FK a soporte_soportemensajes(id)
```

```
id | idgestion | idmensajeraiz | mensaje
---+-----------+---------------+---------------------
1  | 100       | NULL          | Hola
2  | 100       | NULL          | Tengo un problema
3  | 100       | 2             | ¿Qué problema?
4  | 100       | 2             | Es la factura
5  | 100       | NULL          | Gracias
```
```
Conversación principal
├── 1 Hola
├── 2 Tengo un problema
│     ├── 3 ¿Qué problema?
│     └── 4 Es la factura
└── 5 Gracias
```

### Reglas
1. `idmensajeraiz = NULL` → mensaje de la conversación principal.
2. `idmensajeraiz = 25` → respuesta al mensaje raíz 25.
3. Un mensaje raíz puede tener 0..N respuestas.
4. Una respuesta pertenece a 1 solo mensaje raíz.
5. No hay hilos dentro de hilos (una respuesta no puede ser raíz de otra).
6. El mensaje raíz **sigue apareciendo en la conversación principal**.

### Queries base (sin tabla)
- ¿Cuántas respuestas tiene el mensaje X? → `SELECT COUNT(*) ... WHERE idmensajeraiz = X`.
- ¿El ticket tiene hilos? → `EXISTS(... WHERE idgestion = @id AND idmensajeraiz IS NOT NULL)`.
- Conversación principal = `WHERE idmensajeraiz IS NULL`. Hilo de X = `WHERE id = X OR idmensajeraiz = X`.

### Defaults de UI/permisos
- **Vista del hilo:** vista completa con "← Volver" (reemplaza la conversación; reusa el chat actual; sirve en móvil). Panel lateral = mejora posterior.
- **Permisos:** cliente y soporte pueden responder en hilo (cambiar a "solo soporte" = un `if` menos).

### Reglas de negocio resueltas
- **R1 — Privacidad en hilo:** una respuesta respeta `esprivado` igual que en la principal.
  El endpoint de hilo del **portal** filtra `esprivado = false`; el de **soporte** muestra todo.
  Si el mensaje raíz es privado, el cliente no lo ve en la principal → tampoco su hilo ni el contador.
- **R2 — Contador según audiencia (privacidad):** a **soporte** se le muestra el total de
  respuestas; al **cliente** solo `COUNT(esprivado = false)` — así el cliente **no se entera**
  de que existen notas privadas. El listado principal del portal calcula `cantrespuestas`
  excluyendo privadas; el de soporte cuenta todas.
- **R3 — Ticket cerrado:** bloquea responder en hilo igual que en la principal (reusar `estaCerrado`/`ticketEsCerrado`).
- **R4 — No leídos (a nivel ticket):** las respuestas de hilo cuentan como no leídas igual que
  cualquier mensaje (la lógica actual filtra por `idgestion` sin mirar `idmensajeraiz`, así que ya
  las incluye). Cuando un **gestor o subgestor abre el ticket**, se marca **todo** leído a nivel
  ticket (incluidas respuestas de hilos no abiertos). No hay "no leído por hilo" separado.
- **R5 — Notificación de respuesta privada:** no se notifica al cliente
  (ya cubierto por `ObtenerPortalUsuarioParaNotificar(idGestion, esPrivado)`, se reutiliza).
- **R6 — Tiempo real (detalle de UI, sin regla de negocio):** al llegar una respuesta en vivo se
  actualiza el contador "💬 N" del mensaje raíz si está visible; si el raíz no está en la ventana
  paginada, se refleja al recargar.
- **R7 — Adjuntos en hilo (SÍ):** se permiten. Se espeja la columna: `soporte_soportearchivos`
  gana `idmensajeraiz`. Adjunto de principal → `idmensajeraiz IS NULL`; adjunto de hilo →
  `idmensajeraiz = raíz`. El adjunto respeta `esprivado` igual que R1/R2.

> **Regla del proyecto:** invocar skills antes de codear (`siian-actor-dapper-metodos`,
> `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`).
> No se crean archivos `.cs` nuevos → sin cambios en `Data.csproj`.

---

## FASE 0 — Base de datos (script SQL, lo ejecuta el usuario)

```sql
ALTER TABLE soporte_soportemensajes
    ADD COLUMN idmensajeraiz integer NULL
        REFERENCES soporte_soportemensajes(id) ON DELETE CASCADE;
CREATE INDEX idxmensaje_raiz ON soporte_soportemensajes (idmensajeraiz);

-- Adjuntos en hilo (R7): espejo de la columna en archivos
ALTER TABLE soporte_soportearchivos
    ADD COLUMN idmensajeraiz integer NULL
        REFERENCES soporte_soportemensajes(id) ON DELETE CASCADE;
CREATE INDEX idxarchivo_raiz ON soporte_soportearchivos (idmensajeraiz);
```
- `ON DELETE CASCADE`: borrar el mensaje raíz borra sus respuestas y adjuntos de hilo.
- Sin migración: mensajes/adjuntos actuales quedan con `idmensajeraiz = NULL` (conversación principal).

### Vista de mensajes: exponer contador de respuestas
Recrear `soporte_soportevistamensajesticket` agregando, para cada mensaje, cuántas
respuestas cuelgan de él:
```sql
       (SELECT COUNT(*) FROM soporte_soportemensajes r
        WHERE r.idmensajeraiz = m.id)  AS cantrespuestas,   -- total (audiencia soporte)
       m.idmensajeraiz
```

**Verificación fase:** columna+índice creados; la vista devuelve `cantrespuestas`/`idmensajeraiz`.

---

## FASE 1 — Entidad + Actor Dapper (`Blip.Data/Soporte/`) — invocar `siian-actor-dapper-metodos`

### 1.0 `SoporteArchivos.cs` + `SoporteArchivosActor.cs` (adjuntos en hilo, R7)
- `SoporteArchivos.cs`: propiedad `int? Idmensajeraiz` + `IdmensajeraizCampo`/`IdmensajeraizTipo` + constructores.
- `SoporteArchivosActor.cs`: `CrearSelect/Insert/Update` incluyen `idmensajeraiz`.
- Método/consulta de lectura: separar **archivos de principal** (`idmensajeraiz IS NULL`)
  de **archivos de hilo** (`idmensajeraiz = @raiz`); el de portal filtra además `esprivado = false`.

### 1.1 `SoporteMensajes.cs`
- Propiedad columna `public int? Idmensajeraiz { get; set; }` + par estático `IdmensajeraizCampo`/`IdmensajeraizTipo` (`DbType.Int32`).
- Propiedad NO-columna `public int Cantrespuestas { get; set; }` (solo lectura; poblada por el SELECT del listado, ignorada por Insert/Update).
- Actualizar ambos constructores.

### 1.2 `SoporteMensajesActor.cs` (patrón de columnas explícitas)
- `CrearSelect()`, `Insert()`, `Update()`: incluir `idmensajeraiz`.

### 1.3 `SoporteMensajesActorNegocio.cs` (partial Dapper)
- `RegistrarMensajeCliente(..., int? idMensajeRaiz)` y `RegistrarMensajeSoporte(..., int? idMensajeRaiz)`: asignar `Idmensajeraiz`.
- **Listado principal** `ObtenerPrincipalPorIdgestionPaginado(idGestion, skip, take)`
  (ajusta el actual `ObtenerPorIdgestionPaginado`, ruta del **portal**): `AND idmensajeraiz IS NULL`
  + subselect `cantrespuestas` **excluyendo privadas** (`WHERE r.idmensajeraiz = m.id AND r.esprivado = false`, R2).
- **Listado de hilo** `ObtenerHiloPorRaiz(idMensajeRaiz)`:
  `WHERE id = @raiz OR idmensajeraiz = @raiz ORDER BY fechaenvio ASC` (cabecera + respuestas).
  Sobrecarga/param para portal que filtra `esprivado = false` (R1).

**Verificación fase:** principal excluye respuestas y trae `cantrespuestas`; `ObtenerHiloPorRaiz` trae cabecera + respuestas.

---

## FASE 2 — Vista + ViewModels (`Blip.Data/Soporte/`, `Blip.Entities/Soporte.ViewModels/`)

- `SoporteVistaMensajesTicket.cs`: props `Idmensajeraiz`, `Cantrespuestas` + estáticos + constructor (y en su `Actor.CrearSelect()` si enumera columnas).
- `SoporteMensajesViewModel.cs` y `SoporteVistaMensajesTicketViewModel.cs`: agregar `Idmensajeraiz`, `Cantrespuestas`.
- `MensajeSoporteEnviadoViewModel`: agregar `Idmensajeraiz`.

---

## FASE 3 — Negocio (`Negocio/Soporte/`, `Negocio/Portal/`)

### 3.1 `Negocio/Soporte/SoporteMensajesActorNegocio.cs`
- `RegistrarMensajeSoporte(..., int? idMensajeRaiz)` y `EnviarMensajeSoporte(..., int? idMensajeRaiz)`: propagar.
  Si `idMensajeRaiz` viene, validar que ese mensaje pertenece al mismo `idGestion` y **es raíz**
  (`Idmensajeraiz == null`) → aplica reglas 4 y 5 (no cross-ticket, no hilo-de-hilo).
  Reusar `SoporteMensajesActor.ObtenerPorIdSinVerificarExistencia`. Propagar `Idmensajeraiz` al VM.
- Nuevo `ObtenerHilo(idMensajeRaiz)` (proyección a VM) para el endpoint de hilo.

### 3.2 `Negocio/Portal/PortalSoporteTicketActorNegocio.cs`
- `RegistrarMensajeCliente(..., int? idMensajeRaiz)`: misma validación (raíz + mismo ticket + cliente dueño).
- `ObtenerMensajesTicket(...)`: filtrar a **principal** (`idmensajeraiz IS NULL`) + `cantrespuestas`
  **excluyendo privadas** (R2: `COUNT WHERE esprivado = false`).
- Nuevo `ObtenerHilo(idMensajeRaiz, idPortalUsuario)`: filtra `esprivado = false` (R1) e incluye adjuntos no privados del hilo.

---

## FASE 4 — Controllers WebApi (`PruebaPostgreSQL/Controllers/WebApi/`) — invocar `siian-mvc-controllers`

### 4.1 `SoporteMensajesWebApiController.cs`
- `EnviarMensajeViewModel`: agregar `int? IdMensajeRaiz`.
- `EnviarMensajeSoporte(...)`: pasar `IdMensajeRaiz`; incluir `idMensajeRaiz` en el push `nuevoMensaje`.
- Nuevo `GET ObtenerHilo(int idMensajeRaiz)` → cabecera + respuestas.
- `Get`/`Post`/`Put`: propagar `Idmensajeraiz`.

### 4.2 `SoporteVistaMensajesTicketWebApiController.cs`
- El tab de soporte pide **solo principal** (filtro `Idmensajeraiz` nulo) y recibe `Cantrespuestas`.

### 4.3 `SoporteArchivosWebApiController.cs` (R7)
- `SubirArchivo`: aceptar `idMensajeRaiz` opcional (además de `idGestion`, `esPrivado`) y guardarlo.
- `GetPorTicket`: devolver `idmensajeraiz`; el frontend separa principal vs hilo. Añadir/parametrizar
  lectura de **archivos de un hilo** (`idmensajeraiz = @raiz`); el portal filtra privadas.

### 4.4 `Portal/PortalTicketsWebApiController.cs`
- `GET /tickets/{id}/mensajes`: solo principal + `cantrespuestas` (excluyendo privadas, R2).
- `GET /mensajes/{idRaiz}/hilo` → hilo completo (mensajes + adjuntos del hilo; filtra privadas).
- `POST /tickets/{id}/mensajes {mensaje, idMensajeRaiz?}` → principal si null, respuesta si viene raíz.
- Subida de adjuntos del portal: propagar `idMensajeRaiz` al guardar el archivo.

---

## FASE 5 — SignalR (`PruebaPostgreSQL/Hubs/SoporteHub.cs`)

- `EnviarMensajeCliente(idGestion, mensaje)` → `(idGestion, mensaje, int? idMensajeRaiz)`; propagar.
- Payload `nuevoMensaje` incluye `idMensajeRaiz`: si el hilo raíz está abierto, pintar en el hilo;
  si no, incrementar el "N respuestas" del mensaje raíz en la principal (no pintarlo como principal).
- Grupo por ticket se mantiene.

---

## FASE 6 — Frontend soporte (MVC + DevExtreme) — invocar `siian-devextreme-*`

`Views/SoporteDetalle/_TabMensajes.cshtml` + `Scripts/siian/tabMensajes.js`:

- `fetchPaginaMensajes`: filtrar `["Idmensajeraiz","=",null]` (solo principal).
- `crearFilaBurbuja`: si `item.cantrespuestas > 0`, footer "💬 N respuestas · Ver hilo" (data-raiz=id).
- Acción por burbuja **"Responder en hilo"** (delegado) → entra a vista de hilo con `raizActiva = id`.
- Vista de hilo (reusa markup de burbujas): carga `ObtenerHilo`, muestra cabecera + respuestas,
  input que envía con `IdMensajeRaiz = raizActiva`, botón "← Volver".
- **Adjuntos (R7):** en la vista de hilo, el FileUploader agrega `&idMensajeRaiz=` a `uploadUrl`;
  los archivos del hilo se cargan/pintan filtrando `idmensajeraiz = raizActiva` (los de la principal
  se filtran a `idmensajeraiz IS NULL`).
- Bloqueo por ticket cerrado (R3) también en la vista de hilo.
- Marcado leído (R4): al abrir el ticket, gestor **o subgestor** dispara `marcarMensajesLeidos`
  (nivel ticket, ya incluye respuestas de hilo). Reusar el flag actual `esGestorTicket` extendido a subgestor.
- SignalR: enrutar `nuevoMensaje`/`nuevoArchivo` según `idMensajeRaiz` (hilo abierto vs incrementar contador en principal).

---

## FASE 7 — Frontend portal (React, `D:\proyectos\portal-siian`)

- `types.ts` `Mensaje`: agregar `idMensajeRaiz?`, `cantRespuestas?`.
- `shared/helpers/formatters.ts` `normalizarMensaje`: mapear ambos.
- `api/tickets.js`: `getHilo(idRaiz)`, `enviarMensaje(id, mensaje, idMensajeRaiz = null)` y
  `subirArchivo(idGestion, file, idMensajeRaiz = null, ...)` (R7). `getArchivos`/hilo filtran por `idmensajeraiz`.
- `hooks/useMensajesChat.ts`: `getMensajes` trae solo principal; `handleEnviar` pasa `idMensajeRaiz`.
  `handleNuevoMensaje`: si trae `idMensajeRaiz`, no lo agrega a la principal → incrementa `cantRespuestas` del raíz.
- Nuevo `hooks/useHilo.ts` + estado `raizAbierta` en `DetalleTicket.tsx`: al "Ver hilo/Responder en hilo"
  se muestra la vista del hilo (reusa `BurbujaMensaje`/`BurbujaArchivo`) con "Volver".
- `components/BurbujaMensaje.tsx`: acción "Responder en hilo"; si `cantRespuestas > 0`, botón "💬 N respuestas".

---

## Reutilización
- Todo el chat actual (burbujas soporte JS y `BurbujaMensaje`/`BurbujaArchivo` React) se reutiliza en la vista de hilo.
- Escritura + push ya centralizados en `RegistrarMensaje*` / `EnviarMensajeSoporte`.
- Dedupe por id ya existe en ambos frontends.
- Sin tabla nueva, sin `.csproj`, sin migración de datos.

## Verificación end-to-end
1. Ejecutar SQL (columna, índice, vista); confirmar `cantrespuestas`.
2. Compilar `PruebaPostgreSQL.sln`; portal `npm run build`.
3. Soporte: "Responder en hilo" sobre un mensaje → la principal no cambia; el raíz muestra "N respuestas";
   entrar al hilo, conversar, volver; el contador sube.
4. Portal: mismo flujo desde el cliente; validar que no se responde en hilo sobre una respuesta (regla 5) ni cross-ticket (regla 4).
5. SignalR: respuesta con hilo cerrado → sube el contador del raíz en la principal, no aparece como principal; hilo abierto → aparece en el hilo.
6. Cascada: borrar mensaje raíz borra sus respuestas y adjuntos de hilo (`ON DELETE CASCADE`).
7. Privacidad (R1/R2): respuesta/adjunto privado en hilo NO lo ve el cliente; el contador del cliente lo excluye.
8. Adjuntos (R7): subir imagen dentro de un hilo aparece solo en ese hilo, no en la principal; y viceversa.
