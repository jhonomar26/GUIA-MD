# Etapa 5: limpieza del modelo viejo (S11)

## Idea

El estado de un pedido y los archivos eliminados ya no se guardan en tablas aparte: se **derivan** de propiedades (`archivocontable.eseliminado`, `solicitado.esactivo`, el puente). Por eso las tablas/entidades del modelo viejo no tienen reemplazo: se borran.

## Se borra

- Entidades y actores (`Blip.Data/Contabilidad/`): `DocumentoContableCargado`, `DocumentoContableEliminado`, `EstadoDocumentoContable`.
- ViewModels (`Blip.Entities/Contabilidad.ViewModels/`): `DocumentoContableCargadoViewModel`, `DocumentoContableEliminadoViewModel`, `EstadoDocumentoContableViewModel`.
- WebApi: `DocumentoContableCargadoWebApiController`, `DocumentoContableEliminadoWebApiController`, `EstadoDocumentoContableWebApiController`.
- Líneas en `Data.csproj`, `Entities.csproj`, `PruebaPostgreSQL.csproj`.
- `DocumentoContableSolicitadoActorNegocio.cs`: `CrearCasoEstadoVisible`, `ObtenerConEstadoVisible…`, `ObtenerCargadosPor…`, `ObtenerEliminadosPor…` y sus `Consultar…` privados.

## No se toca

- `VistaDocumentoContableCargados*` (modelo nuevo, lo usa T2.1).
- Métodos de `DocumentoContableSolicitadoActorNegocio` que siguen en uso (se verifica uno por uno antes de borrar).

## Script 11

Corregir `CREATE OR REPLACE VIEW`, la vista 6.1 (usa `contabilidad_archivocontable` antes de que exista) y los comentarios de la regla vieja.

## Prueba

Búsqueda de los nombres viejos sin resultados + build en 0 errores.
