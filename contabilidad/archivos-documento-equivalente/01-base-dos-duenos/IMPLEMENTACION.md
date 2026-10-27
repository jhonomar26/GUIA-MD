# Implementación: base de datos y código para dos dueños

> [← README](./README.md) · Decisiones: [ADR-001](../ADR.md), [ADR-002](../ADR-002.md) · Plan cerrado: [archivo/PLAN.md](./archivo/PLAN.md)

Rama `feature/contabilidad-archivos-documento-equivalente`. Commits `12f4dce85` y `a558c80a4` (27 archivos, +385/−204 contra `b001ba022`).

## Base de datos (script 10, fuera del repo)

`C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\archivos-documento-equivalente\`:

| Script | Qué hace |
|---|---|
| `10-archivos-documento-equivalente.sql` | `iddocumentoequivalente` en solicitado, combo y archivo; `iddocumentocontable` opcional; FK `fk_*_docequivalente` `ON DELETE RESTRICT`; CHECK `ck_*_dueno_unico` (`num_nonnulls = 1`); índices `ix_*_iddocumentoequivalente`; vistas de cargados y eliminados recreadas (eliminados con `LEFT JOIN` y tercero por `COALESCE`). Idempotente |
| `10-reversion-archivos-documento-equivalente.sql` | Deshace el 10. Trae su propio `COMMIT`: **no** envolverlo para probar |
| `prueba-reversion-archivos-documento-equivalente.sql` | Copia de la reversión que termina en `ROLLBACK`, con consulta de verificación |
| `pruebas-archivos-documento-equivalente.sql` | P1-P5 en `BEGIN … ROLLBACK`: dos anclas, ninguna, ancla inexistente, vista de eliminados, borrado bloqueado |

## Código

| Capa | Archivo | Qué cambió |
|---|---|---|
| Entidades | `DocumentoContable{Solicitado,Combo,Archivo}.cs` | `Iddocumentocontable` pasa a `int?`; `Iddocumentoequivalente` con `Campo`, `Tipo`, navegación lazy y constructor |
| Actores | `DocumentoContable{Solicitado,Combo,Archivo}Actor.cs` | Columna nueva en `CrearSelect`, `Insert` y `Update`; `ObtenerPorIddocumentoequivalente` |
| Vistas | `VistaDocumentoContableCargados.cs`, `VistaArchivosEliminados.cs` y sus actores | Propiedad, `Campo`, `Tipo` y columna en `CrearSelect` |
| Consultas | `Blip.Data/.../DocumentoContableSolicitadoActorNegocio.cs` | Las 7 consultas por documento reciben `int? p_iddocumentoequivalente = null`. `ObtenerCampoDelDueno` elige la columna; `ObtenerIdDelDocumento` (internal) exige exactamente un id. Parámetro SQL `@iddocumento`. `ValidarDocumentoSolicitadoYTipo` compara los dos dueños |
| Consultas | `VistaDocumentoContableCargadosActorNegocio.ObtenerPorDocumento` | Igual, reutilizando `ObtenerIdDelDocumento` |
| Combos | `DocumentoContableComboActorNegocio.InsertarConDocumentosSolicitados(combo, int? p_idtercero)` | Recibe el tercero ya resuelto y copia las dos anclas. El llamador (`AgregarCombo`) sigue resolviendo el tercero del comprobante; el del documento equivalente es de [02-solicitar-documentos](../02-solicitar-documentos/) |
| ViewModels | `DocumentoContable{Solicitado,Combo,Archivo}ViewModel`, `Vista*ViewModel` | `int?` y propiedad nueva |
| ViewModels | `EliminarArchivosRequest`, `ArchivoContableUploadViewModel` | `IdDocumentoContable` / `IdDocumentoEquivalente` opcionales (en la subida, `IdDocumentoContable` sigue obligatorio: es de [03-subir-archivo](../03-subir-archivo/)) |
| Negocio | `DocumentoContableArchivoActorNegocio.cs` | Pasa `IdDocumentoEquivalente` al crear la relación (local y remota) y al recrear; el resto es reformateo |
| WebApi | `DocumentoContable{Archivo,Combo,Solicitado}WebApiController`, `Vista*WebApiController` | Ajustes por `int?` y el campo nuevo en las respuestas |

## Fuera de alcance, sin revisar

Entró en el commit `12f4dce85` desde una sesión anterior y **no pertenece a esta feature**: `DocumentoContableArchivoWebApiController.Get` ahora limita las consultas agrupadas a 50.000 filas (400 si se supera) y pasa el `loadOptions` real a `DataSourceLoader` en vez de uno vacío. No se probó. Revisar aparte.

## Verificación

| Qué | Cómo | Resultado |
|---|---|---|
| Base | P1-P5 en demo (2026-10-20) | P1, P2 → 23514; P3 → 23503; P4 → fila con `idtercero = tercero_esperado` (455); P5 → 23503 de `fk_docsolicitado_docequivalente` |
| Idempotencia | Script 10 por segunda vez | Sin errores (informado por el usuario) |
| Reversión | `prueba-reversion-…sql` | Funciona (informado por el usuario; salida no adjunta) |
| Build | `msbuild PruebaPostgreSQL.sln -p:Configuration=Debug` | 0 errores |
| Contable sin cambios | 5 servicios del comprobante 168816 contra `../antes/` | Idénticos; cargados locales suman `Iddocumentoequivalente: null` en las 4 filas (campo nuevo). Respuestas en `evidencia/despues/` |
| Latin1 | Bytes no ASCII antes y después | Iguales (`á`) |
