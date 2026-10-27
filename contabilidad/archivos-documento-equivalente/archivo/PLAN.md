> **Histórico (2026-10-20).** Plan original en 4 fases. Se partió en features verticales: ver el [README del área](../README.md). Se conserva para trazabilidad; no se tilda más.

# Plan: archivos en documento equivalente

> [← README](../README.md) · Spec: [ANALISIS.md](../ANALISIS.md) · Decisión: [ADR.md](../ADR.md) · Fuente: engram `sdd/archivos-documento-equivalente/tasks`

**Orden:** fase 0 → script 10 → PR1 → script 11 → PR2 → PR3. Cada fase compila sola. Por cada fase: `EXPLICACION.md` + entrevista antes de programar, y paso 3b antes de commitear ([flujo](../../../guia/flujo-de-feature.md)).

**Marcas:** `[L1]` archivo latin1, se edita a nivel de bytes y el texto nuevo va en ASCII. `[CSPROJ]` archivo nuevo, se registra en el `.csproj`. `[FUERA]` script SQL en `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\archivos-documento-equivalente\` (los contables 1-9 están en `scratch\archivos-documento-contable\`), fuera del repo.

**Tamaño:** 500 a 600 líneas (PR1 ~200, PR2 200-250, PR3 ~100). **Entrega:** una sola rama, `feature/contabilidad-archivos-documento-equivalente`, creada desde `feature/contabilidad-detalle-constancia-eliminacion` (ahí vive el expediente contable). Las fases son el orden de trabajo, no PRs separados.

## Fase 0: verificación previa (7)

- [x] 0.1 Demo: `SELECT version();` ≥ 9.6 (para `num_nonnulls`). Si es menor, CHECK de respaldo `(iddocumentocontable IS NULL) <> (iddocumentoequivalente IS NULL)`.
- [x] 0.2 Demo: `pg_constraint` y `pg_index` de las tres tablas. Sin UNIQUE sobre `iddocumentocontable`; existe PK de `contabilidad_documentoequivalente.id`. Anotar nombres reales.
- [x] 0.3 Demo: `pg_get_viewdef` de `contabilidad_vistadocumentocontablecargados` y `contabilidad_vistaarchivoseliminados` contra los scripts 6 y 8. Si difieren, el script 10 parte de la definición viva. Revisar `pg_depend`.
- [x] 0.4 Confirmar que `NpgsqlException.Code` existe en Npgsql 2.2.7. Si no, el 409 usa `ex.Message.Contains("23503")`.
- [x] 0.5 Confirmar codificación de los 9 archivos marcados `[L1]` abajo.
- [x] 0.6 Foto "antes" del comprobante 168816 con curl a `25.44.200.158/rep1`: solicitados, pendientes, vencidos, cargados (remoto sí/no), cargado, eliminado. Guardar el comando exacto.
- [x] 0.7 Acta "antes" de una constancia contable existente.

**Resultados 0.1-0.5 (2026-10-19):**
- 0.1 PostgreSQL 11.18: `num_nonnulls` disponible, sin CHECK de respaldo.
- 0.2 Sin UNIQUE sobre `iddocumentocontable`. PK `<tabla>_pkey` en las 4. FK actuales hacia `contabilidad_documentocontable` son `ON DELETE CASCADE`: `..._documentocontablearchivo_iddocumentocontable_fkey`, `..._documentocontablecombo_iddocumentocontable_fkey`, `..._documentocontablesolicitado_iddocumentocontable_fkey` (nótese que el de solicitado tiene el nombre truncado: `contabilidad_documentocontablesolicita_iddocumentocontable_fkey`). Índices existentes: `ix_contabilidad_documentocontablecombo_iddocumentocontable`, `ux_doccombo_tipodoc` (parcial). Solicitado y archivo NO tienen índice sobre `iddocumentocontable`.
- 0.3 Las dos vistas vivas coinciden con los scripts 6 y 8. Sin vistas dependientes (`pg_depend`).
- 0.4 `NpgsqlException.Code` existe (`get_Code` en Npgsql 2.2.7): el 409 usa `ex.Code == "23503"`.
- 0.6 Foto "antes" guardada en `antes/*.json` (comprobante 168816, vía `fetch` con la sesión de Orca; curl directo da 401 porque exige cookie): `solicitados_pendientes` (1), `vencidos` (0), `cargados_local` (4), `cargados_remoto` (0), `eliminados` (7). Endpoints: `DocumentoContableArchivoWebApi/ObtenerSolicitadosPendientesPorId?idDocumento=`, `.../ObtenerVencidos?idDocumento=`, `VistaDocumentoContableCargadosWebApi/GetPorDocumento?iddocumento=&remoto=`, `DocumentoContableEliminadoWebApi/GetEliminadosPorIdDocumento?iddocumento=`. Para repetir: mismo `fetch` en la pestaña logueada y `diff` contra `antes/`.
- 0.7 Acta "antes" de la constancia 282 (3 archivos del 168816, tercero ACOSTA JURADO SUSAN, carpeta Contabilidad): `antes/acta_constancia_282.png`. La API `ObtenerFormatoEliminacionArchivos` solo da la plantilla (`antes/acta_constancia_282.json`), por eso la prueba es visual. Se genera en `Formatos/Edicion?id=35`: fijar `$('#selectConstanciaPreview').dxSelectBox('instance').option('value', 282)` y pulsar Previsualizar (el combo no filtra por texto).
- 0.5 Los 9 `[L1]` son ISO-8859 con CRLF; `EdicionV2.cshtml` es UTF-8 con BOM y CRLF.

## Fase 1: script 10 + PR1 datos (21)

Sin cambio de comportamiento: contable queda idéntico.

**Script 10** `[FUERA]` · Se parece a: scripts 4 (índice sobre `iddocumentocontable`), 6 y 8 (vistas)

- [x] 1.1 `10-archivos-documento-equivalente.sql`, idempotente y en transacción: columna en las tres tablas, `iddocumentocontable DROP NOT NULL`, FK `ON DELETE RESTRICT`, CHECK de dueño único, índices parciales, vista de cargados con la columna nueva al final, vista de eliminados con `LEFT JOIN` y `COALESCE` del tercero.
- [x] 1.2 `10-reversion-…sql`: conteos, borrar datos del documento equivalente en orden, `DROP VIEW`, quitar constraints/índices/columna, `SET NOT NULL`, recrear vistas 6 y 8, permisos `esactivo = false`.
- [x] 1.3 `pruebas-…sql` en `BEGIN … ROLLBACK`: dos anclas o ninguna → CHECK; ancla inexistente → FK; vista de eliminados con tercero del documento equivalente; borrar documento equivalente con expediente → 23503.
- [x] 1.4 (omitido: el script 10 ya estaba aplicado en demo) Correr 1.3 antes de aplicar (deben fallar) y aplicar 1.1 en demo.
- [ ] 1.5 Correr 1.3 después (pasan: hecho) y 1.1 por segunda vez (idempotente: pendiente).
- [ ] 1.6 Repetir curls de 0.6 con el código sin cambiar: JSON idéntico.
- [ ] 1.7 Probar 1.2 dentro de una transacción con `ROLLBACK`.

**PR1 datos** · Se parece a: entidades, actores y ViewModels actuales de `DocumentoContable*`; consultas de `DocumentoContableSolicitadoActorNegocio`

- [x] 1.8 ~~`OrigenDocumentoArchivo.cs`~~ **Descartado (2026-10-20):** no hay parámetro de origen; el dueño lo dicen los ids (ver [ADR](../ADR.md)). Se hizo y se borró antes de commitear.
- [x] 1.9 `[L1]` `DocumentoContableSolicitadoViewModel.cs`: `int? Iddocumentocontable`, `int? Iddocumentoequivalente`, constructor con `p_iddocumentoequivalente = null` al final.
- [x] 1.10 `DocumentoContableComboViewModel.cs` y `DocumentoContableArchivoViewModel.cs`: lo mismo.
- [x] 1.11 `EliminarArchivosRequest`: `int? IdDocumentoContable` e `int? IdDocumentoEquivalente`. En `ArchivoContableUploadViewModel` ya existía `IdDocumentoEquivalente`; hacer opcional `IdDocumentoContable` queda en 2.6.
- [x] 1.12 Entidades `DocumentoContable{Solicitado,Combo,Archivo}.cs`: `int?`, propiedad nueva, `IddocumentoequivalenteCampo` y `IddocumentoequivalenteTipo`, lazy con `?? 0`, constructor.
- [x] 1.13 Actores de las tres: columna en `CrearSelect`, `Insert` y `Update`. `ObtenerPorIddocumentoequivalente(int)` en el de solicitado.
- [x] 1.14 `VistaDocumentoContableCargados.cs` y `VistaArchivosEliminados.cs`: propiedad, `Campo`, `Tipo`, columna en `CrearSelect`.
- [x] 1.15 `[L1]` `DocumentoContableSolicitadoActorNegocio.cs`: las 7 consultas reciben `int? p_iddocumentoequivalente = null`; `ObtenerCampoDelDueno` elige la columna y `ObtenerIdDelDocumento` exige exactamente un id. Con solo el comprobante, el SQL es el mismo (el parámetro se llama ahora `@iddocumento`).
- [x] 1.16 `VistaDocumentoContableCargadosActorNegocio.ObtenerPorDocumento(..., int? p_iddocumentoequivalente = null)`.
- [x] 1.17 `DocumentoContableComboActorNegocio.InsertarConDocumentosSolicitados(combo, int? p_idtercero)`, copiando las dos anclas. El llamador sigue buscando el tercero del comprobante; el del documento equivalente llega en 2.4. (Estaba marcada hecha pero seguía asumiendo comprobante: corregida el 2026-10-20.)
- [x] 1.18 Arreglos de compilación por `int?` (`rg Iddocumentocontable`): solo `.Value` o `?? 0`, sin cambiar lógica. Es la tarea más pesada.
- [x] 1.19 Compilar Debug sin errores nuevos. Compilar actualiza el servidor de pruebas.
- [ ] 1.20 Curls de 0.6 + `diff`: idéntico. Si difiere, no se avanza.
- [ ] 1.21 `git diff --stat` ~200 líneas, sin tildes rotas en los `[L1]`.

**Cierre fase 1 (2026-10-20):** cerrada por decision del usuario, con pendientes que pasan a fase 2 (hechos el 2026-10-20 al arrancar la fase 2): 1.8, 1.11, 1.15 y 1.16 (rehechos sin parámetro de origen, ver ADR). Pruebas SQL de 1.3 pasaron en demo (P1-P5, 2026-10-20; P4 y P5 se corrigieron porque el script de pruebas omitia columnas NOT NULL y elegia un documento con otros hijos). Sin verificar: de 1.5 la segunda corrida del script 10 (idempotencia), 1.7 (reversion con ROLLBACK), 1.6 y 1.20 (curls vs `antes/`, la sesion de Orca vencio), 1.21. Compila Debug sin errores. Commits `wip` por squashear antes del PR.

## Fase 2: script 11 + PR2 negocio y servicios (20)

**Script 11** `[FUERA]` · Se parece a: script 9

- [ ] 2.1 `11-permisos-archivos-documento-equivalente.sql`, idempotente: rutas `~/DocumentoContableCombo/AgregarComboEquivalente`, `~/DocumentoContableCombo/AgregarDocumentoIndividualEquivalente` y `~/DocumentoContableArchivo/BorrarDocumentosSeleccionadosEquivalente`, asignadas a los roles que tienen la acción contable activa.
- [ ] 2.2 Correrlo dos veces en demo. Un rol con el permiso contable recibe el nuevo; uno sin él, no.

**PR2** · Se parece a: `AgregarCombo`, `TienePermiso*`, `EliminarArchivos` y las WebApi actuales

- [ ] 2.3 `DocumentoContableComboAsignacionActorNegocio.cs`: constantes del documento equivalente; `TienePermiso*` y `PuedeAgregarCombo` según cuál id viene.
- [ ] 2.4 Mismo archivo: `ObtenerTerceroDelDocumento(idContable, idEquivalente)` y `AgregarCombo` con el ancla correcta, todo o nada.
- [ ] 2.5 `[L1]` `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs`: `PuedeEliminarArchivos(usuario, idContable, idEquivalente)`.
- [ ] 2.6 `[L1]` Mismo: `CrearRelacion(...)`, que reemplaza las dos construcciones duplicadas (local y remota); `IdDocumentoContable` opcional en la subida y exactamente un id.
- [ ] 2.7 `[L1]` Mismo: `EliminarArchivos` comprueba que los archivos pertenecen al documento y el permiso según el dueño de cada fila antes de la transacción. Recrear copia las dos anclas. Guard `== null`.
- [ ] 2.8 `[L1]` Mismo: etiqueta "Documento equivalente" en `ObtenerArchivosEliminadosPorConstancia`.
- [ ] 2.9 `DocumentoContableSolicitadoWebApiController`: los dos ids en `GetPorIdDocumento`, `Post` y `Put`; 400 si no viene exactamente uno; 403 sin permiso; tercero con `ObtenerTerceroDelDocumento`.
- [ ] 2.10 `DocumentoContableComboWebApiController.PostConSolicitados`: dueño desde el ancla del combo y permiso.
- [ ] 2.11 WebApi de cargado, eliminado y vista de cargados: los dos ids y 400.
- [ ] 2.12 `[L1]` `DocumentoContableArchivoWebApiController.cs`: los dos ids en pendientes, vencidos y `EliminarArchivos`.
- [ ] 2.13 MVC `DocumentoContableArchivoController`: `Index(iddocumento, iddocumentoequivalente)`, permiso de eliminar; `SubirArchivo` exige exactamente un id.
- [ ] 2.14 MVC `DocumentoContableComboController.Index(iddocumento, iddocumentoequivalente)`: encabezado del documento equivalente (tipo, número, tercero, fecha) y permisos según el dueño.
- [ ] 2.15 `FirmaArchivoContableController.FirmarDocumento(idArchivo)`: el dueño se lee de la fila del archivo. La firma en sí no cambia.
- [ ] 2.16 `DocumentoEquivalenteWebApiController.Delete`: captura 23503 y responde 409 con mensaje claro.
- [ ] 2.17 Compilar Debug.
- [ ] 2.18 Curls de 0.6 y acta de 0.7: idénticos.
- [ ] 2.19 Curls con los dos ids a la vez y con ninguno, en cada servicio → 400 sin tocar datos.
- [ ] 2.20 Permisos: usuario solo contable sobre el documento equivalente → rechazado, y al revés; archivo de otro documento → rechazado; contabilizar y duplicar no copian.

## Fase 3: PR3 vistas + EdicionV2 (9)

Antes: skills `siian-devextreme-components` y `siian-devextreme-behavior`. · Se parece a: botones y funciones `listarDocumentos()` / `adjuntar()` de `DocumentoContable/CreateV2.cshtml`

- [ ] 3.1 `[L1]` `Views/DocumentoContableArchivo/Index.cshtml`: los dos ids en Razor y JS, título según cuál viene, `&iddocumentoequivalente=` en `listarDocumentos()`.
- [ ] 3.2 `[L1]` `_GestionDocumentos.cshtml`: el id del dueño en los `LoadParams` de cargados, pendientes y vencidos.
- [ ] 3.3 `[L1]` `_SubirArchivo.cshtml`: campos ocultos del dueño y `LoadParams`.
- [ ] 3.4 `[L1]` `_PopupObservacion.cshtml`: los ids del dueño en el JSON de eliminar.
- [ ] 3.5 `[L1]` `Views/DocumentoContableCombo/Index.cshtml`: título, `LoadParams`, ancla en `onInitNewRow` y `agregarCombo`, `&iddocumentoequivalente=` en `adjuntar()`, botones según permiso del dueño.
- [ ] 3.6 `Views/DocumentoEquivalente/EdicionV2.cshtml` (UTF-8): botones "Listar Documentos" y "Adjuntar" después de la línea ~619, deshabilitados con `Id == 0`, que abren `…/DocumentoContable{Combo|Archivo}/?iddocumentoequivalente=@Id`.
- [ ] 3.7 Compilar; los `[L1]` sin tildes rotas; `CreateV2.cshtml` sin cambios.
- [ ] 3.8 Manual contable (E12, E13): CO101 completo y JSON de 168816 idéntico.
- [ ] 3.9 Manual documento equivalente: escenarios E1-E11 del [análisis](../ANALISIS.md#5-escenarios-de-prueba-dado--cuando--entonces).

## Riesgos

- Nueve archivos latin1: se editan de a uno y se revisa el diff.
- El paso a `int?` (1.18) es el cuello de botella del PR1.
- Compilar actualiza el servidor compartido: el script 10 va antes del PR1 y el 11 antes del PR2.
- Sin verificar todavía: `NpgsqlException.Code` (0.4) y las vistas vivas (0.3).
