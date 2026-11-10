# Pruebas de la remodelación de archivos contables

> Casos Dado/Cuando/Entonces de [`ANALISIS.md`](./ANALISIS.md) (S1-S12) que quedaban pendientes en [`PLAN.md`](./PLAN.md). Las casillas se tildan solo con evidencia (dato, captura o respuesta de la API).

**Entorno:** `http://25.44.200.158/rep1` (demo, `PRUEBAS DEMO`). Compilar en `D:\rep1\SIIAN` lo actualiza.
**Pantalla:** `DocumentoContableArchivo/?iddocumento=168768&origen=%2Frep1%2FDocumentoContableCombo%2F%3Fiddocumento%3D168768`
**Sesión:** perfil de Orca con ADMINISTRADOR ya iniciado. Si vence, se renueva a mano.
**Herramienta:** Orca (`snapshot`, `click`, `fill`) y `eval` con `fetch` para leer las APIs con la sesión.

## Ya probado por el usuario (sin evidencia aquí)

Firmar, cargar y eliminar en lo básico.

## Estado inicial verificado (2026-10-28, solo lectura)

Comprobante `168768`:

| Pestaña / API | Resultado |
|---|---|
| Cargados (local) | 1 archivo: `abstracción_de_redmine.pdf`, pedido 70, observación `obligatorio`, vence 2025-10-29 |
| Cargados (Remoto) | vacío |
| Pendientes | pedidos 71, 72, 73… (el 70 no aparece: coincide con S1) |
| Vencidos | vacío (fecha del sistema 16/10/2025, el archivo aún no vence) |
| Ruta de almacenamiento | "Contabilidad" elegida por defecto |

No verificado: el contenido de `ObtenerRutas` (el script lo pisó) y el conteo total de Pendientes (respuesta cortada).

## Reglas de ejecución

- Las pruebas de abajo **cambian datos**: ejecutarlas solo con autorización del usuario en la conversación.
- Antes de cada una, anotar el estado de las cuatro pestañas para poder comparar.
- Tras cada acción: `snapshot` y, si hace falta, leer la API para ver el dato real, no solo la pantalla.
- Si algo falla, anotar la petición y la respuesta, sin suponer la causa.

---

## P1. S3: rechazos al subir

**Prepara:** archivos pequeños de prueba fuera del repo: un `.pdf` válido, un `.exe` (extensión no permitida), un archivo vacío de 0 bytes.

| # | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|
| 1.1 | Pedido elegido, archivo válido, observación vacía | Se pulsa Subir | Rechaza: "obligatoria" (la pantalla marca el campo en rojo) | [x] servidor: "Debe escribir la observación." |
| 1.2 | Observación escrita, sin pedido elegido | Se pulsa Subir | Rechaza con mensaje claro, no sube nada | [x] pedido de otro dueño: "no corresponde al documento indicado"; pedido vacío o inexistente sigue con "La secuencia no contiene elementos" (crudo) |
| 1.3 | Pedido y observación, archivo con extensión no permitida (`.exe`) | Se pulsa Subir | Rechaza por extensión (R6) y muestra las permitidas | [x] servidor: extensión `.exe` no válida, permitidas `.pdf` |
| 1.4 | Pedido y observación, archivo de 0 bytes | Se pulsa Subir | Rechaza: archivo vacío o incompleto | [x] servidor: "Archivo inválido o datos incompletos." |
| 1.5 | Tipo con fecha manual | Fecha vacía, o anterior a hoy | Rechaza (R8) | [x] sin fecha o basura: "Debe indicar la fecha"; 2025-10-01 y 2025-10-15: "no puede ser anterior a la fecha del sistema"; 2025-10-20 sube (archivo 18) |
| 1.6 | Sin ruta elegida (si la pantalla lo deja) | Se pulsa Subir | Rechaza: falta ruta | [x] servidor: sin ruta, ruta 99999 y ruta 0 → "La ruta seleccionada no es una ruta contable activa." |
| 1.7 | Todo válido (`.pdf`, pedido pendiente, observación) | Se pulsa Subir | Sale de Pendientes, aparece en Cargados con observación y vencimiento correctos | [x] pedido 76 → archivo 14, Pendientes 1→0, Cargados 2→3; pedido sin cambios; 2ª subida rechazada (S1) |

**Además en 1.7:** el pedido no cambia (`Descripcion`, `Esobligatorio`, `Esactivo` iguales) y no se puede subir otra vez al mismo pedido (S1, S4).
**Pendiente de definir:** el caso 7 de S3 (límite de almacenamiento) necesita una ruta con límite bajo; decidir si se prueba.

## P2. S9: recrear al eliminar

**Prepara:** un archivo cargado (el de 1.7 sirve).

| # | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|
| 2.1 | Archivo cargado, usuario con permiso | Eliminar → responder **No** a "¿Desea crear un nuevo documento…?" | El archivo sale de Cargados; no hay pedido nuevo; el pedido viejo **no** vuelve a Pendientes | [x] archivo 9, constancia 302, sin pedido nuevo, pedido 79 igual |
| 2.2 | Otro archivo cargado | Eliminar → responder **Sí** | Aparece un pedido nuevo pendiente: descripción vacía, obligatorio, mismo tipo; el viejo no vuelve a Pendientes | [x] archivo 12, constancia 303, pedido nuevo 86 (tipo 3, vacío, obligatorio) |
| 2.3 | Dos archivos marcados | Eliminar los dos con **Sí** | Una sola constancia y dos pedidos nuevos (S8.4, S9) | [x] archivos 14+15, una constancia (304), pedidos nuevos 87 y 88 |
| 2.4 | Eliminar sin escribir observación | Confirmar | La pantalla lo impide (S8.2) | [x] servidor rechaza observación vacía o de 2 letras; el bloqueo de pantalla no se vio |

**Comparar con la base** (`pg-demo`, solo lectura): `eseliminado = true` en los archivos, una constancia por acción, el puente conservado y el pedido viejo sin cambios (S8.6).

## P3. S8: permiso al eliminar

| # | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|
| 3.1 | Usuario **sin** *Eliminar Documentos Cargados Contabilidad* | Llama la eliminación | Rechaza en el servidor (R14), no solo oculta el botón | [ ] |

Requiere un segundo usuario sin el permiso; la sesión la inicia el usuario, no el agente.

## P4. S12: equivalente, mismos flujos

Repetir P1.7, P2.1 y P2.2 en un **documento equivalente** (URL con `iddocumentoequivalente=<id>`).

| # | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|
| 4.1 | Equivalente con un pendiente | Subir archivo válido | Sale de Pendientes, aparece en Cargados | [x] eq 1054, pedidos 84 y 85 → archivos 16 y 17 en Cargados; cruces de dueño y dueño doble o ausente rechazados |
| 4.2 | Archivo cargado | Eliminar con **No** | Igual que 2.1 | [x] archivo 16, constancia 305, sin pedido nuevo, pedido 84 intacto |
| 4.3 | Archivo cargado | Eliminar con **Sí** | Igual que 2.2 | [x] archivo 17, constancia 306, pedido nuevo 89 (tipo 3, vacío, obligatorio, eq 1054) |
| 4.4 | Las cuatro pestañas del equivalente | Abrir | Muestran lo mismo que antes de separar clases (T5.2) | [x] eq 1054: Pendientes, Cargados, Remoto y Vencidos coinciden con la base; no se comparó contra el estado previo a la separación |

**Dato que falta:** el id de un documento equivalente de demo con pedidos. Hay que buscarlo en `pg-demo` (solo lectura).

## P5. S5 cruzado: archivo de otro dueño

| # | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|
| 5.1 | Un `idarchivo` que pertenece a otro comprobante o equivalente | Se pide verlo con la URL del comprobante `168768` | Rechaza (H3), no devuelve el archivo | [x] archivo 16 pedido con URL de doc 168819 o eq 1085: "El archivo no pertenece a este documento"; sin dueño e inexistente también rechazan |
| 5.2 | Un `idarchivo` propio | Pulsar "Ver" en Cargados | Se abre | [x] archivo 16 con eq 1054: 200 `application/pdf` (`%PDF-1.4`); falta pulsar "Ver" en pantalla |
| 5.3 | Un `idarchivo` de otro dueño | Eliminarlo con la URL de `168768` | Rechaza, no elimina nada | [x] archivo 13 (de otro comprobante) rechazado: "Los archivos no pertenecen al documento" |

Se hace con `fetch` desde la pestaña (la acción exacta se confirma leyendo el WebApi antes; no se adivina la URL). 5.3 cambia datos solo si falla la validación: usar un archivo de prueba.

## P6. S10 y S6/S7 (si queda tiempo)

| # | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|
| 6.1 | PDF cargado de un tipo con firma electrónica | Enviar a firmar | Se firma y reemplaza al original (S10) | [ ] |
| 6.2 | Un pedido con archivo | Retirarlo a mano | Su archivo sale de Cargados; al reactivarlo vuelve (S6) | [x] pedido 90 retirado: su archivo 18 sale de Cargados y el pedido no está en Pendientes; al reactivar vuelve |
| 6.3 | Archivo con vencimiento pasado | Abrir Vencidos | Aparece (S7) | [ ] |

6.1: el usuario ya probó firmar; solo repetir si hay duda. 6.3 necesita un archivo con fecha manual pasada o cambiar la fecha del sistema, lo que no se hace sin autorización.

## Resultado del 2026-10-28 (comprobante 168819, dev)

Probado **contra el servidor** con `fetch` desde la sesión de Orca (mismas URLs y campos que la pantalla) y comparado con `pg-demo`. **No se vio la pantalla** (popups, diálogo Sí/No, grids refrescados).

- Cerrado en el comprobante 168819: 1.1 a 1.6, 1.7, 2.1 a 2.4 (servidor), 5.3, 6.2 y S1.
- Cerrado en el equivalente 1054: 4.1 a 4.4, 5.1, 5.2 y 5.3 con archivo activo (cruces de dueño rechazados).
- Pantalla: encabezados y tildes de los cuatro grids (leídos del DOM).
- Aclaración: el "ajeno" de la primera pasada (pedido 1, archivo 13) no probaba el dueño: el pedido no existía y el archivo ya estaba eliminado. Se rehízo con datos reales.
- **No verificado:** 3.1 (sin segundo usuario), 6.1 (firma), 6.3 (Vencidos: `pg-demo` es de solo lectura y no hay archivo con fecha pasada), popups y diálogo Sí/No en pantalla, contenido de las constancias, ver archivo con el botón.

## Pantalla de solo lectura (ya hecha)

Revisar los `Display` y columnas nuevas de los grids (Pendientes y Cargados) tras compilar: encabezados con tilde correcta (`Días de vigencia tras el cargue`, `Documento único`, `Firma electrónica`, `Requiere firma electrónica`, `Firma anulada`) y booleanos como casilla.

- [x] Pendientes muestra las columnas nuevas con sus títulos (2026-10-28, leído del DOM)
- [x] Cargados muestra Obligatorio, Requiere firma, Firmado y Firma anulada (encabezados; no verifiqué cuáles columnas son casilla)
- [x] Sin caracteres rotos (`�`) en los encabezados (Cargados, Remotos, Pendientes y Vencidos)

## Cierre

Al terminar: marcar las casillas con evidencia, pasar a [`PLAN.md`](./PLAN.md) las tareas T1.1-T1.5, T3.1, T4.1 y T5.2 que queden verificadas, y anotar los hallazgos en [`BITACORA.md`](./BITACORA.md). Lo que no se pudo probar se deja escrito como no verificado.
