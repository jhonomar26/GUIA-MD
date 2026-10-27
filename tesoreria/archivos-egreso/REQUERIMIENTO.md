# Requerimiento: archivos en el comprobante de egreso

> [← README](./README.md)

## Pedido

Desde el comprobante de egreso se debe poder pedir documentos y subirlos, igual que ya se hace en el comprobante contable (CO101): combos, documentos sueltos, vencimiento, firma y eliminación con constancia, con los permisos que ya existen. Es la misma historia que [archivos-recaudo](../archivos-recaudo/REQUERIMIENTO.md).

## Lo aclarado (2026-10-22)

- **Pertenece a tesorería**, no a contabilidad (el menú es TE106).
- **El egreso ya tiene comprobante contable.** Se crea la primera vez que se guarda el egreso, antes de aprobarlo. Los documentos se cuelgan de ese comprobante, no de un registro nuevo.
- **Es un atajo.** El usuario de tesorería llega al mismo expediente que vería contabilidad en CO101.
- **Sin carpeta propia.** Los archivos van a la misma ruta que los del comprobante contable.
- **Mismos permisos que CO101.** No se crean permisos nuevos.
