# Explicación — Cierre manual de tickets vencidos

## Cómo funciona el cierre

Botón en configuración de soporte: "Ejecutar cierre de tickets vencidos". Al apretarlo:

1. Si hoy es sábado, domingo o festivo cargado en el calendario, no hace nada — avisa "hoy no es
   día laboral" y termina ahí.
2. Si hoy es día laboral, busca los tickets **Solucionado** o **Cerrado** (esperando calificación
   del cliente) cuyo plazo ya venció.
3. Cada uno de esos pasa a **Cerrado sin calificación** — cierre definitivo, ya no se puede
   reabrir.
4. Avisa cuántos tickets cerró.

Es 100% manual, no corre solo ni programado. Si nadie aprieta el botón un día, los tickets vencidos
quedan esperando a la próxima ejecución.

## Cómo se cuenta el plazo

Al marcar un ticket como Solucionado, o como Resuelto con calificación pendiente, se le da al
cliente una cantidad de días antes de que el ticket se cierre solo:

- Fines de semana y festivos del calendario no suman.
- Un día con jornada reducida (ej. solo la mañana) cuenta como día completo, no como medio día.
- El plazo vence al cierre de esa jornada, sin importar la hora exacta en que se marcó el ticket.

## Qué queda

- El cierre ya no depende del Cierre de Día — es un botón aparte.
- Las ventanas de Solucionado y Resuelto cuentan días hábiles completos, no corridos ni horas.
- Sigue siendo 100% manual.
