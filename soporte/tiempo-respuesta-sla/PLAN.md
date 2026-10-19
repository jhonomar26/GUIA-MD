# Tiempo de respuesta en el SLA — Plan de implementación

> **Para quien ejecute:** usar `superpowers:subagent-driven-development` o `superpowers:executing-plans` tarea por tarea. Las casillas `- [ ]` se tildan al ejecutar, con la evidencia ya escrita en `IMPLEMENTACION.md` (ver `GUIA.md`, "Verificación").

**Meta:** el SLA tiene horas de respuesta además de las de resolución, y la fecha límite del ticket es creación + (respuesta + resolución) en horas hábiles.

**Arquitectura:** columna nueva `horasrespuesta` en `soporte_soportesla` (entera, obligatoria, 0 por defecto), que viaja por la familia generada (entidad, actor, ViewModel, WebApi) según `siian-plantillas-generadas`. `Negocio` suma las dos horas en el único punto que calcula la fecha límite. La pantalla de parametrización muestra las dos horas y el total.

**Stack:** .NET Framework 4.6.2, ASP.NET MVC 5 + Web API 2, Dapper + Npgsql, DevExtreme (backend `D:\soporte\SIIAN`). El portal no cambia.

**Spec:** [ANALISIS.md](./ANALISIS.md) y [REQUERIMIENTO.md](./REQUERIMIENTO.md). Los criterios 1 a 4 de REQUERIMIENTO son los Dado/Cuando/Entonces de este plan.

**EXPLICACION.md:** no se escribe. La regla es una suma en un solo punto, ya explicada y aprobada en `ANALISIS.md` (`GUIA.md`, tabla de docs: solo para features de más de una etapa).

## Restricciones globales

- Sin tests automáticos: cada tarea cierra con **build** (`msbuild PruebaPostgreSQL.sln /p:Configuration=Debug`, 0 errores) y **prueba manual Dado/Cuando/Entonces**. La evidencia (resultado obtenido, no el esperado) va en `IMPLEMENTACION.md`, sección `## Verificación`.
- Columna: `horasrespuesta integer NOT NULL DEFAULT 0`, **al final** de la tabla. En C# es `int` (no nullable) y `DbType.Int32`.
- Los parámetros nuevos van **al final** de cada constructor posicional (`siian-plantillas-generadas`, regla de oro). Nunca en medio.
- La columna `horasmaximo` no se renombra en BD ni en C#: solo cambia la etiqueta visible a "Horas resolución".
- Strings y comentarios de C# en español sin tildes, salvo las etiquetas `[Display]` del ViewModel, que ya usan tildes en Windows-1252. **Conservar la codificación y los saltos de línea de cada archivo.** `SoporteSlaViewModel.cs` está en Windows-1252: editarlo con un comando que la preserve, no con Edit/Write.
- Comentarios solo donde hay un porqué que el nombre no dice (`GUIA.md`, paso 3b). Cada tarea termina con la entrevista de propósito de ese paso antes de cualquier commit.
- Commits solo si el usuario los pide: conventional commits, una línea, sin `Co-Authored-By`.
- El SQL vive en `DataGripProjects/fix-soporte-tickets/entregables/14-10-2026-tiempo-respuesta-sla/` (fuente de verdad); acá solo se referencia.

## Foco de revisión

Casos que la spec implica y que ninguna tarea probaría sola; cada uno queda anclado a la tarea que lo prueba.

1. **SLA viejo, respuesta en 0:** la fecha límite debe ser idéntica a la de antes del cambio. Un default mal puesto (NULL) rompería la creación de tickets. (Tarea 1)
2. **Total que cruza la jornada o el fin de semana** (ticket creado a las 4 p. m. de un viernes con 2 + 4): la fecha cae en el siguiente día hábil, no 6 h de calendario después. (Tarea 1)
3. **Editar un SLA solo en "Activo"** desde la grilla: el `PUT` no debe borrar las horas de respuesta (bloques de copia del `Put`). (Tarea 2)
4. **Horas de respuesta negativas o vacías** en la grilla: se rechaza la negativa; la vacía queda en 0. Una negativa restaría tiempo a la resolución. (Tarea 2)
5. **Ticket creado antes del cambio:** al editar el SLA, su fecha límite no cambia. (Tarea 2)

## Mapa de archivos

| Archivo | Cambio |
|---|---|
| `entregables/14-10-2026-tiempo-respuesta-sla/1-horasrespuesta.sql` | `ALTER TABLE ... ADD COLUMN` |
| `Blip.Data/Soporte/SoporteSla.cs` | Propiedad, estáticos y parámetro final del constructor |
| `Blip.Data/Soporte/SoporteSlaActor.cs` | `CrearSelect`, `Insert`, `Update` |
| `Negocio/Soporte/SoporteSlaActorNegocio.cs` | `ObtenerFechaLimiteSLA` suma las dos horas |
| `Blip.Entities/Soporte.ViewModels/SoporteSlaViewModel.cs` | Propiedad, parámetro final del constructor, etiqueta "Horas resolución" |
| `PruebaPostgreSQL/Controllers/WebApi/SoporteSlaWebApiController.cs` | `Get`, `Post` y los dos bloques del `Put` |
| `PruebaPostgreSQL/Views/SoporteParametros/_TabSla.cshtml` | Columna de respuesta y columna calculada "Total" |

Ningún archivo `.cs` nuevo, así que no hay registros pendientes en los `.csproj`. `SoporteSlaController.cs` (MVC) no construye la entidad: no cambia.

---

### Tarea 1: columna nueva y suma en la fecha límite (BD, datos, negocio)

**Se parece a:** el protocolo "AGREGAR una columna a mano" de `siian-plantillas-generadas` (pasos 1 a 5). La suma se hace en el mismo `ObtenerFechaLimiteSLA` que modificó `prioridades-por-sla`.

**Archivos:** el script SQL, `SoporteSla.cs`, `SoporteSlaActor.cs` y `SoporteSlaActorNegocio.cs`.

**Interfaces:**
- Consume: `SoporteCalendarioActorNegocio.CalcularFechaLimiteHabil(DateTime, int)`, sin cambios.
- Produce:
  - `SoporteSla.Horasrespuesta` (`int`), `SoporteSla.HorasrespuestaCampo = "public.soporte_soportesla.horasrespuesta"` y `HorasrespuestaTipo = DbType.Int32`.
  - Constructor `SoporteSla(int p_id,int p_idmotivo,int p_idprioridad,int p_horasmaximo,bool? p_activo,DateTime? p_fechacreacion,int p_horasrespuesta)`.
  - `ObtenerFechaLimiteSLA` mantiene sus dos firmas.

- [x] **Paso 1:** Escribir el script: `ALTER TABLE public.soporte_soportesla ADD COLUMN horasrespuesta integer NOT NULL DEFAULT 0;`. Aplicarlo en demo.
- [x] **Paso 2:** Entidad `SoporteSla.cs`: propiedad al final de los escalares, estáticos al final de los `{X}Campo`/`{X}Tipo`, y parámetro y asignación al final del constructor. Formato del generador (tabulaciones, sin espacio antes de `{`).
- [x] **Paso 3:** `SoporteSlaActor.cs`:
  - `CrearSelect`: `, soporte_soportesla.horasrespuesta` antes del ` FROM `.
  - `Insert`: `, horasrespuesta` en las columnas y `, @horasrespuesta` en los `VALUES`.
  - `Update`: `sql.Append(", horasrespuesta = @horasrespuesta");` antes del ` WHERE `.
- [x] **Paso 4:** `ObtenerFechaLimiteSLA(DateTime, int, int)`: pasar `sla.Horasrespuesta + sla.Horasmaximo` a `CalcularFechaLimiteHabil`. Actualizar el `summary`: la fecha límite es respuesta + resolución en horas hábiles.
- [x] **Paso 5:** Build de la solución: 0 errores. Fallará en `SoporteSlaWebApiController.cs:41` (constructor con un argumento menos) hasta la Tarea 2: si se ejecuta por separado, agregar ahí `, item.Horasrespuesta` ahora y dejar el resto de ese archivo para la Tarea 2.
- [ ] **Paso 6:** `verificar-constructores.ps1 -Entidad SoporteSla`: 0 hallazgos.
- [x] **Paso 7 (SQL en demo, solo lectura):** `SELECT id, horasmaximo, horasrespuesta FROM public.soporte_soportesla`. Todas las filas tienen `horasrespuesta = 0`.
- [ ] **Paso 8 (prueba manual, `POST /api/portal/tickets` con token de portal, Postman):**
  - **Dado** un SLA existente con respuesta 0, **cuando** se crea un ticket, **entonces** `fechalimite` = las mismas horas hábiles de antes. (Criterio 2, Foco 1)
  - **Dado** ese SLA con `horasrespuesta = 2` y `horasmaximo = 4` (UPDATE en demo, anotar el valor previo para restaurarlo), **cuando** se crea un ticket, **entonces** `fechalimite` queda 6 horas hábiles después de la creación. (Criterio 1)
  - **Dado** el mismo SLA y un inicio a menos de 6 h del fin de la jornada, **entonces** la fecha cae en el día hábil siguiente. Se prueba llamando `ObtenerFechaLimiteSLA(p_inicio, ...)` con un `p_inicio` fijo (por ejemplo, viernes 16:00) desde la ventana inmediata de Visual Studio. (Foco 2)

---

### Tarea 2: pantalla de parametrización del SLA

**Se parece a:** la columna `Horasmaximo` en `SoporteSlaViewModel`, `SoporteSlaWebApiController` y `_TabSla.cshtml` (mismo recorrido, protocolo de `siian-plantillas-generadas`, pasos 6 a 9). Nuevo: la columna calculada "Total", con `CalculateCellValue` de DevExtreme (consultar `siian-devextreme-components` antes de tocar la vista).

**Archivos:** `SoporteSlaViewModel.cs`, `SoporteSlaWebApiController.cs` y `_TabSla.cshtml`.

**Interfaces:**
- Consume: `SoporteSla.Horasrespuesta` y el constructor de 7 parámetros (Tarea 1).
- Produce:
  - `SoporteSlaViewModel.Horasrespuesta` (`int`), con `[Display(Name = "Horas respuesta")]` y `[Range(0, int.MaxValue)]`.
  - Constructor `SoporteSlaViewModel(int p_id, int p_idmotivo, int p_idprioridad, int p_horasmaximo, bool? p_activo, DateTime? p_fechacreacion, int p_horasrespuesta)`.
  - La etiqueta de `Horasmaximo` pasa a ser "Horas resolución".

- [x] **Paso 1:** ViewModel: propiedad, atributos, parámetro y asignación al final, y la etiqueta nueva de `Horasmaximo`. Preservar Windows-1252 y verificar que las tildes existentes ("Fecha de creación") siguen intactas.
- [x] **Paso 2:** WebApi:
  - `Get`: `, x.Horasrespuesta` al final del `new SoporteSlaViewModel(`.
  - `Post`: `, item.Horasrespuesta` al final del `new SoporteSla(`.
  - `Put`: `item.Horasrespuesta = itemBase.Horasrespuesta;` en el primer bloque y `itemBase.Horasrespuesta = item.Horasrespuesta;` en el segundo.
- [x] **Paso 3:** `_TabSla.cshtml`:
  - `columns.AddFor(m => m.Horasrespuesta)` antes de `Horasmaximo`.
  - Columna "Total" de solo lectura, sin `dataField`, calculada como respuesta + resolución y oculta en el formulario de edición.
  - Los estilos `.sla-*` sin uso no se tocan (H4).
- [x] **Paso 4:** Build de la solución: 0 errores. `verificar-constructores.ps1 -Entidad SoporteSla`: 0 hallazgos (incluye `VIEWMODEL`).
- [ ] **Paso 5 (navegador, Parámetros de soporte → pestaña SLA):**
  - **Dado** la grilla, **entonces** se ven "Horas respuesta", "Horas resolución" y "Total", y en los SLA viejos el total es igual a la resolución. (Criterio 3)
  - **Dado** un SLA nuevo con 2 + 4, **cuando** se guarda, **entonces** se ve en la grilla con total 6 y queda así en la BD (SELECT). (Criterio 3)
  - **Dado** un SLA con respuesta 2, **cuando** se edita solo "Activo", **entonces** la respuesta sigue en 2 (SELECT). (Foco 3)
  - **Dado** respuesta -1, **entonces** no se guarda y se ve el error de validación. **Dado** respuesta vacía en un SLA nuevo, **entonces** se guarda en 0. (Foco 4)
  - **Dado** un ticket creado antes de editar el SLA, **cuando** se cambian sus horas, **entonces** su `fechalimite` no cambia (SELECT antes y después). (Criterio 4, Foco 5)

---

### Tarea 3: registrar la fecha de respuesta del ticket

**Reabre** la decisión de `ANALISIS.md` "no se mide ni se registra la respuesta" (fecha de respuesta fuera de alcance, H6). Pedido por el usuario el 2026-10-14.

**Regla:** `fecharespuesta` del ticket (`GestionMaestroCRM`) se llena con la fecha del **primer mensaje público de soporte** y solo si está vacía. Mensajes del cliente y notas privadas (`esprivado`) no cuentan. Nunca se sobrescribe.

**Se parece a:** `SoporteConsultaExternaActorNegocio.cs:292`, que ya deriva la primera respuesta con `MIN(fechaenvio)` de los mensajes públicos de soporte.

**Archivos:** `Blip.Data/Soporte/SoporteMensajesActorNegocio.cs` (`RegistrarMensajeSoporte`, único punto donde soporte guarda un mensaje; lo llama `Negocio/Soporte/SoporteMensajesActorNegocio.EnviarMensajeSoporte`), un script SQL de backfill, la vista `soporte_soportevistadetalleincidente` (`respondioensla`) y `ANALISIS.md` / `REQUERIMIENTO.md`.

- [ ] **Paso 1:** Definir con el usuario el alcance de H6: `respondioensla` hoy compara `fecharespuesta` contra `horasmaximo` (ahora resolución) en horas de calendario. Debe comparar contra `horasrespuesta` en horas hábiles. Leer la definición de la vista en la BD antes de decidir.
- [ ] **Paso 2:** En `RegistrarMensajeSoporte`, tras el `Insert`, si `!esPrivado`: `UPDATE ... SET fecharespuesta = @fecha WHERE id = @idgestion AND fecharespuesta IS NULL` (campos estáticos de `GestionMaestroCRM`, `Split('.')[2]` en el SET). Un solo UPDATE atómico, sin leer antes.
- [ ] **Paso 3:** Script de backfill (`entregables/...`): llenar `fecharespuesta` de los tickets existentes con el `MIN(fechaenvio)` de sus mensajes públicos de soporte. Decidir con el usuario si se corre o se deja solo para tickets nuevos.
- [ ] **Paso 4:** Ajustar `respondioensla` (según Paso 1) y actualizar `ANALISIS.md` / `REQUERIMIENTO.md` con la regla nueva.
- [ ] **Paso 5:** Build: 0 errores.
- [ ] **Paso 6 (prueba manual):**
  - **Dado** un ticket sin respuesta, **cuando** soporte envía un mensaje público, **entonces** `fecharespuesta` = `fechaenvio` de ese mensaje.
  - **Dado** ese ticket, **cuando** soporte envía un segundo mensaje, **entonces** `fecharespuesta` no cambia.
  - **Dado** un ticket sin respuesta, **cuando** soporte envía una nota privada o escribe el cliente, **entonces** `fecharespuesta` sigue vacía.
  - **Dado** un ticket respondido, **entonces** el portal muestra la "fecha respuesta real" y `respondioensla` da un valor coherente.

---

## Autorrevisión

- **Cobertura:** criterio 1 (T1), 2 (T1), 3 (T2), 4 (T2). Reglas confirmadas del análisis: suma sin registrar respuesta (T1, nada toca `fecharespuesta`), sin recálculo de tickets (T2, Foco 5), total en la fecha límite que ve el cliente (T1). H5 y H6 se dejan como están, por decisión.
- **Orden:** T1 → T2. T1 deja el build roto en un solo punto si se ejecuta aislada (ver Paso 5).
- **Antes de desplegar:** aplicar el script en producción **antes** de publicar el código. Sin la columna, `CrearSelect` falla y no se puede crear ningún ticket del portal.
