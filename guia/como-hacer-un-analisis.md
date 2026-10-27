# Cómo se hace un ANALISIS.md

> Entender el proceso completo antes de escribir código. · [← Volver a la guía](../GUIA.md)

**Objetivo:** entender el proceso completo (estados, transiciones, dependencias, reglas) *antes*
de escribir código, para no descubrir problemas de fondo a mitad de la implementación. No es una
técnica nueva: es la idea de **Event Storming** (descubrir estados, eventos y reglas de un
proceso antes de programarlo) y de los **diagramas de estados UML**, sin el taller de
sticky-notes, porque lo escribe una persona (o vos con el asistente) directo en el doc.
Precedente en este repo: `soporte/soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md`.

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
   código (mismo criterio que `REQUERIMIENTO.md`): "¿el cierre se puede ejecutar a
   cualquier hora?", "¿qué pasa si X está en medio de Y?". Se resuelven con el usuario antes
   de pasar a `ADR.md`/`PLAN.md`.
5. **Verificación** — qué se comprueba y qué evidencia se espera (ver [verificación y cierre](./verificacion-y-cierre.md)).

**Cuándo NO hace falta:** cambios de 1 método sin estados ni reglas cruzadas ni nada
existente que analizar — ahí alcanza con `REQUERIMIENTO.md` (o ni eso, ver [qué archivos crear](./estructura.md)).
