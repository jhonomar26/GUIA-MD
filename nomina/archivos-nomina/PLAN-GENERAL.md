# Plan general: expediente virtual de nómina

> Las 8 features de punta a punta, en orden, con lo que cada una crea y de qué commit de ahorros se clona. El detalle (Specs, Casos, Tareas) va en el `PLAN.md` de cada feature cuando arranca. · [← README](./README.md) · [Reglas](./REGLAS-DE-NEGOCIO.md) · [Análisis y nombres](./ANALISIS.md#nombres) · [ADR-001](./ADR.md)

**Meta:** cada contrato de nómina (`nomina_contratos`) tiene su expediente: pedir documentos al empleado (combos o sueltos), subirlos, ver vencidos, firmarlos y eliminarlos con constancia. Se abre desde el grid de Contratos.

**Enfoque:** clon del expediente de ahorros ya cerrado ([IMPLEMENTACION](../../ahorrosyaportes/archivos-ahorros/IMPLEMENTACION.md)), con los nombres de la [tabla de nombres](./ANALISIS.md#nombres): `cuentaahorro` → `contratonomina`, `ahorro` → `archivonomina`, dueño `idcontrato`, firmante el empleado del contrato. Se clona por feature, siguiendo el commit de ahorros de esa feature.

## Cómo se trabaja cada feature

- **Una a la vez:** la siguiente arranca cuando la anterior se probó en pantalla. Lo que aparece al probar corrige reglas y plan de las que siguen.
- **Orden dentro de la feature:** script → clases → pantalla → prueba. Carpeta `<n>-<feature>/` con `PLAN.md` al arrancar.
- **Scripts:** `scriptsSiian/nomina/scratch/archivos-nomina/<n>-<feature>/NN-*.sql`, copia del de ahorros con los nombres de nómina, idempotentes y con reversión; a `entregables/` solo pasan al enviarse a producción. Los revisa y los corre el usuario.
- **Clases:** WFAGenerarDao a un directorio temporal, difear contra ahorros y pegar lo que sirve. Todo `.cs` nuevo registrado en su `.csproj`.
- **Codificación:** las vistas de ahorros son latin1; se editan a nivel de bytes.
- **Explicación:** `EXPLICACION.md` + entrevista antes del código, salvo que el usuario la salte (la feature 1 se saltó por ser el mismo catálogo).
- **Prueba:** matriz de casos del `PLAN.md` recorrida en Orca en el servidor de pruebas, capturas en `evidencia/`.

## Features

### 1. catalogo — EV008

| | |
|---|---|
| Se ve | EV008: agrupaciones, tipos y combos |
| Reglas | R4-R9, R22, R37-R39 |
| Scripts | `01-catalogo.sql` (agrupación, tipo, combo, combo ↔ tipo), `02-menu.sql` (EV008 bajo 1902, `generales_menurol`) |
| Código | 4 entidades + actores en `Blip.Data/Nomina/`, validación y combos en `Negocio/Nomina/`, 4 WebApis, `DocumentoArchivoNominaController` + vista |
| Clona | `f999fad8f` |
| Estado | código hecho (commit `4c4b5c20b`, build 0 errores). Faltan: correr `01` y `02` en el servidor y los 18 casos en Orca. Ver [PLAN](./1-catalogo/PLAN.md) |

### 2. solicitar-documentos — pedir al empleado

|                  |                                                                                                                                                                                                                                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Se ve            | Botón "Documentos" en el grid de Contratos (junto a "Editar" e "Imprimir", `Contratos.cshtml:192-193`, con `e.row.data.Idcontrato`); pantalla de pedidos del contrato; agregar combos y sueltos                                                                                                      |
| Reglas           | R1-R3, R11-R15, R34                                                                                                                                                                                                                                                                                  |
| Scripts          | `01-contrato.sql`: `nomina_documentoarchivonominacontrato` (pedido, FK `idcontrato` → `nomina_contratos` `RESTRICT`, `idtercero` = empleado) y `nomina_contratonominacombo` (combo agregado y cuándo). `02-permisos-solicitar.sql`: `AgregarMasCombosNomina` y `AgregarDocumentosIndividualesNomina` |
| Código           | Clon de `ContratoNominaComboAsignacion`, `DocumentoArchivoNominaContratoAsignacion`, `DocumentoArchivoNominaContratoPermisos`; MVC `DocumentoArchivoNominaContrato`; WebApi de pedidos por contrato                                                                                                  |
| Propio de nómina | El empleado sale de la versión vigente de `nomina_contratogenerales` (`idtercero`). R14: insertar no revisa único ni duplicado. R3: ningún filtro por estado del contrato                                                                                                                            |
| Clona            | `8889fef4a`                                                                                                                                                                                                                                                                                          |
| Prueba           | Contrato sin documentos → combo → N pendientes a nombre del empleado; segundo combo y suelto sin permiso → rechazo en el servidor; la misma lista desde dos versiones del contrato (R1)                                                                                                              |

### 3. subir-y-consultar — subir, Cargados, Pendientes, Vencidos

| | |
|---|---|
| Se ve | Subir a un pendiente; pestañas Cargados, Pendientes y Vencidos; "carpeta de nómina" en EV001 |
| Reglas | R16-R24, R26, R27, R40 |
| Scripts | `01-archivos.sql`: `nomina_archivonomina`, `nomina_contratonominadocumentacion` (vínculo) y columna `generales_parametroscarpetavirtual.escarpetavirtualnomina` + ruta. `02-vistas-combos.sql` (estado, cargados y eliminados de combos) y `03-vistas-archivos.sql` (cargados, pendientes, vencidos): 6 vistas, como ahorros. Ver [PLAN](./3-subir-y-consultar/PLAN.md) |
| Código | Clon de `ArchivoNominaReglas`, `ArchivoNominaSubida`, `DocumentoArchivoNominaArchivoConsulta`; MVC `DocumentoArchivoNominaArchivo` + vistas; WebApi de archivo y de las 4 vistas. Se toca `ParametrosCarpetaVirtual` (propiedad al **final** del constructor posicional, actor, ViewModel, WebApi, pantalla EV001, `VerificarParametroPrincipalPorModulo`) |
| Propio de nómina | R25 fuera de alcance: no hay vencimiento por fin de contrato |
| Clona | `c4bf62ac3` |
| Prueba | Igual que ahorros: PDF a un pendiente sale de Pendientes y entra a Cargados; extensión no permitida, pedido de otro contrato, pedido que ya tuvo archivo (R17) y sin ruta de nómina (R20) → rechazo; fecha pasada → Vencidos; ahorros sigue igual |

### 4. eliminar-con-constancia — eliminar, retirar, reactivar

| | |
|---|---|
| Se ve | Eliminar archivos con constancia y pedido nuevo opcional; retirar y reactivar pedidos; pestaña Eliminados en la pantalla de pedidos |
| Reglas | R28-R32 |
| Scripts | `01-permiso-eliminar.sql`: `EliminarDocumentosCargadosNomina` |
| Código | Clon de `ArchivoNominaEliminacion` (una transacción, borrado físico después del commit) |
| Propio de nómina | R30 y R31 tal cual ahorros hoy: el pedido nuevo se crea siempre y reactivar se permite siempre |
| Clona | `f7e0f69c8`, `55a4bd3e7` |
| Prueba | 3 archivos = 1 constancia; sin motivo, de otro contrato o ya eliminado → rechazo; recrear deja un pendiente nuevo; retirar y reactivar |

### 5. firma-electronica — firma VozData

| | |
|---|---|
| Se ve | Botón Firmar en tipos con firma; el empleado como único firmante |
| Reglas | R33 |
| Scripts | `01-firma.sql`: `firmas_firmaarchivonomina` (`idarchivonomina`, `idprocesomaestro`) y columnas de firma en la vista de cargados |
| Código | Clon de `FirmaArchivoNominaActorNegocio` y MVC `FirmaArchivoNomina`; bandera `EsFirmaNomina` en `FirmaCarpetaVirtualViewModel` y su rama en el handler de VozData (como `EsFirmaAhorro`) |
| Clona | `5cf22f6dd`, `9a2280f18` |
| Prueba | Firmar solo en tipos con firma; firmante = empleado del contrato; archivo que no es de nómina → rechazo. Los casos que envían solicitudes reales se deciden con el usuario |

### 6. acta-constancia-eliminacion — el acta lista nómina

| | |
|---|---|
| Se ve | "Generar formato" de una constancia lista los archivos de nómina en la carpeta "Nómina" |
| Reglas | R41 |
| Scripts | `01-vista-archivos-eliminados.sql`: vista de archivos eliminados de nómina |
| Código | Entidad de la vista y **una línea** `AddRange` en `ConstanciaEliminacionArchivosActorNegocio` |
| Clona | `46168ccf8` |
| Prueba | Constancia con archivos de nómina → el acta los muestra; constancias de ahorros, crédito y contabilidad siguen igual |

### 7. bloqueo-borrar-contrato — mensaje claro

| | |
|---|---|
| Se ve | Borrar desde el grid la última versión de un contrato con expediente da un mensaje claro |
| Reglas | R35 (R34 ya lo protege la FK desde la feature 2; R36 fuera de alcance) |
| Scripts | Ninguno |
| Código | Guarda en `ContratoGeneralesActorNegocio.EliminarContrato` (`:74-78`) antes de `ContratosActor.Delete`: si el contrato tiene pedidos, se rechaza con mensaje |
| Propio de nómina | En ahorros no hizo falta (ninguna pantalla borra cuentas); en nómina sí, el grid borra el contrato de verdad |
| Prueba | Última versión con pedidos → mensaje; versión que no es la última → se borra; contrato sin pedidos → se borra |

### 8. formato-personalizado — PDF al agregar combo

| | |
|---|---|
| Se ve | Al agregar un combo, los tipos con formato se generan y quedan cargados solos |
| Reglas | R10 |
| Scripts | `01-formato.sql`: `nomina_documentoarchivonominaformato` (+ columna de error de cargue en el pedido) |
| Código | TagBox de formatos en EV008; generación al agregar el combo. Primero un spike corto: si `ReportePersonalizadoExpedienteVirtual` acepta un contrato sin tocar crédito |
| Clona | Nada: ahorros tampoco lo hizo. Molde = crédito (`DocumentoCreditoCreditoActorNegocio.AgregarCombo`) |
| Prueba | Combo con un tipo con formato → PDF cargado sin subirlo a mano |

## Riesgos y dependencias

| Qué | Por qué importa |
|---|---|
| Entre la feature 2 y la 7, borrar la última versión de un contrato con pedidos da el **error crudo** de la FK | La 7 es chica y sin scripts; puede adelantarse justo después de la 2 |
| [eliminar-retira-pedido](../../contabilidad/archivos-contabilidad/eliminar-retira-pedido/) sigue abierto en contabilidad | Si se cierra, cambia R30 y R31 también acá (feature 4) |
| `pg-demo` apunta a `demo-6-07-2026`, sin las tablas de ahorros | Las comparaciones contra ahorros se hacen sobre scripts y código |
| Cada feature toca piezas compartidas (EV001, firma, acta) | Cada prueba incluye un caso "ahorros, crédito y contabilidad siguen igual" |

## Cierre del tema

Al terminar la 8 (o la última que se decida hacer): recorrido de punta a punta, `IMPLEMENTACION.md` con `## Verificación` y lo que quedó sin probar, estado `vigente` en el README.
