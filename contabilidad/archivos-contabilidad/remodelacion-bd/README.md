# Feature: remodelación del expediente virtual contable

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-contabilidad |
| Menú | Se abre desde CO101 - Documento Contable (`~/DocumentoContable/CreateV2`) y desde el documento equivalente |
| Estado | en curso |

| Doc | Qué es |
|---|---|
| [EXPLICACION.md](./EXPLICACION.md) | El modelo objetivo en una mirada (pedido → puente → archivo, estado calculado) y qué toca cada acción |
| [explicacion/](./explicacion/) | El detalle por tema: [eliminar y retirar](./explicacion/reglas-eliminar-y-retirar.md), [reglas de crédito](./explicacion/reglas-credito.md), [ciclo con datos](./explicacion/ciclo-con-datos.md), [etapa 1](./explicacion/etapa-1-subir.md), [etapa 3](./explicacion/etapa-3-eliminar.md) |
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Pedido: arreglar la subida de archivos sobre el modelo nuevo |
| [ANALISIS.md](./ANALISIS.md) | Qué existe, hallazgos H1-H6, specs S1-S11 y verificación |
| [ADR.md](./ADR.md) | ADR-001: recrear igual que crédito (supersede DP3) |
| [ADR-002.md](./ADR-002.md) | ADR-002: un punto de entrada para los dos dueños en el borde web (supersede parcialmente al ADR-003 del equivalente) |
| [PLAN.md](./PLAN.md) | Cinco etapas: subir, cargados y vencidos, eliminar, firma, limpieza|
| [BITACORA.md](./BITACORA.md) | Cómo salió cada tarea: evidencia, decisiones y errores encontrados |

## Estado

- Base remodelada y pantalla de combos adaptada (commits `16254cea7`, `5a8c1ad45`).
- Subida de archivos: análisis y plan escritos (2026-10-27). Siguiente: explicar la etapa 1.
