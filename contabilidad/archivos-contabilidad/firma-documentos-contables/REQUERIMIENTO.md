# Requerimiento: firma electrónica de documentos contables igual a crédito

> **Historia.** Pedido original; feature cerrada el 2026-10-07. Vigente: [IMPLEMENTACION.md](./IMPLEMENTACION.md).

## Pedido original

> lo que necesitamos es replicar lo que ya existe en firmas para los documentos de credito, pero ahora con los documentos de contabilidad

Va como feature aparte de `expediente-virtual-carga` y `expediente-virtual-configuracion`.

## Indagación

**P: En crédito firman el titular y sus codeudores activos. El comprobante contable solo tiene un tercero. ¿Quién firma?**
R: "el tercero del comprobante deberia de ser". Firmante único y principal: el tercero del comprobante.

**P: ¿El tercero se guarda en el documento pedido, como en crédito?**
R (Yeison): "si claro lo ideal es que tambien guarde el tercero en el expediente virtual para que no te toque hacer esa consulta larga". Se guarda en cada documento pedido, para consultarlo directo después; no es regla de negocio sino facilidad de consulta. El tercero del comprobante no cambia.

**P: ¿Cómo se manda a firmar: a mano (botón "Firmar"), automático en combos "para firmar", o ambos?**
R: Solo a mano (opción 1). El envío automático de crédito depende de la configuración de convenios, que en contabilidad no se replicó. "Para firmar" sigue siendo solo un filtro de configuración.

**P: Un documento con firma electrónica cargado pero sin firmar, ¿cuenta como completo?**
R: Sí (opción 1). Firmar no cambia el estado del documento solicitado; la firma solo se ve en la grilla, igual que crédito.

**P: ¿Web y móvil?**
R: "por ahora solo vamos a hacerlo para web".

**P: ¿Copia por dominio (como Tercero y CRM) o pieza genérica de firma?**
R: Copia por dominio. Ver [`ADR.md`](./ADR.md).

## Criterios de aceptación

- **Dado** un documento cargado cuyo tipo tiene "Firma electrónica", **cuando** se abre la grilla de documentos del comprobante, **entonces** aparece el botón "Firmar". Sin esa marca, no aparece.
- **Dado** que se envió la solicitud, **cuando** el tercero firma en VozData y se reabre la pantalla de firma, **entonces** el archivo queda reemplazado por su versión `FIRMADO-…` y el ícono muestra "firmado".
- **Dado** un comprobante con tercero, **cuando** se le pide un documento (por combo o a mano), **entonces** el documento queda con ese tercero guardado.
- **Dado** una solicitud pendiente, **cuando** se reenvía o se anula, **entonces** se comporta igual que en crédito.
- **Dado** que se tocan piezas compartidas, **cuando** se firma un documento de crédito, tercero o CRM, **entonces** funciona igual que antes.

## No-gos

- Envío automático de solicitudes.
- App móvil.
- Codeudores o firmantes adicionales.
- Aviso automático del proveedor (callback o tarea programada).
- Cambiar el estado del documento solicitado según la firma.
