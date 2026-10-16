# Feature: carga de documentos en comprobantes contables (paridad con crédito)

Reglas y estados vigentes: [`../ciclo-documentos/`](../ciclo-documentos/). Los docs de esta carpeta son historia, salvo `IMPLEMENTACION.md`.

| Doc | Qué es |
|---|---|
| [ANALISIS.md](./ANALISIS.md) | Cómo funcionaban los documentos de un comprobante frente a crédito al 2026-10-01. Vigente solo el mapa de tablas (1) y "obligatorio" (3) |
| [PLAN.md](./PLAN.md) | Fases F0-F5, una por PR encadenado (base y servidor → solicitud → carga → pestañas → cierre), scripts por fase + anexo técnico |
| [ADR.md](./ADR.md) | ADR-001: combos repetidos y permiso contado por documentos, igual que crédito |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Qué existe hoy en el código: agregar combo, agregar a mano, subir archivo y eliminar |
| [TAREAS.md](./TAREAS.md) | Plan técnico histórico por casillas (archivos, firmas, pruebas). Tasks 1-6 en código, incluida la Task 5 (F3.1) |

Script SQL: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\2-expediente-virtual-carga.sql`. F3.1: `4-combos-repetidos-documento-contable.sql` en la misma carpeta

## Estado

- F0 a F4 están en código.
- Las pruebas manuales de `TAREAS.md` no tienen evidencia y sus casillas siguen sin tildar.
- F5 pendiente: regresión, producción y limpieza de datos de prueba.
- Pendientes de [ciclo-documentos](../ciclo-documentos/REQUERIMIENTO.md): C1 (archivo incompleto) y C2 (solo se carga un pendiente).
