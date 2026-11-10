# Análisis: reglas y modelo del expediente de ahorros

Lectura de notas y base `demo` del 2026-10-28. Referencias: [plan original](../archivo/PLAN-v1.md) (hechos de crédito y de las cuentas, verificados el 2026-10-23), [área contable](../../../contabilidad/archivos-contabilidad/README.md) y [remodelación contable](../../../contabilidad/archivos-contabilidad/remodelacion-bd/EXPLICACION.md).

## Qué ya existe

| Pieza | Hoy | Conclusión |
|---|---|---|
| Cuentas | Todas las cuentas (CDT, ahorro, aporte) son del mismo tipo de registro y tienen titular | **Un solo dueño** para todo el expediente; el titular firma |
| Crédito | Expediente completo: catálogo, combos, pedidos, carga, eliminación con constancia y firma | **Referencia de comportamiento** |
| Contabilidad | Mismo comportamiento que crédito, remodelado: el estado del documento ya no se guarda, se calcula, y sus archivos viven aparte de los de crédito | **Referencia del modelo** |
| Ahorros | Nada construido: ni tablas ni scripts | Se arranca limpio, sin migrar datos |

## Qué cambia frente al plan original

El plan original copiaba el modelo de crédito. Contabilidad, después, corrigió varias cosas de ese modelo. Ahorros nace ya corregido:

| # | Plan original (crédito) | Alineado con contabilidad |
|---|---|---|
| A1 | El vínculo pedido-archivo tenía su propio "activo" | El vínculo no tiene banderas: existe o no existe. En crédito nadie apaga ese "activo" |
| A2 | Estado implícito | **El estado se calcula**, no se guarda: pendiente, cargado (vigente o eliminado) y retirado |
| A3 | Un pedido pendiente era "sin archivo activo" | Un pedido es pendiente si está activo y **nunca** recibió un archivo, aunque se haya eliminado. Un pedido recibe un solo archivo en su vida |
| A4 | Documento único: al subir, apagar los archivos anteriores del pedido | **Sin regla propia al subir**: con A3 nunca hay un archivo anterior en el mismo pedido. El tipo único no se vuelve a pedir mientras haya uno activo en la cuenta |
| A5 | — | Eliminar marca el archivo y deja constancia; **el pedido no se toca**. El pedido solo se retira a mano |
| A6 | Recrear al eliminar | Igual que crédito: pedido nuevo con el mismo tipo y titular, descripción vacía y obligatorio |
| A7 | Extensiones por definir | Las de contabilidad, validadas en el servidor: firma solo PDF, foto solo imágenes, el resto 13 extensiones |

Sigue igual que en el plan original: dueño = cuenta, firmante = titular, sin codeudores, sin geolocalización ni convenios, sin permiso por etapa (la cuenta no tiene etapas) y formato personalizado (feature 8). El vencimiento "después del fin de la cuenta" **queda fuera por ahora** (P3).

No aplica el patrón de dos dueños de contabilidad (comprobante y documento equivalente): ahorros tiene un solo dueño.

## Specs de esta feature

- **S1.** El modelo separa lo **pedido**, el **vínculo** y lo **subido**, y de esas tres piezas sale el estado de cada documento, una fila por pedido y archivo (historial).
- **S2.** Nunca se borra una fila: se agrega o se cambia una bandera.
- **S3.** No se puede borrar una cuenta que tenga documentos pedidos (el mensaje claro llega en la feature 9).
- **S4.** Los scripts corren de punta a punta sin errores sobre una base limpia, se pueden correr dos veces y traen su reversión. Los revisa el usuario antes de correrlos (lección de contabilidad: su script tenía una vista inválida y otra que usaba una tabla antes de crearla).
- **S5.** Crédito y contabilidad no cambian.

## Preguntas abiertas

- ~~**P1. ¿Dónde viven los archivos subidos?**~~ Decidido (2026-10-28): en una tabla propia, como contabilidad. Ver [ADR-001](./ADR.md).
- ~~**P2. ¿Ahorros adopta las diferencias a propósito de contabilidad?**~~ Decidido (2026-10-28): "sí, pero de acuerdo a lo de contabilidad, que en el fondo fue lo que se mejoró". Se toman como están hoy en contabilidad, verificado en la base `demo`:

| # | Regla | Cómo está hoy en contabilidad |
|---|---|---|
| DP1 | Cada documento del combo dice si es obligatorio | Columna `obligatorio` en el detalle del combo |
| DP2 | Un tipo único no se repite en el dueño | Se valida al asignar pedidos (base de A4) |
| DP3 | ~~Recrear copia descripción~~ | Superada: recrear igual que crédito (A6) |
| DP4 | Foto solo acepta imágenes | Regla de extensiones (A7) |
| DP5 | 13 extensiones generales | Regla de extensiones (A7) |
| DP6 | Vencidos no muestra pedidos retirados | Vencidos sale de la vista de cargados, que filtra pedidos activos |

- **P3. ¿Algún documento de una cuenta de ahorros debe vencer cierto tiempo después de que la cuenta termine?** Abierta (2026-10-28). Mientras no se responda, ahorros vence igual que contabilidad: fecha manual o N días desde el cargue. Además no existe una "fecha de fin de cuenta" única: el CDT tiene `fechadevolucion` y `fechacancelacion`, ahorro y aporte solo `fechacancelacion`, y falta ver cómo se llenan.

Además se copia de contabilidad el **registro de combos agregados** al dueño (qué combo se agregó y cuándo), que el plan original no tenía.

## Verificación

| Spec | Dado / Cuando / Entonces |
|---|---|
| S1 | **Dado** una cuenta con un pedido sin archivo, otro con archivo vigente, otro con archivo eliminado y otro retirado, **cuando** se consulta el estado, **entonces** salen pendiente, cargado vigente, cargado eliminado y retirado |
| S2 | **Dado** el modelo, **cuando** se revisan las acciones de pedir, subir, eliminar y retirar, **entonces** ninguna borra filas |
| S3 | **Dado** una cuenta con un pedido, **cuando** se intenta borrar la cuenta, **entonces** la base lo impide |
| S4 | **Dado** una base sin las tablas, **cuando** se corren los scripts dos veces y después la reversión, **entonces** no hay errores y la base queda como estaba |
| S5 | **Dado** los scripts, **cuando** se buscan objetos de crédito o contabilidad, **entonces** ninguno se crea, cambia ni borra |
