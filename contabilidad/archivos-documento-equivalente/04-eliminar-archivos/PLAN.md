# Plan: eliminar archivos del documento equivalente

> [← README](./README.md) · Análisis: [ANALISIS.md](./ANALISIS.md) · Decisiones: [ADR-001](../ADR.md), [ADR-002](../ADR-002.md) · Plan histórico: [archivo/PLAN.md](../archivo/PLAN.md)

**Antes de programar:** `EXPLICACION.md` (parte lógica) y entrevista; después, paso 3b antes de commitear ([flujo](../../../guia/flujo-de-feature.md)). Skills según la capa: `siian-actor-dapper-metodos`, `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`.

**Regla de todas las tareas:** cada servicio recibe el id del comprobante **o** el del documento equivalente, exactamente uno; si no, 400 ([ADR-002](../ADR-002.md)). Marcas: `[L1]` latin1, `[FUERA]` script SQL fuera del repo, `[CSPROJ]` archivo nuevo a registrar.

## Tareas

- [x] 1. `[FUERA]` `12-permisos-eliminar-documento-equivalente.sql`, idempotente: ruta `~/DocumentoContableArchivo/BorrarDocumentosSeleccionadosEquivalente` a los roles con la acción contable activa. Correrlo dos veces. · Se parece a: script 9
- [x] 2. `[L1]` `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs`: `PuedeEliminarArchivos(usuario, idContable, idEquivalente)`. · Se parece a: el permiso contable actual
- [x] 3. `[L1]` Mismo: `EliminarArchivos` comprueba, antes de la transacción, que cada archivo pertenece al documento y el permiso según el dueño de su fila. Recrear copia las dos anclas. Guard `== null`. · Se parece a: `EliminarArchivos` actual
- [x] 4. `[L1]` Mismo: etiqueta "Documento equivalente" en `ObtenerArchivosEliminadosPorConstancia`. · Se parece a: la etiqueta "Contabilidad" actual
- [x] 5. `[L1]` `DocumentoContableArchivoWebApiController.EliminarArchivos` y `DocumentoContableEliminadoWebApiController`: los dos ids; 400. · Se parece a: los mismos métodos
- [x] 6. MVC `DocumentoContableArchivoController.Index`: permiso de eliminar según el dueño. · Se parece a: el permiso contable en el mismo `Index`
- [x] 7. `[L1]` `_PopupObservacion.cshtml`: los ids del dueño en el JSON de eliminar. · Se parece a: el JSON actual
- [x] 8. Compilar Debug sin errores.

## Verificación

- [x] E5c a E9 probados el 2026-10-21 (E8 con 2 archivos, no 3); acta en `evidencia/`. Ver nota abajo.
- [x] El acta de la constancia 282 sigue igual a `../antes/acta_constancia_282.png`.
- [x] Contable sin cambios: curls de 0.6 contra `../antes/` idénticos.
- [ ] Mismo recorrido en CO101 (pendiente, manual).
- [x] Commit propio de esta feature: `843ad637f`.

Nota 2026-10-21: acta 282 igual a `antes/` (`evidencia/acta_constancia_282_despues.png`). Contable 168816: vencidos, cargados y eliminados idénticos (eliminados vía `GetContable`, que reemplazó a `GetEliminadosPorIdDocumento` en la feature 02); pendientes 3 en vez de 2 por el id 40 de pruebas de la feature 02. JSON en `evidencia/`. No verificado: recorrido manual en pantalla CO101.
