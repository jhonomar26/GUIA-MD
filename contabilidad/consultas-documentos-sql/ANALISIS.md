# Análisis: consultas de documentos contables en SQL

Lectura de código del 2026-10-16 en la rama `feature/contabilidad-detalle-constancia-eliminacion`. No se ejecutó nada en la app ni se midió rendimiento.

## Qué ya existe

| Pieza | Hoy | Conclusión |
|---|---|---|
| Lista de archivos cargados de un comprobante | Sale de una vista de la base que ya cruza solicitado, tipo, carga y archivo, filtrada por comprobante y por local/remoto. | **Se reutiliza tal cual.** Cubre lo que hacía la consulta vieja de archivos por documento |
| Pestaña "Pendientes" del comprobante | Lista los documentos pedidos que todavía no tienen archivo. Pagina, filtra y busca en la pantalla. | **Se mantiene igual para el usuario.** Cambia solo cómo se arma la lista |
| Selector "Documento" al subir un archivo | Usa la misma lista de pendientes y, por cada uno, muestra qué extensiones se permiten, si expira, si la fecha es manual, si es obligatorio y si es único. | **Se mantiene igual para el usuario** |
| Consulta de vencidos y de estado visible del mismo módulo | Ya resuelven el cruce en una sola consulta a la base, filtrada por comprobante. | **Es el patrón a imitar** |
| Tres consultas viejas: archivos por documento, pendientes por combo y estado de pendientes | Ninguna pantalla ni script las llama, en esta rama ni en `master`, `developcrmmovil` o `developdevextreme24`. Tampoco hay otro repositorio en `D:\rep1` que las use. | **Se borran** |
| Generador de plantillas (vistas con paginado y filtros en servidor) | Da paginado, filtros y conteo en la base para cualquier vista generada. | **No se usa acá.** Ver H4 y [`ADR.md`](./ADR.md) |

## Qué falta

Una sola consulta a la base que devuelva los pendientes de **un** comprobante ya cruzados con su tipo de documento. Hoy esa lista se arma con dos lecturas: los pedidos del comprobante y **todos** los tipos de documento. El cruce se hace después en memoria.

## Hallazgos

- **H1. Tres consultas sin uso traen tablas completas.** La de archivos por documento lee todos los archivos del sistema (los comparten crédito, terceros y CRM) y los cruza uno contra otro. Las dos de pendientes leen todos los pedidos y todas las cargas de todos los comprobantes. Evidencia: `DocumentoContableArchivoWebApiController.cs:94`, `:158` y `:215`. Hoy no cuestan nada porque nadie las llama, pero cualquiera que las reutilice hereda el problema.
- **H2. La consulta en uso ya filtra bien los pedidos, pero lee todos los tipos.** Lee los pedidos del comprobante y después la tabla completa de tipos para cruzarlos en memoria. Evidencia: `DocumentoContableArchivoWebApiController.cs:261` y `:267`. Los tipos son configuración (pocas filas), así que la ganancia es más de orden que de velocidad: el cruce y los filtros quedan en un solo lugar, en la base.
- **H3. Las extensiones permitidas se calculan con dos datos del tipo:** si es foto y si exige firma electrónica. La consulta nueva tiene que traer esos dos datos para que el cálculo siga igual. Evidencia: `DocumentoContableArchivoWebApiController.cs:281`.
- **H4. Ni la vista ya existente usa el paginado del servidor en esta pantalla.** La grilla de cargados llama a la consulta filtrada por comprobante y pagina en la pantalla, no en la base. Evidencia: `_GestionDocumentos.cshtml:44` y `VistaDocumentoContableCargadosWebApiController.cs` (`GetPorDocumento`).
- **H5. Solo este controlador tiene el patrón.** Los demás controladores de documentos contables leen la tabla completa solo para sacar la fecha del sistema de la compañía, que es una fila. No entran en el alcance.

## Reglas de negocio (no cambian)

Reglas completas del ciclo de vida: [`ciclo-documentos/ANALISIS.md`](../ciclo-documentos/ANALISIS.md). Las que toca esta feature:

1. **Un documento es pendiente** si el pedido está activo, su estado es "pendiente" y su tipo de documento está activo.
2. **Un documento eliminado no vuelve a pendientes.** Si se recreó al eliminar, el que aparece es el pedido nuevo.
3. **El orden y los datos que ve el usuario son los mismos de hoy**, en la pestaña y en el selector.

## Preguntas resueltas

- **¿Vista de la base o consulta directa?** Consulta directa (2026-10-16). Los pendientes son siempre de un comprobante y son pocas filas, así que paginar en el servidor no aporta nada. Detalle en [`ADR.md`](./ADR.md).
- **¿Algún cliente externo llama a las tres consultas sin uso?** No se encontró ninguno en las ramas activas ni en `D:\rep1`.
- **¿Se revisan otros controladores?** No, por H5.

## Verificación

| Caso | Evidencia esperada |
|---|---|
| **Dado** un comprobante con pendientes, **cuando** se abre la pestaña "Pendientes", **entonces** se ven los mismos documentos, con los mismos datos, que antes del cambio | Respuesta del servicio antes y después para el mismo comprobante, comparada campo por campo |
| **Dado** el mismo comprobante, **cuando** se abre el selector de subida y se elige un documento, **entonces** las extensiones, "expira", "fecha manual", "obligatorio" y "único" coinciden con lo de antes | Captura antes y después, o la respuesta del servicio |
| **Dado** un pedido de tipo inactivo, **cuando** se lista, **entonces** no aparece | Resultado del servicio con un tipo inactivado en la base de pruebas |
| **Dado** un pedido eliminado, **cuando** se lista, **entonces** no aparece | Resultado del servicio |
| **Dado** un comprobante sin pendientes, **cuando** se lista, **entonces** la lista llega vacía y sin error | Resultado del servicio |
| **Dado** que se borraron las tres consultas, **cuando** se compila la solución, **entonces** hay 0 errores | Salida del build |
