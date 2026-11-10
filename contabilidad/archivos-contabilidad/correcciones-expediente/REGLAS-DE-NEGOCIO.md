# Reglas de negocio: correcciones del expediente virtual contable

← [README](./README.md) · Detalle de cada hallazgo en [ANALISIS.md](./ANALISIS.md)

Se leen antes que todo. Ninguna feature arranca con una regla "por confirmar" que la afecte.

| R | Regla | Porqué | Estado |
|---|---|---|---|
| R1 | Un archivo contable solo se modifica por las acciones del expediente (subir, editar descripción, eliminar, firmar); no hay servicio genérico de edición | Las acciones validan permiso, dueño y dejan historial; un servicio genérico las salta | Confirmada |
| R2 | Ver un archivo solo lee dentro de la carpeta configurada | Una ruta manipulada no debe exponer archivos del servidor (como crédito) | Anotada, no se corrige por ahora (HA1) |
| R3 | Al eliminar, primero se confirma la base y después se borran los físicos; si falla el borrado se avisa sin revertir | Mejor un archivo huérfano en disco que un registro vigente sin archivo (como ahorros) | Confirmada |
| R4 | Subir registra archivo y vínculo todo o nada; si el registro falla se borra el físico | No dejar archivos huérfanos ni registros a medias | Confirmada |
| R5 | Un pedido tiene a lo sumo un archivo, también si se sube dos veces a la vez | Regla R5 del área; hoy solo la cuida la pantalla | Por confirmar (restricción en base) |
| R6 | Reactivar un pedido de tipo único se rechaza si ya hay otro activo del mismo tipo | Mantiene DP2 (como ahorros) | Reemplazada por R19 (2026-11-05): se reactiva sin revisar el tipo, como crédito |
| R7 | Un documento suelto nace activo | Igual que crédito y ahorros | Confirmada |
| R8 | Después de eliminar sin recrear, el tipo único se puede volver a pedir | Si no, el usuario queda bloqueado sin salida | Reemplazada por R19 (2026-11-05) |
| R9 | Los archivos contables cuentan en el espacio local usado | El límite debe ser real (como crédito) | Confirmada |
| R10 | La carpeta virtual muestra, elimina y consulta archivos contables y de documento equivalente | Paridad con crédito | Por confirmar alcance (necesita un tipo de carpeta propio porque los ids de archivo contable chocan con los generales) |
| R11 | Cargados muestra también los archivos de pedidos retirados | Crédito los muestra; si no, quedan sin forma de verlos ni eliminarlos | Confirmada (2026-11-05) |
| R12 | La lista de solicitados no muestra los tipos inactivos | Igual que crédito | Confirmada (2026-11-05): se queda el filtro, no hay script 17 |
| R13 | Eliminar un archivo **retira su pedido** cuando al pedido no le queda ningún archivo vigente. Aplica a contabilidad (comprobante y equivalente) y a ahorros | El pedido ya no tiene nada vivo: deja de contar como "ya solicitado" y no queda un pedido activo con un archivo muerto | Descartada por R19 (2026-11-05) |
| R14 | Con "Sí" al eliminar nace un pedido nuevo pendiente, igual que hoy, sin revisar el tipo | Volver a subir el documento | ✅ (ya existía; con R19 el pedido viejo sigue activo, como crédito) |
| R15 | La pestaña **Eliminados** muestra el archivo aunque su pedido esté retirado | Es la historia del documento: sí hubo un archivo y se eliminó con constancia | Descartada por R19 (2026-11-05) |
| R16 | Un pedido cuyo archivo fue eliminado **no se reactiva**: si se necesita otra vez, se pide de nuevo | Reactivarlo lo dejaría activo con un archivo muerto y volvería el bloqueo | Descartada por R19 (2026-11-05) |
| R17 | Los pedidos que hoy están activos con todos sus archivos eliminados se retiran con un script, una sola vez | Si no, siguen bloqueando su tipo único | Descartada por R19 (2026-11-05) |
| R18 | "Ya está solicitado" sigue contando los pedidos activos (la consulta no cambia) | Con R13 los activos son exactamente los vivos: pendientes o con archivo vigente | Descartada por R19 (2026-11-05): ya no hay "ya está solicitado" |
| R19 | "Documento único" funciona **como crédito**: (a) no se bloquea repetir el tipo, ni a mano, ni por combo, ni al reactivar, ni al recrear; (b) al subir un archivo a un pedido de tipo único, los archivos anteriores **de ese mismo pedido** quedan inactivos (`esactivo = false`). Aplica a contabilidad (comprobante y equivalente) y a ahorros | Un solo modelo en los tres módulos, ya probado en crédito; es comodidad del usuario. Se acepta que haya dos pedidos activos del mismo tipo único. (b) hoy no tiene efecto en la web: un pedido no recibe un segundo archivo (`TieneArchivo`), igual que en crédito | ✅ confirmada (2026-11-05): "la desicion es dejarlo al igual que credito"; (b) "Literal crédito, por pedido" |

## Reglas de ahorros que cambian con R19

En [archivos-ahorros/REGLAS-DE-NEGOCIO.md](../../../ahorrosyaportes/archivos-ahorros/REGLAS-DE-NEGOCIO.md).

- **R7** y **R14** (un tipo único no se pide otra vez mientras haya uno activo): reemplazadas por R19.
- **R29** (eliminar no devuelve el pedido a pendiente) **se mantiene**.
- **R30**: recrear ya no se salta el pedido nuevo cuando hay otro pendiente del tipo único.
- **R31**: reactivar ya no revisa el tipo único.
