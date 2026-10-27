# Plan: expediente virtual de Ahorros y Aportes (molde: crédito)

> [← README](./README.md) · Molde: expediente virtual de **crédito** (EV002, `CargaArchivos/MostrarArchivos`, `DocumentoCreditoCredito`) · Ejecutar con `superpowers:executing-plans` o `sdd-apply`. Casillas `- [ ]`. Sin suite automatizada: verificación = SQL, curl y pantalla.

**Meta:** cada **cuenta de ahorro** (CDT, ahorro, aporte) tiene su expediente: pedir documentos (combos o sueltos), subirlos, ver vencidos, firmarlos y eliminarlos con constancia. Se abre desde la pantalla de cuentas CDT por tercero.

**Enfoque:** se copia la lógica de negocio y el modelo de datos de crédito, con tablas propias `ahorrosyaportes_*` y dueño `idcuentaahorro`. Se comparte solo lo que en crédito ya es genérico: `generales_archivo`, `generales_constanciaeliminacionarchivos`, `generales_parametroscarpetavirtual` (una marca nueva), `LimiteAlmacenamiento`, `SIIANClienteFTP`, `CargaArchivos/VisualizarArchivo` y el proceso de firma (`firmas_procesomaestro`, `firmas_archivo`).

## Hechos verificados (2026-10-23)

- Todas las cuentas viven en `ahorrosyaportes_cuentaahorro` (base demo: aportes 2798, ahorro 2729, vista/término 264, CDT 27). El tipo sale de `ahorrosyaportes_tipoahorro` (`escdt`, `esaporte`, `escaptacionvista`). Un solo dueño sirve para todas.
- La cuenta trae `idtercero` (titular): será el firmante.
- Crédito: catálogo propio (`credito_documentocredito`), solicitado con `idcredito`, carga en `credito_creditodocumentacion` (solicitado ↔ `generales_archivo`), firma en `firmas_firmaarchivocredito`, lectura por `credito_vistacreditoarchivos`.

## Modelo de datos (crédito → ahorros)

| Rol | Crédito | Ahorros |
|---|---|---|
| Agrupación | `credito_agrupaciondocumentocredito` | `ahorrosyaportes_agrupaciondocumentoahorro` |
| Tipo de documento | `credito_documentocredito` | `ahorrosyaportes_documentoahorro` |
| Combo | `credito_combodocumentocredito` | `ahorrosyaportes_combodocumentoahorro` |
| Combo ↔ tipo | `credito_documentoscreditocombo` | `ahorrosyaportes_documentosahorrocombo` |
| Solicitado | `credito_documentocreditocredito` (`idcredito`) | `ahorrosyaportes_documentoahorrocuenta` (`idcuentaahorro`) |
| Carga | `credito_creditodocumentacion` | `ahorrosyaportes_cuentaahorrodocumentacion` |
| Archivo / constancia | `generales_archivo` / `generales_constanciaeliminacionarchivos` | **mismas** |
| Firma | `firmas_firmaarchivocredito` | `firmas_firmaarchivoahorro` |
| Vista de lectura | `credito_vistacreditoarchivos` | `ahorrosyaportes_vistacuentaahorroarchivos` |
| Ruta | `escarpetavirtualcredito` | `escarpetavirtualahorros` (columna nueva) |

## Qué se copia igual y qué se adapta (decisión del usuario, 2026-10-23: "igual a crédito, adaptar lo que necesitamos")

| De crédito | En ahorros |
|---|---|
| Todo el catálogo, combos, solicitado, carga, eliminación y firma | **Igual** |
| "Días desde el fin del crédito" (`esdiasdespuesdefechafinalizacioncredito`) + job `ActualizarFechasVencimiento` | **Adaptado:** `esdiasdespuesdefechafinalizacioncuenta`. Fin = `cuentaahorrocdt.fechadevolucion` en CDT, `cuentaahorro.fechacancelacion` en las demás. Sin fecha de fin todavía: el archivo queda sin vencimiento y el job lo recalcula cuando la cuenta se cancela (etapa 3b) |
| Formato personalizado (`documentocreditoformato`, PDF al agregar combo con `ReportePersonalizadoExpedienteVirtual`) | **Adaptado:** `ahorrosyaportes_documentoahorroformato`; el reporte recibe `idcuentaahorro` en vez de `idcredito` (etapa 2b) |
| `credito_documentocreditotercero` | **No:** duplica el `idtercero` del solicitado |
| Codeudores como firmantes | **No:** la cuenta solo tiene titular (y `idterceroinformativo`, que no firma) |
| `requieregeolocalizacion`, `esparaconvenios` | **No:** son de la app móvil de crédito y del portal de convenios |
| Permiso "Editar datos" según etapa del crédito | **No:** la cuenta no tiene etapas |

**Diferencias a propósito** (lecciones de crédito y contabilidad):
- Vencimiento calculado **en el servidor**, no en la pantalla (en crédito lo hace `MostrarArchivos.cshtml:802-830`).
- Una sola lista de extensiones, validada en el servidor (en crédito cliente y servidor no coinciden: `.png`).

## Restricciones

- .NET 4.6.2, `.csproj` clásico: todo `.cs` nuevo se registra a mano (`Data.csproj`, `Entities`, `Negocio`, `PruebaPostgreSQL`).
- Entidad/Actor/ViewModel/WebApi se generan con WFAGenerarDao (skills `siian-plantillas-generadas` y `siian-actor-pattern`). `ParametrosCarpetaVirtual` tiene constructor posicional: la columna entra al final.
- `.cs` y `.cshtml` en ISO-8859-1: editar por bytes.
- `Negocio/` sin Dapper; consultas en `Blip.Data/Ahorrosyaportes/*ActorNegocio.cs` con campos estáticos `Campo`.
- Sin tocar código de crédito. Si hace falta algo de `CargaArchivosActorNegocio` (subida local/FTP), se decide en la etapa 3 si se llama tal cual o se copia; no se refactoriza crédito.
- Scripts en `scriptsSiian\ahorrosyaportes\scratch\archivos-ahorros\`, numerados, idempotentes, con reversión; los revisa el usuario antes de correrse.
- Cada etapa: `EXPLICACION.md` y entrevista **antes** de codificar. Commit solo si se pide.

## Foco de revisión

1. Crédito no cambia: ningún script ni archivo de crédito se toca (salvo la rama nueva en el handler de VozData, etapa 5).
2. Ruta de crédito mandada a una cuenta: se rechaza.
3. Cuenta sin ruta activa de Ahorros: mensaje claro, sin archivo ni fila.
4. Borrar una cuenta con documentos: el grid CDT tiene botón Eliminar; las FK son `RESTRICT`; mensaje claro, no error de base.
5. Tipo "documento único" subido dos veces: queda activo solo el último (como `VerificarDocUnico`).

## Etapas (cada una de punta a punta)

### Etapa 1: catálogo y su configuración
**Se parece a:** `DocumentoCreditoController.Index` + `Views/DocumentoCredito/Index.cshtml` (3 grillas: agrupaciones, tipos, combos con detalle).

- [ ] SQL 1: agrupación, tipo, combo y combo ↔ tipo (columnas de crédito con la adaptación de la tabla de arriba). Más reversión.
- [ ] SQL 2: menú **EV007 - Documentos Expediente Virtual Ahorros** (`~/DocumentoAhorro`) bajo 1902 "EV0 - Parámetros"; permiso de la pantalla.
- [ ] Generar las 4 entidades; `DocumentoAhorroController` y vista clonada (sin TagBox de formatos).
- [ ] Reglas de crédito: combo "para firmar" solo con tipos con firma; sin tipo repetido en el combo.
- **Verificación:** EV007 en el menú; crear agrupación, tipo y combo; regla de firma rechaza un tipo sin firma.

### Etapa 2: solicitar documentos desde la cuenta
**Se parece a:** `DocumentoCreditoCreditoController.AgregarCombo`, `ComboDocumentoCreditoActorNegocio.AgregarComboV2`, `Views/DocumentoCreditoCredito/Index.cshtml`.

- [ ] SQL 3: `documentoahorrocuenta` (`idcuentaahorro` FK `RESTRICT`, `iddocumento`, `idtercero`, `descripcion`, `esobligatorio`, `esactivo`) y permisos `AgregarMasCombosAhorros` (`~/DocumentoAhorroCuenta/AgregarCombo`) y `AgregarDocumentosIndividualesAhorros` (`~/DocumentoAhorroCuenta/Index`).
- [ ] Negocio `Negocio/AhorrosyAportes/ComboDocumentoAhorroActorNegocio.AgregarCombo`: por cada tipo activo del combo un solicitado (`idtercero` = titular), todo en una transacción; el segundo combo pide permiso.
- [ ] `DocumentoAhorroCuentaController` + WebApi (`GetPendientesPorIdCuenta`, solicitados, Post/Put con permiso de individuales).
- [ ] Botón de fila "Documentos" en `CuentaPorTercero.cshtml` (junto a los de las líneas 111-116) → `/CargaArchivosAhorro/MostrarArchivos/{Id}`; desde ahí "Lista Documentos" abre esta pantalla.
- **Verificación:** cuenta sin documentos → agregar combo → N pendientes con el titular; segundo combo sin permiso → error; documento suelto sin permiso → rechazado en el servidor.

### Etapa 2b: formato personalizado
**Se parece a:** `DocumentoCreditoCreditoActorNegocio.AgregarCombo` (genera los PDF), `CargaArchivosActorNegocio.SubirArchivoFormatoPersonalizado:491`, `DocumentoCreditoActorNegocioViewModel.GuardarDocumentoCredito:269`.

- [ ] SQL: `ahorrosyaportes_documentoahorroformato` (`iddocumentoahorro`, `idgeneralesformato`). TagBox de formatos en la pantalla de configuración (etapa 1).
- [ ] Al agregar un combo, los tipos con formato se generan y suben solos; si falla, el error queda en el solicitado (`descripcionrespuestacargue`, columna a sumar en SQL 3).
- [ ] Spike corto: qué recibe `ReportePersonalizadoExpedienteVirtual` y si acepta una cuenta sin tocar crédito.
- **Verificación:** combo con un tipo con formato → el PDF queda cargado sin subirlo a mano.

### Etapa 3: subir, ver y vencidos
**Se parece a:** `CargaArchivosController.MostrarArchivos` / `SubirArchivos`, `CargaArchivosActorNegocio.ValidarYSubirArchivo`, `Views/CargaArchivos/MostrarArchivos.cshtml` (pestañas Cargados, Cargados Remoto, Pendientes, Vencidos).

- [ ] SQL 4: `cuentaahorrodocumentacion` (`iddocumento` → solicitado, `idarchivo`, `esactivo`), vista `vistacuentaahorroarchivos` (copia de la de crédito con `idcuentaahorro`), columna `escarpetavirtualahorros` + ruta `~/Uploads/AhorrosAportes/` principal.
- [ ] `ParametrosCarpetaVirtual`: propiedad, actor, ViewModel, WebApi, pantalla de parametrización y `VerificarParametroPrincipalPorModulo`.
- [ ] Negocio `CargaArchivosAhorroActorNegocio`: validar (archivo completo, solicitado pendiente de esa cuenta, ruta de Ahorros, extensión), calcular vencimiento, subir local/FTP, documento único, insertar archivo y carga.
- [ ] `CargaArchivosAhorroController` + vista clonada de `MostrarArchivos`; WebApi de la vista (cargados, editar descripción/activo) y vencidos.
- **Verificación:** PDF a un pendiente → aparece en Cargados y sale de Pendientes; extensión no permitida → rechazo; ruta de crédito → rechazo (foco 2); sin ruta → mensaje (foco 3); único subido dos veces (foco 5); fecha pasada → Vencidos.

### Etapa 3b: vencimiento por fin de la cuenta
**Se parece a:** `CargaArchivosActorNegocio.FechaFinCredito:206`, `ArchivoActorNegocio.ActualizarFechasVencimiento:50-133`.

- [ ] `FechaFinCuenta(idCuentaAhorro)`: `fechadevolucion` del CDT activo o `fechacancelacion` de la cuenta.
- [ ] Recalcular vencimientos de la cuenta cuando se cancela o se renueva el CDT (dónde se engancha: por ubicar en el ANALISIS).
- **Verificación:** CDT con devolución en 90 días, tipo "30 días después del fin" → vence a los 120; cuenta de ahorro abierta → sin vencimiento hasta cancelarla.

### Etapa 4: eliminar con constancia
**Se parece a:** `CargaArchivosController.BorrarDocumentosSeleccionados`, `CargaArchivosActorNegocio.ValidarBorrado`, `NuevosDocumentosAPartirDeArchivosEliminados`.

- [ ] SQL 5: permiso `EliminarDocumentosCargadosAhorros` (`~/CargaArchivosAhorro/BorrarDocumentosSeleccionados`).
- [ ] Negocio: constancia, archivos marcados eliminados, borrado físico/FTP, volumen actualizado; "recrear" crea otro solicitado.
- **Verificación:** sin permiso → rechazo en el servidor; 3 archivos = 1 constancia; recrear deja un pendiente nuevo.

### Etapa 5: firma electrónica
**Se parece a:** `FirmaArchivoCreditoController`, `Negocio/Firmas/FirmaArchivoCreditoActorNegocio` (FirmarDocumento, EnviarSolicitudFirma, DescargarYReemplazar, Reenviar, Anular).

- [ ] SQL 6: `firmas_firmaarchivoahorro` (`idarchivoahorro`, `idprocesomaestro`) y la vista con `idfirma`.
- [ ] `FirmaArchivoAhorroActorNegocio` y controlador; firmante = titular.
- [ ] Rama de ahorros en `FirmarDocumentoCarpetaVirtualHandler.cs:116-118` y en `FirmarDocumentoService`: único cambio fuera de Ahorros.
- **Verificación:** PDF firmado reemplaza al original y el botón cambia de color; crédito sigue firmando igual.

### Etapa 6: bloqueo de borrado
- [ ] Eliminar o anular una cuenta con documentos: mensaje claro en el grid CDT (foco 4).

### Etapa 7: otras pantallas de cuentas
- [ ] Botón "Documentos" en `Views/CuentaAhorro/*` y `Views/VistaCuentasAporte/Index.cshtml` (el dueño ya sirve: hechos verificados).

### Etapa 8: revisión final y cierre
- [ ] Recorrido de punta a punta, `evidencia/`, `IMPLEMENTACION.md` con `## Verificación`, `PLAN` y `EXPLICACION` a `archivo/`, estado `vigente`, filas de README.

## Hallazgos en crédito (fuera de alcance, no se corrigen)

- `MostrarArchivos.cshtml:1083` llama a `CargaArchivos/EliminarArchivo`, que no existe en `CargaArchivosController`.
- Vencimiento calculado en el cliente; extensiones del cliente y del servidor no coinciden (`.png`).
- Vencidos no filtra documentos inactivos.
