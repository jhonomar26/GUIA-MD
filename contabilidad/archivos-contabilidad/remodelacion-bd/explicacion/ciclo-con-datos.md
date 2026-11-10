# Ciclo con datos: la Cédula del comprobante 168900

> Parte de [`EXPLICACION.md`](../EXPLICACION.md). El mismo modelo, visto con filas reales de cada tabla.


El comprobante 168900 pide una Cédula. Las cuatro tablas que intervienen:

- `contabilidad_documentocontablesolicitado` (el pedido)
- `contabilidad_archivocontable` (el archivo)
- `contabilidad_documentocontablearchivo` (el puente)
- `generales_constanciaeliminacionarchivos` (el acta de eliminación)

## 1. Se pide la Cédula
`INSERT` en `contabilidad_documentocontablesolicitado`:

| id | iddocumentocontable | idtipodocumento | esactivo |
| -- | ------------------- | --------------- | -------- |
| 10 | 168900              | 5 (Cédula)      | true     |

`contabilidad_archivocontable`, `contabilidad_documentocontablearchivo` y
`generales_constanciaeliminacionarchivos`: vacías.

→ pedido 10: **pendiente**

## 2. Sube `cedula_mal.pdf`
`INSERT` en `contabilidad_archivocontable`:

| id  | nombre         | eseliminado | idconstanciaeliminacion |
| --- | -------------- | ----------- | ----------------------- |
| 100 | cedula_mal.pdf | false       | null                    |

`INSERT` en `contabilidad_documentocontablearchivo`:

| id | iddocumentocontablesolicitado | idarchivo |
| -- | ----------------------------- | --------- |
| 1  | 10                            | 100       |

`contabilidad_documentocontablesolicitado` no se toca.

→ pedido 10: **cargado** (el archivo 100 es vigente)

## 3. La eliminan y responden "Sí" a crear un documento nuevo
`INSERT` en `generales_constanciaeliminacionarchivos`:

| id | observacioneliminacion | idusuarioeliminacion | fechaeliminacion |
| -- | ---------------------- | -------------------- | ---------------- |
| 7  | archivo equivocado     | (usuario)            | (ahora)          |

`UPDATE` de la fila 100 en `contabilidad_archivocontable`:

| id  | nombre         | eseliminado | idconstanciaeliminacion |
| --- | -------------- | ----------- | ----------------------- |
| 100 | cedula_mal.pdf | **true**    | **7**                   |

`INSERT` del pedido nuevo en `contabilidad_documentocontablesolicitado` (el pedido 10 **no se toca**):

| id     | iddocumentocontable | idtipodocumento | esactivo  |
| ------ | ------------------- | --------------- | --------- |
| 10     | 168900              | 5 (Cédula)      | true      |
| **11** | **168900**          | **5 (Cédula)**  | **true**  |

El puente (fila `1 / 10 / 100`) **no se toca**. Quien marca el archivo como eliminado es `eseliminado`;
la constancia solo guarda quién, cuándo y por qué.

→ pedido 10: su archivo 100 aparece **cargado + eliminado** (`esactivo = true`) · pedido 11: **pendiente**

Si hubieran respondido "No": no se hace el `INSERT` del 11; el pedido 10 queda igual (cargado + eliminado).

## 4. Sube `cedula_ok.pdf` al pedido nuevo
`INSERT` en `contabilidad_archivocontable`:

| id      | nombre            | eseliminado | idconstanciaeliminacion |
| ------- | ----------------- | ----------- | ----------------------- |
| 100     | cedula_mal.pdf    | true        | 7                       |
| **101** | **cedula_ok.pdf** | **false**   | null                    |

`INSERT` en `contabilidad_documentocontablearchivo`:

| id    | iddocumentocontablesolicitado | idarchivo |
| ----- | ----------------------------- | --------- |
| 1     | 10                            | 100       |
| **2** | **11**                        | **101**   |

`contabilidad_documentocontablesolicitado` no se toca.

→ pedido 11: **cargado** (por el archivo 101)

## Resultado final

| Tabla                                      | Contenido                                                                          |
| ------------------------------------------ | ---------------------------------------------------------------------------------- |
| `contabilidad_documentocontablesolicitado` | pedido 10 `esactivo = true` con archivo eliminado · pedido 11 `esactivo = true` → cargado |
| `contabilidad_archivocontable`       | 101 vigente (pestaña "cargados"), 100 eliminado (pestaña "eliminados")             |
| `contabilidad_documentocontablearchivo`    | fila 1: pedido 10 → archivo 100 · fila 2: pedido 11 → archivo 101                  |
| `generales_constanciaeliminacionarchivos`  | constancia 7, la del archivo 100                                                   |
