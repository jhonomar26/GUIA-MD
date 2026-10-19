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
      ANALISIS.md              ← negocio, SIN código: qué ya existe, qué falta, reglas/estados (ANTES de planear)
      ADR.md                   ← si hubo una decisión real de diseño (opcional)
      PLAN.md                  ← plan TÉCNICO por fases y casillas ANTES de programar (superpowers:writing-plans)
      IMPLEMENTACION.md        ← Reference: qué quedó construido, archivo por archivo
      EXPLICACION.md           ← Explanation: cómo funciona cada etapa; primero lógica de negocio, luego código (ver "Flujo de trabajo")
```

**Flujo:** `REQUERIMIENTO.md` (pedido crudo → indagación → regla de negocio clara) →
`ANALISIS.md` (qué existe hoy en SIIAN que cubre o se acerca al pedido, qué falta, estados y
reglas de negocio — **antes** de decidir el enfoque técnico; nada se inventa si ya existe) →
`ADR.md` (si hubo decisión de diseño) → `PLAN.md` (cómo se construye: fases, archivos,
firmas, pruebas, casillas) → `IMPLEMENTACION.md` (mientras/al terminar de construir) →
`EXPLICACION.md` (por etapa, **antes** de programarla: ver "Flujo de trabajo"). Solo `REQUERIMIENTO.md` se crea de entrada;
el resto solo si aplica (ver tabla abajo).

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
| La feature toca algo que ya existe en SIIAN, tiene estados/transiciones, o reglas de negocio que dependen unas de otras (¿qué pasa si X mientras Y?) | `ANALISIS.md`, **antes** de planear — ver "Cómo se hace un ANALISIS.md" abajo |
| Hubo que decidir entre 2+ enfoques y vale la pena que quede el porqué | `ADR.md` |
| Ya hay enfoque y se va a programar algo de más de un archivo (o lo ejecuta un agente) | `PLAN.md` |
| Ya está construido y quieres el mapa de archivos/métodos tocados | `IMPLEMENTACION.md` |
| Feature de más de una etapa (la persona debe entender cada una antes de que se programe), o alguien no técnico / vos en 6 meses necesita el panorama | `EXPLICACION.md` |
| El concepto aplica a más de una feature (ej. "cómo funciona el Report Designer de DevExpress") | va en `conceptos/`, no repetido en cada feature |

## Reglas de contenido

- **`REQUERIMIENTO.md` y `ANALISIS.md` se escriben en términos de negocio/flujo, no de
  código.** Describen *qué* pasa hoy, *qué* va a pasar y *en qué orden* (ej. "el login va a
  pedir seleccionar empresa la primera vez, así se decide cuál mostrar, este caso raro pasa
  si no tiene ninguna") — nada de nombres de clase, archivo, método o endpoint. Debe poder
  leerlo alguien no técnico y entender el comportamiento esperado.
  - **`ANALISIS.md` parte de lo que ya existe, no de lo que se podría inventar:** primero
    se inventaría qué módulo/pantalla/regla de SIIAN ya cubre total o parcialmente el pedido
    (descrito en negocio: "hoy el ticket ya permite X"), y recién después qué falta. El
    asistente (brainstorming) aporta preguntas y alternativas, pero cada propuesta se ancla
    en algo existente; lo que no existe se marca como "nuevo" y se justifica.
  - **Señal de alarma:** si estás escribiendo un nombre de archivo o de clase en un
    `ANALISIS.md`, ya empezaste a planear — pasa ese contenido a `PLAN.md`.
  - `PLAN.md` e `IMPLEMENTACION.md` son los únicos docs donde corresponde hablar en
    términos de código. `PLAN.md` es lo que **se va a** hacer (fases, casillas `- [ ]`, se
    tildan al ejecutar; cada tarea lleva su línea `Se parece a: <precedente>`, ver paso 3b); `IMPLEMENTACION.md` es lo que **quedó** (Reference, archivo por
    archivo). Al cerrar la feature, `PLAN.md` queda como historia; lo vigente pasa a
    `IMPLEMENTACION.md`.
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

## Con superpowers (Claude Code)

Las skills de superpowers escriben en esta carpeta, no en `docs/superpowers/` del repo:

| Skill | Cuándo se invoca | Doc que produce |
|---|---|---|
| `superpowers:brainstorming` | Apenas existe `REQUERIMIENTO.md` de una feature. Se le pasa la ruta: entrevista de a una pregunta, explora el código y propone enfoques | `ANALISIS.md` (el "spec"), anclado en lo que ya existe |
| `superpowers:writing-plans` | Con el `ANALISIS.md` cerrado (sin preguntas abiertas que cambien el enfoque). **Sin spec, no**: el plan terminaría inventando el análisis | `PLAN.md`, cuyo "Spec:" apunta a `ANALISIS.md`. Sin tests automáticos, cada tarea cierra con build + prueba manual Dado/Cuando/Entonces |
| `superpowers:executing-plans` / `subagent-driven-development` | Plan aprobado y etapa explicada (ver "Flujo de trabajo") | Tilda casillas de `PLAN.md` |
| `superpowers:systematic-debugging` | **Bug** reportado (ticket, error, comportamiento raro). Reemplaza a brainstorming + writing-plans: no se planea un fix sin causa raíz | `REQUERIMIENTO.md` (síntoma) e `IMPLEMENTACION.md` (causa raíz + fix). Ver "Flujo de bug" |
| `superpowers:verification-before-completion` | Antes de decir "listo", de tildar una casilla o de commitear | La evidencia va en la sección "Verificación" de `IMPLEMENTACION.md` |
| `superpowers:finishing-a-development-branch` | Feature o fix completo y verificado | Actualiza `IMPLEMENTACION.md` y las filas de los `README.md` |

Los commits siguen las reglas del repo (solo cuando se piden), aunque `PLAN.md` tenga el paso.

**Orden normal de una feature:** `REQUERIMIENTO.md` (a mano) → brainstorming → `ANALISIS.md` → writing-plans → `PLAN.md` → por etapa: `EXPLICACION.md` + entrevista → executing-plans → verification-before-completion → finishing-a-development-branch.

### Flujo de bug (`systematic-debugging`)

Precedente: `soporte/Visualizacion tickets/`. Un bug no lleva `ANALISIS.md` ni `PLAN.md`, salvo que la causa raíz destape una regla de negocio mal definida. En ese caso deja de ser bug y pasa al flujo de feature.

1. **`REQUERIMIENTO.md`: síntoma y reproducción.** Qué ve el usuario, ticket (TKT-…), pasos para reproducirlo y qué debería pasar. En negocio, sin código.
2. **Causa raíz antes de tocar código.** Se reproduce, se traza el flujo completo y se buscan **todos** los llamadores de la función sospechosa. Las hipótesis descartadas se anotan en una línea cada una (evitan repetir la vuelta en 6 meses).
3. **`IMPLEMENTACION.md`**, con 4 secciones fijas: `## Causa raíz` (con archivo:línea de evidencia), `## Archivos tocados`, `## Cambio` y `## Verificación`.
4. **El fix va donde nace el problema**, no en el síntoma: un guard en la función compartida, no uno por cada llamador.

### Verificación (`verification-before-completion`)

Regla: **"listo" sin evidencia no es listo.** Frases como "debería andar", "compila seguro" o "lo probé antes" no cuentan.

- **Evidencia válida:** salida del build (`msbuild … /p:Configuration=Debug`, 0 errores), resultado de cada caso Dado/Cuando/Entonces del `PLAN.md` (respuesta de Postman, captura, resultado de un SQL antes/después) y, en front, `npm run build`.
- **Dónde queda:** en `## Verificación` de `IMPLEMENTACION.md`, un renglón por caso con el resultado obtenido (no el esperado). La casilla del `PLAN.md` se tilda recién con eso escrito.
- **Si algo falla o se saltó**, se escribe así tal cual ("caso 5 no probado: falta token de prueba"). Nunca se tilda en silencio.

## Flujo de trabajo: entender antes de construir

Regla de la mesa (2026-10-06, nacida en `contabilidad/archivos-contabilidad/firma-documentos-contables`): **no se
escribe código de una etapa hasta que quien la va a aprobar la haya entendido y sepa
explicarla.** Escribir primero y explicar después deja a la persona validando algo ya hecho,
sin chance de corregir el rumbo. Explicar antes ayuda además a **descubrir lo que no cuadra** y
a ajustarlo mientras es barato.

Por cada etapa (tarea grande del `PLAN.md`):

1. **Explicar la lógica.** El asistente agrega a `EXPLICACION.md` la parte de la etapa en
   términos de negocio: quién participa, qué pasa y en qué orden, casos raros. Mermaid
   (secuencia o estados), sin nombres de clase ni de método.
2. **La persona la explica con sus palabras, y el asistente la entrevista.** El asistente
   hace preguntas sobre la etapa (qué pasa si..., por qué en este orden...) para encontrar por
   dónde no está clara, en vez de solo explicar. Ese es el criterio de avance: no basta con que
   el asistente diga "está claro". Si la logra explicar, se avanza. Si no, o si algo no le
   cuadra, se ajusta la explicación (o la regla, o el plan) y se vuelve a este paso.
3. **Recién ahora, código.** Se baja la etapa a código, se agrega la "parte de código" a
   `EXPLICACION.md` y se verifica (build + prueba manual del `PLAN.md`).
4. **Entender el código por su propósito** (paso 3b, ver abajo). Sin esto no se commitea.
5. **Commit solo si se pide**, y no antes de haber pasado por los pasos 2 y 4 en esa etapa.

Una etapa que ya tiene código escrito sin pasar por el paso 2 se explica igual (paso 1 y 2)
antes de commitear y de arrancar la siguiente.

### Paso 3b: entender el código por su propósito, no línea por línea

El paso 2 aclara el negocio. Este paso cubre el código: poder decir, de cada paso del método,
**para qué existe** y qué pasa si falla.

**1. Se comenta solo el porqué que el nombre no dice.** Los pasos de un método con varias
reglas van numerados, pero solo lleva comentario el que tiene una regla de negocio, una razón de
seguridad, un caso raro o historia. Si el comentario repite el nombre del método, se borra.
Ejemplo de `RegistrarUsuarioPortal` (`inicio-sesion-terceros`), donde los pasos 3, 5 y 6 quedan
sin comentario porque `EstaAutorizado`, `MsgYaTieneCuenta` e `Insert` ya los dicen:

```csharp
// 1. El correo debe pertenecer a un unico contacto activo (persona + empresa)
// 2. El documento debe ser el de ese contacto (mismo mensaje del paso 1: no revelar de quien es el correo)
// 4. Cuenta vieja sin empresa: la asocia soporte, no se crea otra
```

**2. Cada tarea del `PLAN.md` cita su precedente:** `Se parece a: <archivo o método existente>`,
o `Nuevo, porque <razón>`. Es la regla de no inventar aplicada al código.

**3. Antes de commitear, entrevista de propósito y un caso real.** El asistente pregunta, la
persona responde con sus palabras: ¿para qué existe este paso y qué se rompe si se quita? ¿por
qué en este orden? ¿qué pasa si la consulta devuelve 0 filas o más de una? Después se corre un
caso real de punta a punta (los Dado/Cuando/Entonces del `PLAN.md`); un comentario convincente
no prueba que el código esté bien. Si no se puede explicar el propósito, se vuelve al código.

**En qué se apoya** (investigado 2026-10-13):

| Pieza | Fuente | Evidencia |
|---|---|---|
| Preguntar el porqué en vez de delegar | [Anthropic, RCT con 52 ingenieros](https://www.anthropic.com/research/AI-assistance-coding-skills): con IA 50% contra 67% en comprensión (p=0.010); los de mejor puntaje hacían preguntas conceptuales o pedían explicación con el código (3 a 7 personas por patrón) | Estudio; los patrones son correlación |
| Citar un precedente | [Anthropic, Best practices](https://code.claude.com/docs/en/best-practices) | Guía oficial, sin estudio |
| Un comentario convincente puede hacer aceptar código sin entenderlo | [Li et al., arXiv 2503.11453](https://arxiv.org/abs/2503.11453): 173 programadores; solo se leyó el resumen | Experimento; mide adopción, no corrección |

**Es regla nuestra, sin estudio:** explicar el propósito como condición para commitear, la
numeración de pasos y que el comentario sea de porqué y no de qué. Se revisa si no ayuda.

**En qué se apoya (nada de esto es inventado):**

| Pieza del flujo | Fuente |
|---|---|
| Explorar → planificar → implementar → commitear, con el plan revisable por la persona antes de programar | [Anthropic, Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) |
| Planificar rinde más cuando la persona no conoce lo que se va a tocar | Misma guía: *"Planning is most useful when ... you're unfamiliar with the code being modified"* |
| Que el asistente **entreviste** a la persona (casos límite, tradeoffs) antes de implementar | Misma guía, "Let Claude interview you" |
| Spike para temas nuevos | [Spike, XP](https://en.wikipedia.org/wiki/Spike_(software_development)) |
| No programar hasta cruzar la cima (incertidumbre → certeza) | [Shape Up, hill chart](https://basecamp.com/shapeup/3.4-chapter-12) |
| Por qué importa entender antes: la **deuda de comprensión** (código que funciona pero que nadie puede explicar) | [Comprehension Debt, O'Reilly](https://www.oreilly.com/radar/comprehension-debt-the-hidden-cost-of-ai-generated-code/), [arXiv 2604.13277](https://arxiv.org/pdf/2604.13277) |

**Lo que es nuestro, no de una fuente:** que la persona *explique de vuelta* la etapa como
condición para avanzar. La guía de Anthropic pide revisar el plan, no explicarlo. Es una regla
más estricta, elegida a propósito. Señal de que hace falta: no poder explicar un cambio
reciente sin reabrir el chat o releer todo el diff.

### Tema nuevo para la persona: spike + plan de etapa aparte

Si la etapa toca algo que quien la aprueba **nunca vio** (ej. firma electrónica antes de
`firma-documentos-contables`), no se explica de pasada: se saca en docs propios dentro de la
carpeta de la feature y se avanza despacio. Es un **spike** de XP (investigación acotada para
familiarizarse con algo nuevo; produce entendimiento, no código de producción) y el paso 2 es
cruzar la cima del **hill chart** de Shape Up (cuesta arriba = incertidumbre; cuesta abajo =
certeza y ejecución; solo se programa cuesta abajo).

| Doc | Para qué |
|---|---|
| `EXPLICACION-<tema>.md` | El spike: cómo funciona el tema, en negocio y con diagramas. Con tope de tiempo. |
| `PLAN-<etapa>-<tema>.md` | La tarea del `PLAN.md` desplegada despacio, en pasos chicos, para ir entendiendo y ajustando. |

Cuidado: abusar del spike es una forma de evitar decidir. Solo para temas realmente nuevos;
si la persona ya domina el tema, alcanza con `EXPLICACION.md` de la feature.
Precedente en estas notas: `ANALISIS-CIERRE-JOB.md`, `1-PLAN-IMPLEMENTACION.md`,
`VALIDACION-ESTADO-CIERRE.md` (docs sueltos por tema dentro de la feature).

Esto reordena lo que hacen las skills de superpowers: `ANALISIS.md` aclara el negocio de toda
la feature una vez; `EXPLICACION.md` aclara cada etapa antes de construirla.

## Verificación y cierre (propuesta, pendiente de validar en una feature real)

El repo no tiene tests automáticos ni CI, así que la verificación se diseña **antes** de
programar, no se improvisa al final. Prácticas tomadas de fuentes existentes, no inventadas:

- **Dimensionar el proceso** (BMAD "a escala", guía de Anthropic): si el cambio se describe
  en una línea de diff, no lleva plan ni spec — ver la tabla de arriba.
- **Criterios de aceptación en Given/When/Then** dentro de `REQUERIMIENTO.md`
  ([Cucumber BDD](https://cucumber.io/docs/bdd/)), solo como formato de texto, sin
  automatizar. Ej.: *Dado un crédito vencido, cuando se ejecuta el cierre, entonces pasa a
  cobranza.*
- **Sección "Verificación" en cada `ANALISIS.md`** (Anthropic: *"si no puedes verificarlo, no lo
  despaches"*): qué se comprueba y qué evidencia se espera (compara antes/después, captura,
  checklist manual). Va en términos de negocio; el `PLAN.md` la baja a pasos concretos y el
  comando o script se anota en `IMPLEMENTACION.md` al construir.
- **Golden master puntual** ([Feathers, characterization tests](https://michaelfeathers.silvrback.com/characterization-testing)):
  antes de tocar lógica delicada (contabilidad, cartera, nómina, XML DIAN) se captura la
  salida actual y se compara después. Solo el área que se cambia, no cobertura amplia.
  Herramienta candidata: [ApprovalTests](https://approvaltests.com/) — **compatibilidad
  con .NET 4.6.2 / Npgsql 2.2.7 sin verificar**, hacer un spike antes de adoptarla.
- **Revisión con contexto fresco** ([Anthropic, Writer/Reviewer](https://code.claude.com/docs/en/best-practices)):
  un subagente revisa el diff contra el `ANALISIS.md`/`PLAN.md` y reporta solo lo que afecte
  corrección o requisitos, para no caer en sobreingeniería.
- **No-gos y appetite** en `REQUERIMIENTO.md` ([Shape Up](https://basecamp.com/shapeup/1.5-chapter-06)):
  qué queda explícitamente fuera y cuánto esfuerzo máximo vale la pena.

**Definition of Done** ([Scrum Guide](https://scrumguides.org/scrum-guide.html)) — una
feature está cerrada cuando:

- [ ] Compila (build de la solución)
- [ ] Archivos nuevos registrados en el `.csproj`
- [ ] Verificación del `ANALISIS.md` ejecutada, con evidencia escrita en `IMPLEMENTACION.md` (ver "Verificación (`verification-before-completion`)")
- [ ] `ADR.md` si hubo decisión de diseño
- [ ] Filas de `README.md` sincronizadas (ver "Chequeo de sincronización")

**No adoptado a propósito:** instalar Spec Kit/BMAD/Kiro/Tessl (duplican el flujo SDD),
trunk-based puro (DORA lo condiciona a tests y CI), Cucumber/SpecFlow (arnés caro en MVC5
legacy), Definition of Ready como gate (sin fuente oficial) y más archivos de documentación
por feature (`PLAN.md` ya cumple el rol del plan que superpowers dejaría en el repo).

## Cómo se hace un ANALISIS.md

No se inventa nada nuevo acá tampoco: es la misma idea de fondo que **Event Storming**
(descubrir estados, eventos y reglas de negocio de un proceso *antes* de programarlo) y de
los **diagramas de estados UML** (statecharts) — sin el aparato de taller/sticky-notes,
porque acá lo escribe una persona (o vos con el asistente) directo en el doc. Precedente ya
existente en este repo: `soporte/soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md` (hallazgos
H1-H6 + preguntas + propuesta de fases) — este apartado solo formaliza ese patrón.

**Objetivo:** entender el proceso completo (estados, transiciones, dependencias, reglas)
*antes* de escribir código, para no ir descubriendo problemas de fondo a mitad de la
implementación.

**No son pasos secuenciales, son iterativos.** El diagrama no es algo que se dibuja *después*
de terminar el análisis — es la herramienta con la que se analiza. Arrancar bocetando el
diagrama apenas se identifiquen los actores/estados (aunque quede incompleto); cada vez que
no se pueda explicar una transición o falte una flecha, eso *es* un hallazgo o una pregunta
abierta. Diagrama y hallazgos se completan juntos, en varias vueltas — no "primero el
diagrama entero, después la lista de hallazgos".

**Contenido típico del doc (el orden de las secciones, no el orden en que se piensan):**

0. **Qué ya existe** — inventario en términos de negocio de lo que SIIAN ya hace y se
   relaciona con el pedido (módulos, pantallas, reglas, tablas conceptuales), con la
   conclusión por cada uno: se reutiliza / se extiende / no sirve. Es la base del análisis;
   evita reinventar. La evidencia (archivo:línea) va en los hallazgos, no en el texto.
1. **Diagrama de estados** (si la entidad tiene estados/transiciones) — Mermaid
   `stateDiagram-v2`, etiquetas de nodo/transición **cortas** (nombre del estado o del
   disparador, nada de fórmulas ni rutas de archivo adentro), con el detalle (qué campo se
   fija, qué condición aplica) en una tabla debajo del diagrama. `stateDiagram-v2` rinde
   mejor que `graph`/`flowchart` en paneles angostos (Obsidian) para este tipo de contenido.
2. **Diagrama de dependencias** (si hay varios componentes/actores involucrados) — quién
   llama a quién, mismo criterio de etiquetas cortas + tabla.
3. **Hallazgos** — numerados (H1, H2...), un problema o comportamiento real detectado por
   hallazgo, con evidencia (archivo:línea si ya se investigó código, o el síntoma reportado
   si es puramente de negocio).
4. **Reglas de negocio a confirmar / preguntas abiertas** — en términos de negocio, no de
   código (mismo criterio que `REQUERIMIENTO.md`/`PLAN.md`): "¿el cierre se puede ejecutar a
   cualquier hora?", "¿qué pasa si X está en medio de Y?". Se resuelven con el usuario antes
   de pasar a `ADR.md`/`PLAN.md`.

5. **Verificación** — qué se comprueba y qué evidencia se espera (ver arriba).

**Cuándo NO hace falta:** cambios de 1 método sin estados ni reglas cruzadas ni nada
existente que analizar — ahí alcanza con `REQUERIMIENTO.md` (o ni eso, ver la tabla de arriba).

## Cuándo migrar un doc viejo

No hace falta reorganizar todo de una — cuando se toque un doc suelto de nuevo (nueva
fase, nueva decisión), se le crea su carpeta (dentro del módulo que corresponda) en ese
momento siguiendo esta guía.

**Cambio de convención (2026-10-05):** antes `PLAN.md` era de negocio y `TAREAS.md` el plan
técnico. Ahora `PLAN.md` es el técnico y lo de negocio va en `ANALISIS.md`. En features
viejas: el `PLAN.md` de negocio pasa a `ANALISIS.md` y el `TAREAS.md` se renombra `PLAN.md`,
pero solo cuando se vuelva a tocar la feature.

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
