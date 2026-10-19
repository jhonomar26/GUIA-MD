# Feature: consultas de documentos contables en SQL (deuda técnica)

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Métodos de `DocumentoContableArchivoWebApiController` que filtran tablas completas con LINQ: cuáles borrar y cuál pasar a SQL |
| [ANALISIS.md](./ANALISIS.md) | Qué existe, hallazgos H1-H5, reglas que no cambian y verificación |
| [ADR.md](./ADR.md) | ADR-001: pendientes con consulta directa, sin vista de la base |
| [PLAN.md](./PLAN.md) | Tarea 0 captura del antes, Tarea 1 consulta SQL de pendientes, Tarea 2 borrar las tres sin uso |

## Estado

- Análisis cerrado (2026-10-16). `PLAN.md` escrito (2026-10-16).
- Tarea 0 y Tarea 1 hechas y commiteadas (`50348040d`, 2026-10-19). Tarea 2 hecha y commiteada (`9ec22b4d6`). Detalle en [`IMPLEMENTACION.md`](./IMPLEMENTACION.md).
