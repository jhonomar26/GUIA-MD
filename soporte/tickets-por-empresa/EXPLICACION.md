# Explicación — Tickets visibles por empresa (para no-técnicos)

> Ver `REQUERIMIENTO.md` para el pedido original y `PLAN.md` para el detalle de las
> reglas. Este documento es el resumen en términos de negocio, sin nombres de archivo
> ni de código.

## El problema

Cuando una entidad tiene varios líderes usando el portal de soporte, cada uno solo veía
los tickets que él mismo había creado. Si un líder radicaba un ticket, el otro líder de
la misma entidad no tenía forma de verlo ni de saber en qué iba, aunque fuera un
problema que afectaba a toda la empresa.

## Qué cambió

Ahora los tickets se comparten **dentro de la misma empresa**:

- Cualquier líder de una empresa puede ver todos los tickets de esa empresa, sin
  importar quién los haya creado.
- Solo la persona que radicó el ticket puede responder, calificar el servicio o
  reabrirlo. Los demás lo ven, pero en modo "solo lectura".
- Una empresa nunca ve tickets de otra empresa.

## Cómo se sabe a qué empresa pertenece cada usuario

Cada persona que usa el portal queda asociada a una única empresa. Esa asociación se
resuelve de dos maneras:

- Si la asociación era clara (la persona solo tiene relación con una empresa), quedó
  asignada automáticamente, sin que nadie tuviera que hacer nada.
- Si la asociación era ambigua (la persona aparece relacionada con más de una empresa),
  se le pide elegir una la primera vez que entra al portal — al iniciar sesión o al
  registrarse. Una vez elegida, queda fija; cambiarla requiere pedirlo a soporte.

## Qué queda fuera de esta primera entrega

- Mover un ticket de una empresa a otra.
- Que una persona pertenezca a varias empresas al mismo tiempo.
- Usuarios del portal que todavía no tienen ninguna empresa asociada en el sistema: por
  ahora esos casos quedan sin nombre de empresa visible en vez de bloquear el portal;
  se resuelve más adelante.

## Cómo se comprueba que funciona

- Dos líderes de la misma empresa: uno crea un ticket, el otro lo puede ver pero no
  responder ni calificar; el que lo creó sí puede.
- Un líder de otra empresa no ve el ticket en absoluto.
- Una persona sin empresa asociada no puede terminar su registro en el portal.
