# ADR: Hilos "reply-in-thread" en chat de soporte vía self-FK (sin tabla nueva)

- Estado: **Aceptada** (implementada)
- Fecha: 2026-08 (ver commits `778c98af6`..`bc13b6670` en SIIAN)

## Contexto

El chat de un ticket de soporte (`soporte_soportemensajes`) era una lista plana. Se
necesitaba poder responder a un mensaje puntual agrupando esa conversación (estilo
Discord/WhatsApp), sin romper la conversación principal existente ni la privacidad de
notas internas (`esprivado`).

## Decisión

No crear una entidad/tabla `Hilo`. Un hilo **no tiene atributos propios** — es una vista
lógica = mensaje raíz + mensajes cuyo `idmensajeraiz` apunta a él. Se agrega una sola
columna self-FK nullable:

```
soporte_soportemensajes.idmensajeraiz  int? → FK a soporte_soportemensajes(id) ON DELETE CASCADE
soporte_soportearchivos.idmensajeraiz  int? → FK a soporte_soportemensajes(id) ON DELETE CASCADE  (adjuntos también responden a hilo)
```

Reglas fijadas:
- `idmensajeraiz IS NULL` → mensaje/adjunto de conversación principal.
- Solo 1 nivel de anidación: una respuesta no puede ser raíz de otra respuesta.
- El mensaje raíz sigue apareciendo en la conversación principal (no se "mueve" al hilo).
- Privacidad (`esprivado`) se respeta igual dentro del hilo que en la principal; el
  contador de respuestas que ve el cliente excluye privadas, el de soporte no.
- Sin evento SignalR nuevo: el mismo push `nuevoMensaje`/`nuevoArchivo` lleva `idmensajeraiz`
  y el cliente decide si pintarlo en el hilo abierto o solo subir el contador.

## Alternativas descartadas

- **Tabla `Hilo` separada** (con su propio id, título, estado): más flexible a futuro
  (hilos con metadata propia, hilos multi-nivel) pero sobre-ingeniería para el caso real
  — no hay requisito de título/estado de hilo, y agregar tabla + joins nuevos no aportaba
  nada sobre lo que ya hace un self-FK.
- **Reutilizar tabla de comentarios de otro módulo**: descartado, el dominio de mensajes
  de soporte ya tiene su propia tabla con reglas de privacidad/lectura específicas.

## Consecuencias

- Migración trivial: `ALTER TABLE ... ADD COLUMN`, sin migrar datos existentes (quedan
  como raíz/`NULL`).
- Cualquier query que no filtre explícitamente `idmensajeraiz IS NULL` en el listado
  principal **duplica** mensajes (raíz + respuestas mezclados) — riesgo real, ya se dio
  en la implementación (ver commit `72a60ceed fix: métodos Dapper para hilos`).
- No hay hilos-de-hilos: si en el futuro se pide anidación multinivel, este modelo no
  alcanza y sí requeriría revisar el diseño (path de materialized path o tabla de cierre
  transitivo).
- Portal cliente (React) puede adoptar el mismo contrato cuando se implemente su UI —
  el backend ya expone `idMensajeRaiz` en los endpoints del portal.

## Referencias

- Plan original (fases 0–7): [`PLAN.md`](./PLAN.md)
- Detalle de implementación por archivo: [`IMPLEMENTACION.md`](./IMPLEMENTACION.md)
- Scripts SQL: `C:\Users\User\DataGripProjects\fix-soporte-tickets\entregables\1-09-2026-entregable\hilos-mensajes\`
