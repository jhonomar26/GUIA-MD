# Feature: eliminar un archivo retira su pedido

| Campo | Valor |
|---|---|
| Módulo | contabilidad y ahorrosyaportes |
| Área | archivos-contabilidad (también enlazada desde [archivos-ahorros](../../../ahorrosyaportes/archivos-ahorros/)) |
| Menú | Se abre desde CO101 - Documento Contable (`~/DocumentoContable/CreateV2`), desde el documento equivalente y desde el botón "Documentos" del grid de cuentas de ahorro |
| Estado | en curso: reglas R3-R5 por confirmar |

Al eliminar un archivo, su pedido queda retirado. Así un tipo único se puede volver a pedir y no quedan dos pedidos activos del mismo tipo. Reemplaza la T7 / R8 de [correcciones-expediente](../correcciones-expediente/).

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | El pedido textual |
| [ANALISIS.md](./ANALISIS.md) | Qué pasa hoy en los dos módulos, el flujo nuevo y las reglas R1-R6 |
| [PLAN.md](./PLAN.md) | Specs, casos, tareas y log |
| `EXPLICACION.md` | Se escribe antes del código |
| `evidencia/` | Capturas de la prueba |
