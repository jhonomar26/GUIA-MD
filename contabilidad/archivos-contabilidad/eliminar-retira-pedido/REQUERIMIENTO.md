# Requerimiento: eliminar un archivo retira su pedido

← [README](./README.md)

## Pedido original (2026-11-05)

Salió de la T7 de [correcciones-expediente](../correcciones-expediente/PLAN.md) (H7: un tipo único no se puede volver a pedir después de eliminar su archivo sin recrear).

> ti siento que lo de documento unico nos ha traido diferentes problemas, en si lo que deberiamos de hacer, es simple desactivar el documento solicitado anterior y volver a acargar otro y listo

> al se un cambio un poco mas extenso lo mejor es crear un nuevo feature, pero es lo correcto como deberia de manejarse tanto en ahorros como en contabilidad

## Lo que ve el usuario hoy

1. Un documento contable (o una cuenta de ahorro) tiene un tipo único con su archivo cargado.
2. Elimina el archivo y contesta **"No"** a crear un pedido nuevo.
3. Quiere volver a pedir ese tipo, a mano o con un combo: a mano le sale "Este tipo de documento es unico y ya esta solicitado"; con el combo el tipo se saltea sin aviso. No hay salida.
4. Si contesta **"Sí"**, nace un pedido nuevo, pero el viejo sigue activo: quedan dos pedidos activos de un tipo que debería ser único.
