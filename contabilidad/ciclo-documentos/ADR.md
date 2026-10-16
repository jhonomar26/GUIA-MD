# ADR — Ciclo de vida de los documentos contables

## ADR-001: Crédito es la fuente de verdad, con cinco diferencias a propósito

**Estado:** Aceptado (2026-10-16). Reemplaza como referencia vigente a las reglas R1-R14 de [`expediente-virtual-carga/PLAN.md`](../expediente-virtual-carga/PLAN.md), que quedan como historia.

### Contexto

Las reglas de los documentos contables se escribieron en varias features. Al contrastarlas con el código de crédito el 2026-10-16, algunas describían cosas que crédito no tiene, y en un caso (único repetido) crédito tiene un defecto que contabilidad corrige.

### Decisión

Contabilidad se comporta como crédito. Lo que crédito no tiene se quita, salvo estas diferencias, que se mantienen a propósito:

| # | Diferencia | Crédito | Contabilidad | Por qué se mantiene |
|---|---|---|---|---|
| DP1 | Obligatorio por documento del combo | Todo documento de un combo nace obligatorio (salvo convenios, donde lo decide el convenio para todo el combo) | Cada documento del combo dice si es obligatorio | Informa mejor al usuario. Quitarlo exige tocar la configuración ya en producción. Solo afecta el asterisco |
| DP2 | Un tipo único no se repite en el comprobante | Se pueden pedir dos documentos únicos del mismo tipo | Se rechaza mientras haya uno activo y no eliminado | En crédito no tiene sentido que un único se repita: es un defecto |
| DP3 | Recrear copia la descripción y el obligatorio | El nuevo documento nace con descripción vacía y obligatorio | El nuevo copia ambos datos del eliminado | El documento recreado es el mismo pedido; perder la descripción no aporta nada |
| DP4 | Tipo "foto" solo acepta imágenes | La marca existe en el tipo pero no se usa al subir | Solo .jpg, .jpeg y .png | Le da sentido a la marca |
| DP5 | Lista general de extensiones | 6 extensiones | 16 (agrega .png, .doc, .xls, .xml, .zip, .rar, .7z) | Contabilidad maneja XML de facturas y soportes comprimidos. El impacto es bajo |

### Consecuencias

- Se quitó la regla "un único se puede volver a cargar y reemplaza al anterior": ni crédito ni contabilidad la ofrecen en pantalla. Para cambiar un archivo se elimina con "recrear" y se sube al documento nuevo.
- Lo que crédito tiene y contabilidad no se ajusta en código ([`REQUERIMIENTO.md`](./REQUERIMIENTO.md), C1 y C2).
- Una diferencia nueva necesita un ADR nuevo que la justifique.
