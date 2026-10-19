# Consultas de documentos contables en SQL — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDA: `superpowers:subagent-driven-development` o `superpowers:executing-plans`, tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** que la lista de pendientes de un comprobante salga de una sola consulta SQL (solicitado + tipo) y borrar las tres consultas sin uso que traen tablas completas.

**Arquitectura:** consulta directa con Dapper en el ActorNegocio de `Blip.Data` (ADR-001), igual que `ObtenerVencidosPorIddocumentocontable`. El controlador solo calcula `Extensiones` en C#, porque `ObtenerExtensionesPermitidas` vive en `Negocio/` y `Blip.Data` no puede llamarlo.

**Stack:** .NET 4.6.2, Web API 2, Dapper, PostgreSQL (Npgsql 2.2.7), DevExtreme (las grillas no cambian).

**Spec:** [`ANALISIS.md`](./ANALISIS.md) · [`ADR.md`](./ADR.md) · [`REQUERIMIENTO.md`](./REQUERIMIENTO.md)

## Restricciones globales

- **Codificación:** `DocumentoContableArchivoWebApiController.cs` y `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs` son ISO-8859-1 con CRLF. Se editan a nivel de bytes (Python `rb`/`wb` + `latin1`), nunca con Edit/Write ni `sed -i`. Después: `rg "(?-u:\xEF\xBF\xBD)" <archivo>` sin resultados y `git diff --stat` solo con las líneas esperadas.
- `DocumentoSolicitadoPendienteViewModel.cs` es UTF-8 con BOM: Edit normal sirve.
- SQL con campos estáticos (`DocumentoTipo.NombreCampo`, etc.), nunca literales de tabla/columna. `DynamicParameters`. `catch (Exception) { throw; }`.
- El controlador tiene `[LogApi]`: sin `finally` para cerrar la conexión.
- No cambian reglas: pendiente = solicitado activo + estado `PENDIENTE` + tipo activo (R13); un eliminado no vuelve (R9).
- La respuesta JSON de `ObtenerSolicitadosPendientesPorId` queda idéntica: mismos campos, mismos valores, mismo orden.
- **Compilar = desplegar** al servidor de pruebas `25.44.200.158/rep1`. En git bash: `msbuild PruebaPostgreSQL.sln -p:Configuration=Debug` (con `-p:`, no `/p:`).
- Sin tests automáticos: cada tarea cierra con build + casos Dado/Cuando/Entonces del `ANALISIS.md`.
- Commit solo si el usuario lo pide, después de la entrevista de propósito (GUIA, paso 3b).

## Foco de revisión

1. **Orden.** Hoy la consulta de solicitados no tiene `ORDER BY` (`DocumentoContableSolicitadoActor.cs:225`); la nueva ordena por id. Si la captura "antes" no viene ordenada por id, se anota y se decide con el usuario antes de seguir. Lo cubre el paso 1.4.
2. **Columnas repetidas.** `esactivo` existe en solicitado y en tipo. Si no se pone alias, Dapper puede mapear el del tipo. Cada columna lleva `AS` explícito.
3. **Campos de más en el JSON.** `EsFoto` y `EsFirmaElectronica` se agregan al ViewModel solo para el cálculo. Llevan `[JsonIgnore]` para no cambiar la respuesta.
4. **Tipo inactivo.** Antes se descartaba en memoria (`tipos[...].Esactivo`); ahora va en el `WHERE`. Caso 3 de la verificación.
5. **Comprobante sin pendientes.** Antes devolvía `new List<object>()`; ahora, una lista vacía del ViewModel. Las dos se serializan como `[]`. Caso 5.

---

### Tarea 0: Capturar el "antes"

Sin código. Va primero porque, una vez compilado, el servidor ya no tiene la versión vieja.

- [x] **0.1** Con `pg-demo` (solo lectura), elegir comprobantes reales de `demo-25-09-2026`:
  - A: con 2 o más pendientes de tipos distintos (al menos uno con `esfoto` o `esfirmaelectronica` en true).
  - B: con un solicitado `PENDIENTE` de un tipo inactivo. Si no hay, se le pide al usuario que inactive un tipo en la pantalla de configuración y lo reactive al terminar (`claude_ro` no puede escribir).
  - C: con un solicitado `ELIMINADO` (recreado o no).
  - D: sin pendientes.
- [x] **0.2** Con sesión iniciada (skill `probar-en-navegador`, Orca), guardar la respuesta de `GET /rep1/api/DocumentoContableArchivoWebApi/ObtenerSolicitadosPendientesPorId?idDocumento=<id>` para A, B, C y D en `evidencia/antes-<id>.json` dentro de esta carpeta.
- [x] **0.3** Captura del selector "Documento" de la subida en el comprobante A (extensiones, expira, fecha manual).

### Tarea 1: Pendientes con una sola consulta SQL

Se parece a: `ObtenerVencidosPorIddocumentocontable` (`Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs`), mismo archivo y mismo estilo.

**Archivos:**
- Modificar: `Blip.Entities/Contabilidad.ViewModels/DocumentoSolicitadoPendienteViewModel.cs`
- Modificar: `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs` (latin1; método nuevo después de `ObtenerVencidosPorIddocumentocontable`)
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs:255-302` (latin1; cuerpo de `ObtenerSolicitadosPendientesPorId`)

**Interfaces:**
- Produce: `public static List<DocumentoSolicitadoPendienteViewModel> ObtenerPendientesPorIddocumentocontable(int p_iddocumentocontable)` en `partial class DocumentoContableSolicitadoActor`.
- Produce: en el ViewModel, `[JsonIgnore] public bool EsFoto { get; set; }` y `[JsonIgnore] public bool EsFirmaElectronica { get; set; }` (`using Newtonsoft.Json;`; `Entities.csproj` ya referencia Newtonsoft 12.0.2).
- Consume: `DocumentoContableArchivoActorNegocio.ObtenerExtensionesPermitidas(bool esFoto, bool esFirmaElectronica = false) : string[]` (`Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs:445`).

- [x] **1.0** `EXPLICACION.md`, parte lógica: hoy son dos lecturas y un cruce en memoria; mañana es una consulta y el cálculo de extensiones. Entrevista breve al usuario. No se escribe código hasta que lo explique con sus palabras.
- [x] **1.1** Invocar la skill `siian-actor-dapper-metodos`. Agregar las dos propiedades `[JsonIgnore]` al ViewModel.
- [x] **1.2** Implementar `ObtenerPendientesPorIddocumentocontable`. Fija esto:
  - `FROM DocumentoContableSolicitado INNER JOIN DocumentoTipo ON DocumentoTipo.IdCampo = DocumentoContableSolicitado.IdtipodocumentoCampo`
  - Columnas con alias explícito: solicitado → `id`, `idtipodocumento`, `descripcion`, `esactivo`, `esobligatorio`; tipo → `nombre`, `expira`, `esfechamanual`, `diasvencimientodespuescargue`, `esdocumentounico`, `esfoto`, `esfirmaelectronica`.
  - `WHERE` solicitado `iddocumentocontable = @iddocumentocontable AND esactivo = true AND codigoestadodocumento = 'PENDIENTE' AND` tipo `esactivo = true`.
  - `ORDER BY DocumentoContableSolicitado.IdCampo`.
  - Comentario de una línea con el porqué: `// Pendiente = solicitado activo en estado PENDIENTE (R13) y de tipo activo; un ELIMINADO no vuelve (R9)` (se mueve del controlador).
  - `GeneralDao.Connection.Query<DocumentoSolicitadoPendienteViewModel>(...)`, como el precedente.
- [x] **1.3** En el controlador, el cuerpo del `try` de `ObtenerSolicitadosPendientesPorId` queda así: llamar a `ObtenerPendientesPorIddocumentocontable(idDocumento)`, asignar `Extensiones = ObtenerExtensionesPermitidas(p.EsFoto, p.EsFirmaElectronica)` a cada elemento y devolver `Ok(lista)`. Se quitan el `if (!solicitados.Any())` y el diccionario de tipos. La firma y el `catch` no cambian.
- [x] **1.4** Verificar la codificación (ver restricciones) y compilar: 0 errores. Repetir el 0.2 en `evidencia/despues-<id>.json` y comparar con `diff` contra el "antes":
  - A: idéntico campo por campo. Si solo cambia el orden, frenar y consultar (foco 1).
  - B: el solicitado de tipo inactivo no aparece, ni antes ni después.
  - C: el eliminado no aparece.
  - D: `[]`, HTTP 200.
  - Captura del selector en A igual a la del 0.3.
- [x] **1.5** *(omitido por decisión del usuario: cambio simple)* `EXPLICACION.md`, parte de código. Entrevista de propósito (paso 3b): ¿por qué `INNER JOIN` y no `LEFT`? ¿qué pasa si se quita el alias de `esactivo`? ¿por qué `Extensiones` no se calcula en `Blip.Data`?
- [x] **1.6** Commit, solo si se pide: `refactor(contabilidad): pendientes de documento en una sola consulta SQL`

### Tarea 2: Borrar las tres consultas sin uso

Se parece a: nada que copiar; es borrado. El uso ya se descartó en el `ANALISIS.md` (H1, preguntas resueltas).

**Archivos:**
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs` (latin1): borrar `ObtenerPorDocumento` (`:93-127`), `ObtenerSolicitadosPendientes` (`:156-212`) y `ObtenerSolicitadosPendientesEstado` (`:214-251`), con sus `[HttpGet]`.

**Interfaces:** ninguna. No se toca `VistaDocumentoContableCargadosActor.ObtenerPorDocumento`, que tiene el mismo nombre pero es otra cosa y sí se usa.

- [x] **2.1** Volver a confirmar que no hay usos: `rg -n "ObtenerSolicitadosPendientes\b|ObtenerSolicitadosPendientesEstado|DocumentoContableArchivoWebApi.*ObtenerPorDocumento|ObtenerPorDocumento\"" PruebaPostgreSQL --glob '!bin/**' --glob '!obj/**'`. Lo esperado: 0 resultados fuera del controlador.
- [x] **2.2** Borrar los tres métodos (bytes latin1). No tocar los `using`, aunque alguno quede sin uso (diff mínimo).
- [x] **2.3** Verificar la codificación y compilar: 0 errores. `rg -n "ObtenerRegistros" <controlador>` debe dejar solo `CompaniasActor.ObtenerRegistros()` en `ObtenerVencidos`: es una fila de configuración, igual que la exclusión de H5.
- [x] **2.4** Regresión rápida en el comprobante A: las pestañas Pendientes, Cargados y Vencidos abren sin error.
- [x] **2.5** `IMPLEMENTACION.md` con `## Archivos tocados`, `## Cambio` y `## Verificación`: un renglón por caso, con el resultado obtenido. Actualizar el `README.md` de la feature (fila del plan, estado) y el del módulo si cambia el estado.
- [x] **2.6** Commit, solo si se pide: `refactor(contabilidad): borrar consultas sin uso de documentos contables`
