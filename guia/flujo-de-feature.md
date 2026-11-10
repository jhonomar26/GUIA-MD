# Flujo de una feature

> Del pedido al código. · [← Volver a la guía](../GUIA.md)

## ODD es el motor; la guía llena sus huecos

El asistente trabaja con **ODD** (Organic Driven Development, gentle-ai 4.x) en cada pedido. Esta
guía no repite lo que ODD ya hace: solo agrega lo que ODD no cubre.

| Paso | Dueño | Qué agrega la guía |
|---|---|---|
| Distinguir si se pide un cambio o solo se pregunta | ODD | — |
| Explorar el código antes de proponer | ODD | — |
| Preguntar de a una cuando falta una decisión | ODD | — |
| Medir el tamaño: ¿se retoma solo con el pedido y el `git diff`? | ODD | — |
| **Descubrir las reglas de negocio** antes de nada | **Guía** | ODD no sale a buscar reglas: anota lo pedido y no agrega requisitos |
| **Partir lo grande** | **Guía** | ODD dice "partilo en tareas", no cómo |
| Documento de la feature | ODD | Solo cambia **dónde**: `PLAN.md` en notas-siian, nunca `odd/tasks/` en el repo |
| **Explicar antes de codear** | **Guía** | `EXPLICACION.md` + entrevista |
| Implementar tarea por tarea y verificar antes de tildar | ODD | Cómo se prueba sin tests automáticos: [verificación](./verificacion-y-cierre.md) |
| Commits | **Guía** | **Solo cuando se piden**, aunque ODD los haga por tandas |

| Tamaño (lo mide ODD) | Cómo se trabaja |
|---|---|
| **Chico** (se retoma desde el diff) | En línea, sin docs; alcanza con el commit |
| **Grande** (no se retoma desde el diff) | Los 3 pasos de abajo |

## Un tema grande, en 3 pasos

Ejemplo: "hagamos el expediente para ahorros y aportes". Al pedirlo, nadie tiene claras todas las
reglas; si se descubren programando, se deciden a las apuradas o quedan en el limbo. Por eso las
reglas van **primero, antes de partir y antes de cualquier código**.

### 1. Reglas y análisis (antes de todo, no se salta)

En la carpeta del tema (un **área** si va a tener varias features, ver [estructura](./estructura.md)):

- **`REQUERIMIENTO.md`**: el pedido textual.
- **`ANALISIS.md`**: qué existe hoy en SIIAN, el **flujo** con diagrama (Mermaid) y, si se copia un
  módulo existente, el **mapa** (ej. contabilidad → ahorros). Ver [cómo se hace](./como-hacer-un-analisis.md).
- **`REGLAS-DE-NEGOCIO.md`**: cada regla numerada (R1, R2…) con su **porqué** y su **estado**
  (confirmada · por confirmar · fuera por ahora). Ej.: *R18: un tipo con firma solo acepta PDF; se
  valida en el servidor.* Las dudas se preguntan de a una.

**Se avanza cuando no queda nada en el limbo:** cada regla está confirmada o marcada "fuera por
ahora" con su razón. Una regla "por confirmar" bloquea las features que la usan.

Si se copia un módulo existente, el mapa sirve de base, pero **cada particularidad se explica en
detalle** (en las reglas y en la `EXPLICACION.md` de la feature). "Igual que contabilidad" solo vale
para lo idéntico de verdad.

### 2. Partir en features chicas verticales

El `README.md` del tema lista las features en orden. Cada una:

- lleva **BD + backend + pantalla + prueba** y se puede entregar sola. Nunca una feature por capa
  (ej. "todas las tablas" no es una feature);
- crea **solo las tablas que usa**;
- es **chica para ODD**: se termina y se prueba en pocas sesiones.

La **primera feature muestra algo en pantalla** (ej. el catálogo de tipos de documento con su
pantalla de configuración).

**Una feature a la vez.** La carpeta `<n>-<feature>/` se crea al arrancarla y la siguiente no se
abre hasta que esta se probó en pantalla (matriz recorrida en Orca; los casos que no se pueden
probar quedan anotados con su razón). Lo que aparece al probar (una regla mal entendida, un caso
raro) corrige las reglas y el `README.md` del tema antes de planear la siguiente, cuando todavía es
barato. Precedente: `ahorrosyaportes/archivos-ahorros` (features 1 a 5 y 9, 2026-10-29 a 2026-11-04).

### 3. Por cada feature

1. **`PLAN.md`** (formato ODD, ver [estructura](./estructura.md)): Specs que citan las R# que
   implementa, la **matriz de casos** y las tareas, cada una con `Se parece a: <precedente>`. Si
   aparece una regla nueva, va al catálogo de reglas del tema, no queda suelta.
2. **`EXPLICACION.md`**: la lógica de la feature en negocio, con diagrama; las particularidades en
   detalle.
3. **Entrevista** (refuerzo): ver abajo.
4. **Código.**
5. **Prueba**: se recorre la matriz de casos (en pantalla con Orca). Ver [verificación](./verificacion-y-cierre.md).
6. **Paso 3b** (entender el código por su propósito) y **commit solo si se pide**.

Las decisiones se registran a medida que se toman (en el `## Log` del `PLAN.md`); si una posterior
contradice una anterior, se corrige el doc, no se agrega otro.

> Historial: entre 2026-10-19 y 2026-10-27 se usó gentle SDD (8 fases). `archivos-documento-equivalente`
> nació así; sus artefactos están en engram bajo `sdd/archivos-documento-equivalente/*`. Hasta
> 2026-10-29 cada feature llevaba además `REQUERIMIENTO`, `ANALISIS` e `IMPLEMENTACION` propios; las
> features viejas no se migran.

## Entender antes de construir

Regla de la mesa (2026-10-06, nacida en `contabilidad/archivos-contabilidad/firma-documentos-contables`):
**no se escribe código de una feature hasta que quien la va a aprobar la haya entendido.** Escribir
primero y explicar después deja a la persona validando algo ya hecho, sin chance de corregir el rumbo.

La base son las **reglas confirmadas** (paso 1) y la **`EXPLICACION.md`** de la feature: quién
participa, qué pasa y en qué orden, casos raros. Mermaid (secuencia o estados), sin nombres de clase
ni de método.

**La entrevista es el refuerzo:** la persona explica la feature con sus palabras y el asistente
pregunta (qué pasa si..., por qué en este orden...) para encontrar lo que no cuadra mientras es
barato corregirlo. Repasa también la matriz de casos. Si algo no cierra, se ajusta la regla, la
explicación o el plan, y se vuelve a explicar.

Una feature que ya tiene código sin haber pasado por aquí se explica igual antes de commitear y de
arrancar la siguiente.

### Paso 3b: entender el código por su propósito, no línea por línea

El paso anterior aclara el negocio. Este paso cubre el código: poder decir, de cada paso del método,
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

**1b. Comentarios cortos y concretos** (de `DocumentoAhorroValidacionActorNegocio`, `1-catalogo`):
un `<summary>` de una línea; `<param>` solo si el parámetro no se entiende por el nombre; dentro del
método, una línea por regla que diga lo que se exige, sin números de regla (`R8`) ni historia.
Un método de validación se distingue crear/editar por un parámetro `actual`: `null` en `POST`
(`Actor.Insert`), el registro guardado en `PUT` (`Actor.Update`). Se documenta en el `<param>`:

```csharp
/// <param name="actual">Registro guardado al editar (PUT); null al crear (POST).</param>
// Duplicado: ignora la propia fila para poder editarla.
// No quitar la firma si el tipo esta en un combo para firmar.
```

**2. Cada tarea del `PLAN.md` cita su precedente:** `Se parece a: <archivo o método existente>`,
o `Nuevo, porque <razón>`. Es la regla de no inventar aplicada al código.

**3. Antes de commitear, entrevista de propósito y un caso real.** El asistente pregunta, la
persona responde con sus palabras: ¿para qué existe este paso y qué se rompe si se quita? ¿por
qué en este orden? ¿qué pasa si la consulta devuelve 0 filas o más de una? Después se corre un
caso real de punta a punta (la matriz de casos del `PLAN.md`); un comentario convincente
no prueba que el código esté bien. Si no se puede explicar el propósito, se vuelve al código.

**Cuándo se puede omitir.** En un cambio simple (un método o una consulta, sin reglas nuevas) la
persona puede decidir saltarse la entrevista de propósito. La decisión es suya, no del asistente,
y se deja escrita en el `## Log` del `PLAN.md` ("paso 3b omitido por decisión de <quién>, <fecha>").
Las reglas del paso 1 no se omiten. Precedente: `consultas-documentos-sql`.

### Tema nuevo para la persona: spike + plan aparte

Si la feature toca algo que quien la aprueba **nunca vio** (ej. firma electrónica antes de
`firma-documentos-contables`), no se explica de pasada: se saca en docs propios dentro de la
carpeta de la feature y se avanza despacio. Es un **spike** de XP (investigación acotada para
familiarizarse con algo nuevo; produce entendimiento, no código de producción) y entender la
feature es cruzar la cima del **hill chart** de Shape Up (cuesta arriba = incertidumbre; cuesta
abajo = certeza y ejecución; solo se programa cuesta abajo).

| Doc | Para qué |
|---|---|
| `EXPLICACION-<tema>.md` | El spike: cómo funciona el tema, en negocio y con diagramas. Con tope de tiempo. |
| `PLAN-<tema>.md` | La tarea del `PLAN.md` desplegada despacio, en pasos chicos, para ir entendiendo y ajustando. |

Cuidado: abusar del spike es una forma de evitar decidir. Solo para temas realmente nuevos;
si la persona ya domina el tema, alcanza con `EXPLICACION.md` de la feature.
Precedente en estas notas: `ANALISIS-CIERRE-JOB.md`, `1-PLAN-IMPLEMENTACION.md`,
`VALIDACION-ESTADO-CIERRE.md` (docs sueltos por tema dentro de la feature).

En resumen: las **reglas** y el `ANALISIS.md` aclaran el negocio de todo el tema una vez;
`EXPLICACION.md` aclara cada feature antes de construirla.

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

**Es regla nuestra, sin fuente:** las reglas de negocio confirmadas como condición para partir y
codear, que la persona *explique de vuelta* cada feature (la guía de Anthropic pide revisar el plan,
no explicarlo), explicar el propósito como condición para commitear, la numeración de pasos y que el
comentario sea de porqué y no de qué. Se revisa si no ayuda. Señal de que hace falta: no poder
explicar un cambio reciente sin reabrir el chat o releer todo el diff.
