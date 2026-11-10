# Feature: correcciones del expediente virtual contable

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-contabilidad |
| Menú | Se abre desde CO101 - Documento Contable (`~/DocumentoContable/CreateV2`) y desde el documento equivalente; EV101 y EV201 para la carpeta virtual |
| Estado | etapa 1 cerrada (T1, T2, T3, T5); etapa 2 pendiente (T4, T6-T13) |

Corrige, uno por uno, los hallazgos de la revisión de lógica del expediente contable frente a crédito y ahorros (2026-11-05). Varios son regresiones de [remodelacion-bd](../remodelacion-bd/).

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | El pedido textual y los hallazgos tal como salieron de la revisión |
| [ANALISIS.md](./ANALISIS.md) | Qué hace hoy contabilidad, crédito y ahorros en cada punto, y las reglas R1-R12 con su estado |
| [PLAN.md](./PLAN.md) | Specs, casos, tareas (una por hallazgo, en orden) y log |
| `EXPLICACION-T<n>.md` | Se escribe al arrancar cada tarea, antes del código |
| `evidencia/` | Capturas y salidas de la prueba de cada tarea |
