# Plan — Carga de documentos en comprobantes contables igual a crédito

> **Reglas vigentes:** [`ciclo-documentos/ANALISIS.md`](../ciclo-documentos/ANALISIS.md). La tabla R1-R14 de abajo queda como historia.

> Decisiones de negocio: [`ANALISIS.md`](./ANALISIS.md). Detalle anterior: [`PLAN.anterior.md`](./PLAN.anterior.md). Tareas técnicas: [`TAREAS.md`](./TAREAS.md).

## Qué se hace

Las pantallas de **solicitud** (`Views/DocumentoContableCombo/Index.cshtml`) y **carga** (`Views/DocumentoContableArchivo/Index.cshtml`) de un comprobante contable funcionan como las de crédito. Si a contabilidad le falta algo, se ajusta la base. Se prueba sobre el comprobante **168815** de demo.

## Reglas

| # | Regla |
|---|---|
| R1 | Un combo agregado no se quita; los documentos no deseados se inactivan uno por uno. Desde solicitud no se borra nada |
| R2 | Solo se agrega un combo activo. Como en crédito, el mismo combo se puede agregar más de una vez ([ADR-001](./ADR.md)) |
| R3 | Cada documento copia el "obligatorio" del combo; los agregados a mano arrancan obligatorios. Solo informa (asterisco), no bloquea |
| R4 | Cualquier documento pendiente se puede cargar, sin paso de "marcar" |
| R5 | Un documento tiene una carga activa. **Si es único se puede volver a cargar y el archivo anterior queda inactivo** (como crédito, con función propia, sin tocar crédito). Los no únicos rechazan la segunda carga |
| R6 | Extensiones: foto = solo imágenes; si no, la lista general. Las arma el servidor y se validan en pantalla y servidor. Firma queda fuera |
| R7 | Solo se guarda en rutas activas y contables; el servidor rechaza otras |
| R8 | Fecha manual obligatoria. "Vencido" no se guarda: se calcula en la consulta con un único `CASE` |
| R9 | Eliminar pide observación y si se recrea. Sí: el viejo queda ELIMINADO y se crea uno nuevo pendiente. No: queda eliminado e inactivo |
| R10 | Cargar en contabilidad nunca cambia archivos de crédito |
| R11 | Un tipo único no se repite en el comprobante mientras haya uno activo no eliminado. Agregar a mano exige comprobante guardado y tipo activo |
| R12 | El estado (PENDIENTE, CARGADO, ELIMINADO) lo pone el servidor, nunca la pantalla |
| R13 | Como en crédito: si el comprobante ya tiene **algún documento solicitado** (de un combo o agregado a mano), agregar otro combo exige el permiso "Agregar Mas Combos Documento Contable". Sin el permiso, la pantalla bloquea el selector y el botón, y el servidor lo rechaza. Agregar un combo es todo o nada ([ADR-001](./ADR.md)) |
| R14 | Como en crédito: eliminar un documento cargado exige el permiso "Eliminar Documentos Cargados Contabilidad". Sin el permiso no se ve el botón y el servidor lo rechaza |

## Fases

| Fase | Entrega                                                                                                                                                                                | Estado                                                          |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| F0   | Datos de prueba en demo                                                                                                                                                                | ✅ Cerrada (commits 0261e43, befae91, 8b6d593, ce574b5, ccedea7) |
| F1   | Base y servidor: obligatorio, combos, carga sin marcar, sin borrado, reemplazo de único                                                                                                | ✅ Cerrada (commits 0261e43, befae91, 8b6d593, ce574b5, ccedea7) |
| F2   | Solicitud: encabezado, agregar combo con confirmación, grillas sin borrar, nombres resueltos, exportar                                                                                 | ✅ Cerrada (commits 0261e43, befae91, 8b6d593, ce574b5, ccedea7) |
| F3   | Formulario de carga: ruta, extensiones, fecha manual, único/obligatorio visibles, selector de pendientes (más únicos cargados), botón bloqueado al subir, quitar la función de crédito | ✅ Cerrada (commits 0261e43, befae91, 8b6d593, ce574b5, ccedea7) |
| F3.1 | Combos como crédito: el mismo combo se repite y el permiso se pide si ya hay documentos (R2, R13, ADR-001). Script de base que va a producción                                         | ⬜                                                               |
| F4   | Pestañas Cargados, Cargados (Remoto), Pendientes, Vencidos; ver archivo; exportar; eliminar con "¿recrear?"                                                                            | 🟡 Código hecho y compila; falta probar en la app (Task 6)                                                               |
| F5   | Regresión, entregable de scripts, merge, producción, `IMPLEMENTACION.md`, limpiar datos de prueba                                                                                      | ⬜                                                               |

Por fase: implementar, build sin errores y sin tildes rotas, probar en la app, y commit solo cuando se pida.

### Listo cuando
- **F0:** foto guardada y una ruta contable activa (ya existe la id 7).
- **F1:** combo inactivo o repetido se rechaza; un segundo combo sin permiso se rechaza y con permiso entra; subir sin marcar funciona; segunda carga a un no único se rechaza; a un único deja la primera inactiva.
- **F2:** el encabezado y las grillas coinciden con la base; cancelar no crea nada; no hay forma de borrar.
- **F3:** solo rutas contables activas; ruta o extensión no permitida se rechaza también por petición directa; un eliminado no sale en el selector; subir un único no cambia archivos de crédito.
- **F3.1:**
  - Un comprobante sin documentos recibe su primer combo sin el permiso.
  - Si ya tiene documentos, aunque sean agregados a mano, y el usuario no tiene el permiso, la pantalla no deja elegir combo y una petición directa se rechaza.
  - Con el permiso, el mismo combo entra dos veces: sus documentos no únicos se duplican y los únicos que ya están se saltan.
  - Si algo falla a mitad, no queda nada a medias.
- **F4:** cada archivo sale en su pestaña; Vencidos coincide con el estado visible; eliminar con "sí" deja uno eliminado y uno nuevo pendiente.
- **F5:** en producción y `IMPLEMENTACION.md` escrito.

## Ramas y scripts

- Las ramas `-b` y `-c1` apuntan hoy al mismo commit (`befae9145`) y no existe `-a`: F1 y F2 viajan juntos en commits ya hechos. Cómo partir los PRs se decide en F5.
- Scripts en `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\`: `2-expediente-virtual-carga.sql` (renombra la columna; es lo único que va a producción) y `pruebas-expediente-virtual-carga.sql` (verificación, foto "antes", datos de prueba, limpieza; solo demo).
- Se despliegan juntos script y código: el código viejo no encuentra la columna renombrada.
- F3.1 lleva su propio script, `4-combos-repetidos-documento-contable.sql` (permite repetir un combo en un comprobante). Va a producción junto con el código de F3.1.

## Decisiones

- Replicar crédito; si falta algo, se ajusta la base.
- "Seleccionado" se renombró a "obligatorio" (nadie lo había usado en producción).
- Firma y formatos personalizados al agregar combo quedan fuera. De los permisos por función solo entra "Agregar Mas Combos" (R13), porque crédito lo tiene.
- Combos repetidos y permiso contado por documentos, igual que crédito: [ADR-001](./ADR.md). Reemplaza lo que decían antes R2 y R13: no repetir combos y contar solo combos.
- Selección de varios combos a la vez: fuera, crédito tampoco la tiene. "Documento único" al agregar combo ya está cubierto por R11 (crédito ni lo revisa).
- El tipo de documento solo se edita en filas nuevas de la solicitud.
- Descartado: geolocalización, "para convenios", "días tras fin de crédito".

## Cuidados

- Las dos vistas y algunos archivos del servidor son **latin1**: editar por bytes y revisar con `git diff --stat` y `rg "(?-u:\xEF\xBF\xBD)"`.
- Demo no tiene credenciales FTP: las pruebas FTP necesitan un servidor real.
- La fecha del sistema de demo es 2025-10-16 y sale de la primera compañía; para probar Vencidos hay que forzar un vencimiento.
- Antes de codificar: skills `siian-actor-dapper-metodos`, `siian-plantillas-generadas`, `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`. En SQL, campos estáticos de la entidad.
- Build: `MSBuild.exe PruebaPostgreSQL.sln -p:Configuration=Debug`.

## Preguntas abiertas

1. ¿Producción tiene una sola compañía y una ruta contable activa?
2. ¿Hay ambiente con FTP para probar?
3. ¿Cargados en solicitud muestra solo cargas activas?
4. ¿Los no únicos acumulan varias cargas como crédito, o siguen con una sola?

## Vuelta atrás

Revertir los PRs y volver a renombrar la columna a "seleccionado".

## Errores conocidos que crédito comparte (no se arreglan aquí)

El recién subido se identifica como "el último del usuario"; al eliminar varios los errores se tragan; reemplazar un único no es transaccional; ver un archivo no revisa de quién es. (Agregar un combo sí pasa a ser transaccional con R13.)
