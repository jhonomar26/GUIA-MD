# Requerimiento: archivos en el recaudo

> [← README](./README.md)

## Pedido

Desde el recaudo (recibo financiero, recibo de caja, condonación) se debe poder pedir documentos y subirlos, igual que ya se hace en el comprobante contable (CO101): combos, documentos sueltos, vencimiento, firma y eliminación con constancia, con los permisos que ya existen.

## Lo aclarado (2026-10-22)

- **Pertenece a tesorería**, no a contabilidad.
- **El recaudo ya tiene comprobante contable.** Se crea en el momento en que se guarda el recaudo. Los documentos se cuelgan de ese comprobante, no de un registro nuevo.
- **Es un atajo.** El usuario de caja llega al mismo expediente que vería contabilidad en CO101, sin tener que buscar ahí el comprobante.
- **Sin carpeta propia por ahora.** Los archivos van a la misma ruta que los del comprobante contable. Una ruta propia se haría solo si llega a hacer falta.
- **Mismos permisos que CO101.** No se crean permisos nuevos.
