# Requerimiento: ciclo de vida de los documentos contables alineado con crédito

## Pedido original

> lo importante y que no está documentado es el estado y las reglas que rondan en torno a estos documentos: pendiente, si es activo, si existe el tipo, cargado, si se elimina... la idea en esencia es basarnos en lo que está en crédito, esa es la regla

Nació el 2026-10-16 al analizar [consultas-documentos-sql](../consultas-documentos-sql/). Las reglas estaban repartidas en cuatro features (`expediente-virtual-carga`, `firma-documentos-contables`, `paridad-documentos-credito` y la antigua `eliminacion-documentos`) y algunas ya no coincidían con el código.

## Criterio

Crédito es la fuente de verdad. Cada regla cae en una de cuatro categorías:

| Categoría | Qué se hace |
|---|---|
| Igual a crédito | Se documenta |
| Crédito lo tiene y contabilidad no | Se ajusta contabilidad |
| No existe en crédito | Se quita |
| Diferencia a propósito (crédito tiene un defecto o contabilidad necesita algo propio) | Se queda, con el porqué escrito ([ADR-001](./ADR.md)) |

## Cambios que sí se hacen

| # | Cambio | Por qué |
|---|---|---|
| C1 | Al subir un archivo, rechazarlo si llegó incompleto (lo recibido no coincide con lo que dijo el navegador) | Crédito ya lo hace. Contabilidad solo revisa que no esté vacío. Era la D2 "por decidir" de `paridad-documentos-credito` |
| C2 | Solo se puede cargar un documento **pendiente**, también si la petición llega directo al servidor. Se quita el "reemplazo de único" que nadie usa | La pantalla ya solo ofrece pendientes, igual que crédito. Pero el servidor acepta cargar sobre un documento eliminado y lo devuelve a "cargado" |
| C3 | Un solo documento con los estados y las reglas vigentes ([ANALISIS.md](./ANALISIS.md)), y las features viejas apuntan a él | Hoy las reglas están repartidas y algunas describen cosas que no existen |

## No-gos

- Cambiar las diferencias a propósito (obligatorio por combo, único no repetido, foto solo imágenes, extensiones de contabilidad, copia de datos al recrear).
- La consulta de pendientes en SQL: va en [consultas-documentos-sql](../consultas-documentos-sql/).
- Firma electrónica: no cambia, se enlaza a [firma-documentos-contables](../firma-documentos-contables/).
- Reescribir los `PLAN.md` y `ADR.md` viejos: son historia. Solo se les agrega una línea que apunta a este doc.

## Criterios de aceptación

- **Dado** un archivo que llega cortado, **cuando** se sube, **entonces** se rechaza con "archivo incompleto" y no queda nada guardado.
- **Dado** un documento eliminado, **cuando** se intenta cargarle un archivo con una petición directa, **entonces** se rechaza y sigue eliminado.
- **Dado** un documento ya cargado (único o no), **cuando** se intenta cargarle otro archivo con una petición directa, **entonces** se rechaza.
- **Dado** un documento pendiente, **cuando** se sube su archivo desde la pantalla, **entonces** funciona igual que hoy.
- **Dado** el `ANALISIS.md`, **cuando** se compara regla por regla con el código, **entonces** no describe nada que no exista.
