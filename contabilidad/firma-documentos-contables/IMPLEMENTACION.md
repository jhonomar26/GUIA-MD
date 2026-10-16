# Implementación — Firma electrónica de documentos contables

> Reference. Refleja el código de la rama `feature/expediente-virtual-carga-firmas` al 2026-10-07 (commits `c126b9d75`, `b65dda6ea`, `f51cac4f1`). Se actualiza al construir.
> Leyenda: 🟢 hecho, compila y probado a mano.

## Flujo 🟢

```mermaid
flowchart TD
    A([Grilla de cargados: documento de tipo con firma]) --> B[Botón Firmar abre otra pestaña]
    B --> C[/FirmaArchivoContable/FirmarDocumento?idArchivo=X/]
    C --> D{Archivo ligado a un documento contable?}
    D -- no --> X1[/Error: no pertenece a un documento contable/]
    D -- si --> E{Solicitado con tercero?}
    E -- no --> X2[/Error: sin tercero asignado/]
    E -- si --> F[Firmante = tercero del solicitado]
    F --> G[VozData envía y firma]
    G --> H[Reemplaza el archivo por FIRMADO-... y guarda vínculo en firmas_firmaarchivocontable]
```

El firmante sale de `contabilidad_documentocontablesolicitado.idtercero`. "Firma electrónica" la define el **tipo de documento** (`Esfirmaelectronica`); el flag `Esparafirmar` del combo solo filtra qué tipos se pueden agregar a él.

## Base de datos

Scripts en `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\`:

- `6-firma-documentos-contables.sql`: columna `idtercero` en el solicitado, tabla `firmas_firmaarchivocontable` y 4 columnas nuevas al final de `contabilidad_vistadocumentocontablecargados` (`esfirmaelectronica`, `esfirmadoelectronicamente`, `idfirma`, `esanuladoelectronicamente`).
- `7-eliminacion-constrains.sql`: la unicidad (combo, tipo) del solicitado aplica solo a no eliminados (`codigoestadodocumento <> 'ELIMINADO'`). Necesario para eliminar con "recrear".

## Código por capa

| Capa | Archivo | Qué hace |
|---|---|---|
| Datos | `Blip.Data/Firmas/FirmaArchivoContable.cs`, `FirmaArchivoContableActor.cs` | Vínculo archivo ↔ proceso de firma (12 métodos + `ObtenerPorIdarchivocontable`, `ObtenerPorIdprocesomaestro`) |
| Datos | `Blip.Data/Contabilidad/DocumentoContableSolicitado.cs`, `...Actor.cs` | Propiedad `Idtercero` (9.º parámetro obligatorio del constructor) |
| Datos | `Blip.Data/Contabilidad/VistaDocumentoContableCargados.cs`, `...Actor.cs` | 4 campos de firma de la vista |
| Datos | `Blip.Data/Contabilidad/ComboDocumentoContableActorNegocio.cs` | `TipoEnComboParaFirmar(idtipo)` |
| Entidades | `VistaDocumentoContableCargadosViewModel.cs`, `FirmaArchivoContableViewModel.cs`, `FirmaCarpetaVirtualViewModel.cs` (`EsFirmaContable`) | |
| Negocio | `Negocio/Firmas/FirmaArchivoContableActorNegocio.cs` | Copia de crédito sin codeudores; firmante único = tercero del solicitado; mensajes claros de archivo ajeno o sin tercero |
| Negocio | `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs` | `ValidarArchivoConTiposPermitidos`: si el tipo exige firma, solo `.pdf`. `EliminarArchivos` corre en `TransactionManager.ExecuteTransaction` y propaga errores (antes un `catch` vacío los escondía y la transacción quedaba abortada, `25P02`) |
| Web | `Controllers/Firmas/FirmaArchivoContableController.cs` | Mismas acciones que crédito |
| Web | `SIIAN.VozData/Handlers/FirmarDocumentoCarpetaVirtualHandler.cs` | Rama `EsFirmaContable` que inserta el vínculo |
| Web | `Controllers/Contabilidad/DocumentoContableArchivoController.cs` | `SubirArchivo` pasa `tipo.Esfirmaelectronica` a la validación |
| Web | `Controllers/WebApi/DocumentoTipoWebApiController.cs` | `Put` rechaza quitar la firma a un tipo que está en un combo para firmar |
| Vistas | `Views/FirmaProcesoMaestro/FirmarDocumento.cshtml` | Título y controlador para el caso contable |
| Vistas | `Views/DocumentoContableArchivo/_GestionDocumentos.cshtml`, `_Estilos.cshtml` | Botón Firmar con color por estado (normal, naranja, verde, rojo) |
| Vistas | `Views/DocumentoContableArchivo/Index.cshtml`, `Views/DocumentoContableCombo/Index.cshtml` | "Listar Documentos" y "Adjuntar Archivos" abren pestaña nueva; grillas con scroll horizontal y columnas de comandos fijas |

## Reglas que conviene recordar

- **Quitar la firma a un tipo** que está en un combo para firmar da error 400 (evita subir un `.docx` a un documento que luego no se puede firmar).
- **Agregar tipos a un combo "para firmar"** solo se filtra en la UI (`GetActivosParaCombo`); el servidor no lo valida. Hueco conocido.
- **Eliminar con recrear:** el documento eliminado conserva archivo, carga e historial y el nuevo PENDIENTE hereda `idtercero`.
- El borrado físico (FTP/disco) en `EliminarArchivos` no se revierte con el rollback de la transacción.
