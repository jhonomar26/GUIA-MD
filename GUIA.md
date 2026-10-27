# Guía: cómo documentamos en notas-siian

Las notas van en Markdown dentro de este repo, **por módulo de negocio** (los mismos nombres que `Negocio/<Modulo>/`) y dentro de cada módulo una carpeta por feature. Usamos dos convenciones estándar: **ADR** (una decisión de diseño por documento, que no se reescribe) y **Diátaxis** (separar referencia de explicación).

## Empezar aquí

**¿Qué voy a hacer?**

| Mi cambio es... | Qué hago |
|---|---|
| Algo chico: un método o una consulta, sin dudas | Nada de notas. Alcanza con el mensaje del commit |
| Un bug | `REQUERIMIENTO.md` (qué ve el usuario) → causa raíz → `IMPLEMENTACION.md` (causa, archivos, cambio, verificación). Ver [verificación y cierre](./guia/verificacion-y-cierre.md) |
| Una feature | Los 6 pasos de abajo |

**Una feature nueva, en 6 pasos**

1. **Creo la carpeta** en su módulo (y en su área, si el módulo tiene una) con un `README.md` que abre con la cabecera: módulo, área, menú, estado. → [estructura](./guia/estructura.md)
2. **`REQUERIMIENTO.md`**: qué piden, en palabras de negocio.
3. **`ANALISIS.md`**: qué ya existe en SIIAN y qué falta, sin código. Sale de explorar el código y preguntar de a una. → [cómo se hace](./guia/como-hacer-un-analisis.md), [tamaño y herramientas](./guia/flujo-de-feature.md)
4. **`ADR.md`** si hubo que elegir entre enfoques, y **`PLAN.md`** con **etapas verticales chicas** (backend + pantalla + prueba) y casillas.
5. **Por cada etapa:** entiendo la lógica antes de programar, programo, y verifico con evidencia (build en 0 errores y cada caso probado; lo capturado va en `evidencia/`). → [flujo de feature](./guia/flujo-de-feature.md)
6. **Cierro:** `IMPLEMENTACION.md` con la sección `## Verificación`, `PLAN` y `EXPLICACION` a `archivo/`, estado `vigente` y las filas de los README. → [verificación y cierre](./guia/verificacion-y-cierre.md)

Los commits solo se hacen cuando se piden.

## Dónde está cada cosa

| Si busco... | Voy a |
|---|---|
| Dónde va mi feature, qué archivos crear, **cabecera del README**, **área**, **Reglas de contenido** | [`guia/estructura.md`](./guia/estructura.md) |
| **Tamaño** de la tarea (ODD), etapas verticales, skills de apoyo, **entender antes de construir**, **paso 3b** (entender el código), spike | [`guia/flujo-de-feature.md`](./guia/flujo-de-feature.md) |
| **Flujo de bug**, **Verificación**, carpeta `evidencia/`, golden master, **Definition of Done** | [`guia/verificacion-y-cierre.md`](./guia/verificacion-y-cierre.md) |
| Cómo escribir un `ANALISIS.md` | [`guia/como-hacer-un-analisis.md`](./guia/como-hacer-un-analisis.md) |
| Migrar un doc viejo, rastrear cambios, **chequeo de sincronización** de tablas | [`guia/mantenimiento.md`](./guia/mantenimiento.md) |
| Ejemplos reales de principio a fin | [`GUIA_EJEMPLOS.md`](./GUIA_EJEMPLOS.md) |

Los conceptos que cruzan módulos (ej. el Report Designer) van en `conceptos/`, no repetidos en cada feature.
