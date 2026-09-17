# Guía de flujo de trabajo — ejemplos paso a paso

Complementa [`GUIA.md`](./GUIA.md) (la convención) con ejemplos reales de principio a fin,
para saber exactamente qué archivo crear, cuándo, y con qué contenido.

## Regla de oro (antes de todo)

Antes de crear cualquier doc, preguntate:

> ¿Alguien en 6 meses (incluido vos mismo) necesitaría releer esto para entender **por qué**
> se hizo así, no solo **qué** se hizo?

- **No** → no crees nada, el mensaje de commit alcanza.
- **Sí, solo hubo que entender el pedido** (el requerimiento original era ambiguo/incompleto) → `REQUERIMIENTO.md`.
- **Sí, hubo que elegir entre 2+ caminos técnicos** → `ADR.md`.
- **Sí, fue trabajo grande/por fases**, alguien podría retomarlo a medio camino → `PLAN.md`.
- Nunca se crean los 4-5 archivos "porque toca". Se crea 1, el que aporta, y se agregan más
  solo si el trabajo crece.

---

## Caso 1 — Cambio trivial, sin documentación

**Ejemplo:** "El timeout de la consulta de reportes está en 10s, súbelo a 30s."

No hay ambigüedad, no hay regla de negocio nueva, no hay que indagar nada. El código y el
commit ya son la documentación completa.

**Qué se crea:** nada. Ni carpeta, ni README, ni REQUERIMIENTO.

**Commit:**
```
fix(reportes): subir timeout de consulta de 10s a 30s

Reportes grandes (>50k filas) estaban cortando por timeout.
```

Eso es todo. Si en 6 meses alguien pregunta "¿por qué está en 30s?", `git log -1 --stat` o
`git blame` sobre esa línea responde.

---

## Caso 2 — Cambio mediano con indagación real

**Ejemplo real:** `garantias/feature-mejoras-garantias/` — pedido original:

> "CORRECCION DEPARTAMENTO Y CIUDAD: TENIENDO EN CUENTA EL DEPARTAMENTO SELECCIONADO SE DEBE
> FILTRAR EL MUNICIPIO TANTO PARA BIENES INMUEBLES COMO VEHICULOS"

Este pedido, tal cual llega, **no alcanza para codear**: no dice si el municipio se debe
limpiar al cambiar de departamento, si aplica a edición además de creación, si es el mismo
combo en los dos formularios (inmuebles/vehículos) o dos independientes, etc. Ahí es donde
vale la pena un `REQUERIMIENTO.md`.

### Paso 1 — capturar el pedido crudo, tal cual llega

Se crea la carpeta de la feature (o se reutiliza una existente del mismo módulo si aplica)
y adentro `REQUERIMIENTO.md`:

```
garantias/
  README.md
  feature-mejoras-garantias/
    README.md
    REQUERIMIENTO.md
```

`REQUERIMIENTO.md` arranca así — **no se reescribe el pedido original, se pega literal**:

```markdown
# Requerimiento: mejoras Garantías

## Pedido original

> CORRECCION DEPARTAMENTO Y CIUDAD: TENIENDO EN CUENTA EL DEPARTAMENTO SELECCIONADO SE DEBE
> FILTRAR EL MUNICIPIO TANTO PARA BIENES INMUEBLES COMO VEHICULOS

## Indagación

_(pendiente)_
```

### Paso 2 — indagar y anotar la respuesta

Se habla con quien pidió (o se revisa el ticket/chat), y se completa la sección
"Indagación" **con la conversación resumida**, no solo la conclusión — el porqué importa:

```markdown
## Indagación

**P: ¿el combo de municipio se debe limpiar si el usuario cambia de departamento?**
R: Sí. Si ya había un municipio seleccionado y cambia el departamento, el municipio queda
en blanco — no se debe dejar un municipio de otro departamento seleccionado por error.

**P: ¿aplica igual en creación y edición de garantía, o solo en creación?**
R: Aplica en los dos. Hoy en edición el combo de municipio trae todos los municipios sin
filtrar, es el mismo bug.

**P: ¿bienes inmuebles y vehículos comparten el mismo combo/componente o son dos independientes?**
R: Son dos formularios distintos (`GarantiaInmueble` y `GarantiaVehiculo`), cada uno con su
propio SelectBox de municipio — el fix se replica en los dos, no es un componente compartido.

## Regla de negocio resuelta

- El combo de Municipio siempre se filtra por el Departamento seleccionado (`WHERE iddepartamento = @id`).
- Al cambiar el Departamento, el Municipio seleccionado se limpia (no queda un municipio "huérfano" de otro departamento).
- Aplica a los 2 formularios (inmueble y vehículo) y a los 2 modos (crear/editar).
```

### Paso 3 — decidir si hace falta algo más

Acá el fix es directo una vez está clara la regla: no hubo que elegir entre 2 enfoques
técnicos (no amerita `ADR.md`), y no es trabajo por fases que alguien deba retomar (no
amerita `PLAN.md`). **`REQUERIMIENTO.md` es suficiente, el trabajo termina ahí.**

Si el fix hubiera sido más largo (tocar 5 archivos, requerir migración, etc.), ahí sí se
agrega `IMPLEMENTACION.md` después de construir, con el mapa de archivos tocados.

### Paso 4 — README de la carpeta (índice, no contenido)

```markdown
# Feature: mejoras Garantías

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Pedido original + indagación de regla de negocio |
```

Y el README del módulo (`garantias/README.md`) apunta a la carpeta de la feature, igual
patrón que `soporte/README.md`.

---

## Caso 3 — Trabajo grande, por fases

**Ejemplo real:** `soporte/hilos-chat-soporte/PLAN.md` — agregar respuestas en hilo al chat
de soporte (estilo Discord/WhatsApp), tocando BD, Dapper, Negocio, Controllers, SignalR y
2 frontends (MVC + React).

Acá la indagación fue extensa (7 reglas de negocio: privacidad, contadores por audiencia,
ticket cerrado, no-leídos, notificaciones, tiempo real, adjuntos) y **se volcó directo en
el PLAN.md**, no en un REQUERIMIENTO.md aparte — cuando el trabajo es grande y va a fases,
tiene más sentido un solo documento vivo que separar "requerimiento" de "plan".

### Estructura del PLAN.md (orden real usado)

1. **Contexto** — qué existe hoy, qué se agrega, qué NO se agrega (ej. "no se crea entidad
   Hilo nueva, es una vista lógica sobre datos existentes").
2. **Modelo de datos** — diagrama/tabla de ejemplo si aplica.
3. **Reglas** numeradas simples (invariantes) — ej. "una respuesta pertenece a 1 solo mensaje raíz".
4. **Reglas de negocio resueltas** (R1, R2, R3...) — cada una con la pregunta implícita
   respondida y el porqué. Esto reemplaza la sección "Indagación" del Caso 2.
5. **FASE 0, FASE 1, FASE 2...** — una por capa/paso técnico (BD → Actor/Dapper →
   ViewModels → Negocio → Controllers → SignalR → Frontend), cada fase con:
   - Qué archivos toca (rutas reales).
   - Qué cambia en cada uno (con snippets si ayuda).
   - "Verificación fase" — cómo saber que esa fase quedó bien antes de seguir a la próxima.
6. **Reutilización** — qué NO hay que reconstruir (componentes, endpoints, lógica ya existente).
7. **Verificación end-to-end** — checklist final, numerado, para probar todo el flujo junto.

### Por qué funciona así

- Alguien puede **retomar en la FASE 3** sin releer todo — cada fase es autocontenida.
- Las reglas de negocio (R1-R7) quedan **separadas** de los pasos técnicos — si mañana
  cambia la regla de privacidad, se edita esa sección sin tocar las fases.
- Cuando se termine de construir, se puede agregar `IMPLEMENTACION.md` con el estado final
  (a veces el PLAN.md ya cumple ese rol si no se desvió mucho de lo planeado — no hay que
  duplicar).

---

## Tabla resumen: qué crear según el tamaño

| Tamaño del cambio | Indagación | Docs a crear |
|---|---|---|
| Trivial (1 método/query, sin ambigüedad) | No | Ninguno — commit alcanza |
| Mediano (1-2 archivos, pedido ambiguo) | Sí | `REQUERIMIENTO.md` (Paso 1-2 del Caso 2) |
| Mediano con decisión técnica (ej. "¿cache o vista materializada?") | Sí | `REQUERIMIENTO.md` + `ADR.md` |
| Grande, por fases, múltiples capas | Sí, extensa | `PLAN.md` (con reglas de negocio adentro, como Caso 3) |
| Grande, ya construido, quiero dejar mapa de archivos | — | `IMPLEMENTACION.md` |
| Necesita explicación para no-técnicos | — | `EXPLICACION.md` |

## Errores comunes a evitar

- **Crear carpeta de feature para un cambio trivial** — genera ruido, nadie la va a leer.
- **Reescribir el pedido original** en vez de pegarlo literal — se pierde el "así llegó",
  que a veces explica por qué se entendió mal al principio.
- **Fusionar REQUERIMIENTO.md e IMPLEMENTACION.md** — uno es "qué se pidió y por qué se
  entendió así" (no cambia), el otro es "qué hay en el código hoy" (se actualiza siempre).
  Mezclarlos rompe la regla de Diataxis (propósito distinto → documento distinto).
- **Fragmentar una misma feature en 2-3 carpetas** porque llegaron pedidos en momentos
  distintos — si ya existe una carpeta relacionada en el módulo, se actualiza esa, no se
  crea otra (ver `GUIA.md`, sección "Reglas de contenido").
