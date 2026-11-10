# Implementación — Expediente virtual de Ahorros y Aportes

> Reference. Revisión final (etapa 8 de [PLAN-v1](./archivo/PLAN-v1.md)) hecha el 2026-11-04 sobre la rama `feature/contabilidad-archivos-documento-equivalente`. Detalle por feature en cada carpeta `<n>-<feature>/`. · [← README](./README.md)

## Qué hay

Catálogo (EV007), pedidos por cuenta (combos y sueltos), subir y consultar (Cargados, Pendientes, Vencidos), eliminar con constancia, firma con el titular y acta de constancia. Botón "Documentos" en las pantallas de cuentas CDT, ahorro y aporte.

## Verificación

Revisión de solo lectura (no se subió, borró ni firmó nada), 2026-11-04:

| Qué | Cómo | Resultado |
|---|---|---|
| Compila | MSBuild Debug de la solución | 0 errores (17 advertencias de versiones de ensamblados, ya existentes) |
| Tablas y vistas | SQL en `pg-demo` | Están las 7 tablas del modelo, `firmas_firmaarchivoahorro`, `cuentaahorrodocumentacion` y las 8 vistas |
| Menú | SQL | EV007 `~/DocumentoAhorro` activo, asignado a 19 roles |
| Datos | SQL | 31 pedidos (28 activos), 16 archivos (14 eliminados, 14 en la vista de eliminados), 4 firmas. Archivo 8 no sale en Cargados porque su pedido está retirado: coherente |
| Pantallas | `fetch` con la sesión de Orca | `DocumentoAhorro`, `CuentaPorTercero`, `DocumentoAhorroCuenta`, `DocumentoAhorroArchivo/Index`, `CuentaAhorro`, `VistaCuentasAporte`, `ParametrosCarpetaVirtual` y `ContenidoCarpetaVirtual`: 200, sin error en el HTML |
| APIs | `fetch` con la sesión | Cargados, Pendientes, Vencidos, Estado, pedidos por cuenta, tipos, combos (`Get` y `GetActivos`) y agrupaciones: 200 con datos |
| Pantalla de expediente | Orca, capturas en [evidencia/](./evidencia/) | Cargados, Pendientes y Vencidos abren; Pendientes lista DOCUMENTO 2 y 3 de la cuenta 5872 |

## Sin verificar (no se dan por buenos)

- Feature 2: permisos `AgregarMasCombosAhorros` y `AgregarDocumentosIndividualesAhorros` (el SQL lo corre el usuario) y sus casos en Orca.
- Feature 3: caso 16 (FTP).
- Feature 4: casos 1 y 2 (sin el permiso de eliminar, pide otro usuario), 11 (FTP), 12 (fallo forzado), 14 (crédito y contabilidad) y la pestaña Eliminados del caso 7.
- Feature 5: casos 3-8 y 10 (envían solicitudes reales a VozData).
- Features 6 (formato personalizado) y 8 (vencimiento por fin de cuenta, R25 en duda): sin hacer. La tabla `documentoahorroformato` existe pero está vacía y sin pantalla.
- Subida, eliminación y firma **no se repitieron** en esta revisión; valen los resultados de cada feature.

## Observaciones

- La pantalla de expediente tiene Cargados, Pendientes y Vencidos; **no hay pestaña Eliminados**. Los eliminados se ven en la pestaña Eliminados de la pantalla de combos (`Views/DocumentoAhorroCuenta/Index.cshtml`, `gridDocsEliminados`) y en el acta de la constancia (feature 9).
- `GET api/ComboDocumentoAhorroWebApi` sin acción da 500 ("varias acciones"): `Get` y `GetActivos` coinciden. Las pantallas piden la acción por nombre y funcionan; solo falla la URL pelada.
- Pendientes de las notas: protección de `CuentaAhorroWebApi.Delete` y el borrado del detalle CDT desde su grid (ver "Hallazgos en ahorros" del PLAN-v1).
