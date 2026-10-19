# Feature: configuración de documentos contables (paridad con crédito)

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Pedido original + alcance acordado |
| [ANALISIS.md](./ANALISIS.md) | Brecha crédito vs contabilidad, reglas de vencimiento y firma, hallazgos y decisiones (historia) |
| [FLUJO.md](./FLUJO.md) | Cómo funciona hoy la configuración, de punta a punta, sin código |
| [PLAN.md](./PLAN.md) | Fases F0-F3 (base de datos → servidor → pantalla) + anexo técnico (historia) |

## Estado

- F0 a F3 implementadas en código.
- Pendiente: el filtro "formato contable" del selector de plantillas (la tabla de formatos aún no tiene esa marca) y el script que marca las plantillas contables (P7').
- No hay `IMPLEMENTACION.md` ni evidencia de prueba en navegador.
- Las reglas de carga de documentos están en [ciclo-documentos](../ciclo-documentos/).
