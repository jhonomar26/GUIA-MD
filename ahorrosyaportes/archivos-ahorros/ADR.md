# ADR-001: los archivos de ahorros van en una tabla propia

**Estado:** aceptado (2026-10-28). **Supersede a:** "se comparte `generales_archivo`" del [plan original](./archivo/PLAN-v1.md).

## Contexto

Crédito guarda sus archivos en `generales_archivo`. Contabilidad, en la remodelación (2026-10-27), los pasó a `contabilidad_archivocontable`, copia exacta de las columnas de la general. El plan original de ahorros compartía la general.

## Decisión

Los archivos del expediente de ahorros van en `ahorrosyaportes_archivoahorro`, con las mismas columnas que `generales_archivo`, igual que contabilidad. Decisión del usuario: "en una tabla propia".

## Consecuencias

- El puente, la firma (`firmas_firmaarchivoahorro`) y la constancia apuntan a la tabla propia.
- Ver archivo, firma y eliminación leen esa tabla: no sirven tal cual `CargaArchivos/VisualizarArchivo` ni `ArchivoActor` de crédito. El precedente es contabilidad (`ArchivoContableAlmacenamientoActorNegocio.LeerArchivo`, `ArchivoContableEliminacionActorNegocio`).
- El límite de almacenamiento no cambia: mide el disco de las rutas registradas y la raíz del FTP, no filas (`ArchivoContableAlmacenamientoActorNegocio.cs:25,68`). Basta con que la ruta de Ahorros esté en la parametrización de carpetas.
- Los archivos de ahorros no se mezclan con los de crédito.
