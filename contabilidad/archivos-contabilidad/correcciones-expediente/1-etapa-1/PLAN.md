# Plan: etapa 1

> Hallazgos que se resolvían copiando ahorros o borrando código: H1, H2, H3, H5 y H6 · [← README](../README.md) · Reglas: [R1-R3, R6, R7](../REGLAS-DE-NEGOCIO.md) · Rama: `feature/contabilidad-archivos-documento-equivalente` · Sin tests automáticos: prueba en Orca y `curl`

**Antes del código:** [EXPLICACION.md](./EXPLICACION.md) (T1 y T2). T3 pasó directo al código por decisión del usuario.

## Specs

- S1. Sin servicios genéricos sobre archivo contable ni sobre el vínculo pedido-archivo; ver un archivo no sale de la carpeta configurada. Implementa R1, R2. (H1)
- S2. El listado general de eliminados no se expone sin dueño. Implementa R1. (H2)
- S3. Eliminar confirma la base y después borra físicos, "lo vamos a copiar de ahorros". Implementa R3. (H3)
- S5. Reactivar un pedido de tipo único con otro activo se rechaza, como ahorros. Implementa R6. (H5)
- S6. El documento suelto nace activo, como ahorros. Implementa R7. (H6)

Los números de S, T y casos son los del plan original de correcciones, para que el log siga cuadrando. S4 y S7-S13 están en las features siguientes (ver el [README](../README.md#paso-2-features-en-orden)).

## Casos

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R1 | usuario con sesión | llama `PUT /api/ArchivoContableWebApi` o `PUT/DELETE /api/DocumentoContableArchivoWebApi` | 404/405: el servicio no existe | Pasa (L6) |
| 2 | R1 | pantalla de subida | carga rutas y pendientes y elimina | sigue funcionando (`ObtenerRutas`, `ObtenerSolicitadosPendientes`, `EliminarArchivos`) | |
| 3 | R2 | archivo con url fuera de la carpeta (dato manipulado en BD de prueba) | se pide Visualizar | rechazo, no devuelve el contenido | No aplica: R2 anotada como HA1 (L6) |
| 4 | R1 | usuario con sesión | llama el listado general de eliminados | no lista archivos de otros dueños | Pasa (L8): 404 |
| 4b | R1 | constancia contable | genera el acta | sale igual que antes | |
| 5 | R3 | 2 archivos en local | elimina | base marcada, físicos borrados, constancia única | |
| 6 | R3 | físico bloqueado o FTP caído | elimina | base marcada; aviso "no se pudo borrar el archivo físico" | |
| 9 | R6 | tipo único con un pedido activo y otro retirado | reactiva el retirado | rechazo "ya esta solicitado" | |
| 10 | R6 | tipo no único, mismo escenario | reactiva | se reactiva | |
| 11 | R6 | tipo único sin otro activo | reactiva | se reactiva | |
| 12 | R7 | agregar suelto con `esactivo=false` en el cuerpo | agrega | nace activo | |

## Tareas

- [x] T1 (S1). Hecho en código, sin commit (2026-11-05): borrados `ArchivoContableWebApiController` y `ArchivoAhorroWebApiController` (+ `.csproj`); quitados `Get`/`Put`/`Delete` de `DocumentoContableArchivoWebApiController`. Compila. Caso 1 pasó con `curl`; falta caso 2 en Orca y commit. La barrera de ruta en `ParametrosCarpetaVirtualActorNegocio.VisualizarArchivo:61-70` (R2, caso 3) **no se hace**: queda como hallazgo HA1 (ver [ANALISIS](../ANALISIS.md#hallazgos-anotados-sin-corregir)). Casos 1-2.
- [x] T2 (S2). Hecho en código, sin commit (2026-11-05): borrados `VistaArchivosEliminadosWebApiController` y `VistaArchivosEliminadosViewModel` (+ líneas en `PruebaPostgreSQL.csproj` y `Entities.csproj`). Compila. Caso 4 pasó con `curl`; falta 4b (acta en pantalla) y commit. Cierra el hueco A6 del área.
- [x] T3 (S3). Hecho en código, sin commit (2026-11-05): `ArchivoContableEliminacionActorNegocio.EliminarArchivos` ahora llama a `MarcarEliminados` (transacción: constancia, marcas, pedido nuevo) y después borra físicos y actualiza volumen; si eso falla devuelve "Archivos eliminados, pero no se pudo borrar el archivo fisico: …" sin revertir. `ArchivoContableDuenoActorNegocio.EliminarArchivos` devuelve ese mensaje (el popup ya lo muestra con `data.message`). Copiado de `ArchivoAhorroEliminacionActorNegocio.cs:37-57`. Compila. Casos 5-6 pendientes en Orca.
- [x] T5 (S5). `DocumentoContableSolicitadoAsignacionActorNegocio.ModificarDocumento`: validar tipo único al reactivar. Se parece a: `DocumentoAhorroCuentaAsignacionActorNegocio.cs:101-108`. Casos 9-11.
- [x] T6 (S6). Agregar documento suelto: forzar `Esactivo = true`. Se parece a: alta de pedido en `DocumentoAhorroCuentaAsignacionActorNegocio`. Caso 12.

Sin recorrer en Orca: casos 2, 4b, 5, 6, 9, 10, 11 y 12. Sin commit.

## Log

- L1 (2026-11-05). Pedido textual en [REQUERIMIENTO.md](../REQUERIMIENTO.md#pedido-original-2026-11-05).
- L2 (2026-11-05). Revisión de solo lectura en dos partes (pedir/subir/pestañas y eliminar/firma/carpeta virtual) contra crédito y ahorros. Ahorros se armó con contabilidad como plantilla: coincidir con ahorros no prueba que esté bien.
- L3 (2026-11-05). "con lo que se puede copiar lo vamos a copiar de ahorros": T3, T4 (limpieza), T5, T6 copian ahorros.
- L4 (2026-11-05). T1 adelantada a pedido del usuario ("si"): borrados los servicios genéricos; compila con MSBuild sin errores. Sin probar en la app, sin commit.
- L5 (2026-11-05). [EXPLICACION, T1](./EXPLICACION.md#t1-nadie-edita-un-archivo-por-fuera-del-expediente) escrita. `ParametrosCarpetaVirtualActorNegocio.VisualizarArchivo` es compartida (21 llamadores en todo SIIAN): poner la barrera ahí es riesgo fuera de esta feature. Opciones A (compartida), B (solo contabilidad, recomendada), C (no hacerla). Espera decisión del usuario. `AsegurarSinTraversal` no sirve: no bloquea `~/Web.config`.
- L6 (2026-11-05). Usuario: "dejemoslo como hallazgo, por ahora no lo corijamos". R2 queda anotada (HA1); caso 3 fuera. Caso 1 en el servidor de pruebas, sin sesión: `GET/PUT/DELETE` a `ArchivoContableWebApi`, `ArchivoAhorroWebApi` y `DocumentoContableArchivoWebApi/{Get,Put,Delete}` → 404; controles `CuentaAhorroDocumentacionWebApi/Get` y `DocumentoContableArchivoWebApi/ObtenerRutas` → 401 (existen). Pasa.
- L7 (2026-11-05). Usuario: "pasemos a t2 mejor" (caso 2 de T1 queda pendiente en Orca). [EXPLICACION, T2](./EXPLICACION.md#t2-el-listado-general-de-eliminados-no-queda-expuesto) escrita. Verificado: `VistaArchivosEliminadosWebApiController` y `VistaArchivosEliminadosViewModel` no los usa nada más; la entidad y el actor sí (`DocumentoContableArchivoActorNegocio.ObtenerPorConstancia`), se quedan. Ahorros no tiene WebApi equivalente.
- L8 (2026-11-05). Usuario: "si hazlo total es sencillo". T2 borrada; MSBuild sin errores. Servidor de pruebas sin sesión: `GET VistaArchivosEliminadosWebApi/Get` → 404; control `CuentaAhorroDocumentacionWebApi/Get` → 401. Caso 4 pasa; 4b (acta) pendiente en pantalla.
- L9 (2026-11-05). T5 escrita: `ModificarDocumento` rechaza reactivar un tipo único si `ExisteTipoEnDocumento` (ya filtra `esactivo = true`, así que el retirado no se cuenta a sí mismo). Hallazgo: el `Put` de `VistaDocumentoContableSolicitadoEstadoWebApiController` solo atrapaba `UnauthorizedAccessException`; se agrega `catch (Exception)` → 400 como el `Post`, para que el mensaje llegue a la pantalla. MSBuild sin errores. Casos 9-11 pendientes en Orca.
- L10 (2026-11-05). Usuario: "no, pasa directo al codigo" (T3 sin EXPLICACION). T3 escrita según skill `siian-transacciones` (efecto externo que se borra: después del commit). MSBuild sin errores.
- L11 (2026-11-05). Usuario: "da por finalizada esta etapa". T5 cerrada como está (se descartó bloquear siempre la reactivación de únicos: perdería el caso 11). Casos 9-11 sin recorrer en Orca, sin commit.
- L12 (2026-11-05). Usuario: "da por finalizada esta etapa". Etapa 1 cerrada: T1, T2, T3 y T5 en código y compilando. Sin recorrer en Orca: casos 2, 4b, 5, 6, 9, 10 y 11. Sin commit. Etapa 2: T4 (R5 por confirmar), T6, T8, T12, T13; T7, T9, T10 y T11 bloqueadas por R8, R10, R11 y R12.
- L13 (2026-11-05). T6: el grid sí manda `Esactivo` (onInitNewRow lo pone en true), pero la columna era editable en la fila nueva y el backend lo tomaba tal cual. Usuario: "si, igual son dos lineas". `AgregarDocumentoIndividual` fija `p_esactivo: true` (como ahorros) y `editorDocumentoSolicitadoNuevo` deja `Esactivo` de solo lectura en la fila nueva. MSBuild sin errores. Caso 12 pendiente en Orca, sin commit. T6 entra en esta etapa porque ya está hecha.
- L14 (2026-11-05). Usuario: "en si lo que deberiamos de hacer, es simple desactivar el documento solicitado anterior y volver a acargar otro y listo" y "lo mejor es crear un nuevo feature, pero es lo correcto como deberia de manejarse tanto en ahorros como en contabilidad". T7 y R8 pasan a la feature [2-eliminar-retira-pedido](../2-eliminar-retira-pedido/PLAN.md).
- L15 (2026-11-05). Usuario: "no tengamos esto para cambios tipo explicacion t1, explicacion t2, no es sano, lo mejor en estos casos es crear un feature para cada una de estas etapas", "tal cual como hicimos aca en ahorros, que fuimos etapa por etapa, incluso probando" y "hay que reorganizar esto". Correcciones pasa a ser área como `archivos-ahorros`: este plan es la feature 1 (antes `PLAN.md` de la raíz), `EXPLICACION-T1.md` y `EXPLICACION-T2.md` quedan juntas en [EXPLICACION.md](./EXPLICACION.md), las reglas pasan a [REGLAS-DE-NEGOCIO.md](../REGLAS-DE-NEGOCIO.md). L12 y L13 se renumeraron (estaban repetidos).
