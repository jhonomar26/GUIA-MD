# Plan: acta de la constancia de eliminación

> Que "Generar formato" de una constancia de ahorros liste los archivos eliminados de ahorros, como ya hace contabilidad. · [← README](../README.md) · Reglas: [R41](../REGLAS-DE-NEGOCIO.md) · Viene de [feature 4, L2.3](../4-eliminar-con-constancia/PLAN.md)

**Antes del código:** `EXPLICACION.md` + entrevista (pendiente). Depende de la feature 4.

## Specs

- **S1.** Al eliminar archivos de una cuenta, la constancia aparece en la pestaña "Constancias eliminación" y su botón "Generar formato" imprime el acta **con los archivos de ahorros** (carpeta, tercero, tipo de documento, descripción, fecha de cargue, usuario). Implementa R41.
- **S2.** El detalle de la constancia (`ConstanciaEliminacionArchivosController`) lista esos mismos archivos.
- **S3.** Solo entran los archivos de esa constancia (`idconstanciaeliminacion`). Las actas de crédito, terceros, CRM y contabilidad no cambian.

**Fuera de esta feature:** la pestaña "Eliminados" de `IndexConsulta` (hoy tampoco lista contabilidad; se comenta aparte, L2); firma (5).

## Casos

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R41 | una constancia con 3 archivos de ahorros | genero el formato | el acta lista los 3, con carpeta "Ahorros y aportes" y `noarchivoseliminados = 3` | |
| 2 | R41 | una constancia de ahorros | miro el detalle de la constancia | lista los mismos archivos | |
| 3 | S3 | una constancia de crédito o contabilidad | genero el formato | igual que antes; no aparecen archivos de ahorros | |
| 4 | R41 | un archivo de ahorros eliminado con recrear | genero el formato | sale una sola vez (el pedido nuevo no añade filas) | |
| 5 | R41 | formato con diseñador (`ObtenerDatosEliminacionArchivosDesigner`) | lo imprimo | `tablaEliminados` trae los archivos de ahorros | |

## Tareas

Orden vertical: script → negocio → enganche → prueba. Se parece a contabilidad: `VistaArchivosEliminados{,Actor}`, `DocumentoContableArchivoActorNegocio.ObtenerArchivosEliminadosPorConstancia:23`.

- [x] **T1 (S1). Script SQL nuevo** *(escrito, sin correr: lo revisa y corre el usuario, L3)*: `scriptsSiian/ahorrosyaportes/scratch/archivos-ahorros/7-vista-archivos-eliminados.sql` (vista `ahorrosyaportes_vistaarchivoseliminados`; **reemplazado por `7b`, L5**). Hermano de `8-vista-archivos-eliminados-contabilidad.sql`.
- [x] **T2 (S1). Entidad y actor de la vista** *(hecho, L4 y L5; Data compila en 0 errores)*: `VistaArchivosEliminadosAhorrosAportes{,Actor,ActorNegocio}.cs` en `Blip.Data/Ahorrosyaportes/` (`ObtenerPorConstancia` en el ActorNegocio) y `...ViewModel.cs` en Entities; registrados en los `.csproj`.
- [x] **T3 (S1-S3). Negocio** *(hecho, L6; Negocio compila en 0 errores, sin probar)*: `ArchivoAhorroEliminacionActorNegocio.ObtenerArchivosEliminadosPorConstancia(idConstancia)`, mapea a `ContenidoCarpetaVirtualViewModel` con carpeta "Ahorros y aportes".
- [x] **T4 (S1, S2). Enganche** *(hecho, L7; Negocio compila en 0 errores, sin probar)*: un `AddRange` en `ConstanciaEliminacionArchivosActorNegocio.cs:45` y otro en `CreditoMaestroReportesNegocio.cs:903`, justo después del de contabilidad. La segunda función arma el acta del formato normal y la del diseñador.
- [~] **T5. Prueba** *(no se corrió, decisión del usuario, L8)*: build en 0 errores (hecho); los 5 casos en Orca quedan sin recorrer.

## Log

- **L1 (2026-11-04).** Pedido: "necesitamos una constancia de eliminacion para la parte de ahorros y aportes me puedes ayudar a revisar que necesitamos para hacer esto" (`IndexConsulta.cshtml`) y luego "vamos a armar un feture entonces a partir de esto".
- **L2 (2026-11-04). Hallazgos del análisis:** la constancia **ya se crea** al eliminar (`ArchivoAhorroEliminacionActorNegocio.MarcarEliminados`); falta que el acta liste sus archivos. Solo hay dos puntos donde enganchar (T4): ambos ya llaman a contabilidad. La pestaña "Eliminados" (`ContenidoCarpetaVirtualActorNegocio.ContenidoCarpetasVirtuales(…, true)`) no incluye contabilidad, así que no se toca aquí. **Abierto:** nombre de carpeta del acta (R41, por confirmar).
- **L3 (2026-11-04).** Pedido: "vamos a hacer el plan, primero por la vista" y "o la tarea 1". **T1 escrita:** una fila por archivo eliminado; tercero = el del pedido o, si no tiene, el titular de la cuenta (`cuentaahorro.idtercero`); sin filtrar por `esactivo` del pedido (R29). Incluye `idcuentaahorro` (no lo usa contabilidad) y dos consultas de control: la vista completa y el conteo por constancia contra `noarchivoseliminados`. **Siguiente:** el usuario revisa y corre el script; luego T2 (entidad y actor, regenerando con plantillas).
- **L4 (2026-11-04).** Pedido: "ya pegue las plantillas solo que le cambie el nombre, pq chocaba con otras plantillas, ahora seguiriamos con la fase 2". Las plantillas se generaron como `VistaArchivosEliminadosAhorrosAportes`, y las constantes apuntaban a la vista `ahorrosyaportes_vistaarchivoseliminadosahorrosaportes`, que no existe (la del script 7 se llama `ahorrosyaportes_vistaarchivoseliminados`). Se corrigió el nombre de la tabla en la entidad y en el actor (19 apariciones); las clases conservan el nombre largo. `ObtenerPorConstancia` calca el de contabilidad (orden por fecha de cargue e id). **Siguiente:** T3 (Negocio), que mapea a `ContenidoCarpetaVirtualViewModel`.
- **L5 (2026-11-04).** Corrección del usuario: la vista `ahorrosyaportes_vistaarchivoseliminados` "no nos sirve, ya la debemos de eliminar dado que apunta a una que choca con otras plantillas"; "el nombre" correcto es el de las plantillas. **Verificado en la base:** solo existe `ahorrosyaportes_vistaarchivoseliminadosahorrosaportes`. **Error mío (L4):** cambié las constantes C# al nombre corto; se revirtieron al nombre largo. **Scripts nuevos** (el 7 no se edita): `7b-vista-archivos-eliminados.sql` (borra la vieja si existe y crea la larga) y `7b-reversion-vista-archivos-eliminados.sql`. **Pendiente del usuario:** correr 7b si la vista corta aún existe en su base.
- **L6 (2026-11-04).** Pedido: "si vamos con t" / "t3". **Decisión:** la carpeta del acta se llama "Ahorros y aportes" (R41 queda confirmada). El método va en `ArchivoAhorroEliminacionActorNegocio` (ya agrupa la eliminación, sin clase ni `.csproj` nuevos) y llama a `VistaArchivosEliminadosAhorrosAportesActor.ObtenerPorIdConstancia` (el usuario renombró `ObtenerPorConstancia` en Data). **Siguiente:** T4 (los dos `AddRange`).
- **L7 (2026-11-04).** Pedido: "si". **T4 hecha:** una línea nueva en cada archivo (editados a nivel de bytes para conservar codificación y saltos de línea). **Siguiente:** T5, los 5 casos en Orca; hace falta el script `7b` corrido y una constancia de ahorros (las 310 a 312 de la cuenta 5872 sirven).
- **L8 (2026-11-04).** Decisión del usuario: "YA LO REVISE, COMO ES COMPLEJO PODEMOS DAR POR CERRADA ESTA FASE". La feature se cierra con **revisión de código del usuario y build en 0 errores**, sin recorrer la matriz en Orca ni capturas en `evidencia/`. **Sin verificar:** que el acta y el detalle listen los archivos de ahorros (casos 1-5), que el script `7b` esté corrido en todas las bases y que las actas de crédito y contabilidad no cambien (caso 3). Si algo falla en uso real, los casos 1-5 son la lista para reproducir.
