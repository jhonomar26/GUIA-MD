# ADR — Carga de documentos en comprobantes contables

## ADR-001: Agregar combos igual que crédito (repetidos y permiso por documentos)

**Estado:** Aceptado. Cambia las reglas R2 y R13 de [`PLAN.md`](./PLAN.md) y la observación O7 de [`ANALISIS.md`](./ANALISIS.md).

### Contexto

En crédito, agregar un combo copia sus documentos al crédito y no queda registro de qué combo se usó. Por eso **el mismo combo se puede agregar varias veces**. El permiso "Agregar Mas Combos" se pide en cuanto el crédito ya tiene **cualquier documento**, venga de un combo o se haya agregado a mano.

Contabilidad se había construido distinto:
- Rechazaba un combo ya agregado al comprobante, tanto en el servidor como en la base.
- Pedía el permiso solo cuando ya existía otro **combo**; los documentos agregados a mano no contaban.

Al probar, el usuario vio que se comportaba distinto a crédito. La meta de la feature es replicar crédito.

### Decisión

1. Un comprobante puede recibir **el mismo combo más de una vez**. Se quita el rechazo en el servidor y la restricción de la base.
2. El permiso para agregar otro combo se pide si el comprobante ya tiene **algún documento solicitado**, sin importar de dónde vino.
3. Se mantiene lo que contabilidad hace mejor que crédito o que es regla propia:
   - Agregar un combo sigue siendo todo o nada.
   - Solo entran combos activos.
   - Un tipo único no se repite (R11): al repetir el combo, sus documentos únicos que ya están se saltan y los demás se piden de nuevo.

4. La pantalla bloquea el selector y el botón cuando el usuario no puede agregar (como Terceros y CRM). En la pantalla principal de crédito esos controles solo se bloquean por el permiso de editar documentos y el límite se avisa al pulsar; se eligió bloquear de antemano para que el usuario no tenga que pulsar para enterarse. El servidor rechaza igual.

### Consecuencias

- Repetir un combo duplica sus documentos no únicos, igual que en crédito. Los sobrantes se inactivan uno por uno (R1).
- Un comprobante con solo documentos agregados a mano ya no puede recibir un combo sin el permiso.
- Se sigue guardando de qué combo vino cada documento. Ahora puede haber varias filas del mismo combo en un comprobante.
- Hace falta un script de base que va a producción junto con el código.
