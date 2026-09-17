**Descripción**

Buen día.

Haciendo una revisión de la plataforma de tickets se han encontrado los siguientes errores, los cuales son necesario abordarlos para el buen funcionamiento del aplicativo:

**Caso de horas que siguen corriendo a pesar de ser sábado y domingo:**  
El tiempo se sigue contando a pesar de ser sábado y domingo, se realiza la prueba de horas, tomando un pantallazo de los tickets el día viernes y revisando nuevamente el día lunes.

Foto del día viernes 6 pm:  
![](https://redmine.siian.co/attachments/download/29/clipboard-202609141141-zgin1.png)  

Foto de lunes 8 am:  
![](https://redmine.siian.co/attachments/download/30/clipboard-202609141141-d8qay.png)  

Hay una diferencia de aproximadamente 2 días y medio, lo que corresponde a que siguió corriendo el tiempo

**Caso de solucionados que no cambian de estado a cerrado:**  
Haciendo una revisión de esta funcionalidad, nos encontramos que si bien los tickets quedan como solucionados, estos jamás pasan a estado Resuelto, quedándose en estado solucionado.  
![](https://redmine.siian.co/attachments/download/31/clipboard-202609141142-wfobe.png)  

Para que por favor nos colabores con estos cambios. Gracias