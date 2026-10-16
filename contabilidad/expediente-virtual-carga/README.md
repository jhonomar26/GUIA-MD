# Feature: carga de documentos en comprobantes contables (paridad con crédito)

| Doc | Qué es |
|---|---|
| [ANALISIS.md](./ANALISIS.md) | Cómo funcionan hoy los documentos de un comprobante frente a crédito: tablas que intervienen, ciclo de vida (estado guardado vs deducido), "obligatorio" y preguntas abiertas |
| [PLAN.md](./PLAN.md) | Fases F0-F5, una por PR encadenado (base y servidor → solicitud → carga → pestañas → cierre), scripts por fase + anexo técnico |
| [ADR.md](./ADR.md) | ADR-001: combos repetidos y permiso contado por documentos, igual que crédito |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Qué existe hoy en el código: flujos de agregar combo, agregar a mano y subir archivo, con lo pendiente |
| [TAREAS.md](./TAREAS.md) | Plan técnico por casillas (archivos, firmas, pruebas). Tasks 1-4 con código hecho (faltan pruebas manuales); Task 5 (F3.1, combos como crédito) pendiente |

Script SQL: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\2-expediente-virtual-carga.sql`. F3.1: `4-combos-repetidos-documento-contable.sql` en la misma carpeta
