# Análisis: eliminar archivos del documento equivalente

> [← README](./README.md) · Visión general y numeración de reglas: [ANALISIS del área](../ANALISIS.md)

## Qué hace

Se eliminan archivos cargados con una observación, con la opción de recrear el pendiente. Queda una constancia y el acta dice "Documento equivalente". Permiso propio.

## Reglas que aplica

- **Regla 5 (eliminar).** Solo con el permiso propio del documento equivalente; el servidor también lo valida.
- **Regla 7.** Recrear deja el pendiente nuevo en el mismo documento equivalente.
- **Regla 8.** El acta dice "Documento equivalente" y su tercero, sin número.
- **Todo o nada.** Si un archivo de la petición no es del documento, se rechaza toda la petición antes de tocar la base.
- **Regla 11.** Se recibe el comprobante o el documento equivalente, nunca los dos ni ninguno.

## Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E5c | Usuario con solo permisos de contabilidad | Elimina un archivo de un documento equivalente | Se rechaza |
| E5d | Usuario con el permiso del documento equivalente | Manda eliminar un archivo de otro documento | Se rechaza y no se borra nada |
| E5e | El mismo | Marca 3 archivos, uno de otro documento | Se rechaza toda la petición |
| E8 | Tres archivos marcados | Se eliminan con recrear | Una constancia, tres eliminados, tres pendientes nuevos en el mismo documento equivalente |
| E9 | Constancia de un documento equivalente | Se genera el acta | Dice "Documento equivalente" y su tercero |
