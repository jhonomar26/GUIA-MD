# Plan: correcciones del expediente virtual contable

> Corregir uno por uno los hallazgos H1-H13 · ← [README](./README.md) · Reglas: [R1-R12](./ANALISIS.md#reglas) · Rama: `feature/contabilidad-archivos-documento-equivalente` · Sin tests automáticos: prueba en Orca y `curl`

Orden: una tarea a la vez; la siguiente arranca cuando la anterior se probó. Cada tarea lleva su `EXPLICACION-T<n>.md` antes del código. Las que dependen de una regla "por confirmar" no arrancan hasta confirmarla. Scripts SQL en `scriptsSiian/contabilidad/archivos-contabilidad/correcciones-expediente/NN-*.sql`.

## Specs

- S1. Sin servicios genéricos sobre archivo contable ni sobre el vínculo pedido-archivo; ver un archivo no sale de la carpeta configurada. Implementa R1, R2. (H1)
- S2. El listado general de eliminados no se expone sin dueño. Implementa R1. (H2)
- S3. Eliminar confirma la base y después borra físicos, "lo vamos a copiar de ahorros". Implementa R3. (H3)
- S4. Subir es todo o nada y limpia el físico si falla; un pedido no recibe dos archivos. Implementa R4, R5. (H4)
- S5. Reactivar un pedido de tipo único con otro activo se rechaza, como ahorros. Implementa R6. (H5)
- S6. El documento suelto nace activo, como ahorros. Implementa R7. (H6)
- S7. El tipo único se puede volver a pedir después de eliminar sin recrear. Implementa R8. (H7)
- S8. Los archivos contables cuentan en el espacio local. Implementa R9. (H8)
- S9. La carpeta virtual incluye archivos contables y de equivalente. Implementa R10. (H9)
- S10. Cargados y archivos de pedidos retirados según R11. (H10)
- S11. Lista de solicitados según R12. (H11)
- S12. Menores de H12.
- S13. Notas del área al día con el modelo actual. (H13)

## Casos

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R1 | usuario con sesión | llama `PUT /api/ArchivoContableWebApi` o `PUT/DELETE /api/DocumentoContableArchivoWebApi` | 404/405: el servicio no existe | Pasa (L6) |
| 2 | R1 | pantalla de subida | carga rutas y pendientes y elimina | sigue funcionando (`ObtenerRutas`, `ObtenerSolicitadosPendientes`, `EliminarArchivos`) | |
| 3 | R2 | archivo con url fuera de la carpeta (dato manipulado en BD de prueba) | se pide Visualizar | rechazo, no devuelve el contenido | No aplica: R2 anotada como HA1 (L6) |
| 4 | R1 | usuario con sesión | llama el listado general de eliminados | no lista archivos de otros dueños | Pasa (L8): 404 |
| 5 | R3 | 2 archivos en local | elimina | base marcada, físicos borrados, constancia única | |
| 6 | R3 | físico bloqueado o FTP caído | elimina | base marcada; aviso "no se pudo borrar el archivo físico" | |
| 7 | R4 | falla el registro en base después de guardar el físico | sube | error, sin archivo en BD y sin físico en disco/FTP | |
| 8 | R5 | pedido ya con archivo | se fuerza una segunda subida al mismo pedido | rechazo, queda un solo archivo | |
| 9 | R6 | tipo único con un pedido activo y otro retirado | reactiva el retirado | rechazo "ya esta solicitado" | |
| 10 | R6 | tipo no único, mismo escenario | reactiva | se reactiva | |
| 11 | R6 | tipo único sin otro activo | reactiva | se reactiva | |
| 12 | R7 | agregar suelto con `esactivo=false` en el cuerpo | agrega | nace activo | |
| 13 | R8 | tipo único cargado | elimina con "No" y lo pide a mano | según R8 confirmada | |
| 14 | R8 | tipo único cargado | elimina con "No" y agrega un combo que lo trae | según R8 confirmada | |
| 15 | R8 | tipo único pendiente | pide otro igual a mano | rechazo "ya está solicitado" (no cambia) | |
| 16 | R9 | archivos contables en ruta local | sube o elimina | el volumen usado los incluye | |
| 17 | R10 | archivo contable y de equivalente | abre EV101/EV201 | según R10 confirmada | |
| 18 | R11 | pedido con archivo | se retira el pedido | sigue en Cargados con Activo = No; no aparece en Vencidos | |
| 19 | R12 | tipo inactivo con pedidos | abre solicitados | no los lista, como crédito (no cambia) | |

## Tareas

- [x] T1 (S1). Cerrada en etapa 1 (L12). Hecho en código, sin commit (2026-11-05): borrados `ArchivoContableWebApiController` y `ArchivoAhorroWebApiController` (+ `.csproj`); quitados `Get`/`Put`/`Delete` de `DocumentoContableArchivoWebApiController`. Compila. Caso 1 pasó con `curl`; falta caso 2 en Orca y commit. La barrera de ruta en `ParametrosCarpetaVirtualActorNegocio.VisualizarArchivo:61-70` (R2, caso 3) **no se hace**: queda como hallazgo HA1 (ver [ANALISIS](./ANALISIS.md#hallazgos-anotados-sin-corregir)). Casos 1-2.
- [x] T2 (S2). Cerrada en etapa 1 (L12). Hecho en código, sin commit (2026-11-05): borrados `VistaArchivosEliminadosWebApiController` y `VistaArchivosEliminadosViewModel` (+ líneas en `PruebaPostgreSQL.csproj` y `Entities.csproj`). Compila. Caso 4 pasó con `curl`; falta 4b (acta en pantalla) y commit. Cierra el hueco A6 del área.
- [x] T3 (S3). Cerrada en etapa 1 (L12). Hecho en código, sin commit (2026-11-05): `ArchivoContableEliminacionActorNegocio.EliminarArchivos` ahora llama a `MarcarEliminados` (transacción: constancia, marcas, pedido nuevo) y después borra físicos y actualiza volumen; si eso falla devuelve "Archivos eliminados, pero no se pudo borrar el archivo fisico: …" sin revertir. `ArchivoContableDuenoActorNegocio.EliminarArchivos` devuelve ese mensaje (el popup ya lo muestra con `data.message`). Copiado de `ArchivoAhorroEliminacionActorNegocio.cs:37-57`. Compila. Casos 5-6 pendientes en Orca.
- [ ] T4 (S4). `ArchivoContableAlmacenamientoActorNegocio` (`SubirArchivoLocal`, remoto, `RegistrarArchivo:90-100`): limpiar el físico si falla y envolver archivo+vínculo en `TransactionManager.ExecuteTransaction`. R5 por confirmar: script `UNIQUE (iddocumentocontablesolicitado)` en `contabilidad_documentocontablearchivo`. Se parece a: `ArchivoAhorroSubidaActorNegocio.cs:117-121, 155-159`. Casos 7-8.
- [x] T5 (S5). `DocumentoContableSolicitadoAsignacionActorNegocio.ModificarDocumento:110-122`: validar tipo único al reactivar. Se parece a: `DocumentoAhorroCuentaAsignacionActorNegocio.cs:101-108`. Casos 9-11. **Deshecha** (2026-11-05) por R19: reactivar ya no revisa el tipo único, como crédito.
- [x] T6 (S6). Agregar documento suelto: forzar `Esactivo = true`. Se parece a: alta de pedido en `DocumentoAhorroCuentaAsignacionActorNegocio`. Caso 12.
- [x] T7 (S7). Resuelta en [2-eliminar-retira-pedido](./2-eliminar-retira-pedido/PLAN.md) con R19 (2026-11-05): el tipo único funciona como crédito. Compila; casos 1-7 pasan en ahorros y comprobante (feature 2, L9-L11); equivalente sin recorrer; sin commit.
- [ ] T8 (S8). Script nuevo de `generales_vistaarchivoscargados` que sume `contabilidad_archivocontable` (no eliminados, locales). Se parece a: las ramas actuales de la vista. Caso 16.
- [ ] T9 (S9). **Bloqueada por R10.** `ContenidoCarpetaVirtualActorNegocio:138-167`, `BorrarDocumentosSeleccionados`, `VisualizarArchivo`, vista `generales_vistaarchivosfirmaelectronica`. Se parece a: `CreditoDocumentacionActor.ArchivosCarpetaVirtualCredito`. Caso 17.
- [x] T10 (S10). Cerrada en etapa 2 (L17). Script `correcciones-expediente/01-vista-cargados-con-retirados.sql`: Cargados sin `WHERE s.esactivo = true` (como crédito) y Vencidos con ese filtro, para que DP6 no cambie. Escrito, sin correr en el servidor de pruebas. Caso 18.
- [x] T11 (S11). Cerrada sin código (L18): R12 confirmada, la vista `...solicitadoestado` conserva `WHERE t.esactivo = true` como crédito; no hay script 17. Caso 19.
- [x] T12 (S12). Hecha en código, sin commit (L20). `[HttpPost]` en `DocumentoContableArchivoController.SubirArchivo:60`; mensaje claro en `FirmaArchivoContableActorNegocio.cs:212` (como ahorros `ObtenerArchivo`); dueño en `ArchivoContableDuenoActorNegocio.ActualizarObservaciones:44-55`; texto de `_SubirArchivo.cshtml:205` según dueño; `ConstanciaEliminacionArchivosController.ArchivosEliminadosPorIdConstancia` sin uso.
- [ ] T13 (S13). Actualizar `ciclo-documentos/ELIMINACION.md` y secciones 6 y 9 del README del área al modelo pedido → puente → archivo.

## Log

- L1 (2026-11-05). Pedido textual en [REQUERIMIENTO.md](./REQUERIMIENTO.md#pedido-original-2026-11-05).
- L2 (2026-11-05). Revisión de solo lectura en dos partes (pedir/subir/pestañas y eliminar/firma/carpeta virtual) contra crédito y ahorros. Ahorros se armó con contabilidad como plantilla: coincidir con ahorros no prueba que esté bien.
- L3 (2026-11-05). "con lo que se puede copiar lo vamos a copiar de ahorros": T3, T4 (limpieza), T5, T6 copian ahorros.
- L4 (2026-11-05). T1 adelantada a pedido del usuario ("si"): borrados los servicios genéricos; compila con MSBuild sin errores. Sin probar en la app, sin commit.
- L5 (2026-11-05). [EXPLICACION-T1.md](./EXPLICACION-T1.md) escrita. `ParametrosCarpetaVirtualActorNegocio.VisualizarArchivo` es compartida (21 llamadores en todo SIIAN): poner la barrera ahí es riesgo fuera de esta feature. Opciones A (compartida), B (solo contabilidad, recomendada), C (no hacerla). Espera decisión del usuario. `AsegurarSinTraversal` no sirve: no bloquea `~/Web.config`.
- L6 (2026-11-05). Usuario: "dejemoslo como hallazgo, por ahora no lo corijamos". R2 queda anotada (HA1); caso 3 fuera. Caso 1 en el servidor de pruebas, sin sesión: `GET/PUT/DELETE` a `ArchivoContableWebApi`, `ArchivoAhorroWebApi` y `DocumentoContableArchivoWebApi/{Get,Put,Delete}` → 404; controles `CuentaAhorroDocumentacionWebApi/Get` y `DocumentoContableArchivoWebApi/ObtenerRutas` → 401 (existen). Pasa.
- L7 (2026-11-05). Usuario: "pasemos a t2 mejor" (caso 2 de T1 queda pendiente en Orca). [EXPLICACION-T2.md](./EXPLICACION-T2.md) escrita. Verificado: `VistaArchivosEliminadosWebApiController` y `VistaArchivosEliminadosViewModel` no los usa nada más; la entidad y el actor sí (`DocumentoContableArchivoActorNegocio.ObtenerPorConstancia`), se quedan. Ahorros no tiene WebApi equivalente.
- L8 (2026-11-05). Usuario: "si hazlo total es sencillo". T2 borrada; MSBuild sin errores. Servidor de pruebas sin sesión: `GET VistaArchivosEliminadosWebApi/Get` → 404; control `CuentaAhorroDocumentacionWebApi/Get` → 401. Caso 4 pasa; 4b (acta) pendiente en pantalla.
- L9 (2026-11-05). T5 escrita: `ModificarDocumento` rechaza reactivar un tipo único si `ExisteTipoEnDocumento` (ya filtra `esactivo = true`, así que el retirado no se cuenta a sí mismo). Hallazgo: el `Put` de `VistaDocumentoContableSolicitadoEstadoWebApiController` solo atrapaba `UnauthorizedAccessException`; se agrega `catch (Exception)` → 400 como el `Post`, para que el mensaje llegue a la pantalla. MSBuild sin errores. Casos 9-11 pendientes en Orca.
- L10 (2026-11-05). Usuario: "no, pasa directo al codigo" (T3 sin EXPLICACION). T3 escrita según skill `siian-transacciones` (efecto externo que se borra: después del commit). MSBuild sin errores.
- L11 (2026-11-05). Usuario: "da por finalizada esta etapa". T5 cerrada como está (se descartó bloquear siempre la reactivación de únicos: perdería el caso 11). Casos 9-11 sin recorrer en Orca, sin commit.
- L12 (2026-11-05). Usuario: "da por finalizada esta etapa". Etapa 1 cerrada: T1, T2, T3 y T5 en código y compilando. Sin recorrer en Orca: casos 2, 4b, 5, 6, 9, 10 y 11. Sin commit. Etapa 2: T4 (R5 por confirmar), T6, T8, T12, T13; T7, T9, T10 y T11 bloqueadas por R8, R10, R11 y R12.
- L11 (2026-11-05). T6: el grid sí manda `Esactivo` (onInitNewRow lo pone en true), pero la columna era editable en la fila nueva y el backend lo tomaba tal cual. Usuario: "si, igual son dos lineas". `AgregarDocumentoIndividual` fija `p_esactivo: true` (como ahorros) y `editorDocumentoSolicitadoNuevo` deja `Esactivo` de solo lectura en la fila nueva. MSBuild sin errores. Caso 12 pendiente en Orca, sin commit.
- L12 (2026-11-05). Usuario: "en si lo que deberiamos de hacer, es simple desactivar el documento solicitado anterior y volver a acargar otro y listo" y "lo mejor es crear un nuevo feature, pero es lo correcto como deberia de manejarse tanto en ahorros como en contabilidad". T7 y R8 pasan a [eliminar-retira-pedido](../eliminar-retira-pedido/).
- L13 (2026-11-05). La feature 2 queda bloqueada por R19: el usuario consultará si "único" se maneja como crédito (sin bloqueo de tipo repetido) o como está hoy. Si es como crédito, la T5 de la etapa 1 se deshace. Detalle en [2-eliminar-retira-pedido/PLAN.md](./2-eliminar-retira-pedido/PLAN.md) L4-L5.
- L14 (2026-11-05). Usuario: "ese dejemosla de lado por ahora no es necesario". T8 en pausa. Análisis de T9 (solo lectura): una sola tabla `contabilidad_archivocontable` sirve a contabilidad y a equivalente (el pedido lleva `iddocumentocontable` o `iddocumentoequivalente`); `generales_parametroscarpetavirtual` ya tiene `escontabilidad` y `esdocumentoequivalente`; existe `firmas_firmaarchivocontable` y `contabilidad_documentotipo.esfirmaelectronica`.
- L15 (2026-11-05). Usuario: "por ahora dejemoslo fuera" (T9 en pausa). Análisis de T10 (solo lectura): `contabilidad_vistadocumentocontablecargados` filtra `WHERE s.esactivo = true`; `credito_vistacreditoarchivos` no filtra el pedido (solo `eseliminado` en el actor). La grilla `_GridCargados.cshtml:33` ya tiene la columna `Esactivo`. Único consumidor: `ArchivoContableDuenoActorNegocio.ObtenerCargados` (solo muestra). Con T5, un único retirado con otro activo no se puede reactivar: su archivo queda invisible. Por revisar: el `Get` genérico de `VistaDocumentoContableCargadosWebApiController:26` lista sin dueño (como H2).
- L16 (2026-11-05). Usuario: "esto si hay que corregirlo" → R11 confirmada: Cargados muestra los archivos de pedidos retirados, como crédito. Explicación dada en el chat (sin EXPLICACION-T10.md). El filtro venía a propósito del script 13 de `scratch/archivos-documento-contable` ("un pedido retirado oculta su archivo"); el README del área ya decía lo contrario ("si ya estaba cargado, sigue en Cargados"). La única vista que depende de Cargados es Vencidos (script 14, `pg_depend`): el script nuevo le pasa `c.esactivo = true` para que DP6 no cambie. En `pg-demo`, de solo lectura, el cuerpo nuevo da los mismos conteos (cargados 4/4, vencidos 0/0; no hay ningún retirado con archivo para probar el caso). Falta correrlo en el servidor de pruebas y recorrer el caso 18 en Orca.
- L17 (2026-11-05). Usuario: "marca como finalizada esta etapa". Etapa 2 cerrada con lo hecho: T6 y T10 (script 01 escrito, sin correr en el servidor de pruebas). Sin recorrer en Orca: casos 12 y 18. Sin commit. Quedan abiertas: T4 (R5 por confirmar), T8 (en pausa por el usuario), T12, T13; T7 movida a la feature 2; T9 y T11 bloqueadas por R10 y R12.
- L18 (2026-11-05). Usuario: "si credito ya lo maneja asi, manejemoslo de la misma manera". R12 confirmada: la lista de solicitados no muestra tipos inactivos. T11 cerrada sin cambios de código ni script. Pendiente solo el caso 19 en Orca (no cambia el comportamiento actual).
- L19 (2026-11-05). Usuario: "cierrala tambien". T11 se suma al cierre de la etapa 2 (L17): la etapa queda con T6, T10 y T11. Abiertas: T4 (R5 por confirmar), T8 (en pausa), T12, T13; T7 en la feature 2; T9 bloqueada por R10.
- L20 (2026-11-05). R19 confirmada: "la desicion es dejarlo al igual que credito". Quitado el bloqueo de tipo único en contabilidad y ahorros (T5 deshecha) y, al subir, se desactivan los archivos anteriores del mismo pedido. Detalle en [2-eliminar-retira-pedido/PLAN.md](./2-eliminar-retira-pedido/PLAN.md) L6-L8.
- L20 (2026-11-05). Usuario: "si, son cortos podemos proceder a codigo" (T12 sin EXPLICACION). Hecho: `[HttpPost]` en `SubirArchivo` (el JS ya sube con POST); `FirmaArchivoContableActorNegocio.ObtenerArchivo` con mensaje claro, usado en `FirmarDocumento` y `EnviarSolicitudFirma` (líneas 212 y 352; la 178 no se tocó); etiqueta de documento único de `_SubirArchivo.cshtml` según dueño; borrada `ArchivosEliminadosPorIdConstancia`. Corrección mía: `ActualizarObservaciones` no excluía el equivalente (el puente `contabilidad_documentocontablearchivo` es el mismo para ambos dueños); solo el mensaje y el summary decían "documento contable", ya corregidos. Queda sin validar contra el dueño de la pantalla: el grid no manda el dueño al editar. Hallazgo: `ConstanciaEliminacionArchivosActorNegocio.ContenidoCarpetasVirtuales(int, string)` quedó sin llamadores. MSBuild sin errores. Sin probar en Orca.
