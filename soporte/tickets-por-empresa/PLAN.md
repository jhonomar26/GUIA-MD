# Plan: usuarios por empresa + visibilidad de tickets por empresa

> Ver `REQUERIMIENTO.md` para el pedido original (TKT-000392). Detalle técnico de cómo
> se construyó cada fase en el repo de código (`D:\soporte\SIIAN\PruebaPostgreSQL\docs\
> 0-plan-tickets-visibilidad-empresa.md` y subplanes `1-*`), y en `IMPLEMENTACION.md`
> de esta carpeta.

## Qué se decidió

- Cada empresa ve únicamente sus propios tickets. Dentro de una misma empresa, **todos
  los líderes pueden ver** los tickets radicados por cualquier líder de esa empresa —
  pero **solo quien lo radicó puede interactuar** (responder, calificar, reabrir). Los
  demás lo ven en modo lectura.
- "Traslado de tickets" (mover un ticket de una empresa a otra) queda **fuera de
  alcance**.
- Cada usuario del portal pertenece a **una sola empresa**, decidida/confirmada una vez
  (en el registro, o en el login para los que venían de antes) y después queda fija —
  no hay soporte para pertenecer a varias empresas a la vez ni para cambiar de empresa
  por cuenta propia.
- Los tickets históricos también se comparten automáticamente dentro de la empresa
  (nadie tiene que migrarlos a mano).
- En el listado de tickets se muestra quién radicó cada uno, para poder distinguir "los
  míos" de "los de mis compañeros de empresa".

## Cómo se llegó ahí (fases, en orden)

1. **Cada usuario queda con una empresa asignada.** Los usuarios existentes que solo
   podían pertenecer a una empresa (sin ambigüedad posible) se asignaron automáticamente.
   Los que quedaron ambiguos (asociados a más de una empresa) no se asignan solos —
   seleccionan la empresa ellos mismos la primera vez que inician sesión (ver flujo de
   login con selección de empresa, documentado aparte).

2. **El registro de usuarios nuevos exige una empresa.** Alguien que se registra sin
   tener ninguna empresa asociada no puede completar el registro (mensaje: contacte a
   soporte). Alguien con una o más empresas asociadas la confirma como parte del
   registro.

3. **La sesión del usuario sabe a qué empresa pertenece.** Una vez elegida/asignada la
   empresa, cada acción que el usuario hace durante su sesión ya sabe de qué empresa es,
   sin tener que volver a preguntarlo.

4. **El listado y el detalle de tickets muestran los de toda la empresa,** no solo los
   propios — incluyendo quién los radicó, para poder distinguirlos.

5. **Los mensajes y la calificación siguen siendo privados de quien radicó el ticket.**
   Cualquiera de la empresa puede leer el chat de un ticket ajeno, pero solo el dueño
   puede escribir, calificar o reabrir. Intentar escribir en un ticket ajeno se rechaza
   aunque alguien intente saltarse la UI y llamar directo a la API.

6. **La interfaz refleja esas reglas:** un ticket ajeno se ve pero con los controles de
   interacción deshabilitados y un mensaje explicando por qué.

## Fuera de alcance
- Traslado de tickets entre empresas.
- Que el usuario elija su empresa "a mano" sin relación con los datos del tercero (la
  empresa siempre sale de una asociación real, nunca se inventa).
- Que una persona pertenezca a varias empresas a la vez de forma permanente.

## Cómo se verifica que funciona
- Un usuario nuevo sin empresa asociada no puede registrarse.
- Un usuario existente sin empresa clara ve el selector la primera vez que entra.
- Dos usuarios de la misma empresa: uno crea un ticket, el otro lo ve (puede leerlo)
  pero no puede responder/calificar/reabrir; el que lo creó sí puede.
- Un usuario de otra empresa no ve el ticket en absoluto.
