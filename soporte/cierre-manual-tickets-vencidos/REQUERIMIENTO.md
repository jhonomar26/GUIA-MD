# Requerimiento — Cierre manual de tickets vencidos (respetando el calendario)

> Origen: continuación de [`../soporte-ajustes-dias/REQUERIMIENTO.md`](../soporte-ajustes-dias/REQUERIMIENTO.md).
> Diagnóstico completo del "Caso de solucionados" en
> [`../soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md`](../soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md).

## Descripción (pedido original del cliente)

> Buen día.
>
> Haciendo una revisión de la plataforma de tickets se han encontrado los siguientes errores, los
> cuales son necesario abordarlos para el buen funcionamiento del aplicativo:
>
> **Caso de horas que siguen corriendo a pesar de ser sábado y domingo:**
> El tiempo se sigue contando a pesar de ser sábado y domingo, se realiza la prueba de horas,
> tomando un pantallazo de los tickets el día viernes y revisando nuevamente el día lunes.
>
> Foto del día viernes 6pm / Foto de lunes 8am: hay una diferencia de aproximadamente 2 días y
> medio, lo que corresponde a que siguió corriendo el tiempo.
>
> **Caso de solucionados que no cambian de estado a cerrado:**
> Haciendo una revisión de esta funcionalidad, nos encontramos que si bien los tickets quedan como
> solucionados, estos jamás pasan a estado Resuelto, quedándose en estado solucionado.
>
> Para que por favor nos colabores con estos cambios. Gracias.

## Indagación

El primer caso (horas corriendo en fin de semana) resultó ser el SLA de atención (`horasrestantes`),
ya resuelto en el ciclo anterior (`soporte-ajustes-dias`, commits `559bb319f`, `683087f71`) — quedó
fuera de este documento.

Antes de tocar el segundo caso ("solucionados que no cambian de estado a cerrado"), se envió al
cliente la siguiente propuesta para confirmar el comportamiento esperado del cierre:

> Buenas tardes,
>
> Antes de avanzar con los ajustes, quiero confirmar el funcionamiento esperado para el cierre de
> los tickets.
>
> Actualmente, la fecha y hora límite de atención (SLA) se calcula con base en el calendario
> laboral, las excepciones, el tipo de asunto y la prioridad, y se almacena en la base de datos. Las
> horas restantes y el estado de vencimiento se calculan al consultar el ticket y son únicamente
> informativos.
>
> Para el cierre, propongo tomar como referencia la fecha límite almacenada y, una vez cerrado el
> ticket, guardar un estado que indique si el SLA fue cumplido o incumplido, comparando la fecha de
> cierre con la fecha límite.
>
> Quisiera confirmar si este funcionamiento es el esperado y, en caso de que el calendario cambie
> posteriormente, si debe mantenerse la fecha límite originalmente calculada para el ticket.

**Respuesta / decisión resultante:** el mismo problema de fondo (ventanas que podían caer en
cualquier fecha, incluyendo fin de semana, porque se calculaban en días corridos) aplica igual a
otras dos fechas del ticket que no estaban contempladas en el pedido original:

- `Tiempolimitesolucionado` (ventana de "solucionado" antes de cierre automático).
- `Tiempocalificacion` (ventana para que el cliente califique antes de cierre automático).

Se confirmó que ambas deben calcularse en **días hábiles** (mismo criterio de calendario que ya usa
el SLA), no en días corridos. Ver el detalle de la ambigüedad "días completos vs. horas acumuladas"
y la decisión tomada en [`EXPLICACION.md`](./EXPLICACION.md).

**Pendiente / fuera de alcance de este ciclo:** la parte de la propuesta sobre guardar un estado
explícito de "SLA cumplido / incumplido" al cerrar el ticket (comparando fecha de cierre vs. fecha
límite) **no se implementó** — no existe hoy ningún campo ni lógica para eso. Queda como trabajo
futuro, a retomar cuando se priorice.

## Decisión (definida con soporte)

El barrido que cierra tickets vencidos (*sin calificar* y *solucionado sin reapertura*) hoy vive
enterrado dentro del Cierre de Día (`#region tickets` en `CierreDiaViewModel.cs`), como el paso 13 de
14 — si algo falla antes, nunca se ejecuta. Se acordó:

1. **El proceso es manual.** No se automatiza con un timer ni con el servicio Windows de cierre. Lo
   dispara alguien del equipo cuando corresponda (botón en pantalla).
2. **Debe respetar el calendario.** Si el día en que se ejecuta es sábado, domingo o un festivo
   configurado (según jornada semanal + excepciones — las mismas tablas que ya usa el cálculo del
   SLA), el proceso se ignora ese día: no cierra nada, solo informa que hoy no es día laboral.
3. **Sin parámetro de fecha.** No se pide "procesar para tal fecha" — el proceso siempre evalúa el
   día actual en el momento en que se ejecuta.
4. **Ventanas en días hábiles.** Tanto `Tiempolimitesolucionado` como `Tiempocalificacion` pasan a
   calcularse en días hábiles completos, no en días corridos (ver Indagación arriba).

## Fuera de alcance

- No se toca el cálculo del SLA (`horasrestantes`, `fechalimite`) — ya quedó resuelto en el ciclo
  anterior.
- No se agrega ejecución automática (timer, job, servicio) — explícitamente descartado por ahora.
- No se recalculan los tickets ya existentes con ventana en días corridos — solo aplica a los nuevos.
- No se implementa el estado explícito de "SLA cumplido/incumplido" al cierre — propuesto en la
  indagación, pendiente para otro ciclo.
