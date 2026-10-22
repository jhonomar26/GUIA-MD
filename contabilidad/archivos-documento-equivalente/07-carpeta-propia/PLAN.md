# Plan: carpeta propia del documento equivalente

> [← README](./README.md) · Análisis: [ANALISIS.md](./ANALISIS.md) · Criterio: [ADR-003](../ADR-003.md)
>
> Ejecutar con `superpowers:executing-plans`. Los pasos usan `- [ ]`. No hay suite automatizada: la verificación es SQL, curl y pantalla.

**Meta:** los archivos del documento equivalente se guardan en su propia ruta (`~/Uploads/DocumentoEquivalente/`), y cada dueño (comprobante y documento equivalente) tiene una ruta principal que sale preseleccionada.

**Enfoque:** columna nueva `esdocumentoequivalente` en `generales_parametroscarpetavirtual`, disjunta de `escontabilidad`. Cada dueño tiene su lista de rutas, su validador y su acción de combo. La subida se divide en un método público por dueño sobre un núcleo privado común (ADR-003: sin `bool` ni ternarios para elegir dueño).

## Decisiones tomadas (2026-10-21)

- Ruta del documento equivalente: se marca con columna nueva `esdocumentoequivalente`.
- La ruta nueva se crea con script SQL, como la 7 de contabilidad (no desde la pantalla).
- Cada dueño tiene su principal (`esprincipal`). Hoy las 7 rutas tienen `esprincipal = false`, así que el script marca la 7 y la nueva.
- Lo ya subido no se mueve: el visor lee `archivo.Url`, no la ruta.

## Restricciones

- .NET 4.6.2, `.csproj` clásico. Ningún archivo nuevo en C#, así que no hay que registrar nada.
- Entidad y ViewModel de `ParametrosCarpetaVirtual` tienen constructor posicional: la columna entra al final, después de `essoporte`. Invocar `siian-plantillas-generadas` antes de tocarlos.
- Archivos `.cs` y `.cshtml` en ISO-8859-1: editar a nivel de bytes, no con Edit/Write (ver memoria "Edición latin1").
- Todo en español. Campos SQL con los estáticos de la entidad (`Campo`).
- Sin `finally { GeneralDao.Connection = null; }` en `Negocio/`. En WebApi sin `[LogApi]` sí va.
- Commit solo cuando se pida, sin firma de Claude.

## Foco de revisión (lo que el análisis no prueba y puede fallar)

1. Se manda la ruta 7 a un documento equivalente y viceversa: debe rechazar (E4).
2. Ruta del dueño con `esactivo = false`: no aparece en el combo y se rechaza al subir.
3. Dos principales del mismo dueño: marcar una en la pantalla debe desmarcar la anterior.
4. Archivo viejo del documento equivalente (en `Contabilidad/`): se visualiza y elimina igual (E5).
5. Sin ruta activa del dueño: mensaje claro, no se guarda archivo ni fila (E3).

## Archivos

| Archivo | Cambio |
|---|---|
| `scriptsSiian\contabilidad\scratch\archivos-documento-equivalente\4-carpeta-propia-documento-equivalente.sql` (+ `4-reversion-...sql`) | columna, ruta nueva, principales |
| `Blip.Data\Generales\ParametrosCarpetaVirtual.cs`, `ParametrosCarpetaVirtualActor.cs` | propiedad, `Campo`/`Tipo`, constructor, SELECT, INSERT, UPDATE |
| `Blip.Entities\Generales.ViewModels\ParametrosCarpetaVirtualViewModel.cs` | propiedad y constructor |
| `PruebaPostgreSQL\Controllers\WebApi\ParametrosCarpetaVirtualWebApiController.cs` | copiar el campo en `new ParametrosCarpetaVirtual(...)` (línea 48) y en las asignaciones (líneas ~73-98, 137-156) |
| `PruebaPostgreSQL\Views\ParametrosCarpetaVirtual\Index.cshtml` | columna y casilla junto a `Escontabilidad` (línea ~230) |
| `Negocio\Generales\ParametrosCarpetaVirtualActorNegocio.cs` | `VerificarParametroPrincipalPorModulo` con ramas para contabilidad y documento equivalente |
| `Negocio\Contabilidad\DocumentoContableArchivoActorNegocio.cs` | rutas y validadores por dueño, subida por dueño |
| `PruebaPostgreSQL\Controllers\Contabilidad\DocumentoContableArchivoController.cs` (línea 70) y `DocumentoEquivalenteArchivoController.cs` (línea 37) | llamar a su método de subida; fijar `ViewBag.AccionRutas` |
| `PruebaPostgreSQL\Controllers\WebApi\DocumentoContableArchivoWebApiController.cs` | acción `ObtenerRutasDocumentoEquivalente` |
| `PruebaPostgreSQL\Views\DocumentoContableArchivo\_SubirArchivo.cshtml` | combo con `LoadAction(accionRutas)` |
| `Negocio\Generales\BackupCarpetaVirtualActorNegocio.cs` (línea ~309), `Views\BackupCarpetaVirtual\FormBackup.cshtml` (línea ~389) | módulo "Documento equivalente" |

---

### Tarea 1: columna, ruta nueva y principales (SQL)

**Produce:** columna `esdocumentoequivalente boolean not null default false`; ruta con `esdocumentoequivalente = true`, `escontabilidad = false`, `esprincipal = true`; ruta 7 con `esprincipal = true`.

- [x] **Paso 1:** escribir `4-carpeta-propia-documento-equivalente.sql` (numeración de la carpeta: antes 10, 11, 12 y 13; hoy 1, 2, 3 y 4). Orden: `ALTER TABLE ... ADD COLUMN`, `INSERT` de la ruta (`rutacarpeta = '~/Uploads/DocumentoEquivalente/'`, `aliasruta = 'Documento equivalente'`, `esactivo = true`, resto de flags en `false`, `id = max(id) + 1`), `UPDATE ... SET esprincipal = true WHERE id = 7`. El script pasa por la revisión del usuario antes de correrse.
- [x] **Paso 2:** escribir `4-reversion-...sql` (borra la ruta nueva, quita la columna, deja `esprincipal` de la 7 en `false`).
- [x] **Paso 3 (2026-10-21: corrido por el usuario dos veces, verificado: ruta 8 creada una sola vez, 7 y 8 principales, las otras 6 sin cambio):** correr el script en la base de pruebas. Verificar: `select id, aliasruta, escontabilidad, esdocumentoequivalente, esprincipal from generales_parametroscarpetavirtual order by id` muestra la 7 y la nueva con `esprincipal = true`, y las otras cinco sin cambio.

### Tarea 2: columna en entidad, actor, ViewModel y pantalla de parametrización

**Consume:** columna de la tarea 1. **Produce:** `ParametrosCarpetaVirtual.Esdocumentoequivalente` (`bool`), disponible en el actor, el ViewModel y la pantalla.

> Pasos 1-3 ya estaban hechos: el usuario los commiteó con el generador en `32be254b1` (2026-10-21 17:03). El verificador de constructores da 0 hallazgos.

- [x] **Paso 1:** en `ParametrosCarpetaVirtual.cs`: propiedad `Esdocumentoequivalente`, `EsdocumentoequivalenteCampo`/`Tipo`, parámetro final `p_esdocumentoequivalente` en el constructor. Mismo cambio en el ViewModel.
- [x] **Paso 2:** en `ParametrosCarpetaVirtualActor.cs`: agregar la columna al SELECT (`CrearSelect`), al INSERT y al UPDATE.
- [x] **Paso 3:** en el WebApi controller, pasar el campo en `new ParametrosCarpetaVirtual(...)` y en cada asignación item↔itemBase.
- [x] **Paso 4 (hecho por Claude, sin commitear: columna y valor `false` al agregar fila):** en `Index.cshtml`, columna y casilla `Esdocumentoequivalente` junto a `Escontabilidad`. Sin exclusión entre casillas: marcarlas bien es responsabilidad de quien parametriza.
- [x] **Paso 5 (2026-10-21, exit 0):** compilar con `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug`. Esperado: sin errores (un error "no hay sobrecarga con N argumentos" delata un `new ParametrosCarpetaVirtual(...)` sin actualizar).
- [x] **Paso 6 (2026-10-21, solo lectura, captura en navegador como ADMINISTRADOR tras el script 5):** en la pantalla de parametrización, ver la ruta nueva con la casilla marcada. Se ve la columna "Documento equivalente" y la ruta `DocumentoEquivalente/` con esa casilla y "Es Principal" marcadas. **No verificado:** guardar un cambio sin perder el valor.

### Tarea 3: una principal por dueño en la pantalla de parametrización

**Produce:** `VerificarParametroPrincipalPorModulo(ParametrosCarpetaVirtual parametro)` devuelve la principal actual también para `Escontabilidad` y `Esdocumentoequivalente`, así el controlador (líneas 161-164) desmarca la anterior (foco 3).

- [x] **Paso 1 (hecho, sin compilar ni commitear):** agregar dos ramas `else if` iguales a las existentes en `ParametrosCarpetaVirtualActorNegocio.cs`.
- [x] **Paso 2 (2026-10-21, probado llamando `Post` y `VerificarYActualizar` del WebApi con la sesión del navegador, no clic en la grilla):** contable: ruta de prueba 9 principal → la 7 pasó a `false`, la 8 no cambió. Documento equivalente: ruta de prueba 10 principal → la 8 pasó a `false`, la 9 no cambió. Rutas de prueba borradas y principales 7 y 8 restauradas (quedaron con usuario ADMINISTRADOR y fecha de hoy en `fechamodificacion`). Original del plan: en la pantalla, marcar principal otra ruta contable (crear una de prueba) y confirmar que la 7 queda en `false`. Borrar la ruta de prueba.

### Tarea 4: rutas, validadores y subida por dueño

**Consume:** `Esdocumentoequivalente` de la tarea 2. **Produce**, en `DocumentoContableArchivoActorNegocio`:

- `ObtenerRutasContables()` — sin cambio (activas con `Escontabilidad`, principal primero).
- `ObtenerRutasDocumentoEquivalente(): List<ParametrosCarpetaVirtual>` — activas con `Esdocumentoequivalente`, principal primero, luego `Id`.
- `ValidarRutaContable(int idRuta)` — sin cambio de contrato.
- `ValidarRutaDocumentoEquivalente(int idRuta): ParametrosCarpetaVirtual` — rechaza con "No hay una ruta activa configurada para el documento equivalente." si la lista está vacía, y con "La ruta seleccionada no es una ruta activa del documento equivalente." si el id no está en ella.
- `SubirArchivoAPendienteContable(ArchivoContableUploadViewModel doc, int idDocumentoContable, string idUsuario, string usuario)` y `SubirArchivoAPendienteEquivalente(ArchivoContableUploadViewModel doc, int idDocumentoEquivalente, string idUsuario, string usuario)`, ambos `(bool Exitoso, string Mensaje)`. Cada uno valida su ruta y llama al núcleo privado `SubirArchivoAPendiente(doc, idDocumentoContable, idDocumentoEquivalente, idUsuario, usuario, ruta)`, que es el cuerpo actual sin la línea de `ValidarRutaContable`.

- [x] **Paso 1 (2026-10-21):** implementar lo anterior. Primero se valida la ruta y luego se toca el archivo, para que E3 y E4 no dejen nada guardado.
- [x] **Paso 2 (2026-10-21):** cambiar los dos controladores MVC para llamar a su método (`DocumentoContableArchivoController.cs:70`, `DocumentoEquivalenteArchivoController.cs:37`).
- [x] **Paso 3 (2026-10-21, exit 0):** compilar. Esperado: sin errores.

### Tarea 5: combo de rutas por dueño

**Consume:** `ObtenerRutasDocumentoEquivalente()`. **Produce:** acción WebApi `ObtenerRutasDocumentoEquivalente` con la misma forma que `ObtenerRutasContables` (`Id`, `Nombre`, `Esprincipal`); `ViewBag.AccionRutas`.

- [x] **Paso 1 (2026-10-22):** agregar la acción en `DocumentoContableArchivoWebApiController`, copiando el patrón de `ObtenerRutasContables` (con su `finally`).
- [x] **Paso 2 (2026-10-22):** `DocumentoContableArchivoController` fija `ViewBag.AccionRutas = "ObtenerRutasContables"`; `DocumentoEquivalenteArchivoController`, `"ObtenerRutasDocumentoEquivalente"`.
- [x] **Paso 3 (2026-10-22):** en `_SubirArchivo.cshtml`, `string accionRutas = ViewBag.AccionRutas;` y `.LoadAction(accionRutas)`. La preselección de la principal ya existe en el JS (líneas 154-162).
- [x] **Paso 3b (2026-10-22, aviso visto con la ruta 8 sin principal: no preselecciona):** en el JS de preselección (`_SubirArchivo.cshtml`, líneas 154-162) quitar el respaldo `|| rutas[0]`: si ninguna ruta es principal, no se selecciona nada y se muestra un aviso (`DevExpress.ui.notify`, tipo `warning`): "No hay ruta principal configurada, seleccione una". No bloquea la subida. Cambia el comportamiento actual del comprobante (hoy elige la primera), por eso el script de la tarea 1 marca la 7 como principal.
- [x] **Paso 4 (2026-10-22: E1, E2, E4, aviso y subida/borrado probados con navegador por Claude; el usuario ya había probado lo de rutas, E3 incluido):** compilar y probar en pantalla (E1, E2, E3, E4). Probar también el aviso: quitar `esprincipal` a la ruta del dueño y recargar. Con curl a `ObtenerRutasDocumentoEquivalente`: lista solo la ruta nueva. Subir a un documento equivalente: el archivo cae en `~/Uploads/DocumentoEquivalente/`; a un comprobante, en `Contabilidad/`. Desactivar la ruta nueva: el combo sale vacío y subir se rechaza sin crear fila en la tabla de archivos.
- [x] **Paso 5 (2026-10-22, solo por código: no hay datos viejos para probarlo en pantalla; visualizar y eliminar leen `archivo.Url` y las validaciones de ruta solo corren al subir):** E5: abrir y eliminar un archivo subido antes de la feature en un documento equivalente. Funciona igual.

### Tarea 6: backup

**Produce:** módulo "Documento equivalente" en el backup de carpetas virtuales (E6).

- [x] **Paso 1 (2026-10-22):** en `FormBackup.cshtml` agregar `{ Name: 'Modulo - Documento equivalente', Campo: 'esdocumentoequivalente' }` a la lista.
- [x] **Paso 2 (2026-10-22):** en `BackupCarpetaVirtualActorNegocio.cs` agregar la rama `campoEsCarpetaVirtual.Contains("documentoequivalente")` con el mismo filtro que contabilidad (`Esdocumentoequivalente && Esactivo && Idcredencialesftp == null`, principal primero) y `modulo = "BKDEQ"`. Verificar que ninguna rama anterior capture ese texto.
- [x] **Paso 3 (2026-10-22, exit 0; `BKDEQ_20261022_20261022.rar` con el archivo de `DocumentoEquivalente/`, rar y archivo de prueba borrados):** compilar y correr un backup del módulo. Esperado: el `.rar` `BKDEQ_...` contiene `~/Uploads/DocumentoEquivalente/`.

---

## Revisión contra el análisis

| Regla | Tarea |
|---|---|
| 1. Ruta por dueño | 4, 5 |
| 2. Sin ruta, no se sube | 4 |
| 3. Lo ya subido no se mueve | 5 (paso 5) |
| 4. Contable no cambia | 4, 5 (E2) |
| 5. Backup | 6 |

## Hallazgos fuera de alcance (para comentar; no se tocan sin tu visto bueno)

Encontrados el 2026-10-21 al ver qué hacen otros módulos con la ruta principal. Cada uno se decide aparte: arreglarlo aquí, en otra feature, o dejarlo.

1. **Créditos ignora la principal y falla sin mensaje.** `CargaArchivosActorNegocio.SubirArchivoFormatoPersonalizado` (línea 492) toma la primera ruta de crédito con `FirstOrDefault()`, sin mirar `esprincipal`. Si no hay ninguna, la línea 499 lanza `NullReferenceException`. Arreglo viable: ordenar por principal primero y lanzar un mensaje claro. Cambia créditos.
2. **Pagaré ordena la principal al final.** `CargaArchivoPagareActorNegocio.cs:40` usa `OrderBy(x => x.Esprincipal)` (ascendente), mientras el resto usa `OrderByDescending`. Podría ser un error o intencional; falta confirmarlo.
4. **La pantalla de parametrización no guarda `Escontabilidad`, `Esgarantias` ni `Essoporte`.** La grilla principal actualiza con `VerificarYActualizar` (`ParametrosCarpetaVirtualWebApiController.cs:121-176`), que no copia esos tres campos, ni al leer ni al guardar. Marcar o desmarcar esas casillas en la grilla no cambia nada en la base. Hay que confirmarlo probando en pantalla; el arreglo es agregar las líneas de copia. Además, solo `VerificarYActualizar` desmarca la principal anterior: `Post` y `Put` no lo hacen.
5. **El menú 1836 ("EV001 - Parametros Expediente Virtual") guarda la ruta en minúscula** (`~/ParametrosCarpetaVirtual/index`). El filtro compara con `=` contra `~/ParametrosCarpetaVirtual/Index` (`MenuRolActorNegocio.cs:49-56`), no coincide, y la pantalla da "Acceso Denegado" a todos los usuarios. Es la única ruta de menú en minúscula (44 llevan `Index` y 724 no llevan acción). Arreglo viable: corregir esa fila. Mientras tanto, el script 5 (`5-permiso-parametros-carpeta-virtual.sql`) da acceso al rol ADMINISTRADOR por `generales_funcionalidadrol` y no toca el menú.
3. **Pagaré, garantías y soporte pueden tener varias principales.** `VerificarParametroPrincipalPorModulo` solo desmarca la anterior en terceros, crédito, CRM y CRM detalle. Esta feature le agrega contabilidad y documento equivalente.

## Cierre (2026-10-22)

Tareas 1 a 6 hechas y probadas en el servidor de pruebas (SQL, navegador y backup real). Quedan fuera:

- **E5** (abrir y eliminar un archivo viejo de `Contabilidad/` desde un documento equivalente): sin datos para probarlo en pantalla; verificado por código (visualizar y eliminar leen `archivo.Url`).
- **Revisión final de código**: el agente revisor no pudo leer el árbol; no se hizo.
- **Hallazgos fuera de alcance** (sección anterior): sin decidir.
