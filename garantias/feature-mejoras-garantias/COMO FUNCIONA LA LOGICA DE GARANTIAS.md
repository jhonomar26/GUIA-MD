# Lógica de negocio — Estados de una Garantía  
  
## Qué es una garantía y para qué sirve el estado  
  
Una garantía (vehículo o inmueble) respalda un préstamo. Su estado  
representa en qué punto del ciclo de vida está, y ese estado es lo que  
decide qué acciones tiene permitidas un usuario en un momento dado.  
  
## Los 4 estados de negocio  
  
1. **Creada** — la garantía fue registrada pero todavía no es válida  
   formalmente. Es un borrador: se puede editar libremente (datos del  
   bien, garantes, avalúos) porque nada depende de ella todavía.  
  
2. **Activa (Aprobada)** — la garantía fue revisada y aprobada. A partir  
   de acá respalda el préstamo de verdad: se genera el documento/soporte  
   contable de la aprobación. Ya NO debería poder editarse su información  
   estructural (bien, garantes, avalúo) porque eso rompería la trazabilidad  
   de lo que se aprobó.  
  
3. **Anulada** — la aprobación se deshizo por un error o un caso  
   excepcional (ej. la garantía nunca debió aprobarse). Se genera un  
   documento de anulación. Es un estado final: una garantía anulada no  
   vuelve a ningún otro estado.  
  
4. **Liberada (= "Cancelada" en el lenguaje del negocio)** — el préstamo  
   que la garantía respaldaba ya se pagó o dejó de necesitarla, y se libera  
   formalmente. También es un estado final.  
  
*Aclaración: en el código no existe un estado llamado literalmente  
"Cancelada" — el proceso que el negocio llama coloquialmente "cancelar una  
garantía" es el mismo que el sistema modela como **Liberar**.*  
  
## Reglas que debe cumplir cada transición  
  
- **Aprobar** solo aplica sobre una garantía **Creada**. No se puede  
  aprobar algo ya aprobado, ni algo anulado, ni algo liberado.  
- **Anular** solo aplica sobre una garantía **Activa (aprobada)**. No se  
  puede anular una garantía que todavía es un borrador, ni una que ya está  
  anulada o liberada.  
- **Liberar / "Cancelar"** solo aplica sobre una garantía **Activa  
  (aprobada)**. No se puede liberar un borrador, ni algo ya anulado o ya  
  liberado.  
- **Anulada** y **Liberada** son estados finales: desde ahí no hay ninguna  
  acción de negocio que vuelva a mover la garantía.  
  
Diagrama:  
  
```  
Creada --Aprobar--> Activa --Anular-->  Anulada   (fin)  
                       \----Liberar/Cancelar--> Liberada (fin)```  
  
## Dónde el negocio queda expuesto hoy (riesgos, en términos de negocio)  
  
Las reglas de arriba están bien aplicadas cuando el usuario aprueba, anula  
o libera una garantía **desde los botones pensados para eso**. El riesgo  
detectado es que existen otras vías de acceso a los mismos datos (edición  
directa del registro, borrado, edición de garantes) que **no vuelven a  
preguntar en qué estado está la garantía**. En la práctica eso significa  
que, sin pasar por el flujo formal de aprobación/anulación/liberación,  
alguien podría:  
  
- Forzar el estado de una garantía saltándose la aprobación formal (sin  
  que quede generado el documento de soporte ni registro en el historial  
  de la garantía).  
- Eliminar una garantía que ya fue aprobada (activa), cuando debería ser  
  intocable una vez aprobada.  
- Agregar, quitar o modificar garantes de una garantía que ya está  
  aprobada, anulada o liberada — cuando la regla de negocio dice  
  explícitamente que los garantes solo se editan mientras la garantía está  
  en borrador ("Creada").  
  
Estos tres puntos son inconsistencias respecto a la regla de negocio  
descrita ("no se aprueba/toca algo que ya está aprobado, anulado o  
cancelado") — la regla está bien pensada y bien aplicada en el flujo  
principal, pero no está protegida en todas las puertas de entrada a los  
mismos datos.