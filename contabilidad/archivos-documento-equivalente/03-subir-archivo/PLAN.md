# Plan: subir archivos al documento equivalente

> [← README](./README.md) · Análisis: [ANALISIS.md](./ANALISIS.md) · Decisiones: [ADR-001](../ADR.md), [ADR-002](../ADR-002.md) · Plan histórico: [archivo/PLAN.md](../archivo/PLAN.md)

**Antes de programar:** `EXPLICACION.md` (parte lógica) y entrevista; después, paso 3b antes de commitear ([flujo](../../../guia/flujo-de-feature.md)). Skills según la capa: `siian-actor-dapper-metodos`, `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`.

**Regla de todas las tareas:** el dueño (comprobante o documento equivalente) lo fija el punto de entrada, nunca el formulario ([ADR-003](../ADR-003.md)): un controlador por dueño en lo que escribe, una acción por dueño en lo que lee, y las reglas comunes en un solo método de `Negocio/`. Marcas: `[L1]` latin1, `[FUERA]` script SQL fuera del repo, `[CSPROJ]` archivo nuevo a registrar.

## Tareas

- [x] 1. `[L1]` `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs`: `CrearRelacion(...)` reemplaza las dos construcciones duplicadas (local y remota) con el ancla correcta. · Se parece a: las dos construcciones actuales
- [x] 2. `ArchivoContableUploadViewModel.cs`: `IdDocumentoContable` opcional (ya tiene `IdDocumentoEquivalente`). · Se parece a: `EliminarArchivosRequest`
- [x] 3. `[L1]` Método común en `Negocio/` (`SubirArchivoAPendiente(doc, idContable, idEquivalente, idUsuario, usuario)`): mueve del controlador el flujo ruta → pendiente y tipo → extensión → vencimiento → subir → registrar cargado. El dueño llega por parámetro, no del formulario. · Se parece a: el cuerpo actual de `SubirArchivo`
- [x] 4. `[L1]` WebApi de pendientes y vencidos: una acción por dueño (`GetContable` / `GetEquivalente`). · Se parece a: `DocumentoContableCargado/Eliminado` de 02
- [x] 5. `DocumentoContableCargadoWebApiController` y `VistaDocumentoContableCargadosWebApiController`: igual, una acción por dueño. · Se parece a: lo hecho en 02
- [x] 5b. MVC: controladores independientes por dueño (decisión 2026-10-21). `DocumentoContableArchivoController` conserva `Index(iddocumento)` y su `SubirArchivo` llama al método común con `(iddocumento, null)`; `DocumentoEquivalenteArchivoController` nuevo con `Index(iddocumentoequivalente)` y `SubirArchivo(iddocumentoequivalente, doc)` que llama con `(null, id)`. Cada `Index` deja en `ViewBag` el dueño, el título, la ruta de vuelta y las acciones de cada lista. · Se parece a: `DocumentoEquivalenteComboController` de 02
- [x] 6. `[L1]` `Views/DocumentoContableArchivo/Index.cshtml`: los dos ids en Razor y JS, título según cuál viene, `listarDocumentos()` hacia la pantalla de combos con el id del dueño. · Se parece a: la misma vista en contable
- [x] 7. `[L1]` `_GestionDocumentos.cshtml`: id del dueño en los `LoadParams` de cargados, pendientes y vencidos. · Se parece a: los `LoadParams` actuales
- [x] 8. `_SubirArchivo.cshtml`: sin campos ocultos; el dueño viaja en `ViewBag.UrlSubir` (URL del controlador de cada dueño), nunca en el formulario. · Cambia respecto al plan original: más estricto con ADR-003.
- [x] 9. `[L1]` `Views/DocumentoContableCombo/Index.cshtml`: `adjuntar()` hacia la pantalla de archivos con el id del dueño. · Se parece a: `adjuntar()` actual
- [x] 10. `Views/DocumentoEquivalente/EdicionV2.cshtml`: botón **"Adjuntar"**, deshabilitado con `Id == 0`, que abre `DocumentoEquivalenteArchivo/?iddocumentoequivalente=@Id&origen=...`. · Se parece a: `adjuntar()` de `DocumentoContable/CreateV2.cshtml`
- [x] 11. Compilar Debug sin errores (2026-10-21).

## Verificación

Probado el 2026-10-21 en `25.44.200.158/rep1` con el documento equivalente 1085 y el comprobante 168816. Capturas en `evidencia/`.

- [x] E1: en `NuevoV2` "Adjuntar" y "Listar Documentos" salen deshabilitados (`E1-adjuntar-deshabilitado.png`).
- [x] E6: `.txt` al pendiente 37 (tipo firma) → rechazado con "Extensiones permitidas: .pdf"; sin datos nuevos.
- [x] E6b: PDF al pendiente 41 → `CARGADO` con `Iddocumentoequivalente = 1085`; aparece en Cargados (`E6b-cargado-1085.png`). Deja un archivo de prueba, id 18355 (`verificacion03-e6b.pdf`).
- [ ] E10: contabilizar el 1085 y ver que el comprobante no muestra los archivos. Escribe datos; pendiente de autorizar aparte.
- [x] Dueño cruzado rechazado sin tocar datos, en los dos sentidos: pendiente 37 (equivalente) por el controlador contable, y pendiente 33 (contable) por el del equivalente → "El documento solicitado no corresponde al documento indicado."
- [x] Contable sin cambios contra `../antes/` (comprobante 168816): remoto, eliminados y vencidos idénticos. Cargados añade solo el campo `Iddocumentoequivalente: null` en cada fila. Pendientes trae los mismos 33 y 34 más el 40, que es un solicitado creado después de la línea base (pruebas de 02), no un cambio de código.
- [ ] Commit propio de esta feature (el código de 03 quedó repartido en los commits de 02; decidir si se deja así).
