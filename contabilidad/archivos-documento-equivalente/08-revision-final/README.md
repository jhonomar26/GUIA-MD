# Feature: revisión final del área

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-documento-equivalente |
| Menú | Sin pantalla nueva: se prueba sobre las existentes (`EdicionV2`, `DocumentoContableArchivo`, `DocumentoEquivalenteArchivo`) |
| Estado | pendiente |

Junta lo que quedó abierto en las features 01-07 para analizarlo y cerrarlo con evidencia. No agrega funcionalidad: verifica paridad con el comprobante contable (CO101) y corrige lo que falle.

Origen: revisión del 2026-10-22 contra el código y la BD demo.

## Pendientes, por riesgo

| # | Pendiente | Feature | Qué falta | Estado |
|---|---|---|---|---|
| R1 | Solicitar documentos | 02 | Script 11 ya aplicado en demo (verificado 2026-10-22: funcionalidades 147 y 148, acciones 265 y 266, 1 rol cada una). E1, E2, E4 (con permiso) y aislamiento de lectura probados; E3, E4 (rechazo) y E5a/E5b no se probaron en pantalla por decisión del usuario (2026-10-22: son básicas y piden usuarios con permisos distintos). Ver [Resultados](#resultados) | cerrado |
| R2 | Firma | 05 | E7 y E7b probados a mano por el usuario (2026-10-22): la firma funcionó. Sin captura registrada. El código no tuvo commit propio: el título salió en `3ed7934bc` | cerrado |
| R3 | Bloqueo de borrado | 06 | El catch de `23503` atrapa 15 FK, no solo las 3 del expediente: filtrar por constraint (`fk_doc*_docequivalente`). Probar que Npgsql 2.2.7 trae `Code == "23503"`. Decidir si hay UI de borrado: hoy nadie llama a `DocumentoEquivalenteWebApi.Delete` | cerrado: el usuario confirmó (2026-10-22) que un documento equivalente nunca se elimina (en crédito tampoco), así que el endpoint sobra. Se descartó el cambio sin commitear del `Delete` (409). La protección queda en la BD: 3 FK `ON DELETE RESTRICT` |
| R4 | Regresión de contable | todas | Curls contra `../antes/` idénticos y recorrido completo en CO101. Curls hechos el 2026-10-22: sin regresión, diferencias explicadas (ver [Resultados R4](#r4-curls-contra-antes)). Recorrido en pantalla de subir y eliminar pasa; la firma no se repitió aquí (R2) | cerrado |
| R5 | Eliminar archivos | 04 | Recorrido manual en CO101. Hecho el 2026-10-22: eliminar varios archivos del comprobante con "volver a solicitar" pasa y el acta sale como la de `antes/` (ver [Resultados R5](#r5-eliminar-varios-archivos-en-pantalla)) | cerrado |
| R6 | Carpeta propia | 07 | Revisión final de código; E5 se verificó solo leyendo código | pendiente |
| R7 | Limpieza | — | Borrar `FirmaCarpetaVirtualViewModel.cs.isotmp` y `FirmarDocumento.cshtml.isotmp`; commitear el cambio de 06 | pendiente |

## Resultados

### R1 (2026-10-22, servidor de pruebas, solo lectura)

| Prueba | Resultado |
|---|---|
| E1: documento sin guardar (`NuevoV2`) | Pasa: "Listar Documentos" y "Adjuntar" deshabilitados |
| Documento guardado 1085 (`EditarV2`, POST) | Pasa: los dos botones habilitados |
| E2: pulsar "Listar Documentos" | Pasa: abre `DocumentoEquivalenteCombo/?iddocumentoequivalente=1085` con tipo, número, tercero y fecha del documento. Captura: [R1-E2-combos-1085.png](./evidencia/R1-E2-combos-1085.png). No verificado: que 1085 esté anulado |
| Aislamiento de lectura | Pasa: con id 1085, solicitados del equivalente = 17; los del comprobante = 0; cargados `GetEquivalente` = 1, `GetContable` = 0 |
| E4 (lado "con permiso se acepta") | Pasa: en 1085 (ya con pendientes) se agregó "Combo 1" desde la pantalla. En BD: combo id 12 nuevo, pedidos 17 → 20, siguen con un solo tercero. Captura: [R1-E4-agregar-combo-1085.png](./evidencia/R1-E4-agregar-combo-1085.png). **Dato dejado en la demo:** combo 12 y 3 pedidos más en el documento 1085 |
| E3 | **No probado**: 1085 ya tenía pedidos; hace falta un documento equivalente guardado sin pedidos y un usuario sin permisos |
| E4 (lado "sin permiso se rechaza"), E5a, E5b | **No probados**: necesitan usuarios con permisos distintos (solo contabilidad, solo equivalente, ninguno) |

**Hallazgo:** el PLAN de 02 dice que los servicios reciben "los dos ids" y devuelven 400 con 0 o 2. El código ya no es así: se aplicó ADR-003 y hay un servicio por dueño (`DocumentoEquivalenteSolicitadoWebApi`, `GetEquivalente`/`GetContable`). El dueño lo fija el punto de entrada y el servicio contable ignora el equivalente (`Post` fuerza `Iddocumentoequivalente = null`; `Put` rechaza filas del equivalente con 400). La prueba "400 con 0 o 2 ids" ya no aplica; falta actualizar PLAN.md de 02.

### R4: curls contra `antes/`

2026-10-22, comprobante 168816, `fetch` desde la sesión de Orca (curl directo da 401). Respuestas en [evidencia/r4/](./evidencia/r4/). Eliminados se llama ahora con `DocumentoContableEliminadoWebApi/GetContable` (reemplazó a `GetEliminadosPorIdDocumento`).

| Servicio | Resultado |
|---|---|
| vencidos, cargados remotos | Idénticos |
| cargados locales | Mismas 4 filas; solo suma `Iddocumentoequivalente: null` (esperado) |
| pendientes | Antes 33 y 34; ahora 34 y 40 |
| eliminados | Antes 7; ahora 8 (suma el id 35) |

**Las dos diferencias vienen de una prueba, no del código.** En BD: el cargado 63 (`prueba-contable5-DC09…pdf`, solicitado 33) se subió a las 11:04:52 y se eliminó a las 11:04:57 (eliminado 35, observación "limpieza prueba claude"), ambos con el usuario ADMINISTRADOR `837f4985…`. El solicitado 33 quedó `ELIMINADO`, por eso sale de pendientes. Es el comportamiento normal: 13, 29, 31, 20 y 19 muestran el mismo patrón. El 40 es dato de prueba de 02.

**Sin explicar:** quién disparó esas llamadas. El MCP de Postgres es de solo lectura, así que no fue por ahí; la BD solo guarda el usuario de la sesión. No verificado.

**Por qué el 33 no volvió a pendientes:** al eliminar, la pantalla pregunta "¿Desea volver a solicitar el documento eliminado? Si responde Sí, queda un nuevo pendiente". Con "No" (o llamando al servicio sin esa opción) el solicitado queda `ELIMINADO` y no reaparece.

#### R4: recorrido en pantalla (2026-10-22)

Pantalla `DocumentoContableArchivo/?iddocumento=168816` (contable), vía Orca.

| Paso | Resultado |
|---|---|
| Carga de pestañas | Pasa: Cargados 4, Pendientes 2, Remotos 0 y Vencidos 0, igual que los curls |
| Subir PDF al pendiente 34 | Pasa: cargado 68, solicitado 34 → `CARGADO`; aparece en Cargados y sale de Pendientes |
| Eliminar ese archivo con "Sí" a volver a solicitar | Pasa: eliminado 39 con la observación, cargado 68 inactivo, solicitado 34 → `ELIMINADO`, y nace el solicitado 56 `PENDIENTE` ("PRUEBA B2 editada") |
| Firma | **No probada** en este recorrido (cubierta en R2) |

**Datos dejados en la demo:** cargado 68, eliminado 39 y solicitado 56. El archivo era un PDF mínimo (`r4-prueba-regresion.pdf`).

**Nota de método:** asignar el valor del selector de pendientes por código dispara el manejador antes de cargar el ítem y deja vacías las extensiones permitidas, lo que vacía el cargador. No es un fallo de la pantalla: al elegir desde la lista sí se carga. El archivo hay que asignarlo al `<input type=file>` nativo (`UploadMode.UseForm`).

### R5: eliminar varios archivos en pantalla

2026-10-22, comprobante 168816, pantalla `DocumentoContableArchivo`, vía Orca. Se subieron 2 PDF de prueba (`r5-prueba-a.pdf` al solicitado 56, `r5-prueba-b.pdf` al 40) para no tocar los archivos reales, y se eliminaron solo esos dos.

| Paso | Resultado |
|---|---|
| Subir 2 archivos | Pasa: cargados 69 y 70, solicitados 56 y 40 → `CARGADO` |
| Marcar solo esas 2 filas y "Eliminar seleccionados" con observación | Pasa: el popup pide observación y luego pregunta "¿volver a solicitar?" |
| Responder "Sí" | Pasa: cargados 69 y 70 inactivos, eliminados 40 y 41, y 2 pendientes nuevos (solicitados 57, tipo 3, y 58, tipo 1) |
| Una constancia | Pasa: constancia 293 con `noarchivoseliminados = 2` |
| Acta | Pasa: misma estructura que `../antes/acta_constancia_282.json` (carpeta "Contabilidad", tercero, folios 2, una fila por archivo). Respuesta en [evidencia/r5/](./evidencia/r5/acta_constancia_293.json). **No se miró el PDF renderizado**, solo el JSON de la API |

**Datos dejados en la demo:** cargados 69 y 70, eliminados 40 y 41, constancia 293 y solicitados 57 y 58. Sumados a los de R4: 68, 39, 56 y la constancia 292.

**No cubierto:** eliminar con "No" a volver a solicitar, y el rechazo por permisos (E5c a E5e), que necesitan usuarios con otros permisos.

## Orden propuesto

R1 → R2 → R3 → R5 → R6 → R4 → R7. R1 primero porque sin pendientes no hay qué subir, firmar ni eliminar; R4 al final porque es la regresión sobre todo lo anterior.

## Cómo se trabaja

Un pendiente a la vez: se analiza, se prueba, se anota el resultado aquí con su evidencia en `evidencia/` y se marca. Si una prueba falla, se abre el arreglo como tarea de este mismo feature.
