# Requerimiento: cerrar brechas de documentos contables frente a crédito

> **Historia.** Pedido y brechas tal como se encontraron el 2026-10-14; B1-B6 ya están implementadas ([IMPLEMENTACION.md](./IMPLEMENTACION.md)). Vigente: [ciclo-documentos](../ciclo-documentos/).

## Pedido original

> revisar si hay algo pendiente en documentos que esté en crédito y no esté en contabilidad; la mayoría de funcionalidades ya estaban

Feature aparte de `expediente-virtual-carga`, `expediente-virtual-configuracion` y `firma-documentos-contables` (esta última ya cerrada).

## Origen

Comparación de código entre `Views/CargaArchivos` (crédito) y `Views/DocumentoContableArchivo` (contabilidad), hecha el 2026-10-14 sobre la rama `feature/expediente-virtual-carga-firmas`. Es lectura de código; ningún flujo se ejecutó en la app.

Contabilidad ya cubre: pestañas Cargados, Remoto, Pendientes y Vencidos; subida con ruta, extensiones, único y vencimiento; eliminar con observación, "¿recrear?" y permiso; combos repetidos con permiso; firma; exportar; historial de eliminados; backup de carpeta virtual.

## Brechas a cerrar

| #   | Brecha                                                                                 | En crédito                                                                         | En contabilidad hoy                                                                                                                                                 |
| --- | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| B1  | Constancia de eliminación sin detalle                                                  | `ConstanciaEliminacionArchivosActorNegocio.cs:28-39`                               | Crea la constancia (`DocumentoContableArchivoActorNegocio.cs:198`), pero el detalle solo incluye Terceros, Crédito y CRM: sale vacío                                |
| B2  | Permiso para agregar documentos individuales (sin combo)                               | `DocumentoCreditoActorNegocioViewModel.cs:94-107`                                  | `DocumentoContableCombo/Index.cshtml:211-212` deja `AllowAdding`/`AllowUpdating` en true; `DocumentoContableSolicitadoWebApiController.Post/Put` no validan permiso |
| B3  | Ver archivo desde la pestaña Cargados de combos                                        | Acción propia de crédito                                                           | `DocumentoContableCombo/Index.cshtml:397-404` usa `CargaArchivos/VisualizarArchivo`, que no valida que el archivo sea contable                                      |
| B4  | Editar la descripción de un archivo ya cargado, con usuario y fecha de modificación (activo no aplica, ver [EXPLICACION.md](./EXPLICACION.md)) | `MostrarArchivos.cshtml:396-445`, `VistaCreditoArchivosWebApiController.cs:70-101` | Grillas de solo lectura (`_GestionDocumentos.cshtml:49-62`). `DocumentoContableArchivoWebApiController.Put` existe sin uso en la UI                                 |
| B5  | Pestaña Vencidos completa                                                              | `MostrarArchivos.cshtml:567-621`                                                   | Solo nombre, vencimiento y "Ver" (`_GestionDocumentos.cshtml:125-154`)                                                                                              |
| B6  | Columna "Obligatorio" en Pendientes                                                    | `MostrarArchivos.cshtml:561`                                                       | Solo el `*` en el selector de subida                                                                                                                                |

## Por decidir con negocio (no entran hasta que se confirmen)

- **D1:** bloquear carga y edición según el estado del comprobante (anulado, periodo cerrado). Hoy no hay ningún bloqueo.
- **D2:** validación de integridad al subir (buffer contra `ContentLength`). Hoy solo tamaño > 0 y extensión. **Decidido (2026-10-16): se replica crédito, va como C1 en [ciclo-documentos](../ciclo-documentos/).**
- **D3:** consola central `ContenidoCarpetaVirtual` con documentos de contabilidad.
- **D4:** generar y cargar automáticamente el formato personalizado al agregar combo. Las notas anteriores lo dejaron fuera de alcance.

## Preguntas abiertas

- B4 y B5: ¿el usuario contable debe poder editar y activar/inactivar archivos, o basta con verlos? ¿Con qué permiso? **Respondida:** B4 edita solo la descripción, sin permiso, igual que crédito. B5 es solo lectura ([EXPLICACION.md](./EXPLICACION.md)).
- B2: ¿reutiliza el permiso de combos o es uno nuevo (como "Agregar Mas Combos")? **Respondida:** permiso nuevo ([ANALISIS B2.md](ANALISIS%20B2.md), "Decisión tomada").
- B1: ¿el PDF de la constancia ya cubre contabilidad? No se verificó. **Sigue abierta:** es la P3 de [PLAN B1.md](PLAN%20B1.md).

## Criterios de aceptación

- **Dado** que se eliminan archivos de un documento contable, **cuando** se consulta el detalle de la constancia, **entonces** muestra los archivos eliminados.
- **Dado** un usuario sin el permiso, **cuando** intenta agregar o editar un documento solicitado a mano, **entonces** la pantalla lo impide y el WebApi responde con error.
- **Dado** un archivo de crédito, **cuando** se pide verlo desde la pantalla contable, **entonces** se rechaza.
- **Dado** un archivo cargado, **cuando** el usuario edita su descripción, **entonces** queda guardada con su usuario y fecha.
- **Dado** un documento vencido, **cuando** se abre la pestaña Vencidos, **entonces** muestra los mismos datos que crédito, sin codeudores ni tercero por documento.
- **Dado** un documento pendiente, **cuando** se abre Pendientes, **entonces** se ve si es obligatorio.
- **Dado** que se toca código compartido (constancias, visualización), **cuando** se usa crédito, tercero o CRM, **entonces** funciona igual que antes.

## No-gos

- Codeudores y tercero por documento.
- Convenios, etapas, aprobación y desembolso.
- Geolocalización y carga móvil o por API.
- Las decisiones D1 a D4, hasta que negocio las confirme.
