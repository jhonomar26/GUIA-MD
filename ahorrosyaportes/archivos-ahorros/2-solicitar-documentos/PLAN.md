# Plan: solicitar documentos a una cuenta

> Desde el grid de cuentas CDT, abrir los documentos de una cuenta y pedirle un combo o un documento suelto a su titular. · [← README](./README.md) · Reglas: [R1-R3, R11-R15, R34](../REGLAS-DE-NEGOCIO.md) · Mapa: [ANALISIS](../ANALISIS.md#por-cuenta)

**Antes del código:** `EXPLICACION.md` y entrevista **saltadas por decisión del usuario (2026-10-29)**; se escriben después. Depende de la feature 1 (catálogo); código sin commit.

## Specs

- **S1.** El grid de cuentas CDT por tercero tiene un botón "Documentos" por fila que abre la pantalla de documentos de esa cuenta. Implementa R1, R3.
- **S2.** Agregar un **combo** a la cuenta crea un pedido por cada tipo activo del combo, a nombre del titular, con la obligatoriedad que dice el combo, todo o nada. Implementa R5, R6, R11, R12.
- **S3.** Queda registrado **qué combo** se agregó a la cuenta. Implementa R13.
- **S4.** El primer combo se agrega libre; un **segundo combo** exige el permiso `AgregarMasCombosAhorros`. Implementa R15.
- **S5.** Un **documento suelto** exige el permiso `AgregarDocumentosIndividualesAhorros`, se valida en el **servidor**, y su tipo debe estar activo. Se puede editar descripción y obligatorio, no el tipo. Implementa R11, R15.
- **S6.** ~~Un tipo **único** que la cuenta ya tiene activo no se pide otra vez, ni en combo ni suelto.~~ **Revertida (R19 contable, 2026-11-05, `9e1b92c44`):** no se valida; el pedido se crea.
- **S7.** Una cuenta con pedidos **no se borra**: la base lo impide. El mensaje claro es la feature 7. Implementa R34.
- **S8.** Crédito, contabilidad y el catálogo (feature 1) no cambian.

**Fuera de esta feature:** subir archivos y el estado del pedido (feature 3); retirar un pedido (feature 4, R31): el `Put` de acá **no** toca `esactivo`; formato personalizado y `descripcionrespuestacargue` (feature 6); botón en las demás pantallas de cuentas (feature 7).

## Casos

Se recorren en Orca. Resultado: se llena al probar.

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R1 | el grid CDT por tercero | hago clic en "Documentos" de una cuenta | abre la pantalla de esa cuenta, con su titular a la vista | |
| 2 | R1 | una cuenta de **aporte** (sin botón aún) | abro la URL de documentos con su id | funciona igual que la CDT | |
| 3 | R11, R12 | una cuenta sin pedidos y un combo de 3 tipos activos | agrego el combo | 3 pedidos a nombre del titular, con la obligatoriedad del combo | |
| 4 | R13 | el caso 3 | miro los combos de la cuenta | aparece el combo agregado, una vez | |
| 5 | R5 | un combo con un tipo **inactivo** | agrego el combo | solo se piden los tipos activos | |
| 6 | R5 | un combo inactivo (forzado por API) | lo agrego | se rechaza: "El combo no existe o esta inactivo." | |
| 7 | R15 | la cuenta ya tiene un combo, usuario **sin** permiso | agrego otro | se rechaza en el servidor; sin pedidos ni registro nuevos | |
| 8 | R15 | la cuenta ya tiene un combo, usuario **con** permiso | agrego otro | se agrega | |
| 9 | S2 | un combo cuyo tercer tipo falla al insertar (forzado) | agrego el combo | no queda nada: ni pedidos ni registro del combo | |
| 10 | R11, R15 | usuario **sin** permiso de individuales | agrego un documento suelto (por API) | se rechaza: "No tiene permiso para agregar o editar documentos." | |
| 11 | R11 | usuario **con** permiso | agrego un documento suelto | pedido a nombre del titular | |
| 12 | S5 | un tipo inactivo | lo pido suelto | se rechaza: "El tipo de documento no existe o esta inactivo." | |
| 13 | S5 | un pedido existente | cambio su tipo (por API) | el tipo no cambia; descripción y obligatorio sí | |
| 14 | R14 | la cuenta ya tiene la Cédula (tipo único) activa | pido la Cédula suelta | se crea el pedido (S6 revertida) | |
| 15 | R14 | la cuenta ya tiene la Cédula (tipo único) activa | agrego un combo que la trae | se piden todos, la Cédula incluida (S6 revertida) | |
| 16 | R34 | una cuenta con un pedido | intento borrarla en la base | la base lo impide (`RESTRICT`) | |
| 17 | R5 | un combo inactivo | abro el SelectBox de combos | no aparece: lo filtra el servidor (`ComboDocumentoAhorroWebApi/GetActivos`), como contabilidad | |
| 18 | S8 | crédito y contabilidad | pido documentos como antes | funciona igual | |

## Tareas

Orden vertical: spike → script → clases → pantalla → prueba. Las clases se generan con [WFAGenerarDao](../../../guia/plantillas.md).

- [x] **T1 (S6). Spike corto.** Contabilidad **omite** (`continue`) el tipo único ya pedido al agregar un combo y **rechaza** con "Este tipo de documento es unico y ya esta solicitado..." al pedirlo suelto; un pedido inactivo no cuenta. Ahorros hace igual. *(Revertido el 2026-11-05: ya no se omite ni se rechaza.)*
- [x] **T2 (S2-S7). Script de tablas.** Parte `2-cuenta.sql` de `scriptsSiian/ahorrosyaportes/scratch/archivos-ahorros/`: acá solo `cuentaahorrocombo` y `documentoahorrocuenta` (sin `descripcionrespuestacargue`, que va en la 6); archivo, vínculo y firma pasan a las features 3 y 5. Reversión de estas dos. Las dos tablas **ya existen en `demo`** (con `descripcionrespuestacargue`); las entidades y actores ya estaban generados.
- [~] **T3 (S4, S5). Permisos.** Script con las funcionalidades `AgregarMasCombosAhorros` y `AgregarDocumentosIndividualesAhorros`, una sola fila por rol (L3.1 de la feature 1). Se parece a: las de `~/DocumentoContableCombo/AgregarCombo`.
- [x] **T4 (S2-S6). Entidades y actores** en `Blip.Data/Ahorrosyaportes/`: `CuentaAhorroCombo` y `DocumentoAhorroCuenta` (WFAGenerarDao `dapper`), registrados en `Data.csproj`. Se parece a: `Blip.Data/Contabilidad/DocumentoContableCombo*.cs` y `DocumentoContableSolicitado*.cs`.
- [x] **T5 (S2-S6). Reglas.** Consultas en `Blip.Data/Ahorrosyaportes/` (insertar combo con sus pedidos; la consulta de tipo único activo se borró en `9e1b92c44`) y negocio en `Negocio/AhorrosyAportes/`: `PuedeAgregarCombo`, `AgregarCombo` en transacción, `AgregarDocumento`/`ModificarDocumento`, permisos. Titular = `idtercero` de la cuenta. Se parece a: `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs`, `DocumentoContableSolicitadoAsignacionActorNegocio.cs`, `DocumentoContablePermisosActorNegocio.cs`.
- [x] **T6 (S2-S5). ViewModels y WebApis**: combos de la cuenta (Get, `PostConSolicitados`) y pedidos de la cuenta (Get, Post, Put; **sin** Delete). El WebApi solo llama a un método de Negocio. Se parece a: `DocumentoContableComboWebApiController.cs` y el del solicitado, sin copiar sus fallas.
- [x] **T7 (S1-S5). Pantalla.** `DocumentoAhorroCuentaController` (solo `Index(idcuenta)`, fija `PuedeAgregarCombo` y `PuedeAgregarDocumentoIndividual` desde Negocio) y su vista con los pedidos de la cuenta y los dos botones de agregar; botón "Documentos" por fila en `Views/CuentaAhorroCDT/CuentaPorTercero.cshtml`. Se parece a: `Controllers/Contabilidad/DocumentoContableComboController.cs` y `Views/DocumentoContableCombo/Index.cshtml` (sin las pestañas de cargados y eliminados: son de las features 3 y 4).
- [ ] **T8. Prueba**: build en 0 errores y los 18 casos en Orca, con capturas en `./evidencia/`.

## Log

- **L1 (2026-10-29).** Pedido: "creo que ahí podemos armar feature de las siguientes etapas, ayúdame con esto" (sobre `archivo/PLAN-v1.md`). Se arma el plan de la **feature 2**, la siguiente; las demás se planean al arrancarlas, porque dependen de lo que aparezca al construir la anterior.
- **L2 (2026-10-29).** Cambios frente a la etapa 2 de `PLAN-v1`: se agrega el registro de combos (R13, de contabilidad); el estado y la pestaña de cargados salen a la feature 3; `descripcionrespuestacargue` sale a la 6; el `Put` no retira pedidos (R31, feature 4).
- **L3 (2026-10-29).** Pedido: "pasa al código pero no commitees nada". Se saltó `EXPLICACION.md` por decisión del usuario. Hecho: Data (`DocumentoAhorroCuentaActorNegocio`, `DocumentosAhorroComboActorNegocio`), Negocio (`CuentaAhorroComboAsignacionActorNegocio`, `DocumentoAhorroCuentaAsignacionActorNegocio`, `DocumentoAhorroCuentaPermisosActorNegocio`), VM `DocumentosCuentaPantallaViewModel`, WebApis `CuentaAhorroComboWebApi` y `DocumentoAhorroCuentaWebApi` (reemplazan los stubs generados: sin `Delete`), `DocumentoAhorroCuentaController`, vista `DocumentoAhorroCuenta/Index.cshtml` y botón "Documentos" en el grid CDT. Build de `PruebaPostgreSQL.csproj`: 0 errores. **Pendiente:** T3 (el usuario corre `2b-permisos-solicitar.sql` y asigna roles) y T8 (matriz en Orca; las vistas Razor solo se validan al abrirlas).
- **L4 (2026-10-30).** Hallazgo al entrevistar la feature 3: el SelectBox de combos filtraba los activos en el cliente. Corregido: `GetActivos` (Data `ObtenerCombosActivos`, Negocio `ObtenerCombosParaAgregar`, WebApi y vista). Build 0 errores; falta el caso 17 en Orca.
