# Análisis: subida de archivos sobre el modelo nuevo

Lectura de código y base del 2026-10-27, rama `feature/contabilidad-archivos-documento-equivalente`. No se ejecutó nada en la app. Modelo objetivo: [`EXPLICACION.md`](./EXPLICACION.md). Reglas generales del ciclo (R1-R17): [`../ciclo-documentos/ANALISIS.md`](../ciclo-documentos/ANALISIS.md).

## Qué ya existe

| Pieza | Hoy | Conclusión |
|---|---|---|
| Base de datos | Remodelada: pedido, puente y archivo contable. Las tablas de "cargado", "eliminado" y "estado" ya no existen | **Se usa tal cual.** Falta un ajuste en la vista de cargados (S6) |
| Pantalla de combos y solicitados | Pide documentos y muestra Solicitados, Cargados y Eliminados con el modelo nuevo | **Lista.** No se toca |
| Pantalla de subida | Formulario de carga y pestañas Cargados, Cargados (Remoto), Pendientes y Vencidos. La comparten el comprobante y el documento equivalente | **La forma se queda**, es la misma de crédito. Lo que falla es lo de atrás |
| Subir un archivo | Desactivada en los dos dueños | **Rota.** Se rehace (S3) |
| Lista de pendientes y rutas | La pantalla las pide a un servicio que ya no las ofrece | **Rotas.** Se rehacen (S1, S2) |
| Pestaña Vencidos | El servicio ya no la ofrece, y la consulta lee una tabla que ya no existe | **Rota.** Se rehace (S7) |
| Pestaña Cargados | Lee una vista que ya usa el archivo contable. No descarta los pedidos retirados | **Funciona a medias.** Falta el filtro (S6) |
| Eliminar | El servicio ya no lo ofrece; la lógica escribe en tablas que ya no existen | **Rota.** Se rehace (S8, S9) |
| Ver un archivo y editar su descripción | Leen y escriben en la tabla general de archivos, no en la contable | **Rotos** para archivos nuevos (S5, S6) |
| Firma electrónica | Busca el archivo en la tabla general y el pedido por la tabla de "cargado" | **Rota.** Se adapta (S10) |
| Validaciones de extensión (R6), vencimiento (R8) y rutas | Existen y no dependen del modelo | **Se reutilizan** |

## Hallazgos

- **H1. La lista de pendientes deja subir a un pedido que ya tuvo archivo.** Solo mira que el pedido y su tipo estén activos, no si el pedido ya recibió un archivo. En crédito un pedido recibe un solo archivo en toda su vida.
- **H2. Al recrear se copian descripción y obligatorio.** Crédito no los copia: el pedido nuevo nace con la descripción vacía y obligatorio. El modelo nuevo dice "igual que crédito" (ver ADR-001).
- **H3. La validación de que el archivo a eliminar sea del comprobante está desactivada.** Sin ella, se podría eliminar un archivo de otro comprobante mandando su número.
- **H4. Quedan piezas del modelo viejo en el código** (entidades, servicios y consultas de "cargado", "eliminado" y "estado"). Compilan, pero fallan al ejecutarse.
- **H5. El script de la remodelación tiene errores:** una vista con sintaxis inválida, una vista que usa la tabla de archivos contables antes de crearla, y comentarios que describen la regla vieja de eliminar.
- **H6 (fuera de alcance, se anota).** En la grilla Solicitados de la pantalla de combos, un pedido con varios archivos sale en varias filas con la misma llave. Puede confundir la edición de esa fila.

## Specs

Aplican igual al **comprobante contable** y al **documento equivalente**. Solo cambia el dueño del pedido. Ninguna valida con lo que manda el navegador: el dueño sale de la dirección de la pantalla y los datos, de la base.

### S1. Qué pedidos se pueden cargar
Un pedido aparece en el selector de subida y en la pestaña **Pendientes** si:
1. es del dueño de la pantalla,
2. el pedido está activo,
3. su tipo de documento está activo,
4. y **nunca** recibió un archivo, aunque se haya eliminado.

Cada pedido muestra lo mismo de hoy: nombre, descripción, obligatorio, extensiones permitidas, si expira, si la fecha es manual y si es documento único.

### S2. Rutas de almacenamiento
El selector de ruta lista las rutas activas marcadas para contabilidad (o para documento equivalente, según el dueño). La principal queda elegida por defecto. Si no hay principal, se avisa y el usuario elige.

### S3. Subir un archivo
Al subir, el sistema rechaza con un mensaje claro si:
1. el archivo llegó vacío o incompleto,
2. no se eligió ruta, o la ruta no está activa o no es del dueño,
3. el pedido no cumple S1,
4. la extensión no está permitida para el tipo (R6),
5. falta la fecha manual o es anterior a la fecha del sistema (R8),
6. no se escribió la observación,
7. se supera el límite de almacenamiento (local o FTP), igual que crédito.

Si todo está bien: se guarda el archivo en disco o FTP según la ruta, se registra como archivo contable vigente con la observación como descripción y el vencimiento calculado (R8), y se liga al pedido. **El pedido no se modifica.** Desde ese momento sale de Pendientes y aparece en Cargados.

### S4. Documento único
**No requiere código propio (decisión del usuario, 2026-10-27).** Un tipo único no se vuelve a pedir mientras haya un pedido activo (asignación de pedidos), y S1 rechaza todo pedido que ya tuvo un archivo; por eso nunca hay un archivo anterior en el mismo pedido que inactivar. Crédito sí lo necesita porque su pedido admite varios archivos.

### S5. Ver un archivo
Desde Cargados y Vencidos se abre el archivo, esté en disco o en FTP. Solo se pueden abrir archivos del dueño de la pantalla.

### S6. Pestañas Cargados y Cargados (Remoto)
Muestran los archivos **no eliminados** de pedidos **activos** del dueño, separados según estén en disco o en FTP. Un pedido retirado a mano saca sus archivos de estas pestañas; reactivarlo los vuelve a mostrar. Se puede editar la descripción del archivo.

### S7. Pestaña Vencidos
Muestra los archivos no eliminados del dueño cuyo vencimiento es anterior a la fecha del sistema. **Pregunta abierta P1:** ¿incluye los de pedidos retirados? Se responde en la etapa 2.

### S8. Eliminar archivos
1. Solo con el permiso *Eliminar Documentos Cargados Contabilidad*, validado en el servidor (R14).
2. La observación es obligatoria (se valida en la pantalla, igual que crédito).
3. Solo archivos del dueño de la pantalla y no eliminados (H3).
4. Una constancia por acción, aunque se marquen varios archivos.
5. Cada archivo queda eliminado y ligado a la constancia. Se borra el archivo físico y se recalcula el almacenamiento usado.
6. **El pedido no se toca** y el vínculo pedido-archivo se conserva.
7. Todo o nada: si algo falla, no queda nada a medias.

### S9. Crear un documento nuevo al eliminar
La pantalla pregunta *"¿Desea crear un nuevo documento con las mismas características?"*. Si la respuesta es **Sí**, por cada archivo eliminado nace un pedido nuevo **pendiente**, con el mismo dueño, tipo y tercero; **descripción vacía** y **obligatorio** (ADR-001). Si es **No**, no se crea nada. En los dos casos el pedido viejo queda con su archivo eliminado y no vuelve a Pendientes.

### S10. Firma electrónica
El envío a firma funciona sobre el archivo contable: solo PDF, el firmante es el tercero del pedido, y el archivo firmado reemplaza al original. Mismo comportamiento de hoy ([`../firma-documentos-contables/`](../firma-documentos-contables/)).

### S11. Sin restos del modelo viejo
Ninguna pantalla ni servicio usa las tablas que se fueron. Los scripts de la remodelación corren de punta a punta sin errores sobre una base limpia.

### S12. Una responsabilidad por clase
Cada clase de `Negocio/` tiene **una sola responsabilidad** (SOLID) y el flujo del comprobante queda **separado** del flujo del documento equivalente. Hoy `DocumentoContableArchivoActorNegocio` mezcla consultas de pantalla, subida, eliminación, rutas, reglas de extensión y vencimiento, y acceso a FTP, casi todo duplicado por dueño. El comportamiento de S1-S10 no cambia.

## Decisiones tomadas

- **Separar responsabilidades después de T1.4** (2026-10-27): primero se termina Ver archivo en la clase actual, y luego se separa (T1.5). Eliminar nace ya en su clase nueva (T3.1).
- **Vencidos se queda en la pantalla de subida** (2026-10-27): crédito también la tiene ahí.
- **Eliminados no se agrega a la pantalla de subida** (2026-10-27): en crédito vive en la pantalla de solicitados, igual que nuestra pantalla de combos.
- **Recrear igual que crédito** (H2): ver [`ADR.md`](./ADR.md).

## Preguntas abiertas

- **P1.** S7: ¿Vencidos muestra archivos de pedidos retirados? Hoy contabilidad no los muestra (DP6) y crédito sí. Se decide en la etapa 2.

## Verificación

| Spec | Dado / Cuando / Entonces |
|---|---|
| S1 | **Dado** un comprobante con un pedido sin archivo, otro con archivo vigente, otro con archivo eliminado y otro de tipo inactivo, **cuando** se abre la pantalla, **entonces** en Pendientes y en el selector sale solo el primero |
| S2 | **Dado** una ruta principal contable, **cuando** se abre la pantalla, **entonces** queda elegida |
| S3 | **Dado** un pendiente, **cuando** se sube un archivo válido, **entonces** sale de Pendientes y aparece en Cargados (o Remoto) con la observación y el vencimiento correctos, y el pedido no cambió. Cada rechazo de la lista se prueba con su mensaje |
| S4 | **Dado** un tipo documento único, **cuando** se sube, **entonces** no falla y el archivo queda vigente |
| S5 | **Dado** un archivo cargado, **cuando** se pulsa ver, **entonces** se abre. **Dado** el número de un archivo de otro dueño, **entonces** se rechaza |
| S6 | **Dado** un pedido con archivo, **cuando** se retira el pedido, **entonces** su archivo sale de Cargados; al reactivarlo vuelve. Editar la descripción queda guardado |
| S7 | **Dado** un archivo con vencimiento pasado, **cuando** se abre Vencidos, **entonces** aparece |
| S8 | **Dado** dos archivos marcados, **cuando** se eliminan sin permiso, **entonces** se rechaza; con permiso, queda una sola constancia, los dos eliminados, los físicos borrados y los pedidos sin cambios |
| S9 | **Dado** un archivo eliminado con "Sí", **entonces** hay un pedido nuevo pendiente con descripción vacía y obligatorio; con "No", ninguno. El pedido viejo no vuelve a Pendientes |
| S10 | **Dado** un PDF cargado de un tipo con firma, **cuando** se envía a firmar, **entonces** se firma y se reemplaza |
| S11 | **Dado** el código final, **cuando** se busca cualquier uso de las tablas viejas, **entonces** no hay ninguno, y el build da 0 errores |
| S12 | **Dado** el código final, **cuando** se revisa cada clase de `Negocio/` de esta pantalla, **entonces** hace una sola cosa, ninguna mezcla comprobante con documento equivalente, y el build da 0 errores. Las pruebas de S1-S10 dan el mismo resultado que antes de separar |
