# Prioridades por SLA — Plan de implementación

> **Para quien ejecute:** usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` tarea por tarea. Las casillas `- [ ]` se tildan al ejecutar, con la evidencia ya escrita en `IMPLEMENTACION.md` (ver `GUIA.md`, "Verificación").

**Meta:** el portal solo ofrece prioridades con SLA activo para el motivo elegido, y sin SLA no se crea el ticket (se elimina el tiempo de 72h).

**Arquitectura:** una consulta Dapper nueva en `Blip.Data` entrega las prioridades de un motivo; un endpoint nuevo del portal la expone; `Negocio` deja de inventar 72h y lanza error si falta el SLA activo; el front pide las prioridades al elegir el motivo.

**Stack:** .NET Framework 4.6.2, ASP.NET Web API 2, Dapper + Npgsql (backend `D:\soporte\SIIAN`); React + Mantine + TanStack Query (front `D:\proyectos\portal-siian`).

**Spec:** [ANALISIS.md](./ANALISIS.md) y [REQUERIMIENTO.md](./REQUERIMIENTO.md). Los criterios 1 a 5 de REQUERIMIENTO son los Dado/Cuando/Entonces de este plan.

## Restricciones globales

- Sin tests automáticos: cada tarea cierra con **build** (`msbuild PruebaPostgreSQL.sln /p:Configuration=Debug`, 0 errores; en el front `npm run build`) y **prueba manual Dado/Cuando/Entonces**. La evidencia (resultado obtenido, no el esperado) va en `IMPLEMENTACION.md`, sección `## Verificación`.
- Capas: Dapper y SQL solo en `Blip.Data/`; `Negocio/` sin Dapper ni `GeneralDao.Connection`. Referencias SQL con los campos estáticos de la entidad (`SoporteSla.IdmotivoCampo`), nunca literales.
- Strings y comentarios de C# en español **sin tildes** (precedente: `RegistrarUsuarioPortal`). Conservar codificación y saltos de línea de cada archivo editado.
- Comentarios solo donde hay un porqué que el nombre no dice (`GUIA.md`, paso 3b). Cada tarea termina con la entrevista de propósito de ese paso antes de cualquier commit.
- Commits solo si el usuario los pide: conventional commits, una línea, sin `Co-Authored-By`.
- Mensaje al cliente cuando falta el SLA: `No hay parametrizacion de SLA para este motivo. Comuniquese con soporte.`
- Errores del portal: el controlador ya responde 500 con `{ mensaje, detalle }` y el front muestra `detalle`; no se cambia ese contrato.

## Foco de revisión

Casos que la spec implica y que ninguna tarea probaría sola; cada uno queda anclado a la tarea que lo prueba.

1. **Mismo motivo + prioridad con una fila de SLA inactiva y otra activa**: debe usarse la activa, no la primera que devuelva la BD. (Tarea 2)
2. **Prioridad válida en general pero de otro motivo** (front desactualizado o petición manual): se rechaza con el mensaje de falta de SLA. (Tarea 2)
3. **Prioridad inactiva con SLA activo**: no aparece en la lista del motivo. (Tarea 1)
4. **Cliente elige prioridad y luego cambia de motivo**: la prioridad se limpia y se recalcula la lista. (Tarea 4)
5. **Calendario mal configurado**: el ticket no se crea y el cliente ve el error, nunca 72h. (Tarea 2)

## Mapa de archivos

| Archivo | Cambio |
|---|---|
| `Blip.Data/Soporte/SoportePrioridadActorNegocio.cs` | Agrega `ObtenerActivasPorMotivo` (ya está registrado en `Data.csproj`) |
| `Negocio/Soporte/SoporteSlaActorNegocio.cs` | `ObtenerFechaLimiteSLA` exige SLA activo y quita las 72h y el `catch` |
| `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs` | Endpoint `opciones/prioridades`; `opciones` deja de devolver `prioridades` |
| `portal-siian/src/api/tickets.js`, `src/api/queryKeys.ts` | Llamada y clave de consulta nuevas |
| `portal-siian/src/pages/NuevoTicket/hooks/usePrioridadesMotivo.ts` | Nuevo hook |
| `portal-siian/src/pages/NuevoTicket/hooks/useOpciones.ts`, `NuevoTicket.tsx` | Quita `prioridades` de opciones; sección Prioridad según el motivo |
| `DataGripProjects/fix-soporte-tickets/entregables/<fecha>-prioridades-sla/` | Script de motivos sin SLA (pre-despliegue) |

Ningún archivo `.cs` nuevo, así que no hay registros pendientes en los `.csproj`.

---

### Tarea 1: prioridades activas de un motivo (datos)

**Se parece a:** `SoportePrioridadActor.ObtenerActivos` (mismo archivo, mismo patrón `CrearSelect` + `DynamicParameters` + `ObtenerLista`).

**Archivos:** Modificar `Blip.Data/Soporte/SoportePrioridadActorNegocio.cs`.

**Interfaces:**
- Produce: `public static List<SoportePrioridad> ObtenerActivasPorMotivo(int p_idmotivo)`. Lista vacía si el motivo no tiene ninguna; nunca `null`.

- [x] **Paso 1:** Implementar `ObtenerActivasPorMotivo` en `SoportePrioridadActor`. Condición: prioridad activa **y** `EXISTS` una fila de `soporte_soportesla` con `idprioridad` igual al `id` de la prioridad, `idmotivo = @idmotivo` y `activo = true`. Orden por nombre. Usar `SoportePrioridad.IdCampo`/`ActivoCampo`/`NombreCampo` y `SoporteSla.IdprioridadCampo`/`IdmotivoCampo`/`ActivoCampo`.
- [x] **Paso 2:** Build de `Blip.Data` (`msbuild Blip.Data\Data.csproj /p:Configuration=Debug`): 0 errores.
- [x] **Paso 3 (SQL equivalente en demo, solo lectura):** ejecutar la misma consulta con un `idmotivo` real.
  - **Dado** un motivo con una fila de SLA activa para la prioridad P, **cuando** se consulta, **entonces** devuelve solo P.
  - **Dado** la misma prioridad marcada inactiva (en una transacción con `ROLLBACK`), **cuando** se consulta, **entonces** devuelve 0 filas. (Foco 3)
  - **Dado** un motivo sin ninguna fila de SLA, **entonces** devuelve 0 filas.

---

### Tarea 2: fecha límite sin tiempo inventado (negocio)

**Se parece a:** el mismo método `ObtenerFechaLimiteSLA` (se modifica en el lugar). Nuevo: el rechazo con excepción, que sigue el estilo de `CrearTicketPortal` (`throw new Exception("...")`).

**Archivos:** Modificar `Negocio/Soporte/SoporteSlaActorNegocio.cs`. `SoporteTicketsActorNegocio.cs:44` no cambia: ya es el único llamador y ya propaga excepciones.

**Interfaces:**
- Consume: `SoporteSlaActor.ObtenerPorIdmotivo(int) -> List<SoporteSla>` (existe, sin filtrar por `Activo`) y `SoporteCalendarioActorNegocio.CalcularFechaLimiteHabil(DateTime, int)`.
- Produce: `ObtenerFechaLimiteSLA(int idMotivo, int idPrioridadCliente)` y su sobrecarga con `DateTime p_inicio` mantienen firma. Nuevo contrato: lanza `Exception` con el mensaje de las restricciones globales si no hay SLA activo para esa combinación (incluye `idPrioridadCliente <= 0`).

- [x] **Paso 1:** Reescribir `ObtenerFechaLimiteSLA(DateTime, int, int)`: buscar en `ObtenerPorIdmotivo(idMotivo)` la fila con `Idprioridad == idPrioridadCliente && Activo` (LINQ en `Negocio`, sin Dapper); si no hay, lanzar la excepción; si hay, `CalcularFechaLimiteHabil(p_inicio, sla.Horasmaximo)`. Eliminar `horasDefault`, el `try/catch` y el comentario que lo justificaba. Un fallo del calendario se propaga.
- [x] **Paso 2:** Actualizar el `summary` del método (ya no menciona 72h).
- [x] **Paso 3:** Build de la solución: 0 errores.
- [x] **Paso 4 (prueba manual, `POST /api/portal/tickets` con token de portal, Postman):**
  - **Dado** un motivo con SLA activo y su prioridad, **cuando** se crea el ticket, **entonces** responde 201 y `fechalimite` del ticket coincide con las horas hábiles del SLA (no 72h planas). (Criterio 1/2)
  - **Dado** `IdPrioridadCliente: 0`, **entonces** 500 con `detalle` = mensaje de falta de SLA y no se crea el ticket. (Criterio 4)
  - **Dado** una prioridad que existe pero es de otro motivo, **entonces** el mismo rechazo. (Foco 2)
  - **Dado** dos filas de SLA para el mismo motivo + prioridad, una inactiva y una activa (en la demo, con `ROLLBACK` o limpiando después), **entonces** el ticket se crea con las horas de la activa. (Foco 1)
  - **Dado** el calendario inutilizable (por ejemplo, sin días hábiles configurados, en la demo), **entonces** 500 con el error del calendario y sin ticket. (Criterio 5, Foco 5)

---

### Tarea 3: endpoint de prioridades por motivo (portal)

**Se parece a:** `GetOpciones` en el mismo controlador (mismo `try/catch`, mismas respuestas de error y objetos anónimos `{ Id, Nombre }`, sin ViewModel nuevo y por eso sin `[JsonProperty]`).

**Archivos:** Modificar `PruebaPostgreSQL/Controllers/WebApi/Portal/PortalTicketsWebApiController.cs`.

**Interfaces:**
- Consume: `SoportePrioridadActor.ObtenerActivasPorMotivo(int)` (Tarea 1).
- Produce: `GET api/portal/tickets/opciones/prioridades?idMotivo={int}` → 200 con un arreglo `[{ "Id": int, "Nombre": string }]`, vacío si el motivo no tiene SLA. `GET api/portal/tickets/opciones` deja de incluir `prioridades`.

- [x] **Paso 1:** Agregar `GetPrioridadesPorMotivo(int idMotivo)` con `[HttpGet] [Route("opciones/prioridades")]`.
- [x] **Paso 2:** Quitar `prioridades` de `GetOpciones` (la variable y la propiedad del objeto de respuesta).
- [x] **Paso 3:** Build de la solución: 0 errores.
- [x] **Paso 4 (Postman, token de portal):**
  - **Dado** un motivo con una prioridad parametrizada, **cuando** se pide `opciones/prioridades?idMotivo=X`, **entonces** devuelve exactamente esa. (Criterio 1)
  - **Dado** un motivo con varias, **entonces** devuelve solo las parametrizadas. (Criterio 2)
  - **Dado** un motivo sin SLA, **entonces** devuelve `[]`. (Criterio 3)
  - **Dado** `GET opciones`, **entonces** ya no trae `prioridades` y el resto (motivos, entornos, módulos, aplicaciones) sigue igual.

---

### Tarea 4: pantalla Nuevo Ticket (front)

**Se parece a:** `useOpciones.ts` (hook con `useQuery`) y la sección Prioridad ya existente en `NuevoTicket.tsx`. Nuevo: el hook por motivo y la rama de "sin parametrización".

**Archivos:**
- Crear: `src/pages/NuevoTicket/hooks/usePrioridadesMotivo.ts`
- Modificar: `src/api/tickets.js`, `src/api/queryKeys.ts`, `src/pages/NuevoTicket/hooks/useOpciones.ts`, `src/pages/NuevoTicket/NuevoTicket.tsx`

**Interfaces:**
- Consume: el endpoint de la Tarea 3.
- Produce: `getPrioridadesPorMotivo(idMotivo: number)` en `tickets.js`; `queryKeys.prioridadesMotivo(idMotivo?: number)`; `usePrioridadesMotivo(idMotivo: string | null): { prioridades: Array<{ Id: number; Nombre: string }>; loading: boolean }` con la consulta habilitada solo si hay motivo.

- [x] **Paso 1:** API y clave de consulta.
- [x] **Paso 2:** Hook `usePrioridadesMotivo`.
- [x] **Paso 3:** En `useOpciones.ts` quitar `prioridades` de `Opciones` y `OPCIONES_VACIAS`.
- [x] **Paso 4:** En `NuevoTicket.tsx`:
  - La sección Prioridad aparece solo con un motivo elegido.
  - Con 0 prioridades se muestra una `Alert` con el mensaje de las restricciones globales y el botón de enviar queda deshabilitado.
  - Con 1 prioridad se usa esa como valor efectivo, mostrada ya seleccionada (valor derivado, sin `useEffect`).
  - Con 2 o más, `Select` obligatorio y sin `clearable`.
  - Al cambiar el motivo se limpia `idPrioridad`.
  - `isFormValid` y `handleSubmit` exigen prioridad cuando hay prioridades; el payload manda el valor efectivo.
- [x] **Paso 5:** `npm run build` en `portal-siian`: 0 errores.
- [x] **Paso 6 (navegador, `npm run dev` contra el backend de la demo):**
  - **Dado** un motivo con una prioridad, **cuando** se elige, **entonces** la prioridad aparece seleccionada y se puede enviar. (Criterio 1)
  - **Dado** un motivo con varias, **entonces** el selector muestra solo esas y no deja enviar sin escoger. (Criterio 2)
  - **Dado** un motivo sin SLA, **entonces** aparece el aviso y no se puede enviar. (Criterio 3)
  - **Dado** una prioridad elegida y luego otro motivo, **entonces** la prioridad se limpia y la lista cambia. (Foco 4)

---

### Tarea 5: motivos sin SLA antes de desplegar

**Se parece a:** los scripts de `DataGripProjects/fix-soporte-tickets/entregables/` (fuente de verdad del SQL; acá solo se referencia la ruta). Nuevo: consulta de solo lectura, no modifica datos.

**Archivos:** Crear `DataGripProjects/fix-soporte-tickets/entregables/<fecha>-prioridades-sla/motivos-sin-sla.sql`.

- [x] **Paso 1:** Escribir la consulta: motivos de `crm_motivocrm` con `esactivo` y `soporte` verdaderos que **no tengan** ninguna fila activa en `soporte_soportesla` con una prioridad activa. Columnas: `id`, `nombre`.
- [ ] **Paso 2:** Ejecutarla en la demo y en producción (solo lectura). Guardar el resultado en `IMPLEMENTACION.md`.
- [ ] **Paso 3:** Pasar la lista a soporte. Cada motivo listado queda bloqueado al desplegar hasta que se parametrice o se inactive. Ese trabajo es de soporte y no bloquea el desarrollo, pero **el despliegue espera esa lista**.

---

## Autorrevisión

- **Cobertura:** criterio 1 (T1, T3, T4), 2 (T1, T3, T4), 3 (T3, T4), 4 (T2), 5 (T2); rechazo de prioridad ajena (T2); verificación pre-despliegue del análisis (T5). Fuera de alcance respetado: `_TabSla.cshtml` y tickets existentes no se tocan.
- **Orden:** T1 → T3 → T4 dependen en cadena; T2 es independiente y puede ir primero o en paralelo a T1.
- **Riesgo conocido:** una petición manual con prioridad vacía y un motivo que sí tiene SLA recibe el mismo mensaje de "falta de parametrización", que en ese caso no describe bien la causa. Solo se alcanza saltándose el front; se acepta para no sumar un segundo mensaje.
