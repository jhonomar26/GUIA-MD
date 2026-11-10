# Plan: catálogo del expediente de nómina (EV008)

> Pantalla EV008 para configurar agrupaciones, tipos de documento y combos de nómina, clon de EV007 de ahorros. · [← README](../README.md) · Reglas: [R4-R9, R22, R37-R39](../REGLAS-DE-NEGOCIO.md) · Nombres: [ANALISIS](../ANALISIS.md#nombres)

**Antes del código:** reglas sin pendientes (2026-11-07). La explicación y la entrevista se saltaron (decisión del usuario): es el mismo catálogo de ahorros con otros nombres.

## Specs

- **S1.** Agrupaciones: crear, editar e inactivar. Implementa R4.
- **S2.** Tipos de documento: crear, editar e inactivar, con agrupación, documento único (marca sin efecto, R7), firma electrónica y foto. Implementa R4, R7, R8, R9.
- **S3.** Vencimiento del tipo: si vence, por **una sola** regla, fecha escrita a mano al subir o N días después de subirlo. Se rechaza un tipo que vence sin regla o con dos. Implementa R22 y R39 (0 días vale).
- **S4.** Combos: crear, editar e inactivar; agregar tipos con "obligatorio"; un tipo no se repite en el mismo combo. Implementa R5, R6.
- **S5.** Combo "para firmar": solo admite tipos con firma, y a un tipo que está en un combo para firmar no se le puede quitar la firma. Implementa R8. Marcar un combo "para firmar" no revisa los tipos que ya tiene (R37).
- **S5b.** Un tipo no puede ser firma y foto a la vez. Implementa R38.
- **S6.** Nada se borra: se inactiva. Un interruptor Activos/Todos filtra las tres listas (igual que EV007).
- **S7.** Ahorros, contabilidad y crédito no cambian.

**Fuera de esta feature:** formato personalizado (R10, feature 8): la columna `esformatopersonalizado` se crea con `false` por defecto pero no se muestra. "Foto" solo se guarda acá; se aplica al subir (feature 3).

## Casos

Se recorren sobre EV008 en el servidor de pruebas: la pantalla en Orca y las reglas por la API con la sesión de la pestaña. Datos de prueba con prefijo `ZZ`. Mensajes: los mismos de EV007.

| # | Regla | Dado | Cuando | Entonces | Resultado |
|---|---|---|---|---|---|
| 1 | R4 | la pantalla vacía | creo la agrupación "Identificación" | aparece en la lista y en el desplegable de agrupación del tipo | |
| 2 | R4 | un tipo sin agrupación | lo guardo | se rechaza: "Debe seleccionar una agrupacion de documento valida." | |
| 3 | R22 | un tipo "Cédula" que **no vence** | lo guardo | se guarda; fecha manual y días quedan vacíos aunque se hubieran escrito | |
| 4 | R22 | un tipo que vence con **fecha manual** | lo guardo | se guarda; el campo días queda deshabilitado | |
| 5 | R22 | un tipo que vence a los **30 días** del cargue | lo guardo | se guarda con 30 días | |
| 6 | R22 | un tipo que vence **sin regla** | lo guardo | se rechaza: "Debe indicar los dias de vencimiento despues del cargue cuando el documento expira y la fecha no es manual." | |
| 7 | R22 | un tipo que vence con fecha manual **y** días (forzado por API) | lo guardo | se rechaza: "No debe indicar dias de vencimiento cuando la fecha es manual." | |
| 8 | R22 | un tipo que vence a **-5** días | lo guardo | se rechaza: "Los dias de vencimiento no pueden ser negativos." | |
| 9 | R39 | un tipo que vence a **0** días | lo guardo | se guarda | |
| 10 | R38 | un tipo con firma **y** foto | lo guardo | se rechaza: "Un tipo no puede ser firma electronica y foto a la vez: la firma solo acepta PDF y la foto solo imagenes." | |
| 11 | R7 | un tipo marcado documento único | lo guardo | se guarda con la marca; no hay ninguna otra validación | |
| 12 | R5, R6 | un combo "Ingreso" | le agrego Cédula (obligatorio) y Hoja de vida (no obligatorio) | el detalle del combo muestra los dos con su obligatoriedad | |
| 13 | R5 | el combo "Ingreso" con Cédula | agrego Cédula otra vez | se rechaza: "Este documento ya esta agregado a este combo." | |
| 14 | R8 | un combo "para firmar" | agrego un tipo **sin** firma | no aparece en el desplegable; forzado por API se rechaza: "Un combo para firmar solo admite tipos de documento con firma electronica." | |
| 15 | R8 | un tipo con firma dentro de un combo para firmar | le quito la firma | se rechaza: "No puede quitar la firma electronica: el tipo esta en un combo para firmar." | |
| 16 | R37 | un combo con un tipo sin firma | lo marco "para firmar" | se permite, sin revisar los tipos | |
| 17 | S6 | un tipo activo | lo inactivo y cambio el interruptor a "Activos" | desaparece; con "Todos" vuelve a verse | |
| 18 | S7 | EV007 de ahorros | abro la pantalla y edito un tipo | funciona igual que antes | |

## Tareas

Orden vertical: script → clases → pantalla → prueba. Clases con [WFAGenerarDao](../../../guia/plantillas.md) a un directorio temporal; se difea contra ahorros y se pega lo que sirve.

- [x] **T1 (S1-S6). Script de tablas.** *Escrito (2026-11-07); falta que lo corra el usuario.* `scriptsSiian/nomina/scratch/archivos-nomina/1-catalogo/01-catalogo.sql`, copia de `ahorrosyaportes/entregable/archivos-ahorros/1-catalogo/01-catalogo.sql` con los nombres de nómina (4 tablas: agrupación, tipo, combo, detalle del combo; `CHECK` de vencimiento igual), más su reversión. Lo revisa y lo corre el usuario.
- [x] **T2 (S1-S6). Menú EV008 y permisos.** *Escrito (2026-11-07); falta que lo corra el usuario. Sus `SELECT` probados en `demo`: 1 menú y 10 roles.* `02-menu.sql`: `INSERT` en `generales_menu` (`EV008 - Documentos Expediente Virtual Nomina`, `~/DocumentoArchivoNomina`, mismo padre que EV002-EV005: 1902, a verificar en la base del servidor) y `generales_menurol` **una sola vez por rol**, copiando lo de EV007.
- [x] **T3 (S1-S6). Entidades y actores** en `Blip.Data/Nomina/`: `AgrupacionDocumentoArchivoNomina`, `DocumentoArchivoNomina`, `ComboDocumentoArchivoNomina`, `DocumentosArchivoNominaCombo` y sus `Actor`, registrados en `Data.csproj`. Se parece a: `Blip.Data/AhorrosyAportes/{AgrupacionDocumentoAhorro,DocumentoAhorro,ComboDocumentoAhorro,DocumentosAhorroCombo}`.
- [x] **T4 (S2-S5). Reglas en `Negocio/Nomina/`**: validar y normalizar el tipo (S3, R38, R39), tipo en combo para firmar (S5, R37) y duplicado en combo (S4). Se parece a: `Negocio/AhorrosyAportes/DocumentoAhorroValidacionActorNegocio.cs`, `DocumentosAhorroComboAsignacionActorNegocio.cs`, `DocumentoAhorroOpcionesActorNegocio.cs`.
- [x] **T5 (S1-S6). ViewModels y WebApis** (Get, Post, Put; sin Delete), el controlador solo llama a Negocio. Se parece a: `Blip.Entities/Ahorrosyaportes.ViewModels/` y `Controllers/WebApi/{AgrupacionDocumentoAhorro,DocumentoAhorro,ComboDocumentoAhorro}WebApiController.cs`.
- [x] **T6 (S1-S6). Pantalla EV008**: `DocumentoArchivoNominaController` (solo `Index`, `[Log(RequireAutenticacion = true, ValidaMenu = true, AlmacenaLog = true)]`) y `Views/DocumentoArchivoNomina/Index.cshtml`, copia de `Views/DocumentoAhorro/Index.cshtml` (ojo con la codificación: editar a nivel de bytes si es latin1).
- [x] **T7. Prueba**: build en 0 errores (hecho, 2026-11-07) y los 18 casos en Orca (pendiente: necesita T1 y T2 corridos), con capturas en `./evidencia/`.

## Log

- **L1 (2026-11-06).** Pedido: "ayudame a hacer lo de expediente virtual pero en nomina igual a cmo lo hicimos aca en D:\notas-siian\ahorrosyaportes\archivos-ahorros aca, pero para nomina". Área: [REQUERIMIENTO](../REQUERIMIENTO.md).
- **L2 (2026-11-07).** Decisiones del usuario: dueño = contrato; insertar pedido o combo no valida el único; R3 sin restricción; R25 y R36 fuera de alcance; nombres con `nomina`; la marca de documento único se deja sin efecto. Las notas de ahorros se corrigieron contra el código (documento único sin efecto, commit `9e1b92c44`).
- **L3 (2026-11-07).** "si en este caso si": se salta la explicación. T3-T6 hechos clonando los 23 archivos del catálogo de ahorros con renombres a nivel de bytes (`DocumentoAhorro` → `DocumentoArchivoNomina`, `ahorrosyaportes_*` → `nomina_*`, namespaces `Nomina`, `Negocio.Nomina`, `Entities.Nomina.ViewModels`). La vista sigue en latin1. 24 entradas en los 4 `.csproj`. MSBuild de `PruebaPostgreSQL.csproj`: 0 errores. **Siguiente:** el usuario corre `01-catalogo.sql` y `02-menu.sql` en la base del servidor, y después se recorren los 18 casos en Orca.
