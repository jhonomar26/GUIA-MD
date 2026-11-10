> Parte de [`EXPLICACION.md`](../EXPLICACION.md). Crédito es la referencia: qué hace allá y qué copiamos.

# Reglas de crédito (verificadas en el código)

Cada regla dice dónde vive en crédito y qué hacemos en contabilidad. **Criterio: lo que hace crédito se hace
igual en contabilidad, sin diferencias de comportamiento.** Solo cambian las tablas (las contables) y lo que es
propio de crédito (ver el final).

## Qué significa cada bandera en crédito

| Bandera                                   | Tabla                          | Qué significa                                                                 |
| ----------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `documentocreditocredito.esactivo`        | pedido                         | El pedido se sigue exigiendo. Solo cambia a mano (columna editable en Solicitados) |
| `documentocredito.esactivo`               | tipo de documento              | El tipo está habilitado. Un tipo inactivo saca sus pedidos de las listas      |
| `archivo.eseliminado` + constancia        | archivo                        | El archivo se eliminó (quién, cuándo, por qué)                                |
| `archivo.esactivo`                        | archivo                        | Solo lo apaga la regla de documento único (ver abajo)                         |
| `creditodocumentacion.esactivo`           | puente                         | Se inserta en `true` y nada lo cambia; solo lo filtran algunas consultas      |

En contabilidad: `esactivo` del pedido, `esactivo` del tipo (`contabilidad_documentotipo.esactivo`),
`eseliminado` + constancia del archivo y `esactivo` de `archivocontable` para documento único. El `esactivo` del
puente no existe en nuestro modelo porque en crédito nada lo cambia.

## 1. A qué pedido se le puede subir un archivo

`CargaArchivosController.MostrarArchivos` arma la lista de pedidos para cargar con estas condiciones:

- pedido con `esactivo = true` y tipo de documento con `esactivo = true` (`ObtenerDocSolicitadosPorCredito`);
- **y sin ninguna fila en el puente** (`CreditoDocumentacionActor.ObtenerPorIddocumento(doc.Id).Count == 0`),
  cuente o no un archivo eliminado.

O sea: **un pedido recibe un solo archivo en toda su vida**. Si ese archivo se elimina, el pedido ya no vuelve a
la lista; por eso existe "crear un documento nuevo con las mismas características".

→ Contabilidad: igual. Es exactamente `espendiente` de la vista (pedido activo y sin ninguna fila de archivo).

## 2. Validaciones al subir (`ValidarYSubirArchivo`, `SubirArchivoLocal` / `SubirArchivoRemoto`)

| Regla                                                                 | Contabilidad                                   |
| --------------------------------------------------------------------- | ---------------------------------------------- |
| Archivo no vacío y completo (bytes leídos = `ContentLength`)          | Igual                                          |
| Id de pedido válido (`> 0`)                                           | Igual                                          |
| Extensiones fijas: `.docx .xlsx .txt .pdf .jpg .jpeg`                 | Ya tenemos las nuestras (`EsExtensionPermitida`) |
| Límite de almacenamiento (local o del FTP) antes de guardar           | Igual                                          |
| Ruta local o remota según `ParametrosCarpetaVirtual` (FTP si tiene credenciales y la ruta empieza en `/`) | Igual, con rutas contables / de documento equivalente |
| Nombre guardado: `nombre-CA{id}{guid}.ext`                            | Igual con prefijo propio                       |
| Al subir: `INSERT` archivo (`esactivo = true`, `eseliminado = false`) + `INSERT` puente | Igual (sin `esactivo` en el puente) |

## 3. Documento único (`ArchivoActorNegocio.VerificarDocUnico`)

Si el tipo es `esdocumentounico`, antes de guardar pone `archivo.esactivo = false` a **todos los archivos
anteriores del mismo pedido**. El comentario del código habla de "mismo tercero y tipo", pero la consulta filtra
solo por el pedido.

Como la regla 1 solo deja subir a pedidos sin archivos, en el flujo normal esta regla **no apaga nada**.

→ Contabilidad: igual. Si el tipo es documento único, antes de guardar se pone `archivocontable.esactivo = false`
a los archivos anteriores del mismo pedido.

## 4. Eliminar archivos (`CargaArchivosActorNegocio.ValidarBorrado` y `BorrarDocumentos...`)

| Paso | Crédito                                                                                  | Contabilidad |
| ---- | ---------------------------------------------------------------------------------------- | ------------ |
| 1    | Permiso `EliminarDocumentosCargadosCredito` validado **en el servidor**                   | Igual, con el permiso contable (`PuedeEliminarArchivos`) |
| 2    | Observación obligatoria: **solo se valida en el JS** de la pantalla                       | Igual |
| 3    | Una sola constancia para todos los archivos seleccionados (`noarchivoseliminados = n`)    | Igual |
| 4    | Cada archivo: `eseliminado = true`, `idconstanciaeliminacion`, y **se borra el archivo físico** (disco o FTP) y se recalcula el almacenamiento usado | Igual |
| 5    | El pedido y el puente **no se tocan**                                                     | Igual (modelo B) |
| 6    | Pregunta "¿crear un documento nuevo…?": si es Sí, `NuevosDocumentosAPartirDeArchivosEliminados` | Igual |

El pedido nuevo de crédito copia crédito, tipo y tercero, pero **no copia** la descripción (queda `""`) y fuerza
`esobligatorio = true` y `esactivo = true`. Además inserta su relación con el tercero (`DocumentoCreditoTercero`).

→ Contabilidad: igual: copia dueño (comprobante o documento equivalente), tipo y tercero; descripción vacía,
`esobligatorio = true`, `esactivo = true`. Hoy `EliminarArchivos` copia descripción y obligatorio: hay que
cambiarlo. La relación con el tercero de crédito no aplica (el tercero va en el pedido).

## 5. Retirar y editar pedidos

- Crédito: `Esactivo`, `Esobligatorio`, `Descripcion`, tipo y tercero son editables en la grilla de Solicitados
  (`Put`). **No hay ninguna validación** al poner `esactivo = false`, aunque el pedido tenga archivo vigente.
- Si la etapa del crédito es aprobación con decisión de comité, o desembolso, editar pide el permiso
  `EditarDatosDocumentosCredito`.
- Un pedido nuevo agregado a mano arranca `esactivo = true` y `esobligatorio = true` (`accionAntesAddRow`).
- El API tiene `Delete` físico del pedido, pero la grilla no lo habilita.

→ Contabilidad: igual. Mismo default al agregar, `esactivo` editable sin validaciones, editar siempre
habilitado y sin `Delete` físico en la grilla. El permiso por etapa de crédito se cambia por el permiso contable
que corresponda.

## 6. La pantalla de crédito: tabs y qué muestra cada una

`Views/DocumentoCreditoCredito/Index.cshtml`. Arriba: datos del crédito, "Agregar combos" (combo + tercero) y el
botón "Adjuntar Archivos", que abre **otra pantalla** (`CargaArchivos/MostrarArchivos`): ahí se sube y se
elimina. En esta pantalla solo se piden documentos y se consulta.

| Tab         | Consulta (`CreditoDocumentacionActorNegocio`)   | Filas                                                                                     | Filtro                                                         |
| ----------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Solicitados | `ObtenerFullDocSolicitadosCargadosPorCredito`   | Una por pedido y archivo (`FULL OUTER JOIN` pedido → puente → archivo), pendientes primero (`OrderBy(Cargado)`) | Crédito y **tipo** de documento activo. El pedido puede estar activo o no |
| Cargados    | `ObtenerDocSolicitadosCargadosPorCredito`       | Una por archivo                                                                           | `archivo.eseliminado = false` **y pedido `esactivo = true`**    |
| Eliminados  | `ObtenerDocSolicitadosEliminadosPorCredito`     | Una por archivo eliminado, con la constancia (`JOIN`, no `LEFT JOIN`)                     | **Pedido `esactivo = true`**                                    |

Columnas de cada tab:

- **Solicitados:** tercero, tipo, descripción, obligatorio, respuesta de cargue, `Cargado`, `Eseliminado`,
  `Esactivo` (la única editable de las tres). `Cargado` lo arma el ViewModel: hay archivo en la fila, aunque esté
  eliminado. Agregar pide `PermiteAgregarDocumentosIndividuales` y `PuedeEditarDocumentos`; editar está
  **siempre** habilitado (`AllowUpdating(true)`).
- **Cargados:** tercero, tipo, descripción, obligatorio, activo, descripción del archivo, botón ver archivo y
  ubicación.
- **Eliminados:** tercero, tipo, descripción, obligatorio, activo, observación, fecha y usuario de la eliminación.

Consecuencia de los filtros: **retirar un pedido lo saca de Cargados y de Eliminados**, pero sigue en
Solicitados con `Esactivo = false`.

→ Contabilidad, vistas del script `14-`:

| Punto                                            | Crédito                  | Contabilidad                                        |
| ------------------------------------------------ | ------------------------ | --------------------------------------------------- |
| Solicitados: una fila por pedido y archivo       | Sí                       | Sí (`vistadocumentocontablesolicitadoestado`)       |
| Solicitados: ocultar tipos inactivos             | Sí                       | Sí (`WHERE t.esactivo = true`)                      |
| Solicitados: pendientes primero                  | Sí (en el controller)    | Va en el código (`ORDER BY` del actor), no en la vista |
| Cargados: vigentes de pedidos activos            | Sí                       | Sí (`eseliminado = false` y `s.esactivo = true`)    |
| Eliminados: con constancia, de pedidos activos   | Sí (`JOIN` al usuario)   | Sí (`JOIN` al usuario y `s.esactivo = true`)        |

## Lo que es solo de crédito (no se replica)

- Formato personalizado: al crear o editar un pedido cuyo tipo es `esformatopersonalizado`, se genera un PDF y
  se sube solo.
- Fecha de vencimiento atada al fin del crédito (`FechaFinCredito`) y geolocalización.
- Carga desde móvil a carpeta temporal.
