# Plan: base de datos y código para dos dueños

> [← README](../../README.md) · Visión general: [ANALISIS](../../ANALISIS.md) · Decisiones: [ADR-001](../../ADR.md), [ADR-002](../../ADR-002.md)

Tareas de las fases 0 y 1 del [plan histórico](../../archivo/PLAN.md), con su estado. **Marcas:** `[L1]` archivo latin1 (se edita a nivel de bytes, texto nuevo en ASCII). `[FUERA]` script SQL en `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\archivos-documento-equivalente\`.

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
- [x] 1.5 Correr 1.3 después (pasan: hecho) y 1.1 por segunda vez (idempotente: pendiente).
- [x] 1.6 Repetir curls de 0.6 con el código sin cambiar: JSON idéntico.
- [x] 1.7 Probar 1.2 dentro de una transacción con `ROLLBACK`.

**PR1 datos** · Se parece a: entidades, actores y ViewModels actuales de `DocumentoContable*`; consultas de `DocumentoContableSolicitadoActorNegocio`

- [x] 1.8 ~~`OrigenDocumentoArchivo.cs`~~ **Descartado (2026-10-20):** no hay parámetro de origen; el dueño lo dicen los ids (ver [ADR](../../ADR-002.md)). Se hizo y se borró antes de commitear.
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
- [x] 1.20 Curls de 0.6 + `diff`: idéntico. Si difiere, no se avanza.
- [x] 1.21 `git diff --stat` ~200 líneas, sin tildes rotas en los `[L1]`.

**Cierre fase 1 (2026-10-20):** cerrada por decision del usuario, con pendientes que pasan a fase 2 (hechos el 2026-10-20 al arrancar la fase 2): 1.8, 1.11, 1.15 y 1.16 (rehechos sin parámetro de origen, ver ADR). Pruebas SQL de 1.3 pasaron en demo (P1-P5, 2026-10-20; P4 y P5 se corrigieron porque el script de pruebas omitia columnas NOT NULL y elegia un documento con otros hijos). Sin verificar: de 1.5 la segunda corrida del script 10 (idempotencia), 1.7 (reversion con ROLLBACK), 1.6 y 1.20 (curls vs `antes/`, la sesion de Orca vencio), 1.21. Compila Debug sin errores. Commits `wip` por squashear antes del PR.


## Para cerrar esta feature

- [x] C.1 (2026-10-20, informado por el usuario: corrió sin errores; salida no adjunta) Segunda corrida del script 10 en demo, sin errores ni cambios (la otra mitad de 1.5).
- [x] C.2 (2026-10-20, informado por el usuario: funciona; salida no adjunta) Reversión 1.2 probada con `prueba-reversion-archivos-documento-equivalente.sql` (1.7): copia de la reversión con `ROLLBACK` en vez de `COMMIT` y una consulta de verificación. **No** envolver la reversión original: trae su propio `COMMIT` y se aplicaría.
- [x] C.3 Curls de 0.6 contra `../../antes/` (1.6 y 1.20), 2026-10-20 con el código compilado: pendientes, vencidos, cargados remotos y eliminados **idénticos**; cargados locales idénticos salvo el campo nuevo `Iddocumentoequivalente: null` en las 4 filas (esperado por 1.14). Respuestas en `../evidencia/despues/`.
- [x] C.4 (2026-10-20: +69/−35, sin caracteres no ASCII nuevos, la `á` del latin1 intacta) `git diff --stat` revisado y sin tildes rotas en los `[L1]` (1.21).
- [x] C.5 (commits `12f4dce85` y `a558c80a4`) Commit de lo que está sin commitear (los dos ids en consultas y combo: 1.11, 1.15, 1.16, 1.17).
