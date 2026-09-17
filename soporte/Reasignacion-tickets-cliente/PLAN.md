# Plan — Reasignación de tickets entre usuarios cliente (portal)

## Contexto

Reasignación es entre **usuarios del portal cliente** (`soporte_soporteusuariosistema`), no gestores internos de soporte (eso ya existe aparte, no se toca). El campo que cambia es `crm_gestionmaestrocrm.idportalusuario`.

## Regla core

- Reasignar ticket = cambiar `idportalusuario` del ticket.
- Válido solo si el usuario destino pertenece a la **misma empresa** (`idempresa`) que el usuario origen / ticket. Si no → error explícito.
- Usuario destino debe estar **activo** (`activo = true`). Inactivo no puede recibir ticket.

## Restricciones

- Ticket cerrado/cancelado (`estacerrada = true`) → no se puede reasignar. Mismo criterio que ya aplica para gestores en soporte.
- Reasignar al mismo usuario que ya lo tiene → ignorar (no-op), sin generar log ni correo.

## Quién ejecuta la acción

- El **cliente** desde el portal (usuario logueado en `soporte_soporteusuariosistema`), únicamente sobre tickets de su propia empresa.

## Comentario / motivo

- Campo de observación **opcional** al reasignar.

## Historial

- **Se crea tabla dedicada** (no se reutiliza `soporte_soporteauditoria`). Razón: acá el caso es específico y conocido de antemano (usuario anterior, usuario nuevo), se gana FK tipada real e integridad referencial contra `soporte_soporteusuariosistema`, en vez de guardar ids como texto en `valoranterior`/`valornuevo`. La auditoría genérica queda para cambios de campos variables (estado, prioridad, entorno); esto es un evento de negocio con identidad propia.
- Tabla propuesta: `soporte_soporteticketreasignacion`
  - `idgestion` → `crm_gestionmaestrocrm`
  - `idusuarioanterior` → `soporte_soporteusuariosistema`
  - `idusuarionuevo` → `soporte_soporteusuariosistema`
  - `idportalusuarioejecutor` → `soporte_soporteusuariosistema` (quien hizo la reasignación)
  - `observacion` (opcional)
  - `fecha` (default now())

## Notificación

- Correo al usuario destino avisando que se le reasignó el ticket.
- Se reutiliza el mecanismo de correo que ya existe para la asignación inicial de tickets — no requiere desarrollo nuevo significativo.

## Fuera de alcance / no se necesita

- Tabla de historial separada — la genérica de auditoría cubre el caso.
- Reglas de negocio adicionales (aprobación, límite de reasignaciones, etc.) — no se identificó necesidad real, se agregan si surge caso concreto.

## Pendiente para fase técnica (no resuelto aquí)

- Endpoint / controlador que ejecute la reasignación.
- UI: combo de usuario destino filtrado por empresa + activo, excluyendo al usuario actual.
- Punto exacto donde vive la validación de "misma empresa" (Actor vs ActorNegocio).
