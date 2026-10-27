# Flujo de una feature

> Del requerimiento al código, etapa por etapa. · [← Volver a la guía](../GUIA.md)

## Tamaño y herramientas

El asistente trabaja con **ODD** (Organic Driven Development, gentle-ai 4.x): explora antes de
editar, pregunta de a una solo cuando falta una decisión, y mide el tamaño con una prueba: ¿se
podría retomar el trabajo solo con el pedido y el `git diff`?

| Tamaño | Cómo se trabaja | Docs |
|---|---|---|
| **Chico** (se retoma desde el diff) | En línea, sin plan | Ninguno; alcanza con el commit |
| **Grande** (no se retoma desde el diff) | Se parte en **etapas verticales chicas**: cada una lleva backend + pantalla + prueba y se puede entregar sola. Nunca una etapa por capa | `ANALISIS.md` y `PLAN.md` en esta carpeta |

Dos ajustes nuestros sobre ODD:

- Su documento de feature (`odd/tasks/<feature>.md` dentro del repo) **no se crea**. El de
  SIIAN es `ANALISIS.md` (los "Specs": qué piden y qué ya existe, con las palabras exactas del
  usuario) y `PLAN.md` (las "Tasks": etapas con casillas y su prueba Dado/Cuando/Entonces).
- **Commits solo cuando se piden**, aunque ODD los haga por tandas.

Skills de apoyo (superpowers):

| Skill | Cuándo |
|---|---|
| `superpowers:systematic-debugging` | **Bug** reportado: no se planea un fix sin causa raíz. Produce `REQUERIMIENTO.md` (síntoma) e `IMPLEMENTACION.md` (causa + fix). Ver [flujo de bug](./verificacion-y-cierre.md) |
| `superpowers:verification-before-completion` | Antes de decir "listo", tildar una casilla o commitear. La evidencia va en `## Verificación` de `IMPLEMENTACION.md` |

**Orden de una feature grande:** `REQUERIMIENTO.md` (a mano) → explorar y preguntar de a una →
`ANALISIS.md` → `PLAN.md` en etapas verticales → por etapa: `EXPLICACION.md` + entrevista →
código → verificación → cierre.

Las decisiones del usuario se registran a medida que se toman; si una posterior contradice una
anterior (por ejemplo, porque la premisa resultó falsa), se corrige el doc, no se agrega otro.

> Historial: entre 2026-10-19 y 2026-10-27 se usó gentle SDD (8 fases). `archivos-documento-equivalente`
> nació así; sus artefactos están en engram bajo `sdd/archivos-documento-equivalente/*`.

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
5. **Commit solo si se pide**, y no antes de haber pasado por los pasos 2 y 4 en esa etapa (aunque el `PLAN.md` tenga el paso).

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

**Cuándo se puede omitir.** En un cambio simple (un método o una consulta, sin reglas nuevas) la
persona puede decidir saltarse la entrevista de propósito. La decisión es suya, no del asistente,
y se deja escrita en `IMPLEMENTACION.md` (sección "Pendiente": "paso 3b omitido por decisión de
<quién>, <fecha>"). El paso 2 (entender la lógica) no se omite. Precedente: `consultas-documentos-sql`.

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

En resumen: `ANALISIS.md` aclara el negocio de toda la feature una vez; `EXPLICACION.md` aclara
cada etapa antes de construirla.

## En qué se apoya

| Pieza | Fuente | Evidencia |
|---|---|---|
| Explorar → planificar → implementar → commitear, con el plan revisable antes de programar | [Anthropic, Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) | Guía oficial, sin estudio |
| Planificar rinde más cuando la persona no conoce lo que se va a tocar | Misma guía: *"Planning is most useful when ... you're unfamiliar with the code being modified"* | — |
| Que el asistente **entreviste** a la persona (casos límite, tradeoffs) antes de implementar | Misma guía, "Let Claude interview you" | — |
| Citar un precedente en cada tarea | Misma guía | — |
| Preguntar el porqué en vez de delegar | [Anthropic, RCT con 52 ingenieros](https://www.anthropic.com/research/AI-assistance-coding-skills): con IA 50% contra 67% en comprensión (p=0.010); los de mejor puntaje hacían preguntas conceptuales o pedían explicación con el código (3 a 7 personas por patrón) | Estudio; los patrones son correlación |
| Un comentario convincente puede hacer aceptar código sin entenderlo | [Li et al., arXiv 2503.11453](https://arxiv.org/abs/2503.11453): 173 programadores; solo se leyó el resumen | Experimento; mide adopción, no corrección |
| Spike para temas nuevos | [Spike, XP](https://en.wikipedia.org/wiki/Spike_(software_development)) | — |
| No programar hasta cruzar la cima (incertidumbre → certeza) | [Shape Up, hill chart](https://basecamp.com/shapeup/3.4-chapter-12) | — |
| La **deuda de comprensión**: código que funciona pero que nadie puede explicar | [Comprehension Debt, O'Reilly](https://www.oreilly.com/radar/comprehension-debt-the-hidden-cost-of-ai-generated-code/), [arXiv 2604.13277](https://arxiv.org/pdf/2604.13277) | — |

**Es regla nuestra, sin fuente:** que la persona *explique de vuelta* cada etapa como condición
para avanzar (la guía de Anthropic pide revisar el plan, no explicarlo), explicar el propósito
como condición para commitear, la numeración de pasos y que el comentario sea de porqué y no de
qué. Se revisa si no ayuda. Señal de que hace falta: no poder explicar un cambio reciente sin
reabrir el chat o releer todo el diff.
