# Estructura de las notas

> Dónde va cada cosa y qué lleva cada carpeta. · [← Volver a la guía](../GUIA.md)

Basado en dos convenciones estándar de la industria (no inventadas acá):

- **[ADR — Architecture Decision Records](https://adr.github.io/)**: un documento corto
  por decisión de arquitectura/diseño. Formato Context / Decision / Consequences.
  Inmutable una vez aceptado — si la decisión cambia, se escribe un ADR nuevo que
  referencia al que reemplaza, no se edita el viejo.
- **[Diataxis](https://diataxis.fr/)**: separa la documentación por *propósito*, no por
  tema. Cuatro tipos: **Reference** (qué existe — hechos, exhaustivo, refleja el código),
  **Explanation** (por qué así — entendimiento, no cambia con cada commit), **How-to**
  (pasos para lograr algo puntual), **Tutorial** (aprender haciendo — poco usado en
  proyectos internos backend).

## Estructura

Se organiza **por módulo de negocio primero** (mismos nombres que `Negocio/<Modulo>/`
en el repo SIIAN: `soporte`, `cartera`, `credito`, `contabilidad`, `crm`, etc.), y dentro
de cada módulo, una carpeta por feature. Esto evita que a futuro haya decenas de
carpetas sueltas en la raíz — el módulo actúa de "cajón" natural.

```
notas-siian/
  README.md                    ← índice raíz: 1 fila por módulo + carpetas no-módulo
  GUIA.md                      ← entrada de la guía; el detalle está en guia/
  guia/                        ← la convención, partida por tema
  conceptos/                   ← Explanation transversal, cruza módulos
    REPORT_DESIGNER.md
  mcp-postgres/                ← herramienta/tooling, no es feature de producto ni módulo
  <modulo>/                    ← soporte/, cartera/, reportes/, etc.
    README.md                  ← índice del módulo: 1 fila por área o feature
    <area>/                    ← el tema grande (ej. archivos-ahorros)
      README.md                ← cabecera + features chicas en orden, con su estado
      REQUERIMIENTO.md         ← el pedido textual
      ANALISIS.md              ← negocio, SIN código: qué existe, flujo con diagrama, mapa si se copia un módulo
      REGLAS-DE-NEGOCIO.md     ← R1, R2… con porqué y estado; ANTES de partir en features
      ADR.md                   ← si hubo que elegir entre enfoques (opcional)
      <n>-<feature>/           ← una feature chica vertical (BD + backend + pantalla + prueba)
        README.md              ← cabecera
        PLAN.md                ← formato ODD: Specs (citan R#), Casos, Tareas, Log
        EXPLICACION.md         ← la lógica de la feature en negocio, con diagrama, ANTES del código
        evidencia/             ← capturas y salidas de la prueba
    <bug>/
      REQUERIMIENTO.md         ← síntoma y reproducción
      IMPLEMENTACION.md        ← causa raíz, archivos, cambio, verificación
```

El flujo completo está en [flujo de feature](./flujo-de-feature.md).

### Qué archivos crear

| Si... | Usa |
|---|---|
| Cambio chico: se retoma desde el diff (1 método/query obvio, sin reglas nuevas) | Ninguno — el mensaje de commit alcanza |
| Un bug | `REQUERIMIENTO.md` + `IMPLEMENTACION.md` (ver [flujo de bug](./verificacion-y-cierre.md)) |
| Un tema grande (no se retoma desde el diff) | Área con `README.md`, `REQUERIMIENTO.md`, `ANALISIS.md` y `REGLAS-DE-NEGOCIO.md`; después una carpeta por feature chica con `README.md`, `PLAN.md`, `EXPLICACION.md` y `evidencia/` |
| Una feature grande pero única (no va a tener hermanas) | Una sola carpeta con `README.md`, `REQUERIMIENTO.md`, `ANALISIS.md` (las reglas en su sección `## Reglas`), `PLAN.md`, `EXPLICACION.md` y `evidencia/` |
| Hubo que decidir entre 2+ enfoques y vale la pena que quede el porqué | `ADR.md` |
| El concepto aplica a más de una feature (ej. "cómo funciona el Report Designer de DevExpress") | va en `conceptos/`, no repetido en cada feature |

### Formato del `PLAN.md` de una feature (formato ODD)

```markdown
# Plan: <feature>

> Objetivo en una línea · ← [README](./README.md) · Reglas: [R16-R21](../REGLAS-DE-NEGOCIO.md)

## Specs
- S1. <lo que debe hacer, con las palabras exactas del usuario>. Implementa R16, R18.

## Casos
| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R18 | un tipo con firma | subo un `.docx` | lo rechaza con un mensaje claro | (se llena al probar) |

## Tareas
- [ ] T1 (S1). <qué>. Se parece a: <archivo o método existente>.

## Log
- L1 (fecha). El pedido de esta feature, textual, o enlace al `REQUERIMIENTO.md` del área.
- L2 (fecha). Decisiones, correcciones del usuario y evidencia de la prueba.
```

**¿Qué es "módulo"?** Los mismos del proyecto: `Cartera`, `Credito`, `AhorrosyAportes`,
`Contabilidad`, `Cobranzas`, `Garantias`, `Inventario`, `Firmas`, `CentralRiesgo`,
`Cierre`, `Tesoreria`, `Terceros`, `Crm`, `Soporte`, `Nomina`, `ActivoFijo`,
`Configuraciones` (ver `Negocio/` en el repo). Si una feature no encaja en ningún módulo
de negocio (herramientas, MCP, scripts internos), va suelta en la raíz — no se inventa
un módulo para eso.

### Área (nivel opcional dentro del módulo)

Cuando un módulo acumula varias features de **un mismo tema** y se espera que el tema crezca,
se agrupan en una carpeta de área: `<modulo>/<area>/<feature>/`. Precedente:
`contabilidad/archivos-contabilidad/` (documentos y archivos de un comprobante, 6 features).

- El área lleva su propio `README.md`, que es la **entrada vigente**: explica el tema de punta a
  punta y enlaza al detalle de cada feature. El `README.md` del módulo tiene 1 fila por área.
- Nombre en `kebab-case`, por el tema y no por una feature. No se crea un área para una sola feature.
- Las features que ya existen no se mueven por este motivo (ver [cuándo migrar un doc viejo](./mantenimiento.md)).

### Cabecera del README de una feature

Para saber **a qué pertenece** una feature sin abrir el resto, el `README.md` de cada feature
**nueva** abre con esta tabla:

```markdown
# Feature: <nombre>

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-contabilidad (omitir si no hay) |
| Menú | EV006 - Documentos Expediente Virtual Contabilidad (`~/DocumentoTipo`) |
| Estado | en curso · vigente · histórico |
```

- **Menú:** código y pantalla tal como están en el menú de SIIAN (`generales_menu`). Si la
  pantalla no tiene entrada propia, se escribe de dónde se abre (ej. "se abre desde CO101").
  Para buscarlo, con `pg-demo`: `select codigo, nombre, funcionalidad from generales_menu where funcionalidad ilike '%<Controlador>%'`.
- **Estado:** `en curso` (se está construyendo), `vigente` (cerrada: todos los casos del `PLAN.md`
  pasaron) o `histórico` (la reemplazó otra: se escribe cuál).
- Las features que ya existen no necesitan la cabecera; se agrega cuando se vuelvan a tocar.

## Reglas de contenido

- **`REQUERIMIENTO.md` y `ANALISIS.md` se escriben en términos de negocio/flujo, no de
  código.** Describen *qué* pasa hoy, *qué* va a pasar y *en qué orden* (ej. "el login va a
  pedir seleccionar empresa la primera vez, así se decide cuál mostrar, este caso raro pasa
  si no tiene ninguna") — nada de nombres de clase, archivo, método o endpoint. Debe poder
  leerlo alguien no técnico y entender el comportamiento esperado.
  - **`ANALISIS.md` parte de lo que ya existe, no de lo que se podría inventar:** primero
    se inventariaría qué módulo/pantalla/regla de SIIAN ya cubre total o parcialmente el pedido
    (descrito en negocio: "hoy el ticket ya permite X"), y recién después qué falta. El
    asistente (brainstorming) aporta preguntas y alternativas, pero cada propuesta se ancla
    en algo existente; lo que no existe se marca como "nuevo" y se justifica.
  - **Señal de alarma:** si estás escribiendo un nombre de archivo o de clase en un
    `ANALISIS.md`, ya empezaste a planear — pasa ese contenido a `PLAN.md`.
  - **`REGLAS-DE-NEGOCIO.md` también va en negocio**: cada regla con su porqué y su estado. Una
    regla nueva que aparezca en una feature se agrega ahí, no queda suelta en el `PLAN.md`.
  - `PLAN.md` (y en bugs `IMPLEMENTACION.md`) son los únicos docs donde corresponde hablar en
    términos de código. Las tareas son casillas `- [ ]` que se tildan al ejecutar, cada una con su
    línea `Se parece a: <precedente>` (ver paso 3b).
  - **Al cerrar una feature**, la columna Resultado de sus casos queda llena, el estado del README
    pasa a `vigente` y la fila del README del área se actualiza. No se mueve nada a `archivo/`
    (las features cerradas con el formato viejo tampoco).
- `ADR.md` es historia: no se reescribe cuando la decisión cambia, se agrega un ADR nuevo
  que dice "supersede a X".
- `IMPLEMENTACION.md` (bugs y features viejas) sí se actualiza — es reference, debe reflejar el código actual.
- Cada `PLAN.md` nombra (no copia) los scripts SQL de su feature — la fuente de verdad del
  SQL vive en `C:\Users\User\DataGripProjects\scriptsSiian`, acá solo se referencia la ruta.
  Ver [scripts SQL](#scripts-sql).
- Nombres de carpeta (módulo y feature) en `kebab-case`, cortos, sin fecha (la fecha va
  en los commits del repo de notas, no en el nombre).
- Un `README.md` por carpeta de feature (1 fila por doc) y por carpeta de módulo (1 fila por feature), sin repetir contenido.
- Antes de crear una carpeta de feature nueva, revisar si ya existe una relacionada
  dentro del módulo — si la hay, actualizar esa (su `PLAN.md`) en vez de crear
  otra. Evita fragmentar la misma funcionalidad en 3 carpetas.

## Scripts SQL

Copian la estructura de estas notas: `scriptsSiian/<modulo>/<area>/<n>-<feature>/NN-<que-hace>.sql`
(ej. `ahorrosyaportes/archivos-ahorros/4-eliminar-con-constancia/01-permiso-eliminar.sql`).
Del `PLAN.md` de una feature se llega a sus scripts por el mismo camino. Detalle y fuentes en
[Guia base de datos siian](../Guia%20base%20de%20datos%20siian.md) (copia de `scriptsSiian\ORGANIZACION.MD`).

- La carpeta de la feature se crea al arrancarla, con el **mismo número y nombre** que en notas.
- Dentro, `01-`, `02-`… en el orden en que se crean, que es el orden en que se corren. Entre
  features manda el número de carpeta.
- **Nunca letras ni subnúmeros** (`3b`, `7b`): partir o corregir un script = número siguiente.
- **Un cambio va en un script nuevo, no se corrige el que ya está** (también vistas: cambiar la
  de cargados = script nuevo con el `CREATE OR REPLACE VIEW` completo), idempotente. Va en la
  carpeta de la **feature que pide el cambio**, no en la que creó el objeto. Es lo que hace
  Flyway con sus versionados.
  - **Vale la versión del último script** que toca el objeto. Si la vista de cargados está en 3
    scripts y se corrige el 2, el 3 la vuelve a pisar y ya no se sabe cuál va a producción.
  - Solo se puede corregir el **último** script del objeto, y solo si todavía no lo corrió nadie.
- Lo exploratorio (selects, drops, datos de prueba) va en `pruebas.sql` de la feature, nunca en
  un numerado.
- El orden real entre features para producción lo fija `<modulo>/entregables/YYYY-MM-DD-entregable/`.

Precedente: `archivos-ahorros` llegó a tener `3`, `3b`, `3c`, `3d` y `7b`; el 2026-11-05 se movió
a una carpeta por feature.
