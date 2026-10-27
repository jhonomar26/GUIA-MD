# Análisis: archivos en el comprobante de egreso

> [← README](./README.md) · Negocio, sin código.

## 1. Qué existe hoy

- **El egreso genera su comprobante contable al guardarse por primera vez**, no al aprobarse. Desde ese momento quedan unidos con el tercero del egreso. Verificado en la base de demo el 2026-10-22: 4.969 egresos, ninguno sin comprobante y cada uno con el suyo (uno a uno).
- **El comprobante contable ya tiene expediente.** En CO101 se piden documentos (por combo o sueltos), se suben, vencen, se firman y se eliminan con constancia. Reglas R1-R17 en [archivos-contabilidad](../../contabilidad/archivos-contabilidad/README.md).
- **Las pantallas de documentos de CO101 no distinguen el tipo ni el estado del comprobante.** Sirven igual para el de un egreso.
- **Anular un egreso no borra su comprobante.** El comprobante queda en estado anulado, así que el expediente no se pierde.
- **Un egreso nuevo, sin guardar, no tiene comprobante.** No hay a qué colgar documentos hasta el primer guardado.
- **Después de guardar o aprobar, la pantalla del egreso vuelve como resultado de un envío de formulario.** Si se reemplaza esa página, se pierde lo que muestra.
- La pantalla que se nombró al pedir esto (edición del detalle del egreso) es el popup de **una línea** del detalle (sucursal, flujo, valor). No es el lugar del acceso: los botones van en la pantalla principal del egreso.

## 2. Qué falta

Solo el acceso. En la barra de botones del comprobante de egreso, dos botones ("Listar Documentos" y "Adjuntar") que abran las mismas pantallas de CO101 sobre el comprobante del egreso.

No hace falta:

- Otro dueño ni tablas nuevas: el comprobante existe desde el primer guardado.
- Permisos nuevos.
- Una carpeta propia.
- Bloquear el borrado, porque el comprobante no se borra.

## 3. Reglas

Las R1-R17 de contabilidad aplican igual. Lo propio del egreso:

1. **Mismo expediente.** Lo que se pida o suba desde el egreso se ve en CO101 al abrir ese comprobante, y al revés.
2. **Otra pestaña.** Las pantallas de documentos se abren en una pestaña nueva, para que el egreso siga abierto.
3. **Solo con egreso guardado.** Mientras el egreso no se haya guardado, los botones no se muestran.
4. **Sin límite por estado.** Se opera igual con el egreso sin aprobar, aprobado o anulado, como en CO101.
5. **Tercero.** Los documentos pedidos y la firma usan el tercero del comprobante del egreso.

## 4. Pendiente de decidir

| # | Pregunta | Por defecto |
|---|---|---|
| D1 | Si se cambia el tercero del egreso antes de aprobar, ¿los documentos ya pedidos deben cambiar de tercero? | No: quedan con el tercero que tenían al pedirse, como en CO101 |

**Hallazgo fuera de alcance (H1).** Al volver a guardar un egreso, el comprobante contable actualiza notas y flujo de caja, pero **no el tercero**. Si el usuario cambia el tercero del egreso después del primer guardado, el comprobante (y con él los documentos que se pidan y el firmante) se queda con el tercero viejo. Pasa hoy, con o sin esta feature. No se corrige aquí: se comenta para decidir aparte.

## 5. Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Egreso nuevo, sin guardar | Se mira la barra | No aparecen "Listar Documentos" ni "Adjuntar" |
| E2 | Egreso recién guardado | Se abre "Adjuntar" | Abre en otra pestaña la pantalla de archivos de su comprobante; el egreso sigue abierto |
| E3 | Egreso sin documentos pedidos | Se agrega un combo desde "Listar Documentos" | Se crean los pendientes en su comprobante |
| E4 | Pendiente del egreso | Se sube un archivo | Queda cargado; en CO101, ese comprobante lo muestra |
| E5 | Egreso abierto desde TE106 (editar) | Se usan los botones | Mismo comportamiento que E2-E4 |
| E6 | Egreso aprobado o anulado | Se usan los botones | Funcionan |
| E7 | Usuario sin permisos de CO101 | Agrega un segundo combo, un documento suelto o elimina | Se rechaza, igual que en CO101 |
| E8 | CO101 | Se repite el recorrido contable | Igual que antes |

## 6. Fuera de alcance

- Carpeta propia para los archivos de egresos.
- Permisos propios de tesorería.
- Mostrar los documentos del egreso en EV101/EV201.
- Acceso desde TE202 (Consulta Egresos).
