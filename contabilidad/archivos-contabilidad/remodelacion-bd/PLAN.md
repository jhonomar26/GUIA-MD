# Subida de archivos sobre el modelo nuevo: plan de implementación

> Se trabaja **tarea por tarea**. Antes de programar cada etapa, su parte de negocio va en `explicacion/etapa-N-….md` (el modelo está en `EXPLICACION.md`) y hay entrevista ([flujo de feature](../../../guia/flujo-de-feature.md)). Las casillas se tildan solo con evidencia.

**Objetivo:** que la pantalla de subida (`Views/DocumentoContableArchivo/`) funcione sobre el modelo pedido → puente → `contabilidad_archivocontable`, con crédito como referencia, para el comprobante y el documento equivalente.

**Spec:** [`ANALISIS.md`](./ANALISIS.md) (S1-S11) · [`ADR.md`](./ADR.md) · modelo en [`EXPLICACION.md`](./EXPLICACION.md)

**Stack:** .NET 4.6.2, MVC 5 + Web API 2, Dapper, PostgreSQL, DevExtreme. Sin tests automáticos: cada tarea cierra con build y los casos Dado/Cuando/Entonces del `ANALISIS.md`.

## Restricciones globales

- **Codificación:** son ISO-8859-1 con CRLF `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs`, `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs`, `Controllers/Contabilidad/DocumentoContableArchivoController.cs` y las vistas `.cshtml` de la pantalla. Se editan a nivel de bytes (`latin1`), nunca con Edit/Write. Antes de editar cualquier otro archivo se revisa su codificación con `file`.
- SQL con campos estáticos (`ArchivoContable.EseliminadoCampo`, `.Split('.')[2]` en `SET`), `DynamicParameters`, `ObtenerLista(...)`, `catch (Exception) { throw; }`.
- Dapper solo en `Blip.Data/`; `Negocio/` sin Dapper ni `GeneralDao.Connection`.
- Conexión: los controladores con `[Log]` o `[LogApi]` no llevan `finally`; se revisa que el filtro esté puesto.
- Archivo `.cs` nuevo = registrarlo en su `.csproj`.
- El dueño (comprobante o equivalente) sale de la URL, nunca del formulario.
- **Compilar = desplegar** al servidor de pruebas `25.44.200.158/rep1`: `msbuild PruebaPostgreSQL.sln -p:Configuration=Debug`.
- Las acciones borradas del WebApi se restauran en el **mismo** `DocumentoContableArchivoWebApiController`, tomando el código de `git show 7be4d590c^:…` pero **con el patrón único** (siguiente punto), no con los nombres de antes.
- **Patrón único para comprobante y equivalente (S12, [ADR-002](./ADR-002.md)):** toda acción (WebApi y MVC) recibe `iddocumento` e `iddocumentoequivalente` como `int?` con valor por defecto `null` (sin el valor por defecto, WebApi responde 404 si falta uno de los dos). Llega exactamente uno. Quien decide es `ArchivoContableDuenoActorNegocio` (Negocio), que delega en `DocumentoContableArchivoActorNegocio` o `DocumentoEquivalenteArchivoActorNegocio`. **De ahí hacia abajo, un `int` por dueño:** en `Data`, un método por dueño (`...PorIddocumentocontable(int)` / `...PorIddocumentoequivalente(int)`) sobre un `Consultar...` privado, sin el par `int?`. No se crean pares `...Equivalente` en la capa web. Resumen y checklist en [`conceptos/PATRON_DOS_DUENOS.md`](../../../conceptos/PATRON_DOS_DUENOS.md).
- Commits solo cuando el usuario los pida, después de la entrevista de propósito (paso 3b).

---

> Cómo salió cada tarea (evidencia, decisiones, errores): [`BITACORA.md`](./BITACORA.md). Aquí solo queda qué hacer y si está hecho.

## Etapa 1: subir un archivo (S1, S2, S3, S4, S5)

Prueba de la etapa: en un comprobante y en un documento equivalente, subir un archivo a un pendiente y verlo en Cargados. Explicación: [`etapa-1-subir.md`](./explicacion/etapa-1-subir.md).

### T1.1 Pendientes según la regla de crédito (S1)
Se parece a: `DocumentoCreditoCreditoWebApiController.GetPendientesPorIdCredito:56` (regla) y la consulta actual `ConsultarPendientes` (`DocumentoContableSolicitadoActorNegocio.cs:351-389`), que solo cambia su `WHERE`.

- [x] Agregar a la consulta la condición "sin ninguna fila en el puente" (`NOT EXISTS` sobre `contabilidad_documentocontablearchivo`). Mantener los campos y el orden por id del JSON.
- [x] Restaurar `ObtenerSolicitadosPendientesPorId` y `ObtenerSolicitadosPendientesPorIdEquivalente` en el WebApi (`7be4d590c^`, líneas 141-166).
- [x] Prueba S1 en comprobante (2026-10-28): pedido con archivo, pedido eliminado y pedido de otro dueño rechazados; el pedido sale de Pendientes al subir. Equivalente 1054 repetido (2026-10-28): cruces de dueño rechazados.

### T1.2 Rutas (S2)
Se parece a: `ObtenerRutasContables` / `ObtenerRutasDocumentoEquivalente` de `7be4d590c^` (líneas 167-216).

- [x] Restaurarlas con la proyección en Negocio (`RutaAlmacenamientoViewModel`); el WebApi solo llama y responde.
- [ ] Prueba S2 con sesión (junto con la de T1.3).

### T1.3 Subir (S3, S4)
Se parece a: `CargaArchivosActorNegocio.ValidarYSubirArchivo:390` y `SubirArchivoRemoto:303` (crédito), y al código comentado en `DocumentoContableArchivoActorNegocio.cs:109-312`.

- [x] `Negocio`: adaptar `SubirArchivoAPendiente…` (validar el pedido con la regla de T1.1, guardar `ArchivoContable`, luego el puente).
- [x] Documento único (S4): no se codifica; lo cubren la regla de tipo único al pedir y la validación S1.
- [x] Límite de almacenamiento antes de guardar, igual que crédito.
- [x] Controladores: restaurar `SubirArchivo` en `DocumentoContableArchivoController:62` y en `DocumentoEquivalenteArchivoController:29`.
- [x] Prueba S3 y S4 en comprobante (2026-10-28): observación vacía, `.exe`, 0 bytes y subida válida. Fecha manual (R8) y equivalente probados. **Falta** el límite de almacenamiento.

### T1.4 Ver archivo (S5)
Se parece a: `VisualizarArchivo` actual (`DocumentoContableArchivoActorNegocio.cs:580-587`).

- [x] Leer `ArchivoContable` (y sus credenciales FTP) en lugar de `Archivo`.
- [x] Validar que el archivo sea del dueño (puente → pedido → dueño).
- [x] Prueba S5 (2026-10-28): ver archivo propio da PDF; ajeno, inexistente y sin dueño rechazan. Falta pulsar "Ver" en pantalla.

---

## Etapa 1.5: una responsabilidad por clase (S12)

Prueba de la etapa: build en 0 errores y las pruebas de S1-S5 dan lo mismo que antes. **Solo se mueve código, no cambia comportamiento.**

### T1.5 Separar `DocumentoContableArchivoActorNegocio`
Se parece a: la separación por dueño de `DocumentoEquivalentePermisosActorNegocio` y la regla de nombrar la clase de Negocio por lo que hace (skill `siian-actor-dapper-metodos`).

- [x] `DocumentoContableArchivoActorNegocio`: queda solo el comprobante.
- [x] `DocumentoEquivalenteArchivoActorNegocio` (nueva): los mismos métodos para el equivalente.
- [x] `ArchivoContableReglasActorNegocio` (nueva): extensiones, tipos, vencimiento y nombres. Sin dueño.
- [x] `ArchivoContableAlmacenamientoActorNegocio` (nueva): guardar el físico en local o FTP, rutas y `LeerArchivo`. Sin dueño.
- [x] `ArchivoContableSubidaActorNegocio` (nueva, no estaba en el plan): el flujo de subida compartido.
- [x] Mover por tandas, compilando cada una; cada `.cs` nuevo en `Negocio.csproj`; editar en latin1 a nivel de bytes.
- [x] Decidido: el WebApi **no** se parte por dueño; un solo punto de entrada (`ArchivoContableDuenoActorNegocio`) que recibe los dos ids. Detalle en la bitácora.
- [ ] Prueba S12 y repetir S1-S5.

---

## Etapa 2: Cargados y Vencidos (S6, S7)

Antes: resolver P1 (Vencidos y pedidos retirados).

### T2.1 Cargados solo de pedidos activos (S6)
Se parece a: la vista de combos de cargados del script 14 (ya filtra `s.esactivo = true`).

- [x] Script nuevo en `scriptsSiian/contabilidad/scratch/archivos-documento-contable/`: rehacer `contabilidad_vistadocumentocontablecargados` con `s.esactivo = true`. Se corre en `demo`.
- [x] `VistaDocumentoContableCargadosWebApiController.ActualizarArchivo:94-115`: usar `ArchivoContableActor`.
- [x] Prueba S6.

### T2.2 Vencidos (S7)
Se parece a: `VistaCreditoArchivosWebApiController.ArchivosVencidosPorCredito:55`.

- [x] Reescribir `ConsultarVencidos` (`DocumentoContableSolicitadoActorNegocio.cs:291-333`) sobre la vista de cargados o sobre el puente + `archivocontable`, según P1.
- [x] Restaurar **una sola** `ObtenerVencidos(int? iddocumento = null, int? iddocumentoequivalente = null)` en el WebApi, que llama a `ArchivoContableDuenoActorNegocio.ObtenerVencidos` (`7be4d590c^`, líneas 217-240).
- [x] Prueba S7.

---

## Etapa 3: eliminar (S8, S9)

Explicación: [`etapa-3-eliminar.md`](./explicacion/etapa-3-eliminar.md) y [`reglas-eliminar-y-retirar.md`](./explicacion/reglas-eliminar-y-retirar.md).

### T3.1 Eliminar y recrear
Se parece a: `CargaArchivosActorNegocio.ValidarBorrado:24` y `BorrarDocumentosSeleccionados:119`.

- [x] `EliminarArchivos` sobre `ArchivoContable`: una constancia, cada archivo `Eseliminado = true`, físico borrado y volumen recalculado, sin tocar el pedido (clase `ArchivoContableEliminacionActorNegocio`).
- [x] Recrear (S9, ADR-001): descripción `""`, `Esobligatorio = true`, `Esactivo = true`, mismo dueño, tipo y tercero.
- [x] Validar el dueño de cada archivo (H3), en `ArchivoContableDuenoActorNegocio`.
- [x] Restaurar `EliminarArchivos` en el WebApi con el patrón único (`7be4d590c^`, líneas 113-140). Permiso R14 confirmado por ruta, sin acción de controlador.
- [x] README del área: DP3 marcada como superada.
- [x] Prueba S9 en comprobante (2026-10-28): "No", "Sí" y dos archivos con una sola constancia; S8 validación de dueño y observación. Equivalente probado ("No" y "Sí"). **Falta** el permiso en el servidor (3.1).

---

## Etapa 4: firma (S10)

### T4.1 Firma sobre el archivo contable
Se parece a: el código actual de firma, cambiando solo la tabla del archivo.

- [x] `Blip.Data/Firmas/FirmaArchivoContable.cs:9-18`: carga perezosa de `ArchivoContable`.
- [x] `Negocio/Firmas/FirmaArchivoContableActorNegocio.cs`: `ObtenerSolicitadoPorIdarchivo` va por el puente; `Archivo` → `ArchivoContable` en las líneas 42, 50, 100, 164, 198 y 337.
- [x] Revisar `SIIAN.VozData/Handlers/FirmarDocumentoCarpetaVirtualHandler.cs:122`: sin cambios.
- [ ] Prueba S10 (con sesión; en `demo` no hay archivos hasta T1.3).

---

## Etapa 5: limpieza (S11)

### T5.1 Borrar el modelo viejo y corregir el script 11
- [x] Borrar `DocumentoContableCargado*`, `DocumentoContableEliminado*` y `EstadoDocumentoContable*` (entidades, actores, ViewModels, WebApi) y sus líneas en `Data.csproj`, `Entities.csproj` y el `.csproj` web. Borrar los métodos viejos de `DocumentoContableSolicitadoActorNegocio.cs` (`:36-272`), si nadie más los usa.
- [ ] Script 11: corregir `CREATE VIEW OR REPLACE`, la vista 6.1 que usa `contabilidad_archivocontable` antes de que exista, y los comentarios de la regla vieja.
- [x] Prueba S11: búsqueda sin resultados y build en 0 errores (2026-10-28; tablas viejas ausentes en `pg-demo`).

### T5.2 Alinear `Data` con el patrón por dueño
Se parece a: `ObtenerPendientesPorIddocumentocontable` / `...PorIddocumentoequivalente` sobre un `Consultar...` privado ([ADR-002](./ADR-002.md), punto 4).

- [ ] `VistaDocumentoContableCargadosActor.ObtenerPorDocumento`, `VistaDocumentoContableSolicitadoEstadoActor` y las vistas de combos usan hoy el par `int?` + `ObtenerCampoDelDueno`. Pasarlas a un método por dueño con un `int`, y que `ArchivoContableDuenoActorNegocio.ObtenerCargados` llame al método de cada dueño.
- [ ] Prueba: el build da 0 errores y las pestañas Cargados y Cargados (Remoto) muestran lo mismo que antes en un comprobante y en un equivalente.

---

## Seguimiento

| Tarea | Specs  | Estado                                                           | Commit |
| ----- | ------ | ---------------------------------------------------------------- | ------ |
| T1.1  | S1     | hecho y probado en comprobante y equivalente                     |        |
| T1.2  | S2     | código hecho; prueba con sesión en T1.3                          |        |
| T1.3  | S3, S4 | probado en comprobante y equivalente; falta límite de almacenamiento |    |
| T1.4  | S5     | hecho y probado (falta botón "Ver" en pantalla)                  |        |
| T1.5  | S12    | código hecho; falta repetir S1-S5 con sesión                     |        |
| T2.1  | S6     | hecho (cerrado por el usuario 2026-10-27)                        |        |
| T2.2  | S7     | hecho (cerrado por el usuario 2026-10-27)                        |        |
| T3.1  | S8, S9 | probado en comprobante y equivalente; falta permiso (3.1)        |        |
| T4.1  | S10    | código hecho; prueba con sesión pendiente de T1.3                |        |
| T5.1  | S11    | código y prueba hechos; falta solo el script 11 (fuera de alcance por ahora) |        |
| T5.2  | S12    | pendiente                                                        |        |
