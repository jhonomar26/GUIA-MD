# Plan: modelo de datos del expediente de ahorros

> [← README](./README.md) · Specs: [ANALISIS.md](./ANALISIS.md) S1-S5 · Decisiones: [ADR-001](./ADR.md), P2.

**Objetivo:** las tablas del expediente de ahorros y la vista de estado, copiadas del modelo contable remodelado, con dueño `idcuentaahorro`.

**Alcance:** tablas y la vista de estado (sin ella no se puede probar S1). Las demás vistas (cargados, vencidos, eliminados), el menú y los permisos van con la feature que los usa: su forma depende de las columnas de cada pantalla.

**Scripts:** `C:\Users\User\DataGripProjects\scriptsSiian\ahorrosyaportes\scratch\archivos-ahorros\`, numerados, idempotentes (`IF NOT EXISTS`, `CREATE OR REPLACE`), cada uno con su reversión. Los corre el usuario después de revisarlos.

## Modelo (contabilidad → ahorros)

### Catálogo

| Contabilidad | Ahorros | Columnas | Restricciones |
|---|---|---|---|
| `contabilidad_agrupaciondocumentocontable` | `ahorrosyaportes_agrupaciondocumentoahorro` | `id, nombre, esactivo` | — |
| `contabilidad_documentotipo` | `ahorrosyaportes_documentoahorro` | `id, nombre, esactivo, idagrupaciondocumento, expira, diasvencimientodespuescargue, esdocumentounico, esfechamanual, esfirmaelectronica, esfoto, esformatopersonalizado` | FK agrupación. `CHECK` igual al de contabilidad: si expira, fecha manual **o** días desde el cargue |
| `contabilidad_combodocumentotipo` | `ahorrosyaportes_combodocumentoahorro` | `id, nombre, esactivo, esparafirmar` | — |
| `contabilidad_combodocumentocontable` | `ahorrosyaportes_documentosahorrocombo` | `id, idcombo, iddocumento, obligatorio, esactivo` | `UNIQUE (idcombo, iddocumento)`; FK `CASCADE` a combo y tipo, como contabilidad |
| `contabilidad_documentotipoformato` | `ahorrosyaportes_documentoahorroformato` | `id, iddocumentoahorro, idgeneralesformato, fechacreacion, fechamodificacion, esactivo` | `UNIQUE`; FK a `generales_formatos`. Lo usa la feature 8 |

**Fuera por ahora:** vencimiento "N días después del fin de la cuenta" (en crédito, `esdiasdespuesdefechafinalizacioncredito`). No hay una fecha de fin de cuenta clara y nadie confirmó que haga falta ([P3](./ANALISIS.md)). Si se confirma, se agrega una columna y se ajusta el `CHECK` en la feature 7. No se copia `contabilidad_documentotipotipossoporte` (es de soportes contables).

### Por cuenta

| Contabilidad | Ahorros | Columnas | Restricciones |
|---|---|---|---|
| `contabilidad_documentocontablecombo` | `ahorrosyaportes_cuentaahorrocombo` | `id, idcuentaahorro, idcombo` | FK cuenta `RESTRICT`, FK combo |
| `contabilidad_documentocontablesolicitado` | `ahorrosyaportes_documentoahorrocuenta` (pedido) | `id, idcuentaahorro, iddocumento, descripcion, esobligatorio, esactivo, idtercero, descripcionrespuestacargue` | FK cuenta `RESTRICT` (S3), FK tipo, FK `terceros_terceromaestro` |
| `contabilidad_documentocontablearchivo` | `ahorrosyaportes_cuentaahorrodocumentacion` (puente) | `id, iddocumentoahorrocuenta, idarchivo` | FK pedido `CASCADE`, FK archivo. **Sin banderas** (A1) |
| `contabilidad_archivocontable` | `ahorrosyaportes_archivoahorro` | Las 15 de `generales_archivo` | FK `AspNetUsers` (cargue y modificación), `generales_credencialesftp`, `generales_constanciaeliminacionarchivos` |
| `firmas_firmaarchivocontable` | `firmas_firmaarchivoahorro` | `id, idarchivoahorro, idprocesomaestro` | FK archivo y `firmas_procesomaestro` |
| `generales_parametroscarpetavirtual.escontabilidad` | `.escarpetavirtualahorros` | `boolean NOT NULL DEFAULT false` | Columna nueva al final (constructor posicional) |

**Diferencia a propósito con contabilidad:** allá el pedido cae en cascada si se borra el comprobante; acá la cuenta **no se puede borrar** con pedidos (`RESTRICT`, S3 y foco 4 del plan original). `descripcionrespuestacargue` viene de crédito y la usa la feature 8.

### Vista de estado

`ahorrosyaportes_vistadocumentoahorroestado`: copia de `contabilidad_vistadocumentocontablesolicitadoestado` con `idcuentaahorro`. Una fila por pedido y archivo: `espendiente = s.esactivo AND a.id IS NULL`, `escargado = a.id IS NOT NULL`, `eseliminado = COALESCE(a.eseliminado, false)`, `esactivo = s.esactivo`; solo tipos activos.

### Vistas que vienen después (no se escriben en esta feature)

Dos familias, igual que contabilidad. Cada una se escribe con la feature que construye su pantalla, porque su forma depende de las columnas que la pantalla muestre.

| Familia | Para qué | Vistas (referencia contable) | Feature |
|---|---|---|---|
| **Pantalla de combos** (la de pedir documentos a la cuenta) | Pestañas "Cargados" y "Eliminados" de esa pantalla; la llave es el id del vínculo | `vistadocumentoscargadoscombo`, `vistadocumentoseliminadoscombo` | 3 (solicitar-documentos) |
| **Lado del usuario** (el expediente de la cuenta) | Cargados (con firma y ruta remota), Pendientes, Vencidos y el historial de eliminados con su constancia | `vistadocumentocontablecargados`, `vistadocumentocontablependientes`, `vistadocumentocontablevencidos`, `vistaarchivoseliminados` | 4 (cargados, pendientes, vencidos) y 5 (eliminados) |

La de estado (script 3) es la base común: las demás parten de ella o del mismo vínculo. Los nombres de las vistas contables salen de los scripts 14 a 17; se verifican de nuevo al escribir cada una.

## Tareas

### T1. Scripts
Se parece a: `scriptsSiian/contabilidad/scratch/archivos-documento-contable/11-ajustes-documentocontable.sql`.

- [x] `1-catalogo.sql`: agrupación, tipo, combo, combo ↔ tipo, formato.
- [x] `2-cuenta.sql`: combos agregados, pedido, archivo, puente, firma, columna de ruta. En ese orden: cada tabla se crea antes de que otra la referencie (error H5 de contabilidad).
- [x] `3-vista-estado.sql`.
- [x] `9-reversion.sql`: borra en orden inverso. No toca nada de crédito ni de contabilidad.

Escritos el 2026-10-28, **sin correr** (esperan la revisión del usuario). Extras frente al modelo de arriba: cuatro índices sobre las FK que se consultan por cuenta o pedido, y la vista trae también `iddocumentoarchivo` e `idtercero`, como la vista contable vigente (script 14).

**Aviso:** la vista de estado que hoy tiene contabilidad en la base `demo` es la **vieja** (script 11: solo el último archivo vigente, así que al eliminar el pedido vuelve a pendiente). El modelo acordado y el de ahorros siguen el script 14 (historial). Hay que correr el 14 en `demo` antes de comparar comportamientos.

### T2. Verificación (la corre el usuario; `pg-demo` es de solo lectura)

- [ ] S4: correr 1-3 dos veces sin errores; correr 9 y comprobar que no queda ningún objeto `ahorrosyaportes_*documento*`, `*archivoahorro*` ni la columna.
- [ ] S1: insertar a mano los cuatro casos (sin archivo, vigente, eliminado, retirado) en una transacción con `ROLLBACK` y leer la vista.
- [ ] S3: borrar una cuenta con un pedido → error de FK.
- [ ] S5: `grep` de los scripts: ningún `credito_` ni `contabilidad_` fuera de comentarios.
- [ ] El `CHECK` del tipo rechaza "expira" sin regla y "expira" con dos reglas.
