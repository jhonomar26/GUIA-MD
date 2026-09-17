# Correo al cliente por cambio de estado de ticket

| Doc | Contenido |
|---|---|
| [REGLAS.md](./REGLAS.md) | Trigger, destinatario, contenido, los 6 puntos donde dispara, qué no cubre |
| [IMPLEMENTACION.md](./IMPLEMENTACION.md) | Los 2 archivos tocados, método centralizado `EnviarCorreoCambioEstado` |

Sin `ADR.md` ni `PLAN.md`: cambio quirúrgico de 1 commit, reutiliza infraestructura de
correo ya existente (`EnviarCorreoActorNegocio`), sin decisión de arquitectura nueva.

Relacionado: [../cierre-ticket-solucionado](../cierre-ticket-solucionado/) — este
commit resuelve el pendiente de correo que había quedado documentado ahí.
