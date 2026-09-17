# Explicación — Reasignación de tickets entre usuarios cliente

Un cliente (empresa) puede tener varios usuarios registrados en el portal de soporte. Cuando alguien de esa empresa crea un ticket, queda "asignado" a esa persona: solo ella puede escribir en el chat, subir archivos o calificar la atención una vez cerrado.

Esto era un problema si esa persona se iba de vacaciones, cambiaba de rol, o simplemente otro compañero de la misma empresa debía seguir el caso. No había forma de pasarle el ticket a otro usuario del portal — quedaba "atado" a quien lo creó.

## Qué se resolvió

Ahora el dueño actual de un ticket puede reasignarlo a **otro usuario de su misma empresa**, directamente desde el portal. Al hacerlo:

- El ticket pasa a ser del nuevo usuario: solo él ya puede seguir escribiendo en el chat o subiendo archivos.
- El usuario que reasignó pierde el acceso de edición sobre ese ticket (puede seguir viéndolo si vuelve a entrar, pero ya no puede intervenir).
- El nuevo dueño recibe un correo avisando que se le asignó un ticket.
- Queda guardado un historial: quién lo tenía antes, a quién se lo pasó, quién hizo el cambio, cuándo y por qué (comentario opcional).

## Qué NO se puede hacer (reglas de seguridad)

- **No se puede reasignar a alguien de otra empresa.** El portal solo deja elegir entre los usuarios de la misma empresa que el ticket.
- **Solo el dueño actual del ticket puede reasignarlo.** Un tercer usuario de la misma empresa no puede tomar un ticket ajeno por su cuenta — tiene que pedirle al dueño que se lo pase.
- **Un ticket cerrado no se puede reasignar.** Si ya se resolvió y se calificó, no tiene sentido moverlo de dueño.
- **No se puede reasignar a un usuario inactivo** (por ejemplo, alguien que ya no trabaja ahí y fue desactivado en el portal).
- Reasignárselo "a uno mismo" no hace nada — no genera correo ni queda en el historial, porque no es un cambio real.

## Dónde se ve esto

- **Portal del cliente:** dentro del detalle de un ticket, el dueño ve un botón "Reasignar ticket" (solo si el ticket sigue abierto). Al usarlo, elige un compañero de su empresa y opcionalmente escribe el motivo. También hay una pestaña "Historial" que muestra todos los cambios de dueño que ha tenido ese ticket.
- **Soporte interno (equipo de SIIAN):** en el detalle del ticket, hay una pestaña adicional donde el equipo de soporte también puede ver ese mismo historial de reasignaciones hechas por el cliente — útil para entender con quién hablar si el caso cambió de responsable.

## Por qué se guarda como historial propio (y no en la auditoría genérica)

El sistema ya tiene una tabla de auditoría genérica que registra "el campo X cambió de valor A a valor B". Se decidió **no usar esa** para este caso, y crear una tabla específica de reasignaciones. La razón: acá interesa guardar quién era el usuario anterior y quién es el nuevo como una relación real con la tabla de usuarios (no como texto suelto), para poder mostrar sus nombres, filtrar por usuario, etc. sin trucos adicionales.
