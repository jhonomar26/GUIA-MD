# Decisiones de arquitectura — peticiones-redmine

# ADR-002 — Adoptar piezas de Redmine dentro del módulo de tickets

> **Estado: aceptado.** Supersede a ADR-001 (abajo). Plan: [`PLAN.md`](./PLAN.md).

## Contexto

Se evaluaron dos caminos antes de este:

1. **Módulo propio separado** con peticiones tipo Redmine (el `PLAN.md` original, de 10 fases). Era una solución grande para un problema chico, y replicaba algo que Redmine ya hace mejor.
2. **Integrar con Redmine por API** (ADR-001). Resolvía el puente, pero mantenía dos sistemas y dejaba afuera lo que sí aporta tenerlo en SIIAN: los asesores, los tickets y sus estados ya viven acá.

Al revisarlo en frío, lo que tiene sentido no es copiar Redmine ni conectarse a él, sino **tomar las piezas que sirven y adaptarlas al módulo de tickets que ya existe**:

- Los usuarios internos ya existen (los asesores de soporte). Solo falta agruparlos y darles un rol por proyecto.
- Un ticket necesita partirse en varias piezas de trabajo, cada una con su asignado y su estado. Eso es una tarea hija del ticket, que pertenece a un proyecto.
- El flujo de trabajo de Redmine sirve también para el ticket mismo. Ejemplo: un ticket "En desarrollo" no debería cerrarse sin pasar antes por pruebas.
- Los clientes del portal no necesitan nada de esto: siguen como hoy.

## Decisión

Se adoptan de Redmine, dentro del módulo de tickets: **grupos**, **proyectos**, **rol por proyecto**, **tareas** hijas del ticket (tipo, estado, asignado, fechas, horas, historial) y **flujo de estados** en dos niveles (tareas por Rol + Tipo; ticket con una matriz única). El ticket conserva su lógica actual: portal, SLA, calificación y cierre de vencidos.

## Consecuencias

- No se construye un módulo separado ni se integra con Redmine por API.
- No hay que migrar nada de Redmine: lo que está ahí se queda ahí.
- Se toca el ticket en dos puntos acotados: la matriz de estados en los cambios manuales, y la regla de no solucionar ni resolver un ticket con tareas abiertas.
- Campos personalizados y reglas de campo quedan para después.
- `ANALISIS.md` sigue valiendo para roles, permisos y flujo, aplicado ahora a tareas en lugar de peticiones.

---

# ADR-001 — Conectar con el Redmine existente en vez de construir un módulo propio

> **Estado: superado por ADR-002.** Se conserva como historia.

## Contexto

El `REQUERIMIENTO.md` pedía llevar a SIIAN el modelo de Redmine (proyectos, roles por
proyecto, peticiones, flujo de trabajo, campos personalizados), hoy usado aparte en
`redmine.siian.co`. Se armó un análisis de negocio completo (`ANALISIS.md`) y un plan
técnico de 10 fases (`PLAN.md`) para construirlo dentro de SIIAN.

Al revisar ese análisis aparecieron dos dudas que se repitieron varias veces:

1. **Tamaño desproporcionado.** Redmine ya funciona hoy, en paralelo a los tickets de
   SIIAN. Lo que el plan proponía construir es una fracción chica de lo que Redmine ya
   hace (la sección "Fuera de alcance" del `PLAN.md` deja afuera subproyectos, versiones,
   consultas guardadas, notificaciones, adjuntos, relaciones entre peticiones — todo eso
   Redmine ya lo tiene, probado). Meses de trabajo para terminar con menos funcionalidad
   que la herramienta que ya está en uso.
2. **El problema real es chico.** Lo único que falta hoy es el puente entre el ticket y
   el trabajo interno, y la administración de usuarios duplicada (un login y unos
   permisos en SIIAN, otro login y otros permisos en Redmine). Eso no exige reconstruir
   un motor de roles/flujo/campos personalizados — exige conectar los dos sistemas.
3. Se evaluó también fusionar el ticket con la unidad de trabajo interna (que el ticket
   "sea" la petición). Se descartó: un ticket necesita partirse en varias piezas de
   trabajo independientes (arreglo puntual + desarrollo + reunión, cada una con su propio
   asignado y estado), así que hace falta una tabla/entidad hija de todos modos — la
   llames "petición" o "issue". Fusionar la fila no ahorra esa necesidad. Esto sigue
   aplicando igual acá: lo que antes era "ticket vs. petición propia" ahora es
   "ticket vs. issue de Redmine".

## Decisión

**No se construye un módulo propio de proyectos/roles/flujo/campos personalizados dentro
de SIIAN.** En su lugar, se conecta con el Redmine ya existente (`redmine.siian.co`) por
su API REST:

- Sincronizar usuarios de SIIAN hacia Redmine, para tener un solo lugar de administración
  (en vez de duplicar altas y permisos en los dos sistemas).
- Al escalar un ticket, crear (o vincular) uno o varios **issues en Redmine** por API, en
  vez de crear peticiones propias. El ticket guarda el link al issue creado.
- El detalle del ticket muestra los issues vinculados y su estado, leído desde Redmine.

## Consecuencias

- `PLAN.md` (10 fases, tablas `soporte_peticion` y compañía) queda **superado**. No se
  implementa.
- `ANALISIS.md` se conserva como referencia: la resolución de permisos, el ciclo de vida
  y sobre todo la sección 9 y los hallazgos H9-H12 (por qué ticket y unidad de trabajo no
  se fusionan) siguen siendo válidos conceptualmente, ahora aplicados a "issue de Redmine"
  en vez de "petición propia".
- **No hace falta migrar nada** de Redmine: sus proyectos e historial se quedan donde
  están (ya confirmado con el usuario).
- Falta escribir el `REQUERIMIENTO.md`/`ANALISIS.md` de esta integración (qué se
  sincroniza, cómo se vincula el ticket al issue, qué pasa si la API de Redmine falla o no
  responde) — alcance mucho más chico que el descartado.
