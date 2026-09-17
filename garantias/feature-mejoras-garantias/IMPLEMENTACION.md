# Implementación: mejoras Garantías

Mapa de archivos tocados por el requerimiento, agrupado por corrección. Ver
[EXPLICACION.md](./EXPLICACION.md) para el porqué de cada regla.

## CORRECCION BOTON DE REGRESAR

Se cambió de `window.history.back()` (no funcionaba, la vista se abre en pestaña nueva
sin historial) a navegar a una URL de origen explícita, con `window.close()` como fallback.

- `PruebaPostgreSQL/Views/ArchivoAsociado/SubirArchivo.cshtml` — función `onClickRegresar()`
  movida al bloque `<script>`; navega a `returnUrl` (recibido por `ViewBag`) o cierra la
  pestaña si no llega.
- `PruebaPostgreSQL/Controllers/Garantias/ArchivoAsociadoController.cs` —
  `SubirArchivo(string codigoEntidad, int id, string returnUrl = null)` recibe y expone
  `ViewBag.ReturnUrl`.
- `PruebaPostgreSQL/Views/GarantiaBienInmueble/_GarantiasInmueble.cshtml`,
  `PruebaPostgreSQL/Views/GarantiaBienVehiculo/_GarantiasVehiculosBien.cshtml`,
  `PruebaPostgreSQL/Views/GarantiaBienVehiculo/GestionVehiculo.cshtml` — la función
  `subirArchivo(codigoEntidad, id)` agrega `&returnUrl=` con `window.location.href` al
  abrir la pestaña nueva.

## CORRECCION TIPO DE DOCUMENTOS

- `PruebaPostgreSQL/Views/GarantiaTipoDocumento/_PanelTiposDocumento.cshtml` — el
  `SelectBox` de Grupo Documento en el form de edición filtra `Esactivo = true`
  (`DataSourceOptions().Filter(...)`).
- `Negocio/Garantias/GarantiaArchivoActorNegocio.cs`, método `SubirArchivoLocal`:
  - **Vencimiento server-side**: ya no confía en `item.FechaVencimiento` del cliente.
    Si el Tipo de Documento no expira, fuerza `null`. Si expira y es fecha manual, exige
    que venga informada (error si no). Si expira y es automático, recalcula siempre
    `DateTime.Now.AddDays(Diasvencimientodespuescargue)` en servidor.
  - **Documento único**: si `Esdocumentounico`, antes de guardar el archivo físico
    recorre todas las `EntidadDocumentoSolicitado` de la misma entidad
    (`Codigoentidadarchivo` + `Identidad`) y mismo `Idtipodocumento` (cruza directa/combo);
    si alguna tiene un `EntidadDocumentoCargado` activo, rechaza la carga con error.

Refactor asociado (soportes por tipo documento, ya no viola separación de capas):
- `Negocio/Garantias/GarantiaTipoDocumentoSoporteActorNegocio.cs` (nuevo) —
  `ObtenerIdsSoportesPorDocumento` y `SincronizarSoportesDocumento` (diff
  agregar/quitar entre relaciones actuales y nuevas).
- `PruebaPostgreSQL/Controllers/WebApi/GarantiaTipoDocumentoSoporteWebApiController.cs`
  — delega en el ActorNegocio anterior en vez de tener la lógica de diff en el controller.

## Decisiones explícitas (no obvias por el código)

- **Documento único bloquea, no reemplaza** — a diferencia del patrón usado en
  `Negocio/Terceros/TerceroArchivoDocumentoActorNegocio.cs` (`VerificarDocumentoUnico`,
  que desactiva el anterior en silencio y deja subir el nuevo). En Garantías se decidió
  bloquear porque ya existe un flujo explícito de eliminación
  (`GarantiaArchivoActorNegocio.EliminarArchivosGarantias`) y un documento legal no
  debería desactivarse sin que el usuario lo pida. Ver indagación completa en
  [REQUERIMIENTO.md](./REQUERIMIENTO.md).
- **`returnUrl` explícito en vez de `window.close()` solo** — más robusto porque no
  depende de que la pestaña padre siga abierta; si el padre se cerró, simplemente recarga
  esa URL en vez de fallar.

## Pendiente / no cubierto en esta pasada

- CORRECCION MUNICIPIO, CORRECCION EDITAR PROPIETARIO, CORRECCION DATOS INNECESARIOS
  GARANTIA, CORRECCION EN PARAMETROS DE GARANTIA — items del requerimiento original aún
  no abordados en esta conversación.
