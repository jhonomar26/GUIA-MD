# ADR: un MCP Postgres por base, con uvx y rol claude_ro

Reemplaza a [`../mcp-postgres/ADR.md`](../mcp-postgres/ADR.md).

## Contexto

Se quiere que Claude Code consulte varias bases SIIAN (demo, log, copias de clientes)
en solo lectura. El ADR anterior proponía Docker, un `.mcp.json` en el repo y el rol
`claude_readonly` con permisos solo sobre `public`. En esta máquina no hay Docker, la
idea ahora es exponer varias bases y en `historico` también hay tablas.

## Decisión

- **Servidor:** Postgres MCP Pro (`crystaldba/postgres-mcp`) ejecutado con `uvx`, en
  `--access-mode=restricted` y con `--with "mcp<2"` (la versión 1.30.0 se rompe con `mcp` 2.x).
- **Un servidor MCP por base**, con nombre `pg-<alias>` y scope `user` (`~/.claude.json`).
  La clave no queda en git y el MCP funciona desde cualquier carpeta.
- **Rol `claude_ro`, uno por servidor.** Los permisos se dan por base con
  [`claude_ro.sql`](./claude_ro.sql): SELECT en todos los schemas de usuario, default
  privileges, `default_transaction_read_only = on` y `statement_timeout = 30s`.
- **La barrera real son los permisos de la BD**; el modo `restricted` es una segunda capa.
- **`REVOKE CREATE ON SCHEMA public FROM PUBLIC` en cada base.** En PG < 15 `PUBLIC`
  puede crear tablas en `public`, y se comprobó que `claude_ro` lo lograba haciendo
  `SET default_transaction_read_only = off`.

## Descartado

- `@modelcontextprotocol/server-postgres`: está deprecado y la versión publicada en npm
  (0.6.2) tiene un SQL injection sin parchear que se salta el modo de solo lectura
  (`COMMIT; DROP ...`). Fuente: Datadog Security Labs.
- Un único MCP cambiando `DATABASE_URI` según la base: obliga a reconfigurar y reiniciar
  para cada cambio.
- `pg_read_all_data` en lugar de los grants por schema: solo existe desde PG 14 y SIIAN
  corre sobre PG 11.

## Consecuencias

- Cada base registrada suma 9 herramientas al contexto de todas las sesiones.
- La clave de `claude_ro` queda en texto plano en `~/.claude.json`: sirve solo para
  bases dev/demo.
- Si una versión futura de `postgres-mcp` soporta `mcp` 2.x, se puede quitar el pin.
- El rol `claude_readonly` del ADR anterior sigue existiendo en `localhost` sin uso; se
  puede borrar con `DROP OWNED BY claude_readonly;` (en cada base) y `DROP ROLE claude_readonly;`.
