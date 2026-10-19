# B1: detalle de la constancia de eliminación para documentos contables — Plan de implementación

> **Historia.** Plan ejecutado (código en `1510e9b5c` y `cedcba97c`); las casillas sin tildar siguen pendientes. Vigente: [IMPLEMENTACION.md](./IMPLEMENTACION.md).

> **Para agentes:** SUB-SKILL REQUERIDA: superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans, tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** que el acta de eliminación y el detalle de una constancia listen los archivos contables eliminados, como ya hacen con Terceros, Crédito y CRM.

**Arquitectura:** una vista de base de datos `contabilidad_vistaarchivoseliminados` (los joins viven en la base), su entidad y Actor generados con WFAGenerarDao y copiados a `Blip.Data/Contabilidad/`, un método de consulta por constancia en el Actor, y un método de Negocio que convierte las filas a `ContenidoCarpetaVirtualViewModel` y se suma a los dos sitios que arman la lista.

**Stack:** .NET 4.6.2, Dapper, PostgreSQL 11 (Npgsql 2.2.7), `WFAGenerarDao`.

**Spec:** [`ANALISIS.md`](ANALISIS%20B1.md) (sección B1), [`REQUERIMIENTO.md`](./REQUERIMIENTO.md).

## Restricciones globales

- `.csproj` clásico: todo `.cs` nuevo se registra a mano con `<Compile Include="..." />`.
- Código, mensajes y textos en español.
- SQL con los campos estáticos de la entidad (`Entidad.XxxCampo`, `Entidad.NombreTabla`), nunca literales.
- `catch (Exception) { throw; }`, nunca `throw ex;`.
- Listas con `ObtenerLista(sql, parameters, 0)`.
- `Negocio/` no usa Dapper ni `GeneralDao.Connection`; solo llama a Actores. La consulta con SQL va en `Blip.Data/Contabilidad/…ActorNegocio.cs`.
- Archivos ISO-8859: verificar con `file` antes de editar; si son Latin-1, editar a nivel de bytes para no romper tildes.
- Sin pruebas automáticas: cada tarea cierra con build de la solución + consulta SQL de solo lectura + prueba manual Dado/Cuando/Entonces.
- Build: `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug` (o VS 2022). Esperado: 0 errores.
- Script SQL en `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\`, mismo estilo que los anteriores: sin `BEGIN/COMMIT`, idempotente, comentarios `--` cortos en español. El número 7 ya está ocupado (`7-eliminacion-constrains.sql`): este es el **8**.
- Generador: `D:\Plantillas\WFAGenerarDao\bin\Debug\WFAGenerarDao.exe` (la skill `siian-plantillas-generadas` dice `plantillas\WFAGenerarDao\…`, ruta vieja). **Siempre** a un directorio temporal, nunca al repo; `config` escribe en la BD `configuraciones`, así que se corre **sin** `--borrar-campos`.
- Commits solo cuando el usuario lo pida; mensaje de una línea `tipo: qué cambia`, sin firma de autoría.
- Rama: se sigue en `feature/expediente-virtual-carga-firmas`. Si se prefiere una rama aparte, confirmar antes (pregunta P5).

## Preguntas

Se resuelven **antes** de la tarea que las usa. Cada una lleva mi recomendación; la respuesta del usuario manda.

| # | Pregunta (en términos de negocio) | Recomendación | Bloquea | Estado |
|---|---|---|---|---|
| P1 | En el acta de eliminación, ¿se muestra el número del comprobante? Hoy la tabla del acta solo tiene Carpeta, Tercero, Tipo documento, Descripción, Fecha, Usuario | No: igual que crédito, y la plantilla no tiene columna para eso | Tarea 1 (columnas de la vista) | ✅ No; mejora futura para todos los módulos (usuario, 2026-10-15) |
| P2 | Un documento solicitado viejo puede no tener tercero guardado (pedido antes del script 6). ¿El acta muestra el tercero del comprobante en ese caso? | Sí: `COALESCE(solicitado.idtercero, comprobante.idtercero)` | Tarea 1 | ✅ Sí, `COALESCE` (usuario, 2026-10-15) |
| P3 | ¿La plantilla guardada del acta (formato "eliminación de archivos") depende de algo propio de crédito? No se pudo ver sin la base | Se revisa en Tarea 4 con el acta real; si falla, se vuelve aquí | Tarea 4 | ⬜ por verificar |
| P4 | ¿Se agrega también CRM detalle a `ConstanciaEliminacionArchivosActorNegocio.ContenidoCarpetasVirtuales`? Le falta hoy, pero no es de contabilidad y nadie llama a ese método | No: fuera de alcance, queda anotado | — | ✅ No; fuera de alcance ([ANALISIS B1.md](ANALISIS%20B1.md), "Lo que no entra") |
| P5 | ¿Se trabaja en la rama actual o en una nueva? | La actual: el cambio es pequeño y la feature de firmas ya está cerrada | Tarea 1 | ✅ Rama renombrada a `feature/contabilidad-detalle-constancia-eliminacion` (usuario, 2026-10-15) |

## Foco de revisión

1. **Archivo reemplazado por documento único:** puede haber más de una fila `cargado` por `documentocontablearchivo`. La vista no debe duplicar el archivo eliminado (Tarea 1, S3).
2. **Solicitado sin tercero** y comprobante sin tercero: el acta debe salir con el nombre vacío, no romperse ni perder la fila (Tarea 1, S3; Tarea 3, M3).
3. **Constancia de crédito o tercero:** el acta sale idéntica a antes; no aparece ninguna fila contable en ella (Tarea 3, M2).
4. **Constancia contable sin archivos vinculables** (archivo marcado pero sin fila en `documentocontablearchivo`): el acta sale con tabla vacía, sin error (Tarea 3, M4).
5. **Usuario de cargue inexistente:** el acta usa `AspnetusersActor.ObtenerPorId(item.Idusuariocargue)` y ya contempla `userCargue?.UserName`; confirmar que no revienta con un id vacío (Tarea 3, M3).

---

### Tarea 1: Script SQL de la vista

**Se parece a:** `5-vista-documentos-cargados-contabilidad.sql`.

**Archivos:**
- Crear: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\8-vista-archivos-eliminados-contabilidad.sql`

**Interfaces:**
- Produce: vista `public.contabilidad_vistaarchivoseliminados`, una fila por archivo contable eliminado, con las columnas (en este orden):
  `idarchivo int`, `idconstanciaeliminacion int`, `iddocumentocontable int`, `idsolicitado int`, `nombretipodocumento varchar`, `descripciondocumento varchar`, `nombrearchivo varchar`, `descripcionarchivo varchar`, `idusuariocargue varchar`, `fechacargue timestamp`, `fechavencimiento timestamp`, `idtercero int` (nullable), `nombretercero varchar`, `identificacion varchar`, `fechaeliminacion timestamp`, `idusuarioeliminacion varchar`, `observacioneliminacion varchar`.

- [x] **S1: Escribir la vista.** `CREATE OR REPLACE VIEW`, una columna por línea con alias (estilo del script 5). Base: `generales_archivo a` con `a.eseliminado = true`, `JOIN generales_constanciaeliminacionarchivos k ON k.id = a.idconstanciaeliminacion`, `JOIN contabilidad_documentocontablearchivo d ON d.idarchivo = a.id`, `JOIN contabilidad_documentocontablecargado c ON c.iddocumentoarchivo = d.id` (**sin** filtrar `c.esactivo`: al eliminar queda en `false`), `JOIN contabilidad_documentocontablesolicitado s`, `JOIN contabilidad_documentotipo t`, `JOIN contabilidad_documentocontable dc` y `LEFT JOIN terceros_terceromaestro tm ON tm.id = COALESCE(s.idtercero, dc.idtercero)` (P2). Si el foco 1 se confirma en S3, deduplicar con `DISTINCT ON (a.id)` ordenando por `c.id DESC`.
- [ ] **S2: Correr el script en la base de pruebas dos veces seguidas.** Sin error (idempotente).
- [x] **S3: Verificar con SQL de solo lectura.**
  - `SELECT idarchivo, count(*) FROM contabilidad_vistaarchivoseliminados GROUP BY 1 HAVING count(*) > 1;` → sin filas.
  - `SELECT count(*) FROM generales_archivo a JOIN contabilidad_documentocontablearchivo d ON d.idarchivo = a.id WHERE a.eseliminado AND a.idconstanciaeliminacion IS NOT NULL;` es igual a `SELECT count(*) FROM contabilidad_vistaarchivoseliminados;` (ningún archivo contable eliminado se pierde por un join).
  - `SELECT * FROM contabilidad_vistaarchivoseliminados ORDER BY fechaeliminacion DESC LIMIT 10;` → tercero y tipo con valores razonables; con tercero nulo, `nombretercero` nulo y la fila sigue ahí.

---

### Tarea 2: Entidad y Actor de la vista

**Se parece a:** `VistaDocumentoContableCargados` y su `ObtenerPorDocumento`.

**Archivos:**
- Crear: `Blip.Data/Contabilidad/VistaArchivosEliminados.cs` y `VistaArchivosEliminadosActor.cs` (generados).
- Crear: `Blip.Data/Contabilidad/VistaArchivosEliminadosActorNegocio.cs` (partial, a mano).
- Modificar: `Blip.Data/Data.csproj`, junto a la línea de `Contabilidad\VistaDocumentoContableCargadosActorNegocio.cs` (:1860), tres `<Compile Include=... />`.

**Interfaces:**
- Consume: la vista de la Tarea 1.
- Produce:
  - `VistaArchivosEliminados` con una propiedad por columna de la vista, `NombreTabla = "public.contabilidad_vistaarchivoseliminados"` y su `{X}Campo`/`{X}Tipo`;
  - `VistaArchivosEliminadosActor` con los métodos estándar generados;
  - `VistaArchivosEliminadosActor.ObtenerPorConstancia(int p_idconstanciaeliminacion) : List<VistaArchivosEliminados>`.

- [x] **S1: Generar a temporal.** `WFAGenerarDao.exe dapper --tabla contabilidad_vistaarchivoseliminados --salida %TEMP%\gen`. Si no reconoce la tabla, correr antes `config` (sin `--borrar-campos`) y repetir.
- [x] **S2: Difear contra una vista ya existente** (`VistaDocumentoContableCargados.cs` y su Actor) con `diff --strip-trailing-cr -u` para confirmar que el estilo coincide (llaves en la misma línea, `string` sin `?`), y copiar los dos archivos generados a `Blip.Data/Contabilidad/` (ASCII; sin tildes en nombres).
- [x] **S3: `ObtenerPorConstancia`** en el partial `VistaArchivosEliminadosActorNegocio.cs`, calcado de `VistaDocumentoContableCargadosActor.ObtenerPorDocumento` (`CrearSelect()` + `WHERE {IdconstanciaeliminacionCampo} = @idconstanciaeliminacion` + `ObtenerLista(sql, parametros, 0)`, `catch (Exception) { throw; }`, orden por `FechacargueCampo`, `IdarchivoCampo`).
- [x] **S4: Registrar** los 3 archivos en `Data.csproj`.
- [x] **S5: Build.** 0 errores.

---

### Tarea 3: Conectar el acta y el detalle de la constancia

**Archivos:**
- Modificar: `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs` (método nuevo).
- Modificar: `Negocio/Credito/CreditoMaestroReportesNegocio.cs:869-910` (`ObtenerValoresParametrosEliminacionArchivos`, después de `listaCrmDetalle`).
- Modificar: `Negocio/Generales/ConstanciaEliminacionArchivosActorNegocio.cs:16-52` (`ContenidoCarpetasVirtuales`).

**Interfaces:**
- Consume: `VistaArchivosEliminadosActor.ObtenerPorConstancia(int)` (Tarea 2).
- Produce: `DocumentoContableArchivoActorNegocio.ObtenerArchivosEliminadosPorConstancia(int idConstancia) : List<ContenidoCarpetaVirtualViewModel>`, con `Tipocarpetavirtual = "Contabilidad"`. Mapeo, por propiedades y no por el constructor posicional (tiene `int` no nulables):

| ViewModel | Vista |
|---|---|
| `Iddocumento` | `idsolicitado` |
| `Nombretipodocumento` | `nombretipodocumento` |
| `Nombretercero`, `Num_identificacion`, `Idtercero` | `nombretercero`, `identificacion`, `idtercero ?? 0` |
| `Descripcionarchivo`, `Descripciondocumento` | `descripcionarchivo`, `descripciondocumento` |
| `Idarchivo`, `Nombrearchivo` | `idarchivo`, `nombrearchivo` |
| `Fechavencimiento`, `Fechacargue`, `Idusuariocargue` | iguales |
| `Fechaeliminacion`, `Idusuarioeliminacion`, `Observacioneliminacion` | iguales |
| `Eseliminado`, `Idconstanciaeliminacion` | `true`, `idconstanciaeliminacion` |

- [x] **S1: Método de Negocio** con la firma y el mapeo de arriba. Sin Dapper ni `GeneralDao.Connection` (solo llama al Actor).
- [x] **S2: Sumarlo al acta.** En `ObtenerValoresParametrosEliminacionArchivos`, `listaContenido.AddRange(DocumentoContableArchivoActorNegocio.ObtenerArchivosEliminadosPorConstancia(idConstancia));` junto a las otras cuatro.
- [x] **S3: Sumarlo a `ContenidoCarpetasVirtuales`** (P4: sin tocar CRM detalle). Es la misma línea.
- [x] **S4: Build.** 0 errores.
- [ ] **S5: Prueba manual.**
  - **M1:** dado un comprobante con 2 documentos cargados, cuando se eliminan (una vez con "recrear" y otra sin él) y se genera el acta desde `ContenidoCarpetaVirtual` → pestaña "Constancias eliminación" → "Generar", entonces la tabla del acta lista las 2 filas con carpeta "Contabilidad", tercero, tipo, descripción, fecha de cargue y usuario.
  - **M2:** dada una constancia de crédito y otra de tercero ya existentes, cuando se genera su acta, entonces sale idéntica a antes (mismas filas, ninguna contable).
  - **M3:** dado un solicitado con `idtercero` NULL en comprobante sin tercero (`UPDATE` manual en la base de pruebas), cuando se genera el acta, entonces la fila aparece con tercero vacío y sin error.
  - **M4:** dada una constancia contable cuyo archivo no tenga fila en `contabilidad_documentocontablearchivo`, cuando se genera el acta, entonces la tabla sale vacía y sin error.

---

### Tarea 4: Cierre

- [ ] **C1: Cerrar P3.** Abrir el acta real del M1 con la plantilla guardada; confirmar que no hay textos ni campos propios de crédito. Si los hay, anotar en `ANALISIS.md` y decidir con el usuario.
- [ ] **C2: Actualizar las notas.** Marcar P1-P5 con su respuesta; crear `IMPLEMENTACION.md` de esta feature (archivo por archivo, ruta del script 8, evidencia de las pruebas) y su fila en el `README.md` de la carpeta.
- [ ] **C3: Definition of Done de `GUIA.md`:** build, `.csproj`, verificación con evidencia, filas de README sincronizadas.
