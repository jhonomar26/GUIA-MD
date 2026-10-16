# B2: permiso para agregar y editar documentos individuales — Plan de implementación

> **Historia.** Plan ejecutado (código en `44b917826`); las casillas sin tildar siguen pendientes. Vigente: [IMPLEMENTACION.md](./IMPLEMENTACION.md).

> **Para agentes:** SUB-SKILL REQUERIDA: superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans, tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** que agregar y editar un documento solicitado a mano en contabilidad exija un permiso propio, en la pantalla y en el WebApi.

**Arquitectura:** un script SQL crea la funcionalidad y la acción y la copia a los roles que ya tienen "Agregar Mas Combos". Un método de Negocio consulta el permiso (junto al de combos). El controlador de la pantalla lo pasa a la vista, que lo usa en `AllowAdding`/`AllowUpdating`; el WebApi `Post`/`Put` lo valida y responde 403.

**Stack:** .NET 4.6.2, MVC 5 + Web API 2, DevExtreme, PostgreSQL 11 (Npgsql 2.2.7).

**Spec:** [`ANALISIS B2.md`](ANALISIS%20B2.md), [`REQUERIMIENTO.md`](./REQUERIMIENTO.md).

## Restricciones globales

- `.csproj` clásico: no hay archivos `.cs` nuevos en este plan, así que no hay que registrar nada.
- Código, mensajes y textos en español.
- `catch (Exception) { throw; }`, nunca `throw ex;`.
- `Negocio/` no usa Dapper ni `GeneralDao.Connection`; solo llama a Actores.
- Archivos ISO-8859-1: `DocumentoContableCombo/Index.cshtml` lo es (el editor lo reporta). Verificar con `file` los demás antes de editar; si son Latin-1, editar a nivel de bytes para no romper tildes.
- `DocumentoContableSolicitadoWebApiController` no cierra la conexión a mano: lleva `[LogApi]` a nivel de clase y ese filtro ya la cierra. No agregar `finally`.
- Sin pruebas automáticas: cada tarea cierra con build + prueba manual Dado/Cuando/Entonces.
- Build: `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug` (o VS 2022). Esperado: 0 errores.
- Script SQL en `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\`, mismo estilo que `2-expediente-virtual-carga.sql`: sin `BEGIN/COMMIT`, idempotente, comentarios `--` cortos en español. El 8 está ocupado (`8-vista-archivos-eliminados-contabilidad.sql`): este es el **9**.
- Commits solo cuando el usuario lo pida; mensaje de una línea `tipo: qué cambia`, sin firma de autoría.
- Rama: la actual (`feature/contabilidad-detalle-constancia-eliminacion`) lleva B1. Confirmar con el usuario si B2 va en esa o en una rama aparte antes de la Tarea 1 (P2).

## Preguntas

| # | Pregunta (en términos de negocio) | Recomendación | Bloquea | Estado |
|---|---|---|---|---|
| P1 | Cuando alguien sin permiso intenta guardar, ¿el servicio responde "no autorizado" con un mensaje claro? | Sí, 403 con "No tiene permiso para agregar o editar documentos." | Tarea 2 | ✅ Sí (ANALISIS B2, regla 3) |
| P2 | ¿B2 va en la rama de B1 o en una nueva? | Nueva desde `master`, porque B1 y B2 no comparten código y así se revisan por separado | Tarea 1 | ✅ La misma rama, para no complicar (usuario, 2026-10-15) |
| P3 | ¿Qué roles reciben el permiso? | Los que hoy tienen "Agregar Mas Combos Documento Contable" activo | Tarea 1 | ✅ Sí (usuario, 2026-10-15) |

## Foco de revisión

1. **El permiso en SIIAN va por rol, no por usuario.** La consulta del permiso une usuario → rol → funcionalidad-rol → acción-rol. Copiar solo la fila de la acción no basta: hace falta también la fila que habilita la funcionalidad para el rol (Tarea 1, S1 y S3).
2. **Pantalla y servicio deben decidir lo mismo.** Si la vista oculta el botón pero el servicio no valida (o al revés), queda un hueco (Tarea 2, S3 y S4).
3. **Quién más llama a `Post`/`Put`.** Antes de cerrar, buscar otros llamadores del controlador (Tarea 2, S1). Si existe uno legítimo sin permiso (por ejemplo, un flujo automático), el guard va en el servicio, no en un llamador.
4. **Editar un documento que vino de un combo.** Con permiso nuevo, quien no lo tenga ya no puede editarlo, aunque antes sí (ANALISIS B2, regla 5). Es lo esperado, confirmarlo en la prueba M3.
5. **Sin el permiso, "agregar combo" sigue igual.** No se toca la regla del primer combo (Tarea 3, M4).

---

### Tarea 1: Script SQL del permiso

**Se parece a:** `2-expediente-virtual-carga.sql` (permiso "Agregar Mas Combos Documento Contable").

**Archivos:**
- Crear: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\9-permiso-documentos-individuales-contabilidad.sql`

**Interfaces:**
- Produce: funcionalidad `Agregar Documentos Individuales Documento Contable`, ruta `~/DocumentoContableCombo/AgregarDocumentoIndividual`, y acción `AgregarDocumentosIndividualesDocumentoContable`. Estos tres textos son la clave que usará el código en la Tarea 2.

- [x] **S1: Escribir el script.** Cuatro bloques idempotentes, cada uno con `WHERE NOT EXISTS`:
  1. `INSERT` en `generales_funcionalidad` (nombre, ruta, esactivo).
  2. `INSERT` en `generales_funcionalidadaccion` (idfuncionalidad, nombre, esactivo), buscando la funcionalidad por ruta y nombre.
  3. `INSERT` en `generales_funcionalidadrol` (idrol, idfuncionalidad, eshabilitado) para cada rol que tenga activo el permiso de combos (`AgregarMasCombosDocumentoContable`), sin duplicar.
  4. `INSERT` en `generales_funcionalidadaccionrol` (idfuncionalidadrol, idfuncionalidadaccion, esactivo) para esos mismos roles, sin duplicar.
  
  Antes de escribir los bloques 3 y 4, leer con `SELECT` las filas del permiso de combos (funcionalidadrol y funcionalidadaccionrol) para copiar exactamente sus columnas y valores; `FuncionalidadRol.cs` y `FuncionalidadAccionRol.cs` muestran las columnas que existen, pero pueden faltar las que tienen valor por defecto.
- [x] **S2: Correr el script en la base de pruebas dos veces seguidas.** Sin error, y la segunda vez no inserta filas nuevas (idempotente).
- [x] **S3: Verificar con SQL de solo lectura.** Resultado (2026-10-15): 1 fila, rol `03`, rol-pantalla id 257 habilitado, rol-acción id 388 activo. Un solo rol, sin duplicados.
  - Roles con combos activo = roles con el permiso nuevo activo: `SELECT count(DISTINCT idrol)` de una consulta y de la otra, y el resultado es igual.
  - Un usuario real con el rol correcto: `FuncionalidadAccionActor.ObtenerPorIdUsuarioPorRutaFuncionalidadnombre` devuelve la acción (se comprueba en la Tarea 3, M1).

---

### Tarea 2: Código de la pantalla y del servicio

**Se parece a:** `DocumentoContableComboAsignacionActorNegocio.TienePermisoAgregarMasCombos` (consulta del permiso) y `DocumentoContableComboController.Index` (pasar el permiso a la vista).

**Archivos:**
- Modificar: `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs` (agregar método y tres constantes, junto a los de combos).
- Modificar: `PruebaPostgreSQL/Controllers/Contabilidad/DocumentoContableComboController.cs:21-34` (`Index`).
- Modificar: `PruebaPostgreSQL/Views/DocumentoContableCombo/Index.cshtml` (:6 y :209-214; Latin-1).
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableSolicitadoWebApiController.cs` (`Post` :45, `Put` :102).

**Interfaces:**
- Produce: `DocumentoContableComboAsignacionActorNegocio.TienePermisoAgregarDocumentosIndividuales(string idUsuario) : bool`, con las constantes de la Tarea 1.
- Produce: `ViewBag.PuedeAgregarDocumentoIndividual` (bool, `false` por defecto, como `PuedeAgregarCombo`).

- [x] **S1: Buscar otros llamadores** del controlador `DocumentoContableSolicitadoWebApi` (`Post`/`Put`) en JS y vistas (`rg "DocumentoContableSolicitadoWebApi"` en `PruebaPostgreSQL`). Resultado (2026-10-15): el único llamador es la grilla de `DocumentoContableCombo/Index.cshtml:216`; ningún JS ni otra vista. Si hubiera uno distinto a la grilla, volver a hablar antes de seguir.
- [x] **S2: Método de Negocio.** Mismo cuerpo que `TienePermisoAgregarMasCombos`, con las constantes nuevas. Comentario solo si hay un porqué (no hay excepción de "primer documento"; ese motivo sí merece una línea).
- [x] **S3: Controlador y vista.**
  - En `Index`, `ViewBag.PuedeAgregarDocumentoIndividual = false;` junto a `PuedeAgregarCombo`, y asignarlo dentro del `if (documento != null)` con `User.Identity.GetUserId()`.
  - En la vista, leerlo como `puedeAgregarCombo` (línea 6) y usarlo en `.AllowUpdating(...)` y `.AllowAdding(...)` de la grilla de solicitados (:211-212). La grilla de eliminados (:277-279) queda como está.
  - Verificar con `file` y editar a nivel de bytes si el archivo es Latin-1.
- [x] **S4: Guard en el WebApi.** Al inicio de `Post` y `Put`, si `!TienePermisoAgregarDocumentosIndividuales(User.Identity.GetUserId())`, responder `Request.CreateErrorResponse(HttpStatusCode.Forbidden, "No tiene permiso para agregar o editar documentos.")`. Es la misma línea en los dos métodos; si la repetición molesta, un método privado `SinPermiso()` que devuelva la respuesta o `null`.
- [x] **S5: Build.** `MSBuild PruebaPostgreSQL.csproj -p:Configuration=Debug`: 0 errores, 17 advertencias (conflictos de versiones de ensamblados, preexistentes) (2026-10-16).

---

### Tarea 3: Prueba manual y cierre

- [x] **M1 (2026-10-16):** `ADMINISTRADOR` (rol `03`), comprobante 168816, con el permiso encendido. Pantalla: `allowAdding`/`allowUpdating` en `true`, botón "Agregar Documento", 32 iconos de editar. Alta por la grilla (tipo 1, descripción "PRUEBA B2 alta"): fila nueva id 34 en `contabilidad_documentocontablesolicitado`, obligatorio `true`, tercero 2760. Edición de esa fila: descripción "PRUEBA B2 editada" y obligatorio `false`, confirmado con SELECT. Queda el registro de prueba id 34 en la base de pruebas. La grilla se manejó con la API de DevExtreme por `eval` (mismo `Post`/`Put` del WebApi), no con clics. **Sin permiso** (antes de habilitarlo) la grilla salió con ambos en `false`, sin botón ni iconos: cubre la parte de pantalla de M2.
- [ ] **M2:** dado un usuario **sin** el permiso, cuando abre el mismo comprobante, entonces la grilla no muestra agregar ni editar. Ve la lista y los archivos cargados.
- [ ] **M3:** dado ese usuario sin permiso, cuando se llama directo al servicio (`Post` y `Put` con Postman o `curl` con token), entonces responde 403 y no cambia nada en la base. Probar `Put` sobre un documento que vino de un combo.
- [ ] **M4:** dado el usuario sin permiso y un comprobante sin documentos, cuando intenta agregar el primer combo, entonces puede (la regla del primer combo no cambia).
- [ ] **M5:** crédito, pagaré, tercero y CRM: sin cambios; el cambio no toca código compartido. Basta una navegación a la pantalla de crédito.
- [ ] **C1: Actualizar las notas.** Marcar P2 con su respuesta; crear `IMPLEMENTACION B2.md` (archivo por archivo, ruta del script 9, evidencia de M1-M5) y actualizar el `README.md` de la carpeta.
- [ ] **C2: Definition of Done de `GUIA.md`:** build, verificación con evidencia, filas de README sincronizadas. El script 9 se corre en cada base donde se despliegue **antes** de publicar el código, o nadie podrá agregar documentos sueltos.
