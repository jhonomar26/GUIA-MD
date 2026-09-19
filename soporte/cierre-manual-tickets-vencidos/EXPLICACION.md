# Explicación — Cierre manual de tickets vencidos

> Para alguien que no va a leer el código (o para vos mismo en 6 meses). El detalle técnico
> archivo por archivo está en [`IMPLEMENTACION.md`](./IMPLEMENTACION.md).

## El pedido original, en una frase

"Los tickets marcados como *Solucionado* nunca pasan a *Cerrado* cuando se les vence el plazo, y
además ese plazo no debería contar fines de semana." Sonaba a un ajuste chico. No lo fue.

## Por qué no era un ajuste chico

### 1. El cierre vivía enterrado donde nadie lo iba a ver fallar

El código que cerraba tickets vencidos no corría solo — era **un paso más dentro del Cierre de Día**,
en la posición 13 de 14 (después de cartera, créditos, contabilidad, nómina, backups...). Si
cualquiera de los 12 pasos anteriores fallaba, el proceso se detenía ahí y los tickets **nunca
llegaban a evaluarse**, sin ningún aviso de que eso había pasado. Por eso "nunca pasan a cerrado":
no era que la lógica de cierre estuviera mal, es que muchas veces ni se ejecutaba.

**Decisión:** sacarlo de ahí por completo y convertirlo en un botón independiente, para que tenga
un solo dueño y una sola forma de fallar (visible, con mensaje en pantalla).

### 2. "No contar fines de semana" tiene más de una interpretación válida

Cuando alguien dice "dale 2 días hábiles a partir de que se marca solucionado", hay dos formas
razonables de entenderlo, y no son lo mismo:

- **Días completos:** el reloj arranca al día siguiente, cuenta 2 jornadas completas (sin importar
  la hora exacta en que se marcó) y vence al cierre de la segunda. Si se marca un viernes, vence el
  martes a la tarde, sea que se haya marcado a las 8am o a las 5pm del viernes.
- **Horas acumuladas:** se cuentan las horas de trabajo que quedan desde el instante exacto en que
  se marcó (por ejemplo, si son las 10am y quedan 6 horas de jornada, esas 6 horas ya cuentan),
  sumando las horas de los días siguientes hasta completar el total. Es el mismo criterio que ya se
  usa para el SLA de atención de tickets.

Se confirmó con negocio que el criterio correcto acá es el primero: **días hábiles completos**,
igual que cuenta la gente en la vida real ("te doy 2 días"), no una cuenta de horas de reloj.

### 2.1 El mismo ajuste aplica en dos momentos, no solo en "Solucionado"

El pedido original solo mencionaba "Solucionado". Pero investigando con el cliente
(ver la indagación en [`REQUERIMIENTO.md`](./REQUERIMIENTO.md)) apareció que el mismo problema
existía en **otro momento del ciclo de vida del ticket**: cuando se marca **Resuelto** (con
calificación pendiente del cliente), también se le da al cliente una ventana de tiempo para
calificar antes de que el ticket se cierre solo — y esa ventana también se calculaba en días
corridos, así que también podía vencer un sábado o un domingo.

Antes de este ajuste, el tiempo que se le daba al cliente para responder —ya sea para calificar
después de un "Resuelto", o antes de que un "Solucionado" se cierre solo— **no tenía en cuenta la
jornada laboral en absoluto**: la fecha límite podía caer en cualquier día, laboral o no. Con el
ajuste, ambas ventanas se calculan igual: en días hábiles completos, respetando el calendario
laboral (jornada semanal + festivos configurados).

### 3. ¿Un día de media jornada cuenta como día completo?

Otra pregunta que no era obvia: si en el medio de los 2 días hábiles cae un día con jornada
reducida (por ejemplo, solo la mañana), ¿ese día cuenta como uno de los dos, o solo cuenta "medio"?

La respuesta, y es la misma que ya usan herramientas de tickets del mercado (Zendesk, Freshdesk,
Jira Service Management): cuando el plazo se mide **en días**, no se fracciona. Un día con
cualquier horario laboral configurado —completo o reducido— cuenta como un día entero. Un día sin
ningún horario (festivo, fin de semana) no cuenta nada. Fraccionar el día solo tiene sentido cuando
el plazo se mide en horas, que es un problema distinto (y ya resuelto para el SLA).

### 4. Un problema que no estaba en el pedido original: tickets a medio actualizar

Revisando el código para hacer el cierre por lote, apareció un riesgo que no tenía nada que ver con
fines de semana: cada vez que un ticket cambia de estado, el sistema guarda hasta 25 registros de
auditoría (uno por cada campo que cambió) y después actualiza el ticket. Esos dos pasos **no
estaban protegidos como una sola operación** — si algo fallaba justo en el medio (por ejemplo, se
cae la conexión a la base de datos a mitad de camino), un ticket podía quedar con auditoría
registrada pero sin el cambio de estado real, o al revés. Y no era solo un riesgo del cierre por
vencimiento: el mismo patrón sin protección se repetía en otros 10 lugares donde un ticket cambia
de estado (marcar solucionado, marcar resuelto, reabrir, tanto desde el sistema interno como desde
el portal del cliente).

Se corrigió centralizando esos dos pasos en un único punto que los ejecuta como una sola operación
atómica (o se aplican los dos, o no se aplica ninguno) — así ya no puede pasar que un ticket quede
"a medias" sin importar en qué línea de código explote el error.

### 5. Un día extra de gracia que nadie pidió

Al ponerle hora exacta a los vencimientos (fin de jornada, ej. 6pm), salió a la luz un problema que
antes pasaba desapercibido: la consulta que busca "qué tickets están vencidos" comparaba contra la
medianoche de hoy, no contra la hora actual. Resultado: un ticket que vencía hoy a las 6pm recién
era detectado como vencido **al día siguiente** — todo ticket necesitaba, sin excepción, un día de
más antes de poder cerrarse. Lo mismo pasaba al revés: alguien podía reabrir un ticket hasta la
medianoche del día en que venció, aunque el límite real ya hubiera pasado horas antes.

Se corrigió para que la comparación sea exacta (hora contra hora, no solo fecha contra fecha) tanto
al buscar vencidos como al reabrir. Ojo: esto **no significa que el cierre ahora exija correrse
dentro de un horario laboral** — se puede seguir ejecutando el botón a cualquier hora (8pm incluido)
sin ningún problema; lo único que cambió es que ahora reconoce el vencimiento en el momento exacto
en que ocurre, en vez de esperar al día siguiente.

## Qué queda como comportamiento final

- El cierre de tickets vencidos ya no depende de que el Cierre de Día termine sin errores — es un
  botón aparte, que informa si corrió o si hoy no correspondía (fin de semana/festivo).
- El tiempo que se le da al cliente al marcar un ticket como **Solucionado** o como **Resuelto**
  (ventana antes de cierre automático) ahora tiene en cuenta la jornada laboral: cuenta días hábiles
  completos, no días corridos ni horas de reloj.
- Un ticket nunca queda a medio actualizar, sin importar en qué paso interno falle el proceso.
- Nada de esto es automático — sigue siendo una acción manual, como se acordó con soporte desde el
  principio.
