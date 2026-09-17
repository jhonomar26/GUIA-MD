# Plan: MCP Postgres solo-lectura para BD demo SIIAN

## Context
Consultar directo BD PostgreSQL dev (`demo-6-07-2026`) para row counts, verificar migraciones, muestras de datos — cosas que codigo fuente solo no responde. Decidido: NO MCP custom de "impacto de cambios" (Lexis + skills SIIAN ya cubren eso). Solo MCP Postgres, solo-lectura, scope este repo.

No existe `.mcp.json` en repo. Solo global (`~/.claude/.mcp.json`) con server `engram`.

**Nota servidor MCP**: `@modelcontextprotocol/server-postgres` esta deprecado/archivado desde 2025-07-10 — tiene vulnerabilidad SQL injection que bypasea el modo readonly (payload tipo `COMMIT; DROP SCHEMA public CASCADE`). Usar en su lugar **Postgres MCP Pro (crystaldba/postgres-mcp)** — mantenido activamente, corre via Docker, soporta `--access-mode=restricted` real (bloqueo a nivel de servidor, no solo el GRANT de Postgres). Bonus: incluye health checks, index tuning, explain plans.

## Pasos

### 1. Role solo-lectura en Postgres (usuario ejecuta, no Claude)
```sql
CREATE ROLE claude_readonly WITH LOGIN PASSWORD '<password>';
GRANT CONNECT ON DATABASE "demo-6-07-2026" TO claude_readonly;
GRANT USAGE ON SCHEMA public TO claude_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO claude_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO claude_readonly;
```
Repetir por cada schema no-public usado (revisar `Context.cs` o `information_schema.schemata`).

### 2. Requiere Docker Desktop corriendo (Postgres MCP Pro se distribuye como imagen `crystaldba/postgres-mcp`)
Verificar Docker instalado/corriendo antes de continuar (`docker --version`, `docker ps`).

### 3. Crear `D:\soporte\SIIAN\.mcp.json`
```json
{
  "mcpServers": {
    "postgres-demo": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "DATABASE_URI",
        "--network=host",
        "crystaldba/postgres-mcp",
        "--access-mode=restricted"
      ],
      "env": {
        "DATABASE_URI": "postgresql://claude_readonly:<password>@localhost:5432/demo-6-07-2026"
      }
    }
  }
}
```
`--access-mode=restricted` = solo-lectura enforced por el servidor MCP (no depende solo del GRANT de Postgres — doble capa de seguridad junto al role `claude_readonly`).
Password en texto plano en archivo — agregar `.mcp.json` a `.gitignore` si no debe subir a git.

### 4. Verificar
- Reiniciar sesion Claude Code, `claude mcp list` confirma conexion.
- Query SELECT simple funciona.
- Intento de escritura falla (bloqueado por `--access-mode=restricted` Y por permisos Postgres — doble check).

## Archivos afectados
- `.mcp.json` (nuevo)
- `.gitignore` (agregar si aplica)
- Cero cambios C#/Razor.

## Referencias
- Vulnerabilidad server-postgres deprecado: https://postgres-mcp.dev/security/
- Postgres MCP Pro: https://github.com/crystaldba/postgres-mcp
