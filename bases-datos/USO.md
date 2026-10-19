# Cómo agregar y usar una base en Claude Code

Cada base se expone como un servidor MCP propio (`pg-<alias>`) que se conecta con el rol
de solo lectura `claude_ro`.

## Requisitos (una vez por máquina)

- Python ≥ 3.12 y `uv`: `pip install uv` y luego comprobar con `uvx --version`.
- No hace falta `psql` ni Docker.

## Agregar una base

1. **Permisos en la base.** Abrir [`claude_ro.sql`](./claude_ro.sql) en pgAdmin/DBeaver,
   conectado **a esa base** como `postgres`, y ejecutarlo.
   - Si el servidor es nuevo (todavía no tiene `claude_ro`), reemplazar `CAMBIAR_CLAVE`
     por una clave antes de ejecutar. No guardar el archivo con la clave.
   - Si `claude_ro` ya existe en ese servidor, se ejecuta tal cual y se reutiliza la
     clave que ya tiene.
   - Leer el comentario del `REVOKE` al final del script antes de correrlo en una base nueva.
2. **Registrar el MCP** (una sola línea; desde Claude Code se puede anteponer `! `):
   ```
   claude mcp add pg-<alias> -s user -e DATABASE_URI="postgresql://claude_ro:<clave>@<host>:<puerto>/<base>" -- uvx --with "mcp<2" postgres-mcp --access-mode=restricted
   ```
   - `<alias>` corto y en minúsculas: `pg-demo`, `pg-log`, `pg-cliente-x`.
   - Si la clave tiene `@ : / # ?`, hay que codificarlos en la URI (`@` → `%40`).
   - `-s user` guarda la configuración en `~/.claude.json`: fuera de git y disponible desde
     cualquier carpeta.
3. **Verificar.** Con `claude mcp get pg-<alias>` debe aparecer `Status: ✔ Connected`.
4. **Reiniciar la sesión** de Claude Code para que carguen las herramientas.
5. **Prueba negativa.** Pedirle a Claude que ejecute `CREATE TABLE zz_test(i int)` en
   `pg-<alias>`: tiene que fallar.
6. Agregar la fila en [Bases configuradas](#bases-configuradas).

## Usar

Pedirle a Claude lo que se necesita, en lenguaje natural y **nombrando la base**, por
ejemplo: "en pg-demo, ¿cuántos préstamos están en mora?" o "en pg-demo, ¿qué columnas
tiene `prestamo_maestro`?". Claude usa las herramientas `mcp__pg-<alias>__*`:

| Herramienta | Para qué | ¿Funciona en SIIAN (PG 11)? |
|---|---|---|
| `list_schemas` | Listar los schemas | Sí |
| `list_objects` | Tablas, vistas, secuencias de un schema | Sí |
| `get_object_details` | Columnas, restricciones e índices de una tabla | Sí |
| `execute_sql` | Ejecutar un SELECT | Sí |
| `explain_query` | Plan de ejecución de una consulta | Sí |
| `analyze_db_health` | Índices inválidos o duplicados, vacuum, conexiones, etc. | Parcial (algunos chequeos piden más permisos) |
| `get_top_queries` | Consultas más lentas | No: requiere `pg_stat_statements` activo |
| `analyze_workload_indexes` | Recomendar índices según la carga | No: requiere `pg_stat_statements` |
| `analyze_query_indexes` | Recomendar índices para consultas puntuales | No: requiere la extensión `hypopg` |

`pg_stat_statements` está disponible en el servidor local pero no está activado:
necesita `shared_preload_libraries` en `postgresql.conf`, reiniciar Postgres y
`CREATE EXTENSION`. No se activó porque no hacía falta.

## Cambiar la base de un alias (por ejemplo, al restaurar una demo nueva)

Son 3 pasos (el servidor ya tiene `claude_ro`, no hay que crear nada):

1. **Permisos en la base nueva** (PowerShell):
   ```
   cd D:\Programas\Postgres11\bin
   .\psql -h localhost -U postgres -d "<base-nueva>" -f "D:\notas-siian\bases-datos\claude_ro.sql"
   ```
   Debe imprimir `DO`, `ALTER ROLE`, `ALTER ROLE`, `REVOKE`.
2. **Apuntar el MCP a la base nueva** (la clave actual está en `claude mcp get pg-<alias>`):
   ```
   claude mcp remove pg-<alias> -s user
   claude mcp add pg-<alias> -s user -e DATABASE_URI="postgresql://claude_ro:<clave>@localhost:5432/<base-nueva>" -- uvx --with "mcp<2" postgres-mcp --access-mode=restricted
   ```
3. **Reconectar** con `/mcp` y verificar: `select current_database()` debe dar la base nueva, y
   contar tablas de `public` debe dar > 0 (en SIIAN ~1800). Si da 0, falló el paso 1.

No crear otro rol a mano (`claude_readonly`, etc.): que "ya exista" no da acceso, porque los
permisos son por base y el MCP usa `claude_ro`.

## Quitar

- Solo el MCP: `claude mcp remove pg-<alias> -s user`.
- Quitarle el acceso a una base: conectado a esa base, `DROP OWNED BY claude_ro;` (revoca
  sus permisos y sus default privileges en esa base).
- Borrar el rol del servidor: `DROP OWNED BY claude_ro;` en **cada** base donde tenga
  permisos y después `DROP ROLE claude_ro;`.

## Bases configuradas

| MCP | Servidor | Base | Postgres | Nota |
|---|---|---|---|---|
| `pg-demo` | `localhost:5432` | `demo-6-07-2026` | 11.18 | Antes `demo-25-09-2026` (cambiada 2026-10-07) |

## Problemas conocidos

| Síntoma | Causa / solución |
|---|---|
| `✘ Failed to connect` y, al correrlo a mano, `No module named 'mcp.server.fastmcp'` | `postgres-mcp` no es compatible con `mcp` 2.x. Falta `--with "mcp<2"` en el comando. |
| `Failed to connect` sin más detalle | Correr el servidor a mano para ver el error: `DATABASE_URI="..." uvx --with "mcp<2" postgres-mcp --access-mode=restricted` |
| `password authentication failed for user "claude_ro"` | La clave de la URI no coincide con la del rol en ese servidor. |
| El MCP conecta pero `list_objects` devuelve 0 tablas | Falta ejecutar `claude_ro.sql` en esa base (`CONNECT` viene por defecto, `SELECT` no). |
| `permission denied for table ...` | La tabla se creó después del script con otro usuario. Volver a ejecutar `claude_ro.sql`. |

**Seguridad.** La clave queda en texto plano en `~/.claude.json`. Usar esto solo con
bases dev/demo, no con producción.

**Contexto.** Cada base registrada suma 9 herramientas en todas las sesiones (scope
user). Conviene quitar las que no se estén usando.
