# A dónde apuntamos: expediente virtual contable

> Es el objetivo del modelo. Reflejarlo en el script `11-ajustes-documentocontable.sql` y en el código viene después.
> Sin producción: se borra y se crea, no se migra.


## El modelo en una mirada

```
solicitado  ──<  puente  >──  archivo
(lo que se pide)  (vínculo)   (lo que se subió)
```

| Tabla                                      | Qué es                                                               | Bandera clave              |
| ------------------------------------------ | -------------------------------------------------------------------- | -------------------------- |
| `contabilidad_documentocontablesolicitado` | El documento **pedido** (dueño: comprobante o documento equivalente) | `esactivo`                 |
| `contabilidad_documentocontablearchivo`    | Puente: qué archivo cumple qué pedido                                | ninguna                    |
| `contabilidad_archivocontable`             | El archivo **subido**                                                | `eseliminado` + constancia |

El estado **no se guarda**, se calcula. La vista `contabilidad_vistadocumentocontablesolicitadoestado` devuelve
**una fila por pedido y archivo** (el historial, igual que la grilla "Solicitados" de crédito):

**Cómo recordarlo:** el estado sale de mirar **tres tablas**. Es la misma regla de crédito
(`ObtenerDocsPendientes`: si el pedido **no tiene fila en la tabla puente**, es pendiente):

| Rol            | Crédito                            | Contabilidad                               |
| -------------- | ---------------------------------- | ------------------------------------------ |
| Pedido         | `credito_documentocreditocredito`  | `contabilidad_documentocontablesolicitado` |
| Puente         | `credito_creditodocumentacion`     | `contabilidad_documentocontablearchivo`    |
| Archivo        | `generales_archivo`                | `contabilidad_archivocontable`             |

| Estado    | Cuándo                                                                                               | Tablas que intervienen                       |
| --------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| Pendiente | hay fila en el **pedido**, está activo y **no hay fila en el puente** para él                        | pedido (`esactivo`) + puente (que no exista) |
| Cargado | hay fila en el **puente** para el pedido. Es un **historial**: sigue cargado aunque el archivo se elimine. Se parte en dos (siguientes filas) | puente |
| ↳ vigente | cargado y el archivo tiene `eseliminado = false` | puente + archivo (`eseliminado`) |
| ↳ eliminado | cargado y el archivo tiene `eseliminado = true` | puente + archivo (`eseliminado`) |
| Retirado  | el **pedido** tiene `esactivo = false`; solo cambia si alguien lo retira a mano                      | pedido (`esactivo`)                          |

**Es un historial:** eliminar no borra ni devuelve el pedido a pendiente. La fila del puente y el archivo se quedan tal cual (solo cambia `eseliminado`).
Como "pendiente" exige que **no haya fila en el puente**, ese pedido ya no puede volver a pendiente. Para cargar de nuevo el mismo documento
hay que **crear otro pedido** (por eso existe "crear un documento nuevo con las mismas características" al eliminar, o pedirlo a mano después).

Son las columnas de la vista, una por estado (`esactivo` es del **pedido**, nunca del archivo):

| Columna       | Fórmula en la vista                  |
| ------------- | ------------------------------------ |
| `espendiente` | `s.esactivo AND a.id IS NULL` (pedido activo y sin vínculo) |
| `escargado`   | `a.id IS NOT NULL` (hay vínculo)     |
| `eseliminado` | `COALESCE(a.eseliminado, false)`     |
| `esactivo`    | `s.esactivo`                         |

"Eliminado" es siempre del **archivo**. El pedido no tiene estado "eliminado": eliminar un archivo **no toca el
pedido** (igual que crédito). `esactivo = false` significa solo "pedido retirado a mano".

| Caso                                  | Fila(s) de la vista                                                  |
| ------------------------------------- | -------------------------------------------------------------------- |
| Pedido sin archivo                    | pendiente · `esactivo = true`                                        |
| Pedido con un archivo vigente         | cargado · `esactivo = true`                                          |
| Archivo eliminado (pedido sin tocar)  | cargado + eliminado · `esactivo = true`                              |
| Pedido retirado a mano                | `esactivo = false` (con o sin archivos en sus filas)                 |

Un pedido con varios archivos sale en varias filas, así que la llave de la grilla no es solo `idsolicitado`.

Nunca se borra una fila: se agregan o se cambia una bandera.

## Por qué tres tablas

- El **pedido** dice qué se exige y de quién; no guarda estado, así que no hay nada que mantener sincronizado.
- El **archivo** es lo que se subió. Eliminarlo es una marca (`eseliminado`) con su constancia; la fila no se borra.
- El **puente** une los dos. Que exista o no una fila en él es lo que distingue pendiente de cargado.

## Qué toca cada acción

Una sola mirada para no perderse: qué tabla cambia con cada cosa que hace el usuario.

| Acción                 | Pedido                     | Puente | Archivo                                  | Constancia |
| ---------------------- | -------------------------- | ------ | ---------------------------------------- | ---------- |
| Pedir un documento     | INSERT                     | —      | —                                        | —          |
| Subir un archivo       | sin cambios                | INSERT | INSERT (vigente)                         | —          |
| Eliminar (con **Sí**)  | sin cambios + INSERT del nuevo | sin cambios | UPDATE `eseliminado = true` + constancia | INSERT (una por operación) |
| Eliminar (con **No**)  | sin cambios                | sin cambios | UPDATE `eseliminado = true` + constancia | INSERT (una por operación) |
| Retirar el pedido      | UPDATE `esactivo = false`  | sin cambios | sin cambios                         | —          |

Detalle de eliminar y retirar: [`explicacion/reglas-eliminar-y-retirar.md`](./explicacion/reglas-eliminar-y-retirar.md).

## Lo que cambia respecto a hoy

- Se van `documentocontablecargado`, `documentocontableeliminado`, `estadodocumentocontable` y `solicitado.codigoestadodocumento`.
- El flujo de eliminar y crear un documento nuevo se mantiene como hoy y como en crédito; lo que cambia es que el estado ya no se guarda: se deduce de `eseliminado` (archivo) y `esactivo` (pedido); "eliminado" es del archivo; eliminar no toca el pedido (como crédito), el pedido solo se retira a mano.
- Los archivos contables pasan de `generales_archivo` a `contabilidad_archivocontable`.
- Contable y documento equivalente comparten el mismo modelo. Solo cambia el dueño del pedido.
- Crédito es la referencia de comportamiento: mismas reglas y mismas pestañas, con tablas contables (ver [reglas de crédito](./explicacion/reglas-credito.md)).

## Dónde seguir

| Quiero entender...                                   | Leer |
| ---------------------------------------------------- | ---- |
| Qué pasa al eliminar y al retirar                    | [`explicacion/reglas-eliminar-y-retirar.md`](./explicacion/reglas-eliminar-y-retirar.md) |
| Qué hace crédito y qué copiamos                      | [`explicacion/reglas-credito.md`](./explicacion/reglas-credito.md) |
| El modelo con filas reales (ejemplo de la Cédula)    | [`explicacion/ciclo-con-datos.md`](./explicacion/ciclo-con-datos.md) |
| Etapa 1: subir un archivo                            | [`explicacion/etapa-1-subir.md`](./explicacion/etapa-1-subir.md) |
| Etapa 3: eliminar y crear un documento nuevo         | [`explicacion/etapa-3-eliminar.md`](./explicacion/etapa-3-eliminar.md) |
