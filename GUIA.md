# Guía: cómo documentamos en notas-siian

Las notas van en Markdown dentro de este repo, **por módulo de negocio** (los mismos nombres que `Negocio/<Modulo>/`) y dentro de cada módulo una carpeta por feature. Usamos dos convenciones estándar: **ADR** (una decisión de diseño por documento, que no se reescribe) y **Diátaxis** (separar referencia de explicación).

## Empezar aquí

**¿Qué voy a hacer?**

El asistente trabaja con **ODD**, que decide el tamaño y lleva el ritmo. Esta guía solo agrega lo que ODD no cubre: reglas de negocio primero, cómo partir, explicar antes de codear y cómo probar. → [quién hace qué](./guia/flujo-de-feature.md)

| Mi cambio es... | Qué hago |
|---|---|
| Algo chico: se retoma desde el `git diff` (un método o una consulta, sin reglas nuevas) | Nada de notas. Alcanza con el mensaje del commit |
| Un bug | `REQUERIMIENTO.md` (qué ve el usuario) → causa raíz → `IMPLEMENTACION.md` (causa, archivos, cambio, verificación). Ver [verificación y cierre](./guia/verificacion-y-cierre.md) |
| Un tema grande (ej. "el expediente de ahorros") | Los 3 pasos de abajo |

**Un tema grande, en 3 pasos**

1. **Reglas primero, antes de todo.** Carpeta del tema con `README.md` (cabecera), `REQUERIMIENTO.md` (el pedido textual), `ANALISIS.md` (qué existe, flujo con diagrama) y `REGLAS-DE-NEGOCIO.md` (R1, R2… con su porqué y estado). No se avanza con reglas en el limbo. → [flujo](./guia/flujo-de-feature.md), [cómo se hace un análisis](./guia/como-hacer-un-analisis.md)
2. **Partir en features chicas verticales**: cada una con BD + backend + pantalla + prueba, crea solo sus tablas, y la primera ya muestra algo en pantalla. → [estructura](./guia/estructura.md)
3. **Por cada feature:** `PLAN.md` (Specs con sus R#, matriz de casos, tareas, log) → `EXPLICACION.md` + entrevista → código → recorrido de la matriz en Orca, con capturas en `evidencia/` → estado `vigente`. → [cómo se prueba](./guia/verificacion-y-cierre.md)
   **Una a la vez:** la siguiente no arranca hasta que esta se probó en pantalla; lo que aparece al probar corrige las reglas y el plan de las que siguen.
   Los scripts SQL van en una carpeta por feature, igual que estas notas, numerados `01-`, `02-`…, nunca `3b`. → [scripts](./guia/estructura.md#scripts-sql)
   Si la feature cambia la base de datos, **regenero las plantillas** y pego lo que sirve antes de escribir a mano. → [plantillas](./guia/plantillas.md)

Los commits solo se hacen cuando se piden.

## Dónde está cada cosa

| Si busco... | Voy a |
|---|---|
| Dónde va mi feature, qué archivos crear, **formato del `PLAN.md`**, **cabecera del README**, **área**, **Reglas de contenido**, **scripts SQL** | [`guia/estructura.md`](./guia/estructura.md), detalle en [`Guia base de datos siian.md`](./Guia%20base%20de%20datos%20siian.md) |
| **ODD y la guía (quién hace qué)**, **reglas primero**, features verticales, **entender antes de construir**, **paso 3b** (entender el código), spike | [`guia/flujo-de-feature.md`](./guia/flujo-de-feature.md) |
| **Cómo se prueba** (matriz de casos, Orca), **flujo de bug**, **Verificación**, carpeta `evidencia/`, golden master, **Definition of Done** | [`guia/verificacion-y-cierre.md`](./guia/verificacion-y-cierre.md) |
| **Cambié la base de datos** (tabla o columna nueva): regenerar con las **plantillas** `D:\plantillas\WFAGenerarDao`, qué pegar y qué adaptar, `GeneralDao.cs` | [`guia/plantillas.md`](./guia/plantillas.md) |
| Cómo escribir un `ANALISIS.md` | [`guia/como-hacer-un-analisis.md`](./guia/como-hacer-un-analisis.md) |
| Migrar un doc viejo, rastrear cambios, **chequeo de sincronización** de tablas | [`guia/mantenimiento.md`](./guia/mantenimiento.md) |
| Una funcionalidad que sirve a **comprobante y documento equivalente** (dónde va cada cosa, qué recibe cada capa) | [`conceptos/PATRON_DOS_DUENOS.md`](./conceptos/PATRON_DOS_DUENOS.md) |
| Ejemplos reales de principio a fin | [`GUIA_EJEMPLOS.md`](./GUIA_EJEMPLOS.md) |

Los conceptos que cruzan módulos (ej. el Report Designer) van en `conceptos/`, no repetidos en cada feature.
