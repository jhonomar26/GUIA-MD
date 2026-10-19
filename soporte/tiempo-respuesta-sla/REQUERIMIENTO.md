# Requerimiento: tiempo de respuesta en el SLA

## Pedido

El acuerdo con los clientes define, por severidad, un **tiempo de respuesta** y un **tiempo de resolución**. Hoy el SLA solo tiene un tiempo (horas máximas). Se quiere agregar el tiempo de respuesta.

Los dos tiempos corren desde que se crea el ticket y **se suman**. No es que el tiempo de resolución arranque cuando soporte contesta. Ejemplo: 2 horas para contestar y 4 para resolver dan una fecha límite total de 6 horas hábiles.

No se necesita registrar cuándo contestó soporte ni medir si contestó a tiempo.

### Tabla del acuerdo

Lectura de la tabla recibida (venía desordenada, **confirmar**):

| Severidad | Descripción | Respuesta | Resolución | Total |
|---|---|---|---|---|
| S1 - Crítica | Sistema completamente inaccesible. Operación paralizada | 2 h hábiles | 4 h hábiles | 6 h |
| S2 - Alta | Funcionalidad crítica no disponible. Impacto significativo | 4 h hábiles | 8 h hábiles | 12 h |
| S3 - Media | Funcionalidad no crítica afectada. Existe solución alternativa | 8 h hábiles | 2 días hábiles | — |
| S4 - Baja | Consultas, dudas funcionales o requerimientos de mejora | 1 día hábil | 3 días hábiles | — |

La severidad corresponde a las prioridades que ya existen (INMEDIATA, ALTA, MEDIA, BAJA). Soporte carga las horas en la parametrización del SLA: el sistema no fija esta tabla.

## Criterios de aceptación

1. **Dado** un SLA con 2 h de respuesta y 4 h de resolución, **cuando** el cliente crea un ticket con ese motivo y prioridad, **entonces** la fecha límite queda a 6 horas hábiles de la creación.
2. **Dado** un SLA que ya existía antes del cambio, **cuando** se crea un ticket, **entonces** la fecha límite es la misma de antes, porque la respuesta arranca en 0.
3. **Dado** la pantalla de parametrización del SLA, **cuando** soporte crea o edita un SLA, **entonces** carga horas de respuesta y horas de resolución, y ve el total.
4. **Dado** un ticket creado antes del cambio, **cuando** soporte modifica el SLA, **entonces** la fecha límite de ese ticket no cambia.

## Fuera de alcance

- Guardar la fecha en que soporte contestó por primera vez.
- Semáforo o estado de "vencido por respuesta".
- Recalcular tickets ya creados.
- Cargar las horas de la tabla: lo hace soporte.

## Decisión tomada

El tiempo de respuesta **solo se suma** a la fecha límite. Lo decidió el dueño del requerimiento (2026-10-14).
