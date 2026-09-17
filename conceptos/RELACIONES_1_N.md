# Buenas prácticas: relaciones 1:N / N:M (SQL, Dapper y grid)

> Antes: `buenas-practicas-vistas-sql.md`. Se renombró porque esto no es solo sobre
> vistas SQL — cubre también cómo resolverlo en el Actor/Dapper y cómo mostrarlo en el
> grid (DevExtreme), que es donde este mismo problema vuelve a aparecer una y otra vez.

## El error que motivó esta guía

En `soporte_soportevistaticketdetalle` los datos estaban bien guardados — el problema
era **cómo se leían**. Un `UNION` de gestor + subasesores y un `JOIN` a una tabla
contacto-empresa (N:M) hacían que **un ticket apareciera varias veces** en el grid,
una fila por cada combinación. Los datos nunca estuvieron mal; la vista los presentaba mal.

Esta guía es la regla mental para no repetirlo, en cualquier vista futura (tickets,
créditos, cartera, inventario, lo que sea).

---

## La pregunta que hay que hacerse antes de cada JOIN

> **¿Cuántas filas puede devolver la tabla del otro lado del JOIN, para una fila de mi
> entidad principal?**

La respuesta cae en uno de estos casos:

### Caso 1 — Siempre 1 (relación N:1 / FK normal)

Ejemplo: un ticket tiene *un* estado actual (`idestado`), *un* motivo (`idmotivo`).

```sql
JOIN crm_estadogestioncrm eg ON g.idestado = eg.id
```

**JOIN plano, directo, sin riesgo.** El lado "muchos" (N tickets) apunta a "uno"
(1 estado) — nunca duplica. Esto es la mayoría de tus JOINs y está bien tal cual.

### Caso 2 — Puede haber varios, pero solo me interesa 1

Ejemplo: un contacto puede estar vinculado a varias empresas activas, pero en el grid
solo quiero mostrar una (la más reciente).

```sql
LEFT JOIN LATERAL (
    SELECT emp.nombreunido
    FROM terceros_tercerocontacto ttc
    JOIN terceros_terceromaestro emp ON emp.id = ttc.idtercero
    WHERE ttc.idtercerocontacto = ter.id AND ttc.esactivo = TRUE
    ORDER BY ttc.id DESC
    LIMIT 1
) empresa ON true
```

**Solución: `LATERAL … LIMIT 1` (o `DISTINCT ON`).** Sigue siendo un valor escalar,
se queda tranquilo en la vista SQL. No hay pérdida de información porque de entrada
solo queríamos 1 valor.

### Caso 3 — Puede haber varios y los necesito TODOS, pero solo para mostrar (texto)

Ejemplo: un ticket puede tener varios subgestores, y quiero mostrarlos juntos en el grid.

**❌ Mal (regla general) — agregarlos en la vista SQL:**
```sql
LEFT JOIN LATERAL (
    SELECT string_agg(u2."UserName", ', ') AS subgestores
    FROM soporte_subasesor sa ...
) sub ON true
```
Funciona y no duplica filas, pero **aplasta la lista a un string**. El día que quieras
mostrarlo como chips, contar cuántos son, o hacer click en uno → tenés que volver a
parsear ese texto. Perdiste la estructura de datos por el camino.

**✅ Bien (regla general) — agregarlos en el backend (Dapper/C#):**
1. La vista **no** trae esa columna.
2. En el Actor, una query aparte que trae la relación para **todos los registros de la
   página en una sola consulta** (nunca 1 query por fila — evitar N+1):
   ```sql
   SELECT sa.idgestion, u2."UserName" AS nombresubgestor
   FROM soporte_subasesor sa
   JOIN "AspNetUsers" u2 ON sa.idautorsoporte::text = u2."Id"::text
   WHERE sa.idgestion = ANY(@idsTickets)
   ```
3. En C#, agrupar por `idgestion` en un `Dictionary<int, List<string>>` y asignarlo al
   ViewModel (como `List<string>` o como texto unido, según lo necesite la UI).

**Por qué:** la lista queda como estructura real en C#. Podés decidir cómo mostrarla
(texto, chips, "+2 más") sin volver a tocar SQL.

**⚠️ Excepción aceptada (caso real, `soporte_soportevistaticketdetalle.subgestores`):**
Cuando el consumo es **exclusivamente texto de solo lectura** (sin click, sin popup,
sin necesidad de id/fecha/detalle por subgestor) y la vista **ya es específica** de esa
pantalla (no una vista genérica reusada por 10 consumidores distintos), sí se aceptó
resolverlo directo en la vista con `LATERAL` + `string_agg`:
```sql
LEFT JOIN LATERAL (
    SELECT string_agg(u."UserName", ', ') AS subgestores
    FROM soporte_subasesor sa
    JOIN "AspNetUsers" u ON sa.idautorsoporte = u."Id"
    WHERE sa.idgestion = g.id
) sub ON true
```
Ventaja real: cero código extra en Dapper/C# (nada de query aparte, nada de
`Dictionary`, nada de mapeo manual) — una sola columna, una sola query, listo.
**Costo del atajo:** si mañana se necesita mostrar cada subgestor como entidad propia
(id, fecha de asignación, click individual), hay que sacar esta lógica de la vista y
moverla a Dapper como dice la regla general arriba — no hay marcha atrás gratis.
Antes de repetir este atajo en otra vista, preguntate: *¿esta columna va a necesitar
alguna vez ser algo más que texto plano?* Si la respuesta es "tal vez", andá por la
regla general (Dapper + Dictionary), no por este atajo.

### Caso 4 — Puede haber varios y cada uno tiene su propia vida (fecha, autor, detalle)

Ejemplo: historial de cambios de estado de un ticket (quién lo cambió, cuándo, por qué),
o los mensajes de un ticket.

**Esto no es una columna, ni agrupada ni en Dapper.** Es una **entidad propia** con su
propio grid/popup/endpoint. Aplastarla a una celda pierde información que sí importa
(orden cronológico, autor, detalle). En este proyecto ya existe el patrón correcto:
el botón "Ver historial" de `_GridTickets.cshtml` abre un grid aparte
(`SoporteAuditoriaWebApi`) en vez de meter el historial en una columna del ticket.

**¿Master-detail o popup?** Depende de la cardinalidad real de la relación:
- **1:N** (un ticket → varios subasesores, un pedido → varios items) → **`MasterDetail`**
  con grid expandible (patrón `GestionMaestroCRM/Index.cshtml`). Tiene sentido porque el
  "padre" sigue siendo una sola fila del grid principal; el detalle es una extensión de
  esa fila que se expande in-place.
- **N:M** (un ticket puede estar asociado a varios tickets y viceversa, un usuario a
  varios roles y viceversa) → **popup** de gestión (agregar/quitar relaciones). Acá no
  hay un "padre" claro dueño de la fila — ambos lados son independientes — así que un
  popup representa mejor la acción de "vincular/desvincular" que expandir una fila.
  Ojo: revisando el repo, `_TabAsociaciones.cshtml` (ticket-ticket, que también es N:M)
  en realidad usa `MasterDetail`, no popup — así que esto último es una recomendación,
  no todavía un patrón confirmado en el proyecto. Si te toca resolver un N:M, evaluá
  las dos y quedate con la que mejor comunique la acción (ver/expandir vs. vincular).

---

## Resumen — regla de decisión rápida

| ¿Cuántas filas del otro lado? | ¿Qué necesito mostrar? | Dónde se resuelve |
|---|---|---|
| Siempre 1 (FK) | El valor | `JOIN` plano en la vista |
| Varias, pero me sirve 1 | Un valor representativo | `LATERAL … LIMIT 1` / `DISTINCT ON` en la vista |
| Varias, las necesito todas como texto/lista simple | Lista para mostrar | Query aparte en Dapper, agrupada en C# (`Dictionary<id, List<T>>`) — o, si es solo texto de solo lectura en una vista específica de una pantalla, `LATERAL` + `string_agg` directo en la vista (ver excepción aceptada arriba) |
| Varias, cada una con su propio detalle/fecha/autor | Historial / detalle expandible | Entidad y grid/endpoint separado, nunca una columna |

**Señal de alarma al escribir un JOIN:** si te preguntás "¿esto puede traer más de una
fila por cada fila de mi entidad principal?" y la respuesta es sí — pará antes de
seguir escribiendo el `SELECT` y ubicate en la tabla de arriba.

---

## Ejemplo simple para fijar la idea

Una tabla `pedidos` y una tabla `pedido_items` (N items por pedido).

- **Total de items del pedido** (un número) → `LATERAL (SELECT count(*) ...) ON true`.
  Caso 2: escalar, se queda en la vista.
- **Lista de nombres de producto del pedido, para mostrarlos en una celda del grid**
  → Caso 3: se resuelve en Dapper, una query con `WHERE idpedido = ANY(@ids)` agrupada
  en C#, no `string_agg` en la vista — salvo que, como en la excepción de arriba, sea
  puro texto de solo lectura en una vista ya específica de esa pantalla.
- **Detalle completo de cada item (cantidad, precio, descuento) para editar/ver**
  → Caso 4: pantalla/grid de detalle de pedido, nunca una columna del listado.

Mismo pedido, tres relaciones con la misma tabla `pedido_items`, tres soluciones
distintas — porque la pregunta correcta no es "¿hay relación 1:N?" sino **"¿qué necesito
hacer con esos N registros en esta pantalla?"**.
