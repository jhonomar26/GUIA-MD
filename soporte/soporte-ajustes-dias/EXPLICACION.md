# Explicación — Ajustes tickets de soporte (SLA y estados)

## Qué se reportó

Al revisar la plataforma de tickets se detectaron dos problemas:

1. El "tiempo restante" de un ticket seguía contando durante el fin de semana, como si
   sábado y domingo fueran días laborales. Ejemplo: un ticket visto el viernes a las 6pm
   y otro vistazo el lunes a las 8am mostraba casi 2 días y medio menos de tiempo restante,
   cuando en realidad solo pasó una noche laboral.
2. Un ticket marcado como "solucionado" nunca pasaba automáticamente a "cerrado".

## Qué se resolvió (caso 1 — tiempo del SLA)

La fecha límite de un ticket ya se calculaba bien, respetando los días y horarios
laborales configurados (jornada semanal + festivos). El problema estaba en cómo se
mostraba el "tiempo restante" en la pantalla: ese cálculo sí usaba reloj corrido, contando
sábados, domingos y festivos como si fueran horas de trabajo normales.

Se corrigió para que el tiempo restante se calcule con el mismo calendario laboral que ya
se usaba para definir la fecha límite — así ambos números son consistentes entre sí.
Ahora, si un ticket queda pendiente un viernes a las 6pm y se revisa el lunes a las 8am,
el sistema descuenta solo las horas laborales que realmente transcurrieron, no el fin de
semana completo.

También se agregó la hora (no solo la fecha) a la columna de fecha límite en la vista
interna de tickets, para poder leer el vencimiento con precisión y no solo por día.

**Cómo se puede verificar:** dejar un ticket abierto un viernes y revisarlo el lunes — el
tiempo restante no debe haber bajado por el fin de semana. Si hay un festivo configurado
en el calendario, tampoco debe descontar ese día.

## Qué queda pendiente (caso 2 — solucionado no pasa a cerrado)

Este caso no se resolvió todavía. Antes de tocarlo hace falta definir con el área de
negocio cuál es la regla esperada, por ejemplo:

- ¿El ticket pasa a cerrado automáticamente después de cierta cantidad de días hábiles
  sin que el cliente responda?
- ¿Pasa a cerrado cuando el cliente califica la atención?
- ¿Lo cierra manualmente el gestor?

Además, ya existe documentación de un ajuste relacionado ("marcar como solucionado" con
ventana de reapertura) en este mismo módulo, así que antes de definir esta regla se va a
revisar si es la misma funcionalidad para no duplicar el trabajo.

## Documentos relacionados

- [REQUERIMIENTO.md](./REQUERIMIENTO.md) — pedido original
- [PLAN.md](./PLAN.md) — diagnóstico técnico y fases
- [IMPLEMENTACION.md](./IMPLEMENTACION.md) — archivos y métodos tocados
