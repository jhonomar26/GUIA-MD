# Plan: coherencia dashboard / grilla del portal

> La grilla del portal deja de esconder tickets sin entorno, igual que la de soporte · ← [README](./README.md) · Reglas: [R2](./ANALISIS.md#reglas)

## Specs

- S1. "simple ajustemmos el grid de portal y listo": en `soporte_soportevistaticketoscliente`, `JOIN soporte_soporteentorno` pasa a `LEFT JOIN`, como en `soporte_soportevistaticketdetalle` (grilla de soporte). El 705 debe aparecer ("ni ahí, ni en todos ... no aparece por ninguna parte"). Implementa R2.

Los dashboards no se tocan: el del portal y el global de soporte dan los mismos números (ver L4).

## Casos

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R2 | producción, ticket 705 | corro el diagnóstico de entorno | el 705 aparece con entorno vacío o inexistente (confirma la causa) | ✅ TKT-000705 = Id 914: `Identorno` null, `Idestado` 3 (CERRADA), `Idportalusuario` 29 (L7) |
| 2 | R2 | la empresa de la usuaria del reporte | pulso "Cerrados" en el portal | la lista muestra 5, como la tarjeta, e incluye el 705 con Entorno vacío | |
| 3 | R2 | cualquier empresa | comparo Total con la lista en "Todos" sin filtros | son iguales | |

## Tareas

- [ ] T1 (S1). Diagnóstico en producción (caso 1). Inline.
- [ ] T2 (S1). Script que cambia solo el join de entorno, leyendo la definición vigente de la BD donde se corre (no pisa cambios de producción). Se parece a: el `LEFT JOIN soporte_soporteentorno` de `soporte_soportevistaticketdetalle`. Inline.
- [ ] T3. Verificación: casos 2 y 3 en Orca con capturas en `evidencia/`. No hay cambios de C# ni de front (la columna Entorno ya admite nulos).

### Script T2

Entregable: `DataGripProjects/fix-soporte-tickets/entregables/29-10-2026-coherencia-dashboard-portal/` (`1-fix-vista-ticketoscliente.sql`, `2-fix-vista-ticketdetalle.sql`). Pruebas y diagnósticos: `scratch/soporte/coherencia-dashboard-portal.sql`. Abajo, la variante que parte de la definición vigente.

```sql
-- Diagnóstico (T1): tickets que el grid del portal descarta por entorno
select g.numeroticket, eg.nombre as estado, g.identorno, sus.idempresa
from crm_gestionmaestrocrm g
join crm_estadogestioncrm eg on eg.id = g.idestado
join soporte_soporteusuariosistema sus on sus.id = g.idportalusuario
left join soporte_soporteentorno se on se.id = g.identorno
where g.esticketsoporte and se.id is null;

-- Corrección (T2)
begin;
do $$
declare d text; n text;
begin
  d := pg_get_viewdef('public.soporte_soportevistaticketoscliente'::regclass, true);
  n := regexp_replace(d, '(\n\s+)JOIN soporte_soporteentorno ', '\1LEFT JOIN soporte_soporteentorno ', 'g');
  if n <> d then
    execute 'create or replace view public.soporte_soportevistaticketoscliente as ' || n;
    raise notice 'Vista actualizada';
  else
    raise notice 'Sin cambios';
  end if;
end $$;
-- debe devolver 1
select count(*) from soporte_soportevistaticketoscliente where numeroticket::text like '%705';
commit;  -- o rollback si no da 1
```

Riesgo: item 1 (cambia la definición de una vista en producción). Probar primero en una copia, dentro de la transacción.

## Fuera por ahora

- Que el dashboard cuente sobre la vista del grid (antes S1). Evita que se vuelvan a separar con un cambio futuro.
- Vencidos filtrable en el portal (`estadosla` + `onClick`, antes S3-S4). Hoy la tarjeta cuenta bien, pero no se puede pulsar.

## Log

- L1 (2026-10-29). Pedido: ver [REQUERIMIENTO.md](./REQUERIMIENTO.md). "si ajustemos esa vista entonces, para que refleje de manera correcta la logica junto al dashboard, en ese orden de ideas creemos un spec".
- L2 (2026-10-29). Revisión en BD demo `demo-6-07-2026`: totales y conteos por estado cuadran; el 705 no existe ahí. La tarjeta Vencidos del portal (30 en la empresa 1) mezcla abiertos, en trámite, reabiertos y el estado VENCIDA (7), y no se puede filtrar.
- L3 (2026-10-29). Primera hipótesis (categoría inexistente, `INNER JOIN crm_motivocrm`) descartada: el 705 aparece en el grid de soporte, que también hace ese join. Queda el entorno: el portal hace `INNER JOIN soporte_soporteentorno` y soporte `LEFT JOIN`.
- L4 (2026-10-29). Dashboard del portal (suma de empresas) vs. global de soporte en la demo: 76/13/10/4/1/2/35/1/35 en ambos, mismas condiciones SQL. El error está en el grid del portal, no en los dashboards. Decisión del usuario: "entonces simple ajustemmos el grid de portal y listo". Se recorta a S1.
- L5 (2026-10-29). `idmotivo` es NOT NULL pero sin FK: un motivo borrado esconde el ticket. Usuario: "no deberiamos de depender de eso". Ambas grillas pasan `crm_motivocrm` a `LEFT JOIN`: portal en `fix-vista-tickets-cliente-entorno.sql`, soporte en `fix-vista-ticketdetalle-motivo.sql` (misma carpeta `scratch/soporte`). Entidad C# `SoporteVistaTicketDetalle.Idmotivo` ya es `int?`.
- L6 (2026-10-29). Pruebas en Orca (BD demo): portal 39 y CRM 76, cada tarjeta igual al total del grid; filtro búsqueda + "Sin cerrados" bien armado (`Tickets.tsx`). En demo la vista del portal aún tiene `INNER JOIN crm_motivocrm`: falta re-aplicar. Se descartó obtener la empresa del contacto (`LATERAL` sin amarrar a `sus.idempresa`: 128 filas para 76 tickets, 42 con otra empresa). Hallazgo: cuentas con empresa guardada sin contacto activo que la respalde (demo: cuenta 1 → empresa 27, 6 tickets). Decisión: pedir copia de la BD de producción para confirmar si el 705 es por un dato incorrecto (entorno vacío o empresa guardada) antes de seguir.
- L7 (2026-10-29). Causa confirmada con la respuesta de producción (pestaña Red): TKT-000705 es la gestión Id 914, `Identorno: null`, `Idestado: 3`, `Esticketsoporte: true`, `Gestionotro: true`. El dashboard lo cuenta en Cerrados y el `INNER JOIN soporte_soporteentorno` del grid del portal lo descarta. Pendiente: aplicar `fix-vista-tickets-cliente-entorno.sql` en producción y ver con el diagnóstico cuántos tickets más tienen `identorno` null.
