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
    README.md                  ← índice del módulo: 1 fila por feature
    <feature-o-iniciativa>/
      README.md                ← índice de la carpeta, 3-5 líneas
      REQUERIMIENTO.md         ← pedido original + indagación (primer doc, apenas llega el requerimiento)
      ANALISIS.md              ← negocio, SIN código: qué ya existe, qué falta, reglas/estados (ANTES de planear)
      ADR.md                   ← si hubo una decisión real de diseño (opcional)
      PLAN.md                  ← plan TÉCNICO por fases y casillas ANTES de programar (superpowers:writing-plans)
      IMPLEMENTACION.md        ← Reference: qué quedó construido, archivo por archivo
      EXPLICACION.md           ← Explanation: cómo funciona cada etapa; primero lógica de negocio, luego código (ver [flujo de feature](./flujo-de-feature.md))
```

### Qué archivos crear

Solo `REQUERIMIENTO.md` se crea de entrada. El resto, solo los que aporten:

| Si... | Usa |
|---|---|
| Cambio de 1 método/query obvio, sin ambigüedad ni indagación real | Ninguno — el mensaje de commit alcanza |
| Hubo indagación real (el pedido original no bastaba, tocó preguntar/entender la regla) | `REQUERIMIENTO.md` |
| La feature toca algo que ya existe en SIIAN, tiene estados/transiciones, o reglas de negocio que dependen unas de otras (¿qué pasa si X mientras Y?) | `ANALISIS.md`, **antes** de planear — ver [cómo se hace un `ANALISIS.md`](./como-hacer-un-analisis.md) |
| Hubo que decidir entre 2+ enfoques y vale la pena que quede el porqué | `ADR.md` |
| Ya hay enfoque y se va a programar algo de más de un archivo (o lo ejecuta un agente) | `PLAN.md` |
| Ya está construido y quieres el mapa de archivos/métodos tocados | `IMPLEMENTACION.md` |
| Feature de más de una etapa (la persona debe entender cada una antes de que se programe), o alguien no técnico / vos en 6 meses necesita el panorama | `EXPLICACION.md` |
| El concepto aplica a más de una feature (ej. "cómo funciona el Report Designer de DevExpress") | va en `conceptos/`, no repetido en cada feature |

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
- **Estado:** `en curso` (se está construyendo), `vigente` (cerrada y `IMPLEMENTACION.md` refleja el
  código) o `histórico` (la reemplazó otra: se escribe cuál).
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
  - `PLAN.md` e `IMPLEMENTACION.md` son los únicos docs donde corresponde hablar en
    términos de código. `PLAN.md` es lo que **se va a** hacer (fases, casillas `- [ ]`, se
    tildan al ejecutar; cada tarea lleva su línea `Se parece a: <precedente>`, ver paso 3b); `IMPLEMENTACION.md` es lo que **quedó** (Reference, archivo por
    archivo).
  - **Al cerrar una feature nueva**, `PLAN.md`, `EXPLICACION.md` y los `PLAN-*`/`EXPLICACION-*` de
    spike pasan a una subcarpeta `archivo/`, se corrigen sus enlaces y el estado del README pasa a
    `vigente`. Quedan a la vista `README.md`, `REQUERIMIENTO.md`, `ANALISIS.md`, `ADR.md`,
    `IMPLEMENTACION.md` y `evidencia/`. Las features ya cerradas no se mueven.
- `ADR.md` es historia: no se reescribe cuando la decisión cambia, se agrega un ADR nuevo
  que dice "supersede a X".
- `IMPLEMENTACION.md` sí se actualiza — es reference, debe reflejar el código actual.
- Cada carpeta de feature enlaza (no copia) a los scripts SQL en
  `DataGripProjects/fix-soporte-tickets/entregables/...` cuando aplique — la fuente de
  verdad del SQL vive en ese repo, acá solo se referencia la ruta.
- Nombres de carpeta (módulo y feature) en `kebab-case`, cortos, sin fecha (la fecha va
  en los commits del repo de notas, no en el nombre).
- Un `README.md` por carpeta de feature (1 fila por doc) y por carpeta de módulo (1 fila por feature), sin repetir contenido.
- Antes de crear una carpeta de feature nueva, revisar si ya existe una relacionada
  dentro del módulo — si la hay, actualizar esa (`IMPLEMENTACION.md`) en vez de crear
  otra. Evita fragmentar la misma funcionalidad en 3 carpetas.
