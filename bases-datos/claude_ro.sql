-- Acceso de solo lectura para Claude (MCP postgres-mcp) sobre la base actual.
--
-- Ejecutar conectado A LA BASE que se quiere exponer, como el usuario dueño de las
-- tablas (normalmente postgres). Es idempotente: se puede correr varias veces.
--
-- El rol claude_ro es de todo el servidor; los permisos son por base. Por eso, en un
-- servidor nuevo se define la clave la primera vez y en las demás bases de ese mismo
-- servidor ya no se usa.
--
-- IMPORTANTE: no guardar la clave real en este archivo (el repo de notas está en git).

DO $$
DECLARE
    clave   text := 'CAMBIAR_CLAVE';  -- solo se usa si claude_ro no existe en este servidor
    esquema text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'claude_ro') THEN
        IF clave = 'CAMBIAR_CLAVE' THEN
            RAISE EXCEPTION 'claude_ro no existe en este servidor: defina la variable "clave" antes de ejecutar';
        END IF;
        EXECUTE format('CREATE ROLE claude_ro LOGIN PASSWORD %L', clave);
    END IF;

    EXECUTE format('GRANT CONNECT ON DATABASE %I TO claude_ro', current_database());

    -- Todos los schemas de usuario (en SIIAN: public, historico, ...).
    -- En PG >= 14 bastaria con GRANT pg_read_all_data, pero SIIAN corre sobre PG 11.
    FOR esquema IN
        SELECT nspname FROM pg_namespace
        WHERE nspname NOT IN ('pg_catalog', 'information_schema')
          AND nspname NOT LIKE 'pg_toast%'
          AND nspname NOT LIKE 'pg_temp%'
    LOOP
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO claude_ro', esquema);
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO claude_ro', esquema);
        -- Tablas que se creen a futuro con el usuario que ejecuta este script.
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO claude_ro', esquema);
    END LOOP;
END $$;

ALTER ROLE claude_ro SET default_transaction_read_only = on;
ALTER ROLE claude_ro SET statement_timeout = '30s';

-- En PG < 15, PUBLIC tiene CREATE sobre el schema public: sin esta línea claude_ro
-- podría crear tablas haciendo "SET default_transaction_read_only = off".
-- Antes de ejecutarlo en una base nueva, confirmar que las tablas son todas del mismo
-- dueño (si la app crea tablas con otro usuario, este REVOKE se lo impediría):
--   SELECT DISTINCT pg_get_userbyid(relowner)
--   FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
--   WHERE n.nspname = 'public';
-- Para revertirlo: GRANT CREATE ON SCHEMA public TO PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
