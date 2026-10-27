# Verificación y cierre

> Bugs, evidencia y cuándo una feature está cerrada. · [← Volver a la guía](../GUIA.md)

## Flujo de bug (`systematic-debugging`)

Precedente: `soporte/Visualizacion tickets/`. Un bug no lleva `ANALISIS.md` ni `PLAN.md`, salvo que la causa raíz destape una regla de negocio mal definida. En ese caso deja de ser bug y pasa al flujo de feature.

1. **`REQUERIMIENTO.md`: síntoma y reproducción.** Qué ve el usuario, ticket (TKT-…), pasos para reproducirlo y qué debería pasar. En negocio, sin código.
2. **Causa raíz antes de tocar código.** Se reproduce, se traza el flujo completo y se buscan **todos** los llamadores de la función sospechosa. Las hipótesis descartadas se anotan en una línea cada una (evitan repetir la vuelta en 6 meses).
3. **`IMPLEMENTACION.md`**, con 4 secciones fijas: `## Causa raíz` (con archivo:línea de evidencia), `## Archivos tocados`, `## Cambio` y `## Verificación`.
4. **El fix va donde nace el problema**, no en el síntoma: un guard en la función compartida, no uno por cada llamador.

## Verificación (`verification-before-completion`)

Regla: **"listo" sin evidencia no es listo.** Frases como "debería andar", "compila seguro" o "lo probé antes" no cuentan.

- **Evidencia válida:** salida del build (`msbuild … -p:Configuration=Debug`, 0 errores; en git bash con `-p:`, porque `/p:` lo convierte MSYS en una ruta), resultado de cada caso Dado/Cuando/Entonces del `PLAN.md` (respuesta de Postman, captura, resultado de un SQL antes/después) y, en front, `npm run build`.
- **Dónde queda:** en `## Verificación` de `IMPLEMENTACION.md`, un renglón por caso con el resultado obtenido (no el esperado). La casilla del `PLAN.md` se tilda recién con eso escrito.
- **Si algo falla o se saltó**, se escribe así tal cual ("caso 5 no probado: falta token de prueba"). Nunca se tilda en silencio.
- **Carpeta `evidencia/`** dentro de la feature, para lo que se captura y no cabe en el texto:
  `antes-<caso>.json` y `despues-<caso>.json` (respuesta del servicio), capturas `.png` y salidas
  de consulta. Se nombra por caso y `IMPLEMENTACION.md` la enlaza. Precedente:
  `contabilidad/archivos-contabilidad/consultas-documentos-sql/evidencia/`.

## Prácticas de verificación y Definition of Done

El repo no tiene tests automáticos ni CI, así que la verificación se diseña **antes** de
programar, no se improvisa al final. Prácticas tomadas de fuentes existentes, no inventadas.

**Ya usadas en una feature real** (`consultas-documentos-sql`): la sección "Verificación" del `ANALISIS.md`, el golden master y la Definition of Done. **Sin probar todavía:** la revisión con contexto fresco y los no-gos/appetite.


- **Dimensionar el proceso** (BMAD "a escala", guía de Anthropic): si el cambio se describe
  en una línea de diff, no lleva plan ni spec — ver [qué archivos crear](./estructura.md).
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
  **Validado el 2026-10-19** en `consultas-documentos-sql`, sin herramienta: se guardó la
  respuesta JSON del servicio antes del cambio (`evidencia/antes-*.json`), se repitió después y
  se comparó byte a byte con `cmp`. Alcanza para un endpoint; [ApprovalTests](https://approvaltests.com/)
  (compatibilidad con .NET 4.6.2 / Npgsql 2.2.7 sin verificar) solo si algún día hace falta algo más.
- **Revisión con contexto fresco** ([Anthropic, Writer/Reviewer](https://code.claude.com/docs/en/best-practices)):
  un subagente revisa el diff contra el `ANALISIS.md`/`PLAN.md` y reporta solo lo que afecte
  corrección o requisitos, para no caer en sobreingeniería.
- **No-gos y appetite** en `REQUERIMIENTO.md` ([Shape Up](https://basecamp.com/shapeup/1.5-chapter-06)):
  qué queda explícitamente fuera y cuánto esfuerzo máximo vale la pena.

**Definition of Done** ([Scrum Guide](https://scrumguides.org/scrum-guide.html)) — una
feature está cerrada cuando:

- [ ] Compila (build de la solución)
- [ ] Archivos nuevos registrados en el `.csproj`
- [ ] Verificación del `ANALISIS.md` ejecutada, con evidencia escrita en `IMPLEMENTACION.md` (ver "Verificación" arriba)
- [ ] `ADR.md` si hubo decisión de diseño
- [ ] Filas de `README.md` sincronizadas (ver [chequeo de sincronización](./mantenimiento.md))

**No adoptado a propósito:** instalar Spec Kit/BMAD/Kiro/Tessl (duplican el flujo SDD),
trunk-based puro (DORA lo condiciona a tests y CI), Cucumber/SpecFlow (arnés caro en MVC5
legacy), Definition of Ready como gate (sin fuente oficial) y más archivos de documentación
por feature (`PLAN.md` ya cumple el rol del plan que superpowers dejaría en el repo).
