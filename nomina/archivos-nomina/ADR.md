# ADR-001: el expediente de nómina es del contrato y sus archivos van en tabla propia

**Estado:** aceptado (2026-11-06).

## Contexto

Ahorros dejó el expediente en la cuenta y los archivos en una tabla propia ([ADR de ahorros](../../ahorrosyaportes/archivos-ahorros/ADR.md)). En nómina el contrato tiene dos niveles: `nomina_contratos` (el contrato, solo `id` y `fechacreacion`) y `nomina_contratogenerales` (las **versiones** del contrato: cada modificación con fecha de inicio distinta crea una fila nueva). El grid de Contratos muestra versiones. Un empleado puede tener varios contratos si lo recontratan.

## Decisión

1. El dueño del expediente es `nomina_contratos.id`, no la versión ni el empleado. Decisión del usuario: "Del contrato".
2. Los archivos van en `nomina_archivonomina`, con las columnas de `generales_archivo`, igual que ahorros y contabilidad.

## Consecuencias

- Las versiones del contrato comparten un solo expediente: modificar el contrato no lo vacía.
- Un empleado recontratado tiene un expediente nuevo (se le piden otra vez los documentos).
- Quien firma es el empleado del contrato (`idtercero` de su versión vigente).
- Borrar la última versión borra el contrato (`ContratoGeneralesActorNegocio.EliminarContrato`): con expediente, la base lo impide (R34).
