# Feature: paridad de documentos contables con crédito (brechas)

Las reglas vigentes de los documentos contables están en [ciclo-documentos](../ciclo-documentos/). Esta carpeta guarda cómo se cerraron las brechas B1-B6.

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Brechas B1-B6 frente a crédito, decisiones D1-D4, criterios de aceptación y no-gos (historia) |
| [ANALISIS B1.md](ANALISIS%20B1.md) | Análisis de B1: constancia de eliminación sin detalle (historia) |
| [ANALISIS B2.md](ANALISIS%20B2.md) | Análisis de B2: permiso para documentos individuales (historia) |
| [PLAN B1.md](PLAN%20B1.md) | Plan técnico de B1, ya ejecutado (historia) |
| [PLAN B2.md](PLAN%20B2.md) | Plan técnico de B2, ya ejecutado (historia) |
| [EXPLICACION B2.md](EXPLICACION%20B2.md) | Explicación por etapa de B2: script del permiso, pantalla y servicio |
| [EXPLICACION.md](./EXPLICACION.md) | Explicación de B4, B5 y B6 |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Qué quedó construido por brecha, scripts SQL y verificación |

## Estado de brechas

| # | Estado | Commit |
|---|---|---|
| B1 | Implementada: el acta y el detalle de la constancia listan los archivos contables | `cedcba97c` |
| B2 | Implementada: permiso "Agregar Documentos Individuales Documento Contable" en pantalla y servicio | `44b917826` |
| B3 | Implementada: ver archivo desde combos valida que sea contable | `44b917826` |
| B4 | Implementada solo la descripción, por decisión (activar o inactivar el archivo no aplica en contabilidad) | `7955091af` |
| B5 | Implementada: Vencidos muestra descripción, archivo, cargue y usuario | `7955091af` |
| B6 | Implementada: Pendientes muestra la columna "Obligatorio" | `7955091af` |

- Las pruebas manuales están pendientes, salvo B2 M1. El detalle está en la sección Verificación de [IMPLEMENTACION.md](./IMPLEMENTACION.md).
- D1, D3 y D4 siguen por decidir con negocio.
- D2 pasó a [ciclo-documentos](../ciclo-documentos/) como C1.
- La deuda de LINQ sobre tablas completas en `DocumentoContableArchivoWebApiController` quedó en [consultas-documentos-sql](../consultas-documentos-sql/).
