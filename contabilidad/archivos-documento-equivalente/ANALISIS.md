# Análisis: archivos en documento equivalente

> [← README](./README.md) · Negocio, sin código. El detalle técnico está en el PLAN de cada feature (ver [README del área](./README.md)).

## 1. Qué existe hoy

- **Comprobante contable (CO101).** Puede pedir documentos (por combo o sueltos), el usuario los sube, el sistema controla vencimiento, firma y eliminación con constancia. Reglas R1-R17 en [`ciclo-documentos/ANALISIS.md`](../archivos-contabilidad/ciclo-documentos/ANALISIS.md); recorrido completo en el [README de archivos-contabilidad](../archivos-contabilidad/README.md).
- **Parametrización (EV006).** Agrupaciones, tipos de documento y combos son un catálogo general: **no pertenecen a ningún comprobante**. Sirve tal cual para el documento equivalente.
- **Lo que ata todo al comprobante.** Cada documento pedido, cada combo asignado y cada archivo guardan **a qué comprobante pertenecen**, y ese dato es obligatorio. Es lo único que hay que abrir.
- **Documento equivalente.** Pasa por edición → proceso → aprobado (contabilizado), o anulado. **Solo al contabilizar** se crea su comprobante contable; antes no existe. Por eso no sirve colgar los archivos del comprobante.
- **Carpeta virtual (EV101, EV201).** Lista archivos de terceros, créditos y CRM. **No lista archivos contables**; esos solo salen en el acta de eliminación.

## 2. Qué falta

Que un documento pedido, un combo asignado o un archivo puedan pertenecer a **un comprobante o a un documento equivalente**, nunca a los dos ni a ninguno. Con eso, las mismas pantallas de CO101 sirven para el documento equivalente: la petición trae el id de uno o del otro, y eso basta para saber de cuál se trata.

## 3. Opciones evaluadas

| Opción | Qué es | Por qué sí / no |
|---|---|---|
| **A. Un expediente, dos dueños posibles** | Cada registro dice si es de un comprobante o de un documento equivalente | **Elegida.** Reusa pantallas, reglas, firma y constancia. Riesgo: tocar algo que hoy funciona en contable |
| B. Copiar todo para documento equivalente | Tablas y pantallas paralelas | ~25 piezas duplicadas; cada arreglo futuro, dos veces |
| C. Dueño genérico (tipo + número) | Un campo que sirva para cualquier documento futuro | Pierde la protección de la base; excesivo hoy |
| D. Colgar del comprobante generado | Usar el comprobante que nace al contabilizar | No sirve antes de contabilizar, y los archivos son del documento equivalente |

Ver [ADR.md](./ADR.md).

## 4. Reglas

Las reglas R1-R17 de contable aplican igual. Lo propio del documento equivalente:

1. **Dueño único.** Un registro pertenece a un comprobante **o** a un documento equivalente. La base lo exige.
2. **Hace falta guardar primero.** Sin documento equivalente guardado no se puede pedir ni subir nada.
3. **Sin límite por estado.** Se opera igual en edición, proceso, aprobado o anulado.
4. **Primer combo libre, el resto con permiso.** Igual que en contable, pero con el permiso propio del documento equivalente. El permiso de contabilidad no sirve acá, ni al revés.
5. **Documentos sueltos y eliminar**, solo con el permiso propio. El servidor también lo valida, no solo la pantalla.
6. **Tercero.** Los documentos pedidos y la firma usan el tercero del documento equivalente.
7. **Recrear** al eliminar deja el pendiente nuevo en el mismo documento equivalente.
8. **Acta de eliminación.** Dice "Documento equivalente" y muestra su tercero. No muestra el número (el acta contable tampoco muestra el del comprobante).
9. **Independencia.** Al contabilizar no se copia nada al comprobante generado. Cada pantalla ve solo lo suyo. "Duplicar" un documento equivalente no copia sus documentos.
10. **Borrado bloqueado.** Un documento equivalente con documentos pedidos o archivos no se puede borrar; el usuario ve un mensaje claro.
11. **Dueño exacto.** Toda pantalla o servicio recibe el id del comprobante **o** el del documento equivalente, nunca los dos ni ninguno. Si no, se rechaza sin tocar nada.
12. **Contable no cambia.** Con solo el id del comprobante, todo se comporta como hoy. CO101 sigue igual.

## 5. Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Documento equivalente sin guardar | Se abre la pantalla | "Listar Documentos" y "Adjuntar" deshabilitados |
| E2 | Documento equivalente guardado y anulado | Se abre la pantalla | Los botones funcionan |
| E3 | Documento equivalente sin documentos pedidos | Usuario sin permisos agrega un combo | Se crean los pendientes |
| E4 | El mismo, ya con pendientes | El mismo usuario agrega otro combo | Se rechaza; con el permiso propio, se acepta |
| E5 | Usuario con solo permisos de contabilidad | Agrega un documento suelto o elimina en un documento equivalente | Se rechaza |
| E6 | Pendiente de tipo con firma | Sube un archivo no PDF | Se rechaza con las extensiones válidas |
| E7 | PDF cargado de tipo con firma | Se firma | Firma el tercero del documento equivalente |
| E8 | Tres archivos marcados | Se eliminan con recrear | Una constancia, tres eliminados, tres pendientes nuevos en el mismo documento equivalente |
| E9 | Constancia de un documento equivalente | Se genera el acta | Dice "Documento equivalente" y su tercero |
| E10 | Documento equivalente con 2 archivos | Se contabiliza | El comprobante generado no los muestra |
| E11 | Documento equivalente con documentos pedidos | Se intenta borrar | Mensaje claro; nada se borra |
| E12 | Comprobante de referencia 168816 | Antes y después del cambio | Pendientes y cargados idénticos |
| E13 | CO101 | Se repite todo el recorrido contable | Igual que antes, acta incluida |

## 6. Fuera de alcance

- Carpeta virtual EV101/EV201.
- Número del documento en el acta.
- Copiar archivos al contabilizar o al duplicar.
- Restricciones por estado.
- Cambios en la parametrización, entrada de menú propia, botón "Volver".

## 7. Hallazgo aparte

En EV101, eliminar archivos confía en el tipo de carpeta que manda la pantalla y no usa transacción: alguien podría borrar un archivo contable marcándolo como de créditos. Existe hoy, no lo causa este cambio. Conviene abrir un cambio aparte.
