# Requerimiento: correcciones del expediente virtual contable

← [README](./README.md)

## Pedido original (2026-11-05)

> lo que vamos a revisar en esencia es que el expediente virtual de contabilidad este funcionando mas que todo la parte logica similar a como lo hace credito, me puedes ayudar revisar esto, ya lo revise a mano y mire algunas cosas, no se si haga falta otras

> la verdad no revise credito revise ahorro y aportes que en esencia tienen lo mismo o algo parecido

> con lo que se puede copiar lo vamos a copiar de ahorros

> vamos mejor a hacer lo siguiente, de los hallazgos que encontraste vamos a armar un nuevo feature D:\notas-siian\GUIA.md para ir uno por uno

## Criterio

- **Crédito** es la referencia de cómo debe funcionar; las diferencias a propósito DP1-DP6 del [README del área](../README.md#11-diferencias-a-propósito-con-crédito) no son hallazgos.
- **Ahorros** se construyó usando contabilidad como plantilla. Cuando ahorros ya resolvió algo, se copia de ahí. Cuando ahorros tiene el mismo error, se anota (no se corrige en esta feature salvo que se pida).

## Hallazgos de la revisión

Por gravedad. El detalle de cada uno, en negocio, está en [ANALISIS.md](./ANALISIS.md).

| # | Hallazgo | Gravedad |
|---|---|---|
| H1 | Servicios genéricos expuestos que permiten cambiar la ruta de un archivo, revivir un eliminado o soltar un archivo de su pedido, sin permiso ni dueño | Alta (seguridad) |
| H2 | El listado general de archivos eliminados no filtra por dueño | Media (exposición de datos) |
| H3 | Al eliminar, el archivo físico se borra antes de confirmar la base | Media |
| H4 | Subir no es atómico: archivo y vínculo sin transacción, sin limpieza del físico si falla, sin restricción de un archivo por pedido | Media |
| H5 | Reactivar un pedido no valida el documento único | Media |
| H6 | Agregar un documento suelto acepta "activo" desde el navegador | Baja |
| H7 | Un tipo único no se puede volver a pedir después de eliminar su archivo sin recrear | Media |
| H8 | El espacio de almacenamiento local no cuenta los archivos contables | Media |
| H9 | La carpeta virtual (EV101, EV201) no muestra archivos contables ni de documento equivalente | Media |
| H10 | Cargados oculta los archivos de pedidos retirados; crédito los muestra | Corregir (R11) |
| H11 | La vista de solicitados (script 17 decidido) no existe en scripts ni en la base | Descartado: se queda como crédito (R12) |
| H12 | Menores: subida responde a GET, mensaje poco claro al firmar un id inexistente, editar descripción sin validar dueño, texto "comprobante" en el equivalente, detalle de constancia sin uso | Baja |
| H13 | Notas del área que describen el modelo viejo | Baja |
