# Bitácora de la remodelación

> Evidencia y decisiones de cada tarea del [`PLAN.md`](./PLAN.md). El plan dice **qué** se hace; aquí queda **cómo salió**: qué se probó, qué se decidió y por qué. Las entradas se agregan, no se reescriben. Todas las fechas son 2026-10-27 salvo que se indique otra.

---

## Etapa 1: subir un archivo

### T1.1 Pendientes según la regla de crédito (S1)

**Evidencia**
- Build 0 errores.
- La consulta generada corre en `pg-demo`: comprobante 168816 con 14 pendientes, 168815 con 8.
- Las dos rutas del WebApi responden 401 sin sesión (existen); una inexistente responde 404.

**Pendiente:** la prueba S1 con los cuatro pedidos del caso. Bloqueada hasta T1.3: en `demo` el puente y `archivocontable` tienen 0 filas, no hay pedido con archivo para probar. Los pedidos se eligen con `pg-demo`.

### T1.2 Rutas (S2)

**Decisión (corrección del usuario):** nada de lógica en controladores. Frente a la versión vieja (`7be4d590c^`, líneas 167-216), la proyección (`Id`, `Nombre`, `Esprincipal`) va en Negocio (`ObtenerOpcionesRutasContables` / `...DocumentoEquivalente` sobre un `CrearOpcionesRuta` privado) y devuelve `RutaAlmacenamientoViewModel`. El WebApi solo llama y responde, sin `finally` (tiene `[LogApi]`).

**Evidencia**
- Build 0 errores; las dos rutas responden 401 sin sesión.
- En `demo`: contable = ruta 7 "Contabilidad" (principal); equivalente = ruta 8 "Documento equivalente", **no principal**. La pantalla del equivalente va a mostrar el aviso "No hay ruta principal configurada": es lo que dice S2, y se arregla marcándola como principal en la configuración.

**Pendiente:** prueba S2 con sesión (junto con T1.3).

### T1.3 Subir (S3, S4)

**Qué se hizo en `Negocio`:** se descomentó y adaptó `SubirArchivoAPendiente…`. Valida el pedido con la regla de T1.1. Guarda un `ArchivoContable` (`Esactivo = true`, `Eseliminado = false`, descripción = observación, `Idcredencialesftp` si es remoto) con `ArchivoContableActor.Insert`, y después el puente `new DocumentoContableArchivo(0, idSolicitado, idArchivo)`. Se quitó `RegistrarArchivoCargado`.

**Decisiones**
- **Documento único (S4): no se codifica.** Lo cubren la regla de tipo único al pedir y la validación S1 al subir. Se construyó `InactivarArchivosDelPedido` y se quitó por ser inalcanzable.
- El archivo huérfano si falla el registro y la carrera de dos subidas simultáneas **se ignoran por ahora** (igual que crédito).
- El nombre del archivo lleva el id del pedido (`-DC{idpedido}`), no el del archivo, que aún no existe.

**Evidencia:** código de las 4 primeras casillas; build 0 errores; `SubirArchivo` responde 302 (login) en los dos controladores (`DocumentoContableArchivoController:62` y `DocumentoEquivalenteArchivoController:29`).

**Pendiente:** prueba con sesión (S3 válido + cada rechazo, S4).

### T1.4 Ver archivo (S5)

**Decisión:** una sola acción `DocumentoContableArchivoController.Visualizar(idarchivo, iddocumento?, iddocumentoequivalente?)`. Llega exactamente uno de los dos ids; si no, se rechaza. Cada `Index` fija `ViewBag.UrlVisualizar` con su dueño y `_GestionDocumentos.cshtml` le agrega `&idarchivo=`. También se rechaza un archivo `Eseliminado`. (La decisión de T1.5 unificó después todo el punto de entrada y reemplaza a esta.)

**Evidencia:** build 0 errores; la acción responde 302 a Login sin sesión con los tres formatos de URL.

**Pendiente:** abrir un archivo propio y uno de otro dueño; en `demo` no hay archivos hasta T1.3.

---

## Etapa 1.5: una responsabilidad por clase

### T1.5 Separar `DocumentoContableArchivoActorNegocio` (S12)

**Cómo quedaron las clases**
- `DocumentoContableArchivoActorNegocio`: solo el comprobante (pendientes, vencidos, rutas, subir, ver archivo). Siguieron aquí hasta T3.1 `ObtenerArchivosEliminadosPorConstancia`, los permisos de eliminar y `EliminarArchivos` (este último ya se movió, ver T3.1).
- `DocumentoEquivalenteArchivoActorNegocio` (nueva): los mismos métodos para el equivalente.
- `ArchivoContableReglasActorNegocio` (nueva): extensiones y tipos permitidos, `CalcularFechaVencimiento`, nombre del archivo, fecha del sistema, completar extensiones y nombre original. Sin dueño.
- `ArchivoContableAlmacenamientoActorNegocio` (nueva): guardar el físico en local o FTP y registrarlo (`SubirArchivoLocal`, `SubirArchivoRemoto`, `CrearClienteFTP`), opciones de ruta y `LeerArchivo`. Sin dueño. El borrado del físico nació en T3.1.
- `ArchivoContableSubidaActorNegocio` (nueva, no estaba en el plan): el flujo de subida que comparten comprobante y equivalente; el dueño y la ruta los fija quien llama.

**Decisión: el WebApi no se parte por dueño.** Un solo punto de entrada que recibe los dos ids y despacha `ArchivoContableDuenoActorNegocio`. Se unificaron `ObtenerSolicitadosPendientes`, `ObtenerRutas`, `GetPorDocumento` (cargados), `Visualizar` y `SubirArchivo`. La vista ya no usa `ViewBag.Accion*`. `Data` de pendientes y vencidos se queda con un método por dueño (ADR-003, ver ADR-002). El permiso de eliminar y el popup de eliminar usan el mismo patrón. Reemplaza la decisión de T1.4 y la de las dos acciones `Visualizar`. `DocumentoEquivalenteArchivoController` llegó a llamar a la clase del equivalente, pero con esta decisión `ArchivoContableDuenoActorNegocio` despacha.

**Evidencia:** 2 tandas, build 0 errores tras cada una; `Visualizar` de los dos dueños responde 302 a Login sin sesión. Cada `.cs` nuevo se registró en `Negocio.csproj`; se editó en latin1 a nivel de bytes.

**Pendiente:** prueba S12 y repetir S1-S5.

---

## Etapa 2: Cargados y Vencidos

Sin notas: T2.1 y T2.2 cerradas por el usuario.

---

## Etapa 3: eliminar

### T3.1 Eliminar y recrear (S8, S9)

**Qué se hizo**
- `EliminarArchivos` salió de `DocumentoContableArchivoActorNegocio` a la clase nueva `ArchivoContableEliminacionActorNegocio` (sin dueño). Una constancia, cada archivo `Eseliminado = true` con `Idconstanciaeliminacion`, borrado del físico y volumen recalculado. Ya no usa `DocumentoContableCargadoActor`, `DocumentoContableEliminadoActor` ni el `Update` del pedido.
- Recrear (ADR-001): descripción `""`, `Esobligatorio = true`, `Esactivo = true`, mismo dueño, tipo y tercero.
- Validación del dueño (H3): `ValidarArchivosEliminables` vive ahora en `ArchivoContableDuenoActorNegocio`; además rechaza archivos ya eliminados. Se valida todo antes de abrir la transacción.
- WebApi: `EliminarArchivos` en el mismo controlador (`7be4d590c^`, líneas 113-140) con el patrón único. El cuerpo trae `ids`, `observacion`, `recrear`, `iddocumento` e `iddocumentoequivalente`. Responde `ResultadoEliminacionArchivosViewModel` (`success`/`message`) y el popup no cambia.

**Decisiones**
- El borrado físico a mitad de falla queda como crédito (la base se revierte, los físicos ya borrados no vuelven). El usuario lo confirmó: la lógica se toma de crédito, el cómo se puede mejorar.
- Se rechaza un archivo ya eliminado en la selección (antes se saltaba en silencio).

**Evidencia**
- Build 0 errores; `POST EliminarArchivos` responde 401 sin sesión (existe).
- Permiso R14 confirmado en `demo`: funcionalidades 145 (contabilidad) y 149 (equivalente) con su acción activa. Se valida por ruta, sin acción de controlador: no hizo falta crear nada.

**Error encontrado en la prueba del usuario (2026-10-28):** "Debe indicar el comprobante o el documento equivalente, pero no ambos". Causa: el popup manda `iddocumento` / `iddocumentoequivalente` y la clase `EliminarArchivosRequest` tenía `IdDocumentoContable` / `IdDocumentoEquivalente`; el binding JSON solo ignora mayúsculas, no cambia nombres, así que los dos llegaban `null`. Arreglo: las propiedades pasaron a `Iddocumento` e `Iddocumentoequivalente`. Lección: antes de anotar "el popup ya lo manda así", comparar los nombres con la clase.

**Pendiente:** prueba S8 y S9 con sesión y archivos (junto con T1.3). Falta ver con "Sí" y con "No".

**Hecho:** README del área, DP3 marcada como superada.

---

## Etapa 4: firma

### T4.1 Firma sobre el archivo contable (S10)

**Evidencia:** build de Negocio 0 errores. `SIIAN.VozData/Handlers/FirmarDocumentoCarpetaVirtualHandler.cs:122` quedó sin cambios: ya recibe `archivoContable.Id` y la FK de `firmas_firmaarchivocontable` ya apunta a `contabilidad_archivocontable`.

**Decisión del usuario:** no se firma el archivo de un pedido retirado ni un archivo eliminado/inactivo; se lanza un mensaje claro ("No puede firmar este documento porque ...").

**Hallazgo fuera de alcance:** `ReemplazarRemoto` / `ReemplazarLocal` siempre devuelven `false`.

**Pendiente:** prueba S10 con sesión (en `demo` no hay archivos hasta T1.3).

---

## Pruebas de backend en el comprobante 168819 (2026-10-28, dev)

Detalle y casillas en [`PRUEBAS.md`](./PRUEBAS.md). Se probó contra el servidor con `fetch` (sesión de Orca) y se comparó con `pg-demo`; no se vio la pantalla.

**Pasó:** rechazos de subida (observación vacía, `.exe`, 0 bytes, pedido con archivo, pedido de otro dueño), subida válida (Pendientes 1→0, Cargados 2→3, pedido intacto), eliminar con "No", con "Sí" y con dos archivos (una constancia, pedidos nuevos con descripción vacía y obligatorio), rechazo de archivo ajeno, ya eliminado, observación corta y petición sin dueño.

**Hallazgos (en revisión; el usuario ya corrigió algunos, no re-verificado):**
- Pedido inexistente, vacío o de otro dueño responde "La secuencia no contiene elementos" (excepción cruda de `.First()` en `ValidarDocumentoSolicitadoYTipo`).
- Pedido cuyo archivo fue eliminado responde "ya tiene un archivo cargado": rechaza bien, pero el texto confunde.
- El archivo 13 (pedido 83) no es de este comprobante; no lo creó esta prueba.

**No verificado:** pantalla, 1.5, 1.6, 3.1 (permiso R14), P4 (equivalente), 5.1/5.2, P6, contenido de constancias, vigencia del vencimiento del tipo 2.

### Segunda tanda (2026-10-28): equivalente 1054, fecha manual, retiro y pantalla

Detalle en [`PRUEBAS.md`](./PRUEBAS.md). Todo contra el servidor con `fetch`; el pedido 90 (tipo 4, fecha manual) se creó por `VistaDocumentoContableSolicitadoEstadoWebApi/Post`.

**Pasó:** subida, eliminar con "No" y con "Sí" en el equivalente; cruces de dueño (subir, eliminar, ver); fecha manual (R8); retirar y reactivar un pedido (S6); encabezados de los cuatro grids.

**Hallazgos:**
- Corrección: el "pedido ajeno" de la primera tanda (id 1) no existía; con uno real el mensaje es claro. El mensaje crudo "La secuencia no contiene elementos" queda solo para pedido vacío o inexistente.
- Corrección: 1.6 sí se valida en el servidor (sin ruta, 99999 y 0 rechazan). La ruta de otro dueño se rechaza ("La ruta seleccionada no es una ruta contable activa.") antes que el pedido de otro dueño; el orden de las validaciones no es un defecto, pero conviene saberlo al probar.
- El archivo 13 ya estaba eliminado (constancia 301).

**No verificado:** 3.1 (permiso), 6.1 (firma), 6.3 (Vencidos con fecha pasada; `pg-demo` es de solo lectura), popups en pantalla.
