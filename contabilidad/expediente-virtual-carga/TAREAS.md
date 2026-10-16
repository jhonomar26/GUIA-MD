# Tareas — Agregar más combos en comprobante contable (R13)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un comprobante contable acepta un solo combo, salvo que el usuario tenga la acción "Agregar Mas Combos" (igual que crédito), y agregar un combo queda en una sola transacción.

**Architecture:** Se replica el gate de crédito (`Negocio/Credito/ComboDocumentoCreditoActorNegocio.cs:52-61`) en un método nuevo de `Negocio/Contabilidad/`. El WebApi `PostConSolicitados` delega en ese método; las validaciones que hoy tiene (comprobante guardado, combo activo, combo repetido) se mueven ahí sin cambiar mensajes. El permiso se registra en base con el mismo formato que los otros 5 módulos (`generales_funcionalidad` + `generales_funcionalidadaccion`); la asignación a roles se hace desde la pantalla de funcionalidades existente.

**Tech Stack:** .NET 4.6.2, WebApi 2, Dapper, PostgreSQL, `Negocio.TransactionUtil.TransactionUtils.CrearTransaccion()`.

**Spec:** [`PLAN.md`](./PLAN.md) (regla R13) y [`ANALISIS.md`](./ANALISIS.md). Repo: `D:\rep1\SIIAN`, rama `feature/expediente-virtual-carga-c1`.

## Global Constraints

- Código, mensajes y nombres en español; clases/métodos PascalCase; parámetros `p_`/camelCase según SIIAN.
- `Negocio/` no importa Dapper ni toca `GeneralDao.Connection`.
- `catch (Exception) { throw; }` — nunca `throw ex;`.
- Archivo `.cs` nuevo → registrar `<Compile Include>` en `Negocio/Negocio.csproj`.
- Archivos latin1: antes de editar revisar encoding; tras editar `rg "(?-u:\xEF\xBF\xBD)" <archivo>` sin resultados.
- Commit solo cuando el usuario lo pida; mensaje `tipo: qué cambia`, sin Co-Authored-By.
- Sin suite de tests: verificación = build + pruebas manuales en demo sobre el comprobante **168815**.
- Build: `MSBuild.exe PruebaPostgreSQL.sln -p:Configuration=Debug`.

## Review Focus

1. Usuario sin permiso, comprobante que solo tiene documentos agregados a mano (sin combo) → **sí** puede agregar el primer combo (cuenta combos, no documentos; diferencia consciente con crédito). Prueba V5.
2. Usuario con la acción asignada pero el rol o la acción inactivos → se trata como sin permiso (lo resuelve la consulta existente, que filtra `esactivo`/`eshabilitado`). Prueba V6.
3. Combo repetido con permiso → sigue rechazado ("Este combo ya fue asignado..."). Prueba V4.
4. Falla a mitad de la inserción de solicitados → no queda el combo sin sus documentos (transacción). Prueba V7.
5. Combo cuyos documentos son todos únicos ya presentes → se agrega el combo sin documentos nuevos (comportamiento actual, se mantiene). Prueba V8.

---

### Task 1: Permiso en base de datos

**Files:**
- Modify: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\2-expediente-virtual-carga.sql` (agregar al final; es el script que va a producción)

**Interfaces:**
- Produces: funcionalidad con `ruta = '~/DocumentoContableCombo/AgregarCombo'`, `nombre = 'Agregar Mas Combos Documento Contable'`; acción `nombre = 'AgregarMasCombosDocumentoContable'`. Task 2 usa estos tres literales exactos.

- [x] **Step 1: Agregar el bloque idempotente**

```sql
-- Permiso "Agregar Mas Combos" para comprobantes contables (igual que credito, id 533)
INSERT INTO public.generales_funcionalidad (nombre, ruta, esactivo)
SELECT 'Agregar Mas Combos Documento Contable', '~/DocumentoContableCombo/AgregarCombo', true
WHERE NOT EXISTS (SELECT 1 FROM public.generales_funcionalidad
                  WHERE ruta = '~/DocumentoContableCombo/AgregarCombo'
                    AND nombre = 'Agregar Mas Combos Documento Contable');

INSERT INTO public.generales_funcionalidadaccion (idfuncionalidad, nombre, esactivo)
SELECT f.id, 'AgregarMasCombosDocumentoContable', true
FROM public.generales_funcionalidad f
WHERE f.ruta = '~/DocumentoContableCombo/AgregarCombo'
  AND f.nombre = 'Agregar Mas Combos Documento Contable'
  AND NOT EXISTS (SELECT 1 FROM public.generales_funcionalidadaccion a
                  WHERE a.idfuncionalidad = f.id AND a.nombre = 'AgregarMasCombosDocumentoContable');
```

- [x] **Step 2: Correr en demo dos veces y verificar**

Run (2ª vez debe insertar 0 filas):
```sql
SELECT f.id, f.nombre, f.ruta, a.id AS idaccion, a.nombre AS accion
FROM public.generales_funcionalidad f
JOIN public.generales_funcionalidadaccion a ON a.idfuncionalidad = f.id
WHERE f.ruta = '~/DocumentoContableCombo/AgregarCombo';
```
Expected: exactamente 1 fila.

---

### Task 2: Regla en Negocio + WebApi delgado

**Files:**
- Create: `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs` (namespace `Negocio.Contabilidad`; no se llama igual que la de Data para no confundir al buscar)
- Modify: `Negocio/Negocio.csproj` (registrar el archivo)
- Modify: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableComboWebApiController.cs:49-87`

**Interfaces:**
- Consumes: literales de Task 1; `FuncionalidadAccionActor.ObtenerPorIdUsuarioPorRutaFuncionalidadnombre(string idUsuario, string funcionalidad, string nombre)`; `DocumentoContableComboActor.ObtenerPorIddocumentocontable(int)`; `DocumentoContableComboActor.Insert(DocumentoContableCombo)`; `Data.Contabilidad.DocumentoContableComboActorNegocio.InsertarConDocumentosSolicitados(DocumentoContableCombo)`.
- Produces: `public static DocumentoContableCombo AgregarCombo(int idDocumentoContable, int idCombo, string idUsuario)` — lanza `Exception` con mensaje para el usuario si una regla falla.

- [x] **Step 1: Implementar `AgregarCombo` en el archivo nuevo** (`Esactivo` es `bool?`: se compara `== true`, como crédito)

Orden, todo dentro de `TransactionManager.ExecuteTransaction(() => { ... })` (abre una sola conexión dentro de la transacción; un `TransactionScope` suelto con Dapper abre una conexión por consulta y falla). El resultado se guarda en una variable de afuera porque el lambda es un `Action`:
1. Comprobante inexistente o `idDocumentoContable <= 0` → `"Primero debe guardar el documento contable."`
2. Combo inexistente o inactivo → `"El combo no existe o esta inactivo."`
3. `var combos = DocumentoContableComboActor.ObtenerPorIddocumentocontable(idDocumentoContable);` — si `combos.Any(c => c.Idcombo == idCombo)` → `"Este combo ya fue asignado a este documento contable."`
4. Gate: si `combos.Any()` y el usuario no tiene la acción `AgregarMasCombosDocumentoContable` activa (mismo `Where(x => x.Nombre == accion && x.Esactivo)` que crédito `:57`) → `"Ya ha sido agregado un combo para este comprobante"`.
5. `Insert` del combo + `InsertarConDocumentosSolicitados(nuevoCombo)`; retornar `nuevoCombo`.

Los tres literales del permiso como `private const string` en la clase, igual que crédito `:52-54`.

- [x] **Step 2: Reducir `PostConSolicitados`**

Mantener `PopulateObject` + `Validate`/`ModelState`. Reemplazar las validaciones e inserción por:
```csharp
try
{
    var nuevoCombo = Negocio.Contabilidad.DocumentoContableComboAsignacionActorNegocio.AgregarCombo(item.Iddocumentocontable, item.Idcombo, User.Identity.GetUserId());
    return Request.CreateResponse(HttpStatusCode.Created, new { nuevoCombo.Id, nuevoCombo.Iddocumentocontable, nuevoCombo.Idcombo });
}
catch (Exception ex)
{
    return Request.CreateErrorResponse(HttpStatusCode.BadRequest, ex.Message);
}
finally
{
    GeneralDao.Connection = null;
}
```
Agregar `using Microsoft.AspNet.Identity;`. La vista no cambia: ya muestra `xhr.responseJSON.Message`.

- [x] **Step 3: Build** (0 errores, sin caracteres rotos)

Run: `MSBuild.exe PruebaPostgreSQL.sln -p:Configuration=Debug`
Expected: `0 Error(s)`; `rg "(?-u:\xEF\xBF\xBD)"` sobre los archivos tocados sin resultados.

- [ ] **Step 4: Verificación manual en demo (comprobante 168815)**

Preparar: anotar los combos actuales con `SELECT * FROM contabilidad_documentocontablecombo WHERE iddocumentocontable = 168815;` y, para empezar limpio, usar un comprobante sin combos o limpiar con el script de pruebas.

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| V1 | Usuario sin la acción, comprobante sin combos | agrega combo A | se crea, con sus solicitados |
| V2 | Mismo usuario, comprobante con A | agrega combo B | error "Ya ha sido agregado un combo para este comprobante"; no hay fila nueva en combo ni en solicitados |
| V3 | Acción asignada a un rol del usuario (pantalla Funcionalidad Acción Rol) | agrega combo B | se crea |
| V4 | Con permiso | agrega A otra vez | error "Este combo ya fue asignado..." |
| V5 | Sin permiso, comprobante con solo documentos manuales | agrega combo A | se crea |
| V6 | Acción asignada pero `esactivo = false` en la acción del rol | agrega combo B | error del gate |
| V7 | Forzar falla en solicitados (p. ej. combo con un detalle cuyo tipo no existe, o romper temporalmente el insert en local) | agrega combo | no queda fila en `contabilidad_documentocontablecombo` |
| V8 | Combo cuyos tipos son únicos y ya están en el comprobante | agrega con permiso | se crea el combo, 0 solicitados nuevos |

- [ ] **Step 5: Commit (solo cuando el usuario lo pida)**

```bash
git add Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs Negocio/Negocio.csproj PruebaPostgreSQL/Controllers/WebApi/DocumentoContableComboWebApiController.cs
git commit -m "feat(contabilidad): permiso para agregar mas combos al comprobante"
```

---

### Task 3: Eliminar con "¿volver a solicitar?" (R9)

Crédito pregunta con un diálogo (`CargaArchivos/MostrarArchivos.cshtml:984-989`): sí → inserta una fila nueva pendiente; no → solo elimina. Contabilidad eliminaba y marcaba ELIMINADO sin recrear ni preguntar.

**Files:**
- Modify: `Blip.Entities/Contabilidad.ViewModels/EliminarArchivosRequestViewModel.cs` (+ `bool Recrear`)
- Modify: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs` (`EliminarArchivos` pasa `request.Recrear`)
- Modify: `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs` (`EliminarArchivos(int[] ids, string idUsuario, string observacion, bool recrear = false)`)
- Modify: `PruebaPostgreSQL/Views/DocumentoContableArchivo/_PopupObservacion.cshtml` (latin1, editado por bytes)

- [x] **Step 1:** con `recrear = true`, tras marcar el solicitado ELIMINADO se inserta uno nuevo con el mismo comprobante, combo de origen, tipo, descripción y obligatorio, activo y PENDIENTE.
- [x] **Step 2:** el popup, tras validar la observación, pregunta "¿Desea volver a solicitar...?" y envía `recrear` según la respuesta.
- [x] **Step 3: Build** (0 errores, sin caracteres rotos).
- [ ] **Step 4: Verificación manual**

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Documento CARGADO | elimina y responde **Sí** | el viejo queda ELIMINADO (con su archivo e historial) y aparece uno nuevo PENDIENTE con el mismo tipo y obligatorio |
| E2 | Documento CARGADO | elimina y responde **No** | queda ELIMINADO, sin fila nueva |
| E3 | Tipo **único** cargado | elimina con **Sí** | no choca con R11 (el eliminado ya no cuenta) y el nuevo se puede cargar |
| E4 | Documento que vino de un combo | elimina con **Sí** | el nuevo conserva el combo de origen |

Limitación conocida (no se arregla aquí): el método traga los errores por archivo (`catch (Exception ex) { }`); si el insert del nuevo fallara, el archivo quedaría eliminado sin aviso.

---

### Task 4: Permiso para eliminar (R14)

Crédito, terceros, CRM y pagaré tienen un permiso "Eliminar Documentos Cargados ..." (crédito: funcionalidad 534). Contabilidad no tenía ninguno: cualquiera con acceso a la pantalla podía eliminar.

**Files:**
- Modify: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\2-expediente-virtual-carga.sql` (bloque idempotente al final)
- Modify: `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs` (`PuedeEliminarArchivos(string idUsuario)`; `EliminarArchivos` lo exige)
- Modify: `PruebaPostgreSQL/Controllers/Contabilidad/DocumentoContableArchivoController.cs` (`Index` pone `ViewBag.PuedeEliminarArchivos`)
- Modify: `PruebaPostgreSQL/Views/DocumentoContableArchivo/_GestionDocumentos.cshtml` (latin1; botón "Eliminar seleccionados" con `.Visible`)

**Interfaces:** funcionalidad `ruta = '~/DocumentoContableArchivo/BorrarDocumentosSeleccionados'`, `nombre = 'Eliminar Documentos Cargados Contabilidad'`; acción `EliminarDocumentosCargadosContabilidad`.

- [x] **Step 1:** bloque SQL agregado al script.
- [x] **Step 2:** servidor rechaza con "No tiene permisos para eliminar documentos" (mismo mensaje que crédito); la pantalla oculta el botón.
- [x] **Step 3: Build** (0 errores, sin caracteres rotos).
- [ ] **Step 4: Correr el bloque en demo** (solo el bloque nuevo) y asignar acción a un rol en "Rol Funcionalidad", igual que con "Agregar Mas Combos".
- [ ] **Step 5: Verificación manual**

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| P1 | Usuario **sin** la acción | abre la pantalla de carga | no ve "Eliminar seleccionados" |
| P2 | Usuario sin la acción | llama `EliminarArchivos` directo (petición manual) | `success = false`, "No tiene permisos para eliminar documentos"; nada cambia |
| P3 | Usuario **con** la acción | abre la pantalla y elimina | ve el botón y elimina normal (con la pregunta de volver a solicitar) |

---

### Task 5: Combos como crédito (F3.1, ADR-001)

Cambia lo que hicieron V4 y V5 de Task 2: un combo repetido ya **entra**, y si solo hay documentos agregados a mano, el combo **pide** el permiso. Crédito: `Negocio/Credito/ComboDocumentoCreditoActorNegocio.cs:55-61` no valida que el combo se repita, y su gate es `listaDocumentoCreditoTercero.Count > 0`.

**Files:**
- Create: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\4-combos-repetidos-documento-contable.sql` (script propio, no se mezcla con `2-`)
- Modify: `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs`
- Ya hecho sin commit: `Controllers/Contabilidad/DocumentoContableComboController.cs` (`ViewBag.PuedeAgregarCombo`) y `Views/DocumentoContableCombo/Index.cshtml` (latin1; `.ReadOnly`/`.Disabled` según el flag). No cambian: consumen `PuedeAgregarCombo`.

**Interfaces:**
- Consumes: `DocumentoContableSolicitadoActor.ObtenerPorIddocumentocontable(int)` (`Blip.Data/Contabilidad/DocumentoContableSolicitadoActor.cs:224`).
- Produces:
  - `public static bool TienePermisoAgregarMasCombos(string idUsuario)`.
  - `public static bool PuedeAgregarCombo(int idDocumentoContable, string idUsuario)`: verdadero si no hay solicitados o si el usuario tiene el permiso.

- [x] **Step 1: Script.** En demo, la UNIQUE es el único índice que cubre `iddocumentocontable` (verificado con `pg_indexes`). Se reemplaza por un índice simple:

```sql
-- Combos repetidos en un comprobante, igual que credito (ADR-001)
ALTER TABLE public.contabilidad_documentocontablecombo
    DROP CONSTRAINT IF EXISTS contabilidad_documentocontablec_iddocumentocontable_idcombo_key;
CREATE INDEX IF NOT EXISTS ix_contabilidad_documentocontablecombo_iddocumentocontable
    ON public.contabilidad_documentocontablecombo (iddocumentocontable);
```

- [x] **Step 2: Negocio.** En `AgregarCombo`:
  - Quitar el chequeo `combos.Any(c => c.Idcombo == idCombo)` y su mensaje "Este combo ya fue asignado...".
  - Reemplazar el gate por `if (!PuedeAgregarCombo(idDocumentoContable, idUsuario)) throw new Exception("Ya ha sido agregado un combo para este comprobante");`.
  - `PuedeAgregarCombo` usa `DocumentoContableSolicitadoActor.ObtenerPorIddocumentocontable(id).Any()` en lugar de los combos.
  - Si `DocumentoContableComboActor.ObtenerPorIddocumentocontable` queda sin uso en el método, se quita de ahí.
  - Se mantienen la transacción, el chequeo de combo activo y el salto de únicos (R11, en `InsertarConDocumentosSolicitados`).
- [ ] **Step 3: Build** en Visual Studio (MSBuild no está en el PATH de bash): 0 errores, y `rg "(?-u:\xEF\xBF\xBD)"` sin resultados en `Index.cshtml`.
- [ ] **Step 4: Correr el bloque del Step 1 en demo** y volver a consultar `pg_indexes`. Debe quedar la PK y el índice nuevo.
- [ ] **Step 5: Verificación manual (comprobante 168815)**

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| C1 | Sin permiso, comprobante sin documentos | agrega combo A | entra, con sus solicitados |
| C2 | Sin permiso, comprobante con solo un documento agregado a mano | abre la pantalla | selector de combo en solo lectura y botón deshabilitado; una petición directa a `PostConSolicitados` devuelve 400 "Ya ha sido agregado un combo para este comprobante" |
| C3 | Con permiso, comprobante con A | agrega A otra vez | entra: hay dos filas de A en combos, los no únicos aparecen duplicados y los únicos ya presentes no |
| C4 | Con permiso | agrega un combo inactivo (petición directa) | 400 "El combo no existe o esta inactivo." |
| C5 | Forzar falla en solicitados | agrega combo | no queda fila nueva en `contabilidad_documentocontablecombo` |

- [ ] **Step 6: Commit (solo cuando el usuario lo pida)**: `feat(contabilidad): combos repetidos y permiso por documentos como credito`

**Fuera:** `DocumentoContableComboActor.ObtenerPorIddocumentocontableIdcombo` se generó por la UNIQUE y no tiene usos. Queda como está: usa QueryFirst y no se rompe.

---

### Task 6: Pestañas de carga (F4)

Pestañas Cargados, Cargados (Remoto), Pendientes y Vencidos; ver archivo; exportar; Vencidos con el único `CASE` (R8). Eliminar con "¿recrear?" (R9) y su permiso (R14) ya están en Task 3 y 4.

**Files:**
- Modify: `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs` (latin1): `ObtenerVencidosPorIddocumentocontable(id, fechaSistema)` reutiliza `CrearCasoEstadoVisible()` en el WHERE.
- Modify: `Blip.Entities/Contabilidad.ViewModels/DocumentoVencidoViewModel.cs`: se quitan `Expira` y `EsFechaManual`, se agrega `Idarchivo`.
- Modify: `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs`: `VisualizarArchivo(int idArchivo)` solo abre archivos ligados a un comprobante contable.
- Modify: `PruebaPostgreSQL/Controllers/Contabilidad/DocumentoContableArchivoController.cs`: acción `Visualizar(idarchivo)`.
- Modify: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs`: `ObtenerPorDocumento(iddocumento, remoto)` filtra por `Idcredencialesftp`; `ObtenerVencidos` delega en la consulta nueva con la fecha del sistema de la compañía.
- Modify: `PruebaPostgreSQL/Views/DocumentoContableArchivo/_GestionDocumentos.cshtml` (latin1): 4 pestañas, grid de cargados generado en un bucle (local y remoto), botón "Ver" y exportar en los 4 grids.

- [x] **Step 1: Código** hecho; build de la solución con 0 errores.
- [ ] **Step 2: Verificación manual (comprobante 168815)**

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| T1 | Archivos cargados por ruta local | abre la pestaña Cargados | salen solo los locales; Cargados (Remoto) vacía |
| T2 | Archivo en ruta con FTP (necesita servidor real) | abre Cargados (Remoto) | sale ahí y no en Cargados |
| T3 | Archivo cargado | pulsa "Ver" | se abre; con un id de archivo de crédito por URL directa, el servidor lo rechaza |
| T4 | Documento cargado con vencimiento anterior a la fecha del sistema | abre Vencidos | aparece, y su estado en Solicitud dice VENCIDO |
| T5 | Documento vigente o eliminado | abre Vencidos | no aparece |
| T6 | Cualquiera de las 4 grillas | exporta | descarga xlsx, pdf o csv |
| T7 | Eliminar con "Sí" | confirma | uno ELIMINADO y uno PENDIENTE nuevo (E1 a E4 de Task 3) |

Las vistas Razor se compilan al abrirlas: el bucle de la grilla de cargados hay que verlo en la app.

---

## Fuera de alcance (igual que crédito o ya resuelto)

- Selección múltiple de combos: crédito tampoco la tiene.
- "Documento único inactiva otros": crédito no lo hace al agregar combo; contabilidad ya salta únicos repetidos y reemplaza el archivo al recargar (R5, R11).
- Tercero por combo, formatos personalizados autogenerados y bloqueo por etapa: no aplican a contabilidad.
