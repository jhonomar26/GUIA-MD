# Plan: eliminar un archivo retira su pedido

> Al eliminar un archivo su pedido queda retirado, en contabilidad y en ahorros · ← [README](./README.md) · Reglas: [R1-R6](./ANALISIS.md#reglas) · Sin pruebas automáticas: matriz en Orca

## Specs
- S1. "desactivar el documento solicitado anterior y volver a acargar otro y listo": al eliminar un archivo, su pedido queda retirado si no le queda otro archivo vigente, y el tipo único se puede volver a pedir a mano o por combo. Implementa R1, R6.
- S2. Con "Sí" al eliminar queda un solo pedido activo del tipo: el nuevo pendiente. Implementa R2.
- S3. La pestaña Eliminados sigue mostrando el archivo eliminado aunque su pedido esté retirado. Implementa R3.
- S4. Un pedido con su archivo eliminado no se puede reactivar. Implementa R4.
- S5. Los pedidos actuales que están activos con todos sus archivos eliminados quedan retirados. Implementa R5.
- S6. "tanto en ahorros como en contabilidad": aplica al comprobante, al documento equivalente y a la cuenta de ahorro.

## Casos
Cada caso se recorre en contabilidad (comprobante y equivalente) y en ahorros.

| # | Regla | Dado | Cuando | Entonces | Contabilidad | Ahorros |
|---|---|---|---|---|---|---|
| 1 | R1 | tipo único cargado | elimina con "No" | el pedido queda inactivo, "cargado eliminado" | | |
| 2 | R1, R6 | caso 1 hecho | pide el tipo a mano | lo agrega | | |
| 3 | R1, R6 | caso 1 hecho | agrega un combo que trae ese tipo | lo crea | | |
| 4 | R2 | tipo único cargado | elimina con "Sí" | un solo pedido activo del tipo: el nuevo pendiente | | |
| 5 | R3 | caso 1 o 4 hecho | abre la pestaña Eliminados | ve el archivo eliminado | | |
| 6 | R4 | caso 1 hecho | reactiva el pedido retirado | rechazo con mensaje claro | | |
| 7 | R6 | tipo único pendiente | pide otro igual a mano | rechazo "ya esta solicitado" (no cambia) | | |
| 8 | R5 | pedido activo con su archivo eliminado de antes | corre el script | el pedido queda retirado y el caso 2 pasa | | |

## Tareas
- [ ] T0. Confirmar R3, R4 y R5 con el usuario; escribir `EXPLICACION.md`.
- [ ] T1 (S1-S6, contabilidad). Vista de Eliminados sin el filtro de pedido activo (script nuevo); `ArchivoContableEliminacionActorNegocio.MarcarEliminados` retira el pedido; rechazo de R4 en `DocumentoContableSolicitadoAsignacionActorNegocio.ModificarDocumento`; script de datos de R5. Se parece a: `contabilidad_vistadocumentoseliminadoscombo` (script 12) y la validación de T5 de correcciones. Casos 1-8 en contabilidad.
- [ ] T2 (S1-S6, ahorros). Lo mismo en `ArchivoAhorroEliminacionActorNegocio.MarcarEliminados`, `DocumentoAhorroCuentaAsignacionActorNegocio.ModificarDocumento` y `ahorrosyaportes_vistadocumentoseliminadoscuentacombo`; actualizar R30 y R31 de ahorros. Se parece a: T1. Casos 1-8 en ahorros.

## Log
- L1 (2026-11-05). Pedido textual en [REQUERIMIENTO.md](./REQUERIMIENTO.md#pedido-original-2026-11-05).
- L2 (2026-11-05). Verificado en la base de pruebas: `contabilidad_vistadocumentoseliminadoscombo` y `ahorrosyaportes_vistadocumentoseliminadoscuentacombo` filtran `s.esactivo = true`; las listas generales (`contabilidad_vistaarchivoseliminados`, `ahorrosyaportes_vistaarchivoseliminadosahorrosaportes`) no. El estado (`...solicitadoestado`, `...ahorroestado`) calcula cargado y eliminado sin mirar `s.esactivo`, así que un pedido retirado sigue saliendo "cargado eliminado".
