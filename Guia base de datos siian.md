# Organización de scripts SQL

> Los scripts viven en `C:\Users\User\DataGripProjects\scriptsSiian` (repo aparte). Este documento es copia de su `ORGANIZACION.MD`: si cambia uno, se cambia el otro. · [← Volver a la guía](./GUIA.md)

Los scripts copian la estructura de `D:\notas-siian`: módulo → área → feature. Así, del
`PLAN.md` de una feature se llega a sus scripts por el mismo camino.

## Estructura

```
scriptsSiian/
└── ahorrosyaportes/                       ← módulo (igual que Negocio/<Modulo>)
    ├── archivos-ahorros/                  ← área o tema (igual que en notas-siian)
    │   ├── 1-catalogo/                    ← feature (mismo nombre y número que su carpeta en notas)
    │   │   ├── 01-catalogo.sql
    │   │   └── pruebas.sql                ← exploratorio, nunca sale
    │   ├── 2-solicitar-documentos/
    │   │   ├── 01-cuenta.sql
    │   │   └── 02-permisos-solicitar.sql
    │   └── 3-subir-y-consultar/
    │       ├── 01-archivos.sql
    │       ├── 02-vistas-combos.sql
    │       ├── 03-vistas-archivos.sql
    │       └── 04-ruta-tesoreria.sql
    └── entregables/
        └── 2026-11-10-entregable/         ← una carpeta por entrega a producción
            ├── 1-catalogo.sql
            └── 2-cuenta.sql
```

Un cambio chico sin carpeta de feature en notas (un bug, un ajuste) va directo en
`<modulo>/<que-hace>/01-....sql`.

## Numeración

- **Dentro de la feature**, `NN-<que-hace>.sql`: dos dígitos, en el orden en que se crean.
  Ese es el orden en que se corren.
- **Entre features** manda el número de la carpeta: `1-catalogo/` antes que `2-solicitar-documentos/`.
- **Nunca letras ni subnúmeros** (`3a`, `3b`, `7b`). Si un script hay que partirlo o
  corregirlo, lo nuevo toma el **número siguiente** dentro de su feature.
- **Un cambio va en un script nuevo, no se corrige el que ya está**, idempotente
  (`CREATE OR REPLACE`, `ADD COLUMN IF NOT EXISTS`, `WHERE NOT EXISTS`). Vale también para
  vistas: cambiar la vista de cargados = script nuevo con el `CREATE OR REPLACE VIEW` completo.
  - Va en la carpeta de la **feature que pide el cambio**, no en la que creó el objeto.
    Ej.: `5-firma-electronica/01-firma.sql` rehace vistas de la feature 3.
  - **La versión que va a producción es la del último script** (en orden de ejecución) que
    toca el objeto. Por eso nunca se corrige uno anterior: si la vista de cargados está en 3
    scripts y se corrige el 2, el 3 la vuelve a pisar y ya no se sabe cuál es la buena.
    Corridos en orden, el último es también lo que hay hoy en la base. Si hay duda (alguien
    corrió uno viejo a mano), se compara con la base:
    `SELECT pg_get_viewdef('public.<vista>', true);`
  - Única excepción: el **último** script que toca el objeto y que todavía no corrió nadie.
- El nombre dice qué hace (`01-firma.sql`), no la fecha.
- El `PLAN.md` de la feature nombra sus scripts.

Por qué: en `archivos-ahorros` se partió `3-archivos.sql` en `3b`/`3c`/`3d` y la vista de
eliminados terminó en `7b`; el orden de ejecución dejó de leerse a simple vista.

## pruebas.sql — lo exploratorio

Cada feature puede tener un `pruebas.sql` con todo lo que **no** va a producción: selects
exploratorios, drops, deletes, inserts de prueba. Los scripts numerados quedan limpios:
solo lo que debe persistir (create, alter, insert real), listos para copiar enteros.

Esto evita el drop colado: lo destructivo nunca está en el mismo archivo que lo que se entrega.

## entregables/ — lo que se envía a producción

Una carpeta por fecha de entrega: `<modulo>/entregables/YYYY-MM-DD-entregable/`.
Dentro, scripts numerados `1-`, `2-`, `3-`... en el **orden exacto de ejecución**.

Es el único lugar donde importa el orden **entre** features: si después de la feature 5
aparece un arreglo de la 3, en la feature 3 toma su número siguiente, pero en el entregable
se corre al final, cuando de verdad pasó.

**Nunca se reescribe una carpeta de entrega ya enviada.** Si algo quedó mal, se agrega el
**siguiente número** en esa carpeta o una carpeta nueva con la fecha del fix:

```
entregables/2026-08-26-entregable/
  1-ajustes-tickets.sql
  2-calendario.sql
  3-nuevo-estado.sql
  4-nuevo-estado-fix.sql   <- corrección, número siguiente, no se toca el 3
```

## Flujo completo

1. Al arrancar una feature en notas, se crea su carpeta acá con el mismo nombre.
2. Se escribe el script con el número siguiente; lo exploratorio va a `pruebas.sql`.
3. Al entregar, se copian los numerados (no `pruebas.sql`) al siguiente número de
   `entregables/YYYY-MM-DD-entregable/`, en el orden en que se corrieron.

## Pendiente de migrar

`contabilidad/scratch/` y `credito/scratch/` siguen con el formato anterior (numeración
global del área). Se mueven a carpetas por feature cuando se vuelvan a tocar.

## En qué se apoya

| Pieza | Fuente |
|---|---|
| Agrupar los cambios por feature o por versión, no por tipo de objeto | [Liquibase, Set up your changelog structure](https://docs.liquibase.com/community/implementation-guide-5-0/set-up-your-changelog-structure); [How to Structure a Complex Changelog](https://support.liquibase.com/hc/en-us/articles/29383071573659-How-to-Structure-a-Complex-Changelog) (carpeta por versión, un changelog por feature) |
| Agrupar por tipo ("todos los inserts juntos") termina en dependencias cruzadas | [Liquibase Best Practices (gist)](https://gist.github.com/BenArunski/98edb4e9e737864ea694205260d1cdd1) — práctica, no doc oficial |
| Un archivo raíz fija el orden de todo (acá: el entregable) | Misma doc de Liquibase: el *root changelog* solo incluye a los demás, en orden |
| Un script versionado ya corrido no se toca | [Flyway, Versioned migrations](https://documentation.red-gate.com/fd/versioned-migrations-273973333.html) (valida checksum) |
| Las vistas y funciones se podrían reescribir en vez de versionar | [Flyway, Repeatable migrations](https://documentation.red-gate.com/fd/repeatable-migrations-273973335.html) (`R__`, se re-corren al cambiar). **No se adopta**: la experiencia en SIIAN (2026-11-05) es que un cambio de vista también conviene en script nuevo; así queda rastro de cada versión y de qué feature la pidió |

**Es regla nuestra, sin fuente:** que la carpeta copie el número y nombre de la feature de
notas-siian, y `pruebas.sql` aparte. Se revisa si no ayuda.
