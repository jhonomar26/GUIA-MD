# Análisis: archivos en el recaudo

> [← README](./README.md) · Negocio, sin código.

## 1. Qué existe hoy

- **El recaudo genera un comprobante contable al guardarse.** Recaudo y comprobante quedan unidos. Casi siempre es un solo comprobante por recaudo (verificado en la base de demo el 2026-10-22: 127.758 recaudos con uno y 54 con dos).
- **El comprobante contable ya tiene expediente.** En CO101 se piden documentos (por combo o sueltos), se suben, vencen, se firman y se eliminan con constancia. Reglas R1-R17 en [archivos-contabilidad](../../contabilidad/archivos-contabilidad/README.md).
- **Anular un recaudo no borra su comprobante.** El comprobante queda anulado o se genera uno de reverso, así que el expediente no se pierde.
- **Todas las entradas del recaudo terminan en el mismo detalle.** Guardar un recibo financiero, un recibo de caja o una condonación, y abrir el detalle desde la consulta de transacciones, muestran la misma pantalla.
- **El detalle se abre como resultado de un envío de formulario**, no por una dirección propia. Si se reemplaza esa página, no hay forma de volver a ella.

## 2. Qué falta

Solo el acceso. Desde el detalle del recaudo, dos botones ("Listar Documentos" y "Adjuntar") que abran las mismas pantallas de CO101 sobre el comprobante del recaudo.

No hace falta:

- Otro dueño ni tablas nuevas, como sí necesitó el documento equivalente. Ahí no existía comprobante antes de contabilizar; acá sí.
- Permisos nuevos.
- Una carpeta propia.
- Bloquear el borrado, porque el comprobante no se borra.

## 3. Reglas

Las R1-R17 de contabilidad aplican igual. Lo propio del recaudo:

1. **Mismo expediente.** Lo que se pida o suba desde el recaudo se ve en CO101 al abrir ese comprobante, y al revés.
2. **Otra pestaña.** Las pantallas de documentos se abren en una pestaña nueva, para que el detalle del recaudo siga abierto.
3. **Sin límite por estado.** Se opera igual con el recaudo vigente o anulado, como en CO101.
4. **Tercero.** Los documentos pedidos y la firma usan el tercero del comprobante del recaudo.

## 4. Pendiente de decidir

| # | Pregunta | Por defecto |
|---|---|---|
| D1 | En los recaudos con dos comprobantes (factura electrónica y recibo de caja separados), ¿a cuál se cuelgan los documentos? | Al que hoy muestra el detalle, que en ese caso es la factura electrónica |
| D2 | ¿CO101 deja abrir un comprobante de recibo de caja? Si no, este atajo es la única forma de adjuntarle documentos | Sin verificar |

## 5. Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Recaudo recién guardado | Se abre "Adjuntar" | Abre en otra pestaña la pantalla de archivos de su comprobante; el detalle sigue abierto |
| E2 | Recaudo sin documentos pedidos | Se agrega un combo desde "Listar Documentos" | Se crean los pendientes en su comprobante |
| E3 | Pendiente del recaudo | Se sube un archivo | Queda cargado; en CO101, ese comprobante lo muestra |
| E4 | Recaudo abierto desde la consulta de transacciones | Se usan los botones | Mismo comportamiento que E1-E3 |
| E5 | Recaudo anulado | Se usan los botones | Funcionan |
| E6 | Usuario sin permisos de CO101 | Agrega un segundo combo, un documento suelto o elimina | Se rechaza, igual que en CO101 |
| E7 | Recaudo con dos comprobantes | Se usan los botones | Opera sobre el comprobante elegido en D1 |
| E8 | CO101 | Se repite el recorrido contable | Igual que antes |

## 6. Fuera de alcance

- Carpeta propia para los archivos de recaudos.
- Permisos propios de tesorería.
- Mostrar los documentos del recaudo en EV101/EV201.
