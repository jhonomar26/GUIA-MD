# Feature: firma electrónica de documentos contables (paridad con crédito)

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Pedido original, preguntas y respuestas, criterios de aceptación y no-gos |
| [ANALISIS.md](./ANALISIS.md) | Qué ya existe de firmas y qué se reutiliza, estados de la firma, hallazgos, reglas y verificación |
| [ADR.md](./ADR.md) | ADR-001: copiar crédito como un dominio más, sin pieza genérica |
| [PLAN.md](./PLAN.md) | Plan técnico: script SQL, tercero en el solicitado, firma contable de punta a punta, botón en la grilla, cierre |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Qué quedó construido, archivo por archivo, con los scripts SQL y las reglas a recordar |
| [EXPLICACION.md](./EXPLICACION.md) | Cómo funciona la firma, en términos de negocio: flujo, estados, casos raros y botón en la grilla |

## Estado

Implementado y probado a mano. Las reglas de los documentos contables (estados, extensiones, eliminación) viven en [ciclo-documentos](../ciclo-documentos/).

Pendiente:
- El servidor no valida que a un combo "para firmar" solo se agreguen tipos con firma electrónica. Solo lo filtra la pantalla.
- `FirmaArchivoContableWebApiController` es un CRUD generado por plantilla que nadie usa.
