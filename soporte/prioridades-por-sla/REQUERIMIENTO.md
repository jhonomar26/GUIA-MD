# Requerimiento: prioridades según el SLA parametrizado

## Pedido

Hoy la empresa maneja una sola prioridad. Al crear un ticket en el portal, el cliente ve todas las prioridades activas, tengan o no tiempo parametrizado. Si no elige ninguna, o elige una sin tiempo para ese motivo, el sistema asigna 72 horas por su cuenta. Eso es un tiempo inventado que confunde.

Lo que se quiere:

- El cliente ve **solo** las prioridades que tienen tiempo parametrizado para el motivo que eligió.
- Si hay una sola, aparece ya seleccionada. Si no hay ninguna, no puede crear el ticket.
- Nunca se asigna un tiempo automático. Si falta la parametrización, es un problema de parametrización: se avisa y se contacta a soporte.

## Criterios de aceptación

1. **Dado** un motivo con una sola prioridad parametrizada, **cuando** el cliente lo elige, **entonces** esa prioridad aparece seleccionada.
2. **Dado** un motivo con varias prioridades parametrizadas, **cuando** el cliente lo elige, **entonces** ve solo esas y debe escoger una.
3. **Dado** un motivo sin ninguna prioridad parametrizada, **cuando** el cliente lo elige, **entonces** ve el aviso *"No hay parametrización para este motivo, comuníquese con soporte"* y no puede enviar el ticket.
4. **Dado** una prioridad inactiva o sin tiempo para ese motivo, **cuando** se intenta crear el ticket igual (por ejemplo desde una pantalla desactualizada), **entonces** el sistema lo rechaza con el mismo aviso.
5. **Dado** un fallo al calcular el tiempo (calendario mal configurado), **cuando** se crea el ticket, **entonces** se avisa del error y no se crea con un tiempo por defecto.

## Fuera de alcance

- La pantalla de parametrización del SLA no cambia.
- Los tickets ya creados no se tocan.
- Quién parametriza qué motivo es responsabilidad de soporte; este cambio no parametriza nada.

## Decisión tomada

Un motivo sin SLA **bloquea** la creación del ticket. Lo decidió el dueño del requerimiento. Se acepta que un motivo mal parametrizado quede bloqueado hasta que soporte lo corrija.
