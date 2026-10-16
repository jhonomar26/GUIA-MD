# Feature: paridad de documentos contables con crédito (brechas)

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Brechas encontradas frente a crédito, decisiones pendientes, criterios de aceptación y no-gos |
| [ANALISIS.md](ANALISIS%20B1.md) | Análisis por brecha (B1 hecho: constancia de eliminación) |
| [PLAN.md](PLAN%20B1.md) | Plan técnico de B1: vista SQL, entidad y Actor generados, conexión con el acta; incluye preguntas abiertas |

## Estado de brechas

- **B3 completa** (2026-10-16): `verArchivoCargado` en `DocumentoContableCombo/Index.cshtml` ahora usa `DocumentoContableArchivo/Visualizar`, que valida que el archivo sea contable. Sin código nuevo en backend. Pendiente: commit y prueba manual.
- **B5 completa** (2026-10-16): Vencidos muestra descripción, archivo, cargue y usuario. Se mantiene la query `ObtenerVencidosPorIddocumentocontable` y no la vista de BD, para no duplicar el CASE de vencido (R8). Además, Cargados y Vencidos muestran el nombre del archivo sin el sufijo `-DC<guid>`. Pendiente: commit y prueba manual.
- **B6 completa** (2026-10-16): Pendientes tiene la columna "Obligatorio" (`EsObligatorio`). El dato ya venía de `ObtenerSolicitadosPendientesPorId`, solo faltaba mostrarlo. Pendiente: commit y prueba manual.
- La deuda de LINQ sobre tablas completas en `DocumentoContableArchivoWebApiController` quedó en [consultas-documentos-sql](../consultas-documentos-sql/).
