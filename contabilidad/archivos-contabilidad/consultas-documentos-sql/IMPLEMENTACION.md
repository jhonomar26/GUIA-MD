# Implementación: consultas de documentos contables en SQL

Qué quedó construido en la rama `feature/contabilidad-detalle-constancia-eliminacion`, verificado el 2026-10-19 contra el servidor de pruebas `25.44.200.158/rep1`. Reglas vigentes: [ciclo-documentos](../ciclo-documentos/).

## Archivos tocados

| Archivo | Cambio |
|---|---|
| `Blip.Entities/Contabilidad.ViewModels/DocumentoSolicitadoPendienteViewModel.cs` | Dos propiedades `EsFoto` y `EsFirmaElectronica` con `[JsonIgnore]`, solo para calcular `Extensiones` |
| `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs` | Método nuevo `ObtenerPendientesPorIddocumentocontable(int)` |
| `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs` | `ObtenerSolicitadosPendientesPorId` usa el método nuevo; se borran `ObtenerPorDocumento`, `ObtenerSolicitadosPendientes` y `ObtenerSolicitadosPendientesEstado` |

Los tres archivos son ISO-8859-1 con CRLF salvo el ViewModel (UTF-8 con BOM). Se editaron a nivel de bytes; sin caracteres de reemplazo ni `LF` sueltos.

## Cambio

**Tarea 1 (commit `50348040d`).** Antes eran dos lecturas (los pedidos del comprobante y todos los tipos) y tres filtros en C#. Ahora es una consulta con `INNER JOIN` entre solicitado y tipo, y las tres reglas de pendiente en el `WHERE`: solicitado activo, estado `PENDIENTE` y tipo activo (R13). `ORDER BY` el id del solicitado. Cada columna lleva `AS` explícito porque `esactivo` existe en ambas tablas. En C# solo queda calcular `Extensiones`, porque `ObtenerExtensionesPermitidas` vive en `Negocio/` y `Blip.Data` no puede llamarlo.

**Tarea 2 (commit `9ec22b4d6`).** Se borran 137 líneas: tres endpoints que nadie llamaba y que leían tablas completas (archivos de todo el sistema y todos los pedidos y cargas). Ninguna pantalla, script ni rama activa los usaba. No se tocó `VistaDocumentoContableCargadosActor.ObtenerPorDocumento`, que tiene el mismo nombre pero sí se usa.

## Verificación

Comprobantes de `demo-25-09-2026`: A y C = `168816`, D = `168815`. Evidencia en [`evidencia/`](./evidencia/).

| Caso | Resultado |
|---|---|
| Compilación tras la Tarea 1 | 0 errores |
| A: mismos pendientes, mismos datos | `antes-168816.json` y `despues-168816.json` idénticos byte a byte (ids 32, 33, 34, mismas `Extensiones`) |
| C: eliminado no aparece | Los 7 eliminados de `168816` no están en la respuesta, antes ni después |
| D: sin pendientes | `[]`, HTTP 200, idéntico al antes |
| B: tipo inactivo no aparece | Probado a mano por el usuario inactivando y reactivando `DOCUMENTO 1`; correcto. Antes del cambio se había capturado `antes-168816-B.json` (solo el id 32). **No hay captura de B después del cambio.** |
| Selector "Documento" de la subida | Capturas del antes (`antes-selector-168816*.png`). **No se repitieron después**; la respuesta del servicio es idéntica |
| Código nuevo desplegado | `Data.dll` y `DevExtremeMvcApp24.dll` con hora del build y con el método nuevo |
| Compilación tras la Tarea 2 | 0 errores |
| Regresión de pestañas | Los endpoints de Cargados (local y remoto) y Vencidos responden 200 en `168816`. **Las pestañas no se abrieron en pantalla** |
| Endpoints borrados | `ObtenerPorDocumento` responde 404 |
| Pendientes tras la Tarea 2 | `168816` con `DOCUMENTO 1` activo devuelve los ids 33 y 34. El 32 ya no sale porque alguien lo cargó durante la prueba |
| `ObtenerRegistros` en el controlador | Solo queda `CompaniasActor.ObtenerRegistros()` en `ObtenerVencidos`: una fila de configuración (H5) |

## Pendiente

- `EXPLICACION.md`, parte de código y entrevista del paso 1.5: se omitieron por decisión del usuario (cambio simple).
