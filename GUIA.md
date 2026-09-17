# Guía: cómo documentamos features en notas-siian

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
  GUIA.md                      ← este archivo
  conceptos/                   ← Explanation transversal, cruza módulos
    REPORT_DESIGNER.md
  mcp-postgres/                ← herramienta/tooling, no es feature de producto ni módulo
  <modulo>/                    ← soporte/, cartera/, reportes/, etc.
    README.md                  ← índice del módulo: 1 fila por feature
    <feature-o-iniciativa>/
      README.md                ← índice de la carpeta, 3-5 líneas
      REQUERIMIENTO.md         ← pedido original + indagación (primer doc, apenas llega el requerimiento)
      ADR.md                   ← si hubo una decisión real de diseño (opcional)
      PLAN.md                  ← si el trabajo se planeó por fases (opcional)
      IMPLEMENTACION.md        ← Reference: qué quedó construido, archivo por archivo
      EXPLICACION.md           ← Explanation: para alguien que no va a leer código
```

**Flujo:** `REQUERIMIENTO.md` (pedido crudo → indagación → regla de negocio clara) →
`ADR.md` y/o `PLAN.md` (una vez hay enfoque) → `IMPLEMENTACION.md` (mientras/al terminar
de construir) → `EXPLICACION.md` (opcional, para no-técnicos). Solo `REQUERIMIENTO.md` se
crea de entrada; el resto solo si aplica (ver tabla abajo).

**¿Qué es "módulo"?** Los mismos del proyecto: `Cartera`, `Credito`, `AhorrosyAportes`,
`Contabilidad`, `Cobranzas`, `Garantias`, `Inventario`, `Firmas`, `CentralRiesgo`,
`Cierre`, `Tesoreria`, `Terceros`, `Crm`, `Soporte`, `Nomina`, `ActivoFijo`,
`Configuraciones` (ver `Negocio/` en el repo). Si una feature no encaja en ningún módulo
de negocio (herramientas, MCP, scripts internos), va suelta en la raíz — no se inventa
un módulo para eso.

No los cuatro archivos por feature son obligatorios — solo los que aporten. Reglas para
elegir:

| Si... | Usa |
|---|---|
| Cambio de 1 método/query obvio, sin ambigüedad ni indagación real | Ninguno — el mensaje de commit alcanza |
| Hubo indagación real (el pedido original no bastaba, tocó preguntar/entender la regla) | `REQUERIMIENTO.md` |
| Hubo que decidir entre 2+ enfoques y vale la pena que quede el porqué | `ADR.md` |
| El trabajo se hizo/se va a hacer por fases y alguien podría retomarlo | `PLAN.md` |
| Ya está construido y quieres el mapa de archivos/métodos tocados | `IMPLEMENTACION.md` |
| Alguien no técnico (o vos en 6 meses sin contexto) necesita el panorama | `EXPLICACION.md` |
| El concepto aplica a más de una feature (ej. "cómo funciona el Report Designer de DevExpress") | va en `conceptos/`, no repetido en cada feature |

## Reglas de contenido

- **`REQUERIMIENTO.md` y `PLAN.md` se escriben en términos de negocio/flujo, no de
  código.** Describen *qué* va a pasar y *en qué orden* (ej. "el login va a pedir
  seleccionar empresa la primera vez, así se decide cuál mostrar, este caso raro pasa
  si no tiene ninguna") — nada de nombres de clase, archivo, método o endpoint, porque
  esos todavía no existen o van a cambiar al implementar. Debe poder leerlo alguien no
  técnico y entender el comportamiento esperado.
  - **Señal de alarma:** si estás escribiendo un nombre de archivo o de clase en un
    `PLAN.md`, ya dejaste de planear y empezaste a implementar — para ahí y pasa ese
    contenido a `IMPLEMENTACION.md` en vez de seguir mezclándolo.
  - `IMPLEMENTACION.md` es el único doc donde sí corresponde hablar en términos de
    código — es su propósito explícito (Reference, archivo por archivo).
- `ADR.md` es historia: no se reescribe cuando la decisión cambia, se agrega un ADR nuevo
  que dice "supersede a X".
- `IMPLEMENTACION.md` sí se actualiza — es reference, debe reflejar el código actual.
- Cada carpeta de feature enlaza (no copia) a los scripts SQL en
  `DataGripProjects/fix-soporte-tickets/entregables/...` cuando aplique — la fuente de
  verdad del SQL vive en ese repo, acá solo se referencia la ruta.
- Nombres de carpeta (módulo y feature) en `kebab-case`, cortos, sin fecha (la fecha va
  en los commits del repo de notas, no en el nombre).
- Un `README.md` por carpeta de feature: tabla de 1 fila por doc, sin repetir contenido.
- Un `README.md` por carpeta de módulo: tabla de 1 fila por feature, sin repetir contenido.
- Antes de crear una carpeta de feature nueva, revisar si ya existe una relacionada
  dentro del módulo — si la hay, actualizar esa (`IMPLEMENTACION.md`) en vez de crear
  otra. Evita fragmentar la misma funcionalidad en 3 carpetas.

## Cuándo migrar un doc viejo

No hace falta reorganizar todo de una — cuando se toque un doc suelto de nuevo (nueva
fase, nueva decisión), se le crea su carpeta (dentro del módulo que corresponda) en ese
momento siguiendo esta guía.

## Rastrear cambios / qué es lo más reciente

No se guarda fecha manual en los docs — se usa git:
```
git log --oneline -10                                   # últimos commits
git status                                               # qué está sin commitear todavía
git log -1 --stat <ruta>                                 # qué tocó el último commit de un doc puntual
git log --oneline --diff-filter=A --name-only -- <modulo>/ | grep README.md   # orden real de creación de features
```

## Chequeo de sincronización de tablas

Antes de cerrar una feature, verificar que la carpeta quedó reflejada en el `README.md`
del módulo (y ese, a su vez, en el `README.md` raíz) — es fácil crear la carpeta y olvidar
la fila:
```
diff <(ls -d <modulo>/*/ | xargs -n1 basename) <(grep -oP '\[\K[a-z-]+(?=\])' <modulo>/README.md)
```
Si no imprime nada, están sincronizados. Con pocas features alcanza revisarlo a ojo; si el
módulo crece mucho, correr el comando antes de cada cierre.
