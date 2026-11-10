# Eliminar y retirar un pedido

> Parte de [`EXPLICACION.md`](../EXPLICACION.md). Primero el modelo y los estados; aquí, las dos acciones que cambian banderas.

# Regla de eliminar (igual que crédito para el usuario)

Al eliminar un archivo, la pantalla pregunta *"¿Desea crear un nuevo documento con las mismas características?"*.
En **los dos casos** el archivo queda `eseliminado = true` con su constancia, y el pedido viejo **no se toca**
(sigue `esactivo = true`, igual que crédito). No queda un pendiente duplicado porque la vista solo marca
pendiente al pedido que no tiene ninguna fila de archivo:

| Respuesta | Pedido viejo                                    | Pedido nuevo                                              |
| --------- | ----------------------------------------------- | --------------------------------------------------------- |
| Sí        | sin cambios · cargado + eliminado               | INSERT, pendiente: mismo dueño, tipo y tercero; descripción vacía, `esobligatorio = true` (como crédito) |
| No        | sin cambios · cargado + eliminado               | no se crea                                                |

El mismo pedido **no** vuelve a pendiente: lo que queda pendiente es un pedido nuevo. Con "No" el pedido viejo
queda activo con su archivo eliminado y no aparece como pendiente (igual que crédito).

# Regla de retirar un pedido

Retirar un pedido (`esactivo = false`) es una acción **manual** del usuario (columna editable en la grilla de
Solicitados), sin validaciones, igual que crédito. Eliminar un archivo nunca lo dispara. Retirar **no toca sus
archivos**, pero los **saca de las pestañas Cargados y Eliminados** (filtran pedido activo); en Solicitados el
pedido sigue visible con `esactivo = false`. Reactivarlo los vuelve a mostrar.
