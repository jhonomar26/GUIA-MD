# Plan: catálogo del expediente de ahorros (EV007)

> Pantalla EV007 para configurar agrupaciones, tipos de documento y combos de ahorros, copia de EV006 de contabilidad. · [← README](./README.md) · Reglas: [R4-R9, R22, R37-R39](../REGLAS-DE-NEGOCIO.md) · Mapa: [ANALISIS](../ANALISIS.md#catálogo)

**Antes del código:** R37-R39 confirmadas (2026-10-29). La explicación y la entrevista se saltaron: el usuario ya entendía la lógica.

## Specs

- **S1.** Agrupaciones: crear, editar e inactivar. Implementa R4.
- **S2.** Tipos de documento: crear, editar e inactivar, con agrupación, documento único, firma electrónica y foto. Implementa R4, R7, R8, R9.
- **S3.** Vencimiento del tipo: si vence, por **una sola** regla, fecha escrita a mano al subir o N días después de subirlo. Se rechaza un tipo que vence sin regla o con dos. Implementa R22 y R39 (0 días vale).
- **S4.** Combos: crear, editar e inactivar; agregar tipos con "obligatorio"; un tipo no se repite en el mismo combo. Implementa R5, R6.
- **S5.** Combo "para firmar": solo admite tipos con firma, y a un tipo que está en un combo para firmar no se le puede quitar la firma. Implementa R8. Marcar un combo "para firmar" no revisa los tipos que ya tiene (R37).
- **S5b.** Un tipo no puede ser firma y foto a la vez. Implementa R38.
- **S6.** Nada se borra: se inactiva. Un interruptor Activos/Todos filtra las tres listas (igual que EV006).
- **S7.** Crédito y contabilidad no cambian.

**Fuera de esta feature:** formato personalizado (R10, feature 6): la columna `esformatopersonalizado` se crea con `false` por defecto pero no se muestra, y la tabla de formatos va en la feature 6. "Documento único" y "foto" solo se guardan acá; se aplican al pedir (feature 2) y al subir (feature 3).

## Casos

Se recorren sobre EV007 en el servidor de pruebas (2026-10-29): la pantalla en Orca y las reglas por la API con la sesión de la pestaña. Datos de prueba con prefijo `ZZ`.

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R4 | la pantalla vacía | creo la agrupación "Identificación" | aparece en la lista y en el desplegable de agrupación del tipo | ✅ ZZ Identificacion creada; aparece en la lista y los tipos la usan ([01](./evidencia/01-pantalla-activos-todos.png)) |
| 2 | R4 | un tipo sin agrupación | lo guardo | se rechaza: "Debe seleccionar una agrupacion de documento valida." | ✅ 400 con el mensaje exacto |
| 3 | R22 | un tipo "Cédula" que **no vence** | lo guardo | se guarda; fecha manual y días quedan vacíos aunque se hubieran escrito | ✅ guardado con fecha manual y días vacíos (se envió manual=true y 7 días) |
| 4 | R22 | un tipo que vence con **fecha manual** | lo guardo | se guarda; el campo días queda deshabilitado | ✅ guardado, días vacíos |
| 5 | R22 | un tipo que vence a los **30 días** del cargue | lo guardo | se guarda con 30 días | ✅ guardado con 30 días |
| 6 | R22 | un tipo que vence **sin regla** (ni fecha manual ni días) | lo guardo | se rechaza: "Debe indicar los dias de vencimiento despues del cargue cuando el documento expira y la fecha no es manual." | ✅ 400 con el mensaje exacto |
| 7 | R22 | un tipo que vence con fecha manual **y** días (forzado por API) | lo guardo | se rechaza: "No debe indicar dias de vencimiento cuando la fecha es manual." | ✅ 400 con el mensaje exacto |
| 8 | R22 | un tipo que vence a **-5** días | lo guardo | se rechaza: "Los dias de vencimiento no pueden ser negativos." | ✅ 400 con el mensaje exacto |
| 9 | R39 | un tipo que vence a **0** días | lo guardo | se guarda: nace vencido (R39) | ✅ guardado con 0 días ([01](./evidencia/01-pantalla-activos-todos.png)) |
| 10 | R38 | un tipo con firma **y** foto | lo guardo | se rechaza con un mensaje claro: la firma solo acepta PDF y la foto solo imágenes | ✅ 400: «Un tipo no puede ser firma electronica y foto a la vez: la firma solo acepta PDF y la foto solo imagenes.» |
| 11 | R5, R6 | un combo "Apertura" | le agrego Cédula (obligatorio) y RUT (no obligatorio) | el detalle del combo muestra los dos con su obligatoriedad | ✅ el detalle muestra Cédula (obligatorio) y Manual (no) ([04](./evidencia/04-combo-detalle.png)) |
| 12 | R5 | el combo "Apertura" con Cédula | agrego Cédula otra vez | se rechaza con un mensaje claro (texto exacto: el de contabilidad) | ✅ 400 «Este documento ya esta agregado a este combo.» (idéntico al de contabilidad) |
| 13 | R8 | un combo "para firmar" | agrego un tipo **sin** firma | no aparece en el desplegable; forzado por API se rechaza | ✅ el desplegable `GetActivosParaCombo(true)` no trae el tipo sin firma y por API da 400 «Un combo para firmar solo admite tipos de documento con firma electronica.» |
| 14 | R8 | un tipo con firma dentro de un combo para firmar | le quito la firma | se rechaza: "No puede quitar la firma electronica: el tipo esta en un combo para firmar." | ✅ 400 con el mensaje exacto |
| 15 | R37 | un combo con un tipo sin firma | lo marco "para firmar" | se permite, sin revisar los tipos (R37); al **agregar** un tipo sin firma a un combo ya marcado, se rechaza (caso 13) | ✅ marcar y desmarcar el combo con tipos da 200 (sin revisar); agregar tipo sin firma da 400 (caso 13) |
| 16 | S6 | un tipo activo | lo inactivo y cambio el interruptor a "Activos" | desaparece; con "Todos" vuelve a verse | ✅ inactivo: no sale en Activos, sale en Todos ([01](./evidencia/01-pantalla-activos-todos.png)) |
| 17 | S7 | EV006 de contabilidad | abro la pantalla y edito un tipo | funciona igual que antes | ✅ EV006 carga con sus datos y un PUT de un tipo da 200 ([03](./evidencia/03-ev006-contabilidad.png)); no se editó por pantalla |

## Tareas

Orden vertical: script → clases → pantalla → prueba. Las clases se generan con [WFAGenerarDao](../../../guia/plantillas.md) (a un directorio temporal, se difea y se pega lo que sirve).

- [x] **T1 (S1-S6). Script de tablas.** `1-catalogo.sql` de `scriptsSiian/ahorrosyaportes/scratch/archivos-ahorros/` **sin** la tabla de formato (pasa a la feature 6), más la reversión de estas 4 tablas. Lo revisa y lo corre el usuario. Se parece a: `scriptsSiian/contabilidad/scratch/archivos-documento-contable/11-ajustes-documentocontable.sql`.
- [x] **T2 (S1-S6). Menú EV007 y permisos.** Script con el `INSERT` en `generales_menu` (`funcionalidad = '~/DocumentoAhorro'`, padre y módulo de ahorros, a verificar) y sus filas de `generales_menurol` **una sola vez por rol**. Nuevo, porque el repo no tiene script de EV006 (se creó a mano en la base).
- [x] **T3 (S1-S6). Entidades y actores** en `Blip.Data/Ahorrosyaportes/`: `AgrupacionDocumentoAhorro`, `DocumentoAhorro`, `ComboDocumentoAhorro`, `DocumentosAhorroCombo` (WFAGenerarDao `dapper`), registrados en `Data.csproj`. Se parece a: `Blip.Data/Contabilidad/AgrupacionDocumentoContable.cs`, `DocumentoTipo.cs`, `ComboDocumentoTipo.cs`, `ComboDocumentoContable.cs` y sus `Actor`.
- [x] **T4 (S2-S5). Reglas en `Negocio/Ahorrosyaportes/`**: validar y normalizar el tipo (S3, R38, R39), tipo en combo para firmar (S5, R37) y duplicado en combo (S4). El WebApi solo llama a un método de Negocio. Se parece a: `Negocio/Contabilidad/DocumentoTipoValidacionActorNegocio.cs` (sin la parte de plantillas), `DocumentoContableComboAsignacionActorNegocio.cs:44`, `Blip.Data/Contabilidad/ComboDocumentoContableActorNegocio.cs:15`.
- [x] **T5 (S1-S6). ViewModels y WebApis** (Get, Post, Put; **sin** Delete). Se parece a: `Blip.Entities/Contabilidad.ViewModels/` (las 4) y `PruebaPostgreSQL/Controllers/WebApi/{AgrupacionDocumentoContable,DocumentoTipo,ComboDocumentoTipo,ComboDocumentoContable}WebApiController.cs`, sin copiar sus fallas (ver Log L3).
- [x] **T6 (S1-S6). Pantalla EV007**: `DocumentoAhorroController` (solo `Index`, `[Log(RequireAutenticacion = true, ValidaMenu = true, AlmacenaLog = true)]`) y `Views/DocumentoAhorro/Index.cshtml` con los tres grids, el detalle de combo y el interruptor Activos/Todos; sin el TagBox de plantillas ni el check de formato. Se parece a: `PruebaPostgreSQL/Controllers/Contabilidad/DocumentoTipoController.cs` y `Views/DocumentoTipo/Index.cshtml` (codificado Windows-1252: editar con cuidado).
- [x] **T7. Prueba**: build en 0 errores y los 17 casos en Orca, con capturas en `./evidencia/`.

## Log

- **L1 (2026-10-29).** Pedido: "primero hacemos [...] lo de tipo de documentos con la interfaz". Área: [REQUERIMIENTO](../REQUERIMIENTO.md).
- **L2 (2026-10-29).** Mapeo de EV006: una sola vista (`Views/DocumentoTipo/Index.cshtml`) con tres grids apilados y el detalle del combo como MasterDetail. La regla de vencimiento se valida tres veces: `CHECK` en la base (`contabilidad_documentotipo_check`, idéntico al de nuestro script), C# (`DocumentoTipoValidacionActorNegocio.ValidarYNormalizar`) y JS (`setCellValue`). Documento único y foto **no** se validan en el catálogo, solo al pedir y al subir. El menú EV006 no tiene script: existe solo como filas en la base (`generales_menu` id 2088). Al mapear aparecieron los huecos R37-R39.
- **L3 (2026-10-29). Hallazgos en contabilidad, fuera de alcance (no se corrigen, no se copian):**
  1. EV006 tiene 38 filas en `generales_menurol` para 19 roles: el permiso se insertó dos veces.
  2. `AgrupacionDocumentoContableController`, `ComboDocumentoTipoController` y `ComboDocumentoContableController` compilan pero no tienen vista: su `Index` falla.
  3. El `Get` de agrupación y de combo-documento usa `new DataSourceLoadOptionsBase()` (línea 27) y descarta los filtros del grid.
  4. El `Put` de `ComboDocumentoContableWebApiController` (líneas 63-66) no copia `Esactivo` del registro: un PUT sin ese campo deja la fila inactiva.
  5. `DocumentoTipoWebApiController.Put` (línea 131) valida en el controlador; en ahorros va a Negocio.
  6. `Controllers/DocumentoCreditoController.cs` en la raíz duplica la clase de `Credito/` y no está en el `.csproj`.
- **L4 (2026-10-29).** Pruebas: 17/17 casos pasan. Pantalla vista en Orca (listas, interruptor, detalle del combo); reglas de negocio por la API de EV007 con la sesión de la pestaña. No corrí `msbuild` aparte: el servidor ya corre la compilación actual. Los datos `ZZ` quedan en la base de pruebas (nada se borra, R6/S6). Nota: `GET /api/DocumentoTipoWebApi` sin acción da 500 por dos `HttpGet` (`Get` y `GetConDocumentoTipoFormato`); la pantalla usa `/Get` y funciona, no es regresión nuestra.
