# Implementación: brechas B1-B6 de documentos contables frente a crédito

Qué quedó construido en la rama `feature/contabilidad-detalle-constancia-eliminacion`, contrastado con el código el 2026-10-16. Reglas vigentes: [ciclo-documentos](../ciclo-documentos/).

## Scripts SQL

Ruta: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\`. Sin `BEGIN/COMMIT` e idempotentes.

| Script | Brecha | Qué hace |
|---|---|---|
| `8-vista-archivos-eliminados-contabilidad.sql` | B1 | `CREATE OR REPLACE VIEW public.contabilidad_vistaarchivoseliminados`: una fila por archivo contable eliminado |
| `9-permiso-documentos-individuales-contabilidad.sql` | B2 | Crea la funcionalidad y la acción del permiso, y la asigna a los roles con "Agregar Mas Combos Documento Contable" activo. Cuatro bloques `WHERE NOT EXISTS`. Se corre **antes** de publicar el código |

## B1. Detalle de la constancia de eliminación

Commits `1510e9b5c` (archivos generados) y `cedcba97c` (consulta y conexión).

| Archivo | Qué hay |
|---|---|
| `Blip.Data/Contabilidad/VistaArchivosEliminados.cs` | Entidad de la vista, generada con WFAGenerarDao |
| `Blip.Data/Contabilidad/VistaArchivosEliminadosActor.cs` | Actor estándar de la vista, generado |
| `Blip.Data/Contabilidad/VistaArchivosEliminadosActorNegocio.cs` | `ObtenerPorConstancia(int)`: filtra por constancia y ordena por fecha de cargue y archivo |
| `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs` | `ObtenerArchivosEliminadosPorConstancia(int)`: convierte las filas a `ContenidoCarpetaVirtualViewModel` con carpeta "Contabilidad" |
| `Negocio/Credito/CreditoMaestroReportesNegocio.cs` | `ObtenerValoresParametrosEliminacionArchivos`: suma la lista contable al acta |
| `Negocio/Generales/ConstanciaEliminacionArchivosActorNegocio.cs` | `ContenidoCarpetasVirtuales`: suma la lista contable al detalle de la constancia |
| `Blip.Data/Data.csproj` | Registra los tres archivos de `Blip.Data` |

El commit `1510e9b5c` también generó `Blip.Entities/Contabilidad.ViewModels/VistaArchivosEliminadosViewModel.cs` y `PruebaPostgreSQL/Controllers/WebApi/VistaArchivosEliminadosWebApiController.cs`, registrados en sus `.csproj`. El plan no los pedía y ninguna pantalla los usa (no verificado en vistas).

## B2. Permiso para documentos individuales

Commit `44b917826`.

| Archivo | Qué hay |
|---|---|
| `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs` | Tres constantes del permiso y `TienePermisoAgregarDocumentosIndividuales(string idUsuario)` |
| `PruebaPostgreSQL/Controllers/Contabilidad/DocumentoContableComboController.cs` | `Index`: `ViewBag.PuedeAgregarDocumentoIndividual`, `false` por defecto |
| `PruebaPostgreSQL/Views/DocumentoContableCombo/Index.cshtml` | La grilla de solicitados usa el permiso en `AllowAdding` y `AllowUpdating` |
| `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableSolicitadoWebApiController.cs` | `Post` y `Put` llaman primero a `RechazarSinPermiso()`, que responde 403 "No tiene permiso para agregar o editar documentos." |

## B3. Ver archivo desde combos

Commit `44b917826`.

| Archivo | Qué hay |
|---|---|
| `PruebaPostgreSQL/Views/DocumentoContableCombo/Index.cshtml` | `verArchivoCargado` abre `DocumentoContableArchivo/Visualizar` en vez de `CargaArchivos/VisualizarArchivo` |

Sin código nuevo en backend: `DocumentoContableArchivoActorNegocio.VisualizarArchivo` ya rechazaba archivos que no son de un comprobante contable.

## B4. Editar la descripción de un archivo cargado

Commit `7955091af`. Solo la descripción, por decisión ([EXPLICACION.md](./EXPLICACION.md)). Sin permiso, igual que crédito.

| Archivo | Qué hay |
|---|---|
| `PruebaPostgreSQL/Controllers/WebApi/VistaDocumentoContableCargadosWebApiController.cs` | `ActualizarArchivo` (PUT): rechaza con 403 si el archivo no es de un documento contable; guarda descripción, usuario y fecha de última modificación |
| `PruebaPostgreSQL/Views/DocumentoContableArchivo/_GestionDocumentos.cshtml` | Grillas Cargados y Remoto: edición en fila, solo la columna `Observaciones` |

## B5. Pestaña Vencidos completa

Commit `7955091af`.

| Archivo | Qué hay |
|---|---|
| `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs` | `ObtenerVencidosPorIddocumentocontable`: agrega descripción, nombre del archivo, fecha y usuario de cargue |
| `Blip.Entities/Contabilidad.ViewModels/DocumentoVencidoViewModel.cs` | Propiedades `Descripcion`, `Nombrearchivo`, `Fechacargue`, `Usuariocargue` |
| `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs` | `ObtenerVencidos`: muestra el nombre del archivo sin el sufijo de guid |
| `PruebaPostgreSQL/Views/DocumentoContableArchivo/_GestionDocumentos.cshtml` | Grilla `gridDocsVencidos` con las columnas nuevas |

En el mismo commit, `GetPorDocumento` (Cargados y Remoto) también muestra el nombre sin el sufijo.

## B6. Columna Obligatorio en Pendientes

Commit `7955091af`.

| Archivo | Qué hay |
|---|---|
| `PruebaPostgreSQL/Views/DocumentoContableArchivo/_GestionDocumentos.cshtml` | Grilla `gridDocsPendientes`: columna `EsObligatorio` ("Obligatorio") |

El dato ya venía del servicio de pendientes.

## Verificación

Solo figura como hecho lo que tiene evidencia anotada.

| Caso | Estado |
|---|---|
| B1 script 8 corrido dos veces | No probado (`PLAN B1.md`, Tarea 1 S2 sin tildar) |
| B1 consultas de control de la vista | Tildado en `PLAN B1.md` (Tarea 1 S3), sin resultado anotado |
| B1 build | Tildado en `PLAN B1.md` (Tareas 2 y 3), sin salida anotada |
| B1 M1: acta de una constancia contable lista los archivos | No probado |
| B1 M2: acta de crédito y tercero igual que antes | No probado |
| B1 M3: solicitado sin tercero sale con tercero vacío | No probado |
| B1 M4: constancia sin archivos vinculables sale vacía | No probado |
| B1 P3: la plantilla del acta no depende de crédito | No probado |
| B2 script 9 corrido dos veces y verificado | Hecho (2026-10-15): un rol (`03`), sin duplicados (`PLAN B2.md`, Tarea 1) |
| B2 build | Hecho (2026-10-16): 0 errores, 17 advertencias preexistentes |
| B2 M1: usuario con permiso agrega y edita | Hecho (2026-10-16): comprobante 168816, registro de prueba id 34 |
| B2 M2: usuario sin permiso no ve agregar ni editar | Parcial: la grilla salió sin agregar ni editar antes de habilitar el permiso (anotado en M1). No anotado que siga viendo la lista y los archivos |
| B2 M3: llamada directa sin permiso responde 403 | No probado |
| B2 M4: sin permiso puede agregar el primer combo | No probado |
| B2 M5: crédito, pagaré, tercero y CRM sin cambios | No probado |
| B3: ver un archivo contable desde combos abre el archivo; uno de crédito se rechaza | No probado |
| B4: editar la descripción guarda usuario y fecha; un archivo no contable responde 403 | No probado |
| B5: Vencidos muestra descripción, archivo, cargue y usuario | No probado |
| B6: Pendientes muestra la columna Obligatorio | No probado |
| Build de B3-B6 | No probado (sin salida anotada) |
