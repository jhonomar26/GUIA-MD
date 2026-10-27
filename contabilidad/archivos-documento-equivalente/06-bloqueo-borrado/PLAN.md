# Plan: bloquear el borrado de un documento equivalente con expediente

> [← README](./README.md) · Análisis: [ANALISIS.md](./ANALISIS.md) · Decisiones: [ADR-001](../ADR.md), [ADR-002](../ADR-002.md) · Plan histórico: [archivo/PLAN.md](../archivo/PLAN.md)

**Antes de programar:** `EXPLICACION.md` (parte lógica) y entrevista; después, paso 3b antes de commitear ([flujo](../../../guia/flujo-de-feature.md)). Skills según la capa: `siian-mvc-controllers`, `siian-devextreme-behavior`.

**Marcas:** `[L1]` latin1, `[FUERA]` script SQL fuera del repo.

## Punto de partida

- La FK que impide el borrado vive en la base `[FUERA]`: **anotar aquí cuál es y en qué script** (P5 del script de pruebas), y confirmar que cubre las dos tablas, documentos pedidos **y** archivos (regla 10).
- `DocumentoEquivalenteActor.Delete` hace `catch (Exception ex) { throw ex; }`: conserva el tipo, así que la `NpgsqlException` llega al controlador. No se toca.
- No hay hoy ningún caso en el repo que capture `23503`: este sería el primero.

## Tareas

- [ ] 1. `[L1]` `DocumentoEquivalenteWebApiController.Delete`: cambiar la firma de `void` a `HttpResponseMessage`. Captura `NpgsqlException` con `Code == "23503"` y responde `Request.CreateErrorResponse(HttpStatusCode.Conflict, "<mensaje claro>")`; cualquier otra excepción se relanza con `throw;`. Si no hay error, `Request.CreateResponse(HttpStatusCode.OK)`. · Se parece a: 409 de `EntidadComboDocumentoWebApiController.Post`
- [ ] 2. Confirmar con una prueba que con Npgsql 2.2.7 la excepción llega como `NpgsqlException` y `Code` trae `"23503"`. Si no, ajustar la captura.
- [ ] 3. Pantalla `~/DocumentoEquivalente`: comprobar cómo el grid muestra el error del `Delete`. Si solo muestra un mensaje genérico, mostrar el mensaje del 409 (`siian-devextreme-behavior`).

## Verificación

- [ ] E11: documento con documentos pedidos → mensaje claro, nada se borra.
- [ ] E11-archivos: documento con archivos y sin documentos pedidos → mismo mensaje.
- [ ] E11b: documento sin expediente → se borra como hoy.
- [ ] Compila Debug sin errores.
- [ ] Commit propio de esta feature.
