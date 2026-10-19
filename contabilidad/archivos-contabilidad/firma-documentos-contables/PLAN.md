 # Firma electrónica de documentos contables — Plan de implementación

> **Historia.** Plan ejecutado; el código difiere en cuatro puntos: el controlador usa `[Log]` en vez de `finally` (T3.4), se agregó `ValidarEsPdf` (T3.3), la vista tiene un 4.º campo `Esanuladoelectronicamente` (T4.1) y la rama real fue `feature/expediente-virtual-carga-firmas`. Vigente: [IMPLEMENTACION.md](./IMPLEMENTACION.md).

> **Para agentes:** SUB-SKILL REQUERIDA: superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans, tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** firmar con VozData, a mano y desde la web, los documentos cargados en un comprobante contable cuyo tipo tenga "Firma electrónica", igual que crédito.

**Arquitectura:** copia del dominio crédito como un dominio de firma más (ADR-001): vínculo `firmas_firmaarchivocontable` → `generales_archivo`, `FirmaArchivoContableActorNegocio` copiado de `FirmaArchivoCreditoActorNegocio` sin codeudores, un caso `EsFirmaContable` en las piezas compartidas, y botón "Firmar" en la grilla del comprobante. El firmante sale de `idtercero`, columna nueva del documento solicitado (R7).

**Stack:** .NET 4.6.2, ASP.NET MVC 5 + Web API 2, Dapper, PostgreSQL 11 (Npgsql 2.2.7), DevExtreme, `SIIAN.VozData`.

**Spec:** [`ANALISIS.md`](./ANALISIS.md) (reglas R1-R7, verificación V1-V10), [`REQUERIMIENTO.md`](./REQUERIMIENTO.md), [`ADR.md`](./ADR.md).

## Restricciones globales

- `.csproj` clásico: todo `.cs` nuevo se registra a mano con `<Compile Include="..." />`.
- Código, mensajes y textos en español.
- SQL con los campos estáticos de la entidad (`Entidad.XxxCampo`, `Entidad.NombreTabla`), nunca literales.
- `catch (Exception) { throw; }`, nunca `throw ex;`.
- Listas con `ObtenerLista(sql, parameters, 0)`.
- `Negocio/` no usa Dapper ni `GeneralDao.Connection`. La copia de crédito trae `finally { GeneralDao.Connection = null; }`: **se quita en la copia**, y el cierre queda en el `finally` del controlador.
- Archivos ISO-8859 (`_GestionDocumentos.cshtml` y otros): verificar con `file` antes de editar; si son Latin-1, editar a nivel de bytes para no romper tildes.
- Sin pruebas automáticas: cada tarea se verifica con build de la solución + consultas SQL de solo lectura + prueba manual Dado/Cuando/Entonces.
- Build: `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug` (o compilar en VS 2022). Esperado: 0 errores.
- Commits solo cuando el usuario lo pida; mensaje de una línea `tipo: qué cambia`, sin firma de autoría.
- Rama nueva `feature/firma-documentos-contables` **desde `feature/expediente-virtual-carga-c1`**, porque depende de su código (documento solicitado, grilla). Confirmar con el usuario antes de crearla.

## Foco de revisión

1. **Archivo con varias firmas** (una anulada y otra nueva): la grilla debe mostrar una sola fila con la firma más reciente. La vista de crédito duplica; la contable no (Tarea 1, verificación S4).
2. **Documento sin tercero** (pedido antes del script, o script sin correr): "Firmar" debe mostrar un mensaje claro, no un error de referencia nula (Tarea 3, M4).
3. **Archivo en FTP (grilla de remotos):** enviar a firmar y reemplazar por `FIRMADO-…` debe funcionar igual que con un archivo local (Tarea 3, M5; Tarea 4, G3).
4. **`idArchivo` de otro dominio** en la URL contable (por ejemplo, un archivo de crédito): mensaje claro "El archivo no pertenece a un documento contable" (Tarea 3, M4).
5. **Crédito, tercero y CRM después del cambio:** siguen firmando igual, porque se tocan el servicio y la pantalla compartidos (Tarea 3, M6).

---

### Tarea 1: Script SQL

**Archivos:**
- Crear: `C:\Users\User\DataGripProjects\scriptsSiian\contabilidad\scratch\6-firma-documentos-contables.sql`

**Interfaces:**
- Produce:
  - columna `contabilidad_documentocontablesolicitado.idtercero integer NULL` (FK `terceros_terceromaestro.id`);
  - tabla `firmas_firmaarchivocontable(id serial PK, idarchivocontable integer FK generales_archivo.id, idprocesomaestro integer FK firmas_procesomaestro.id)`, con secuencia `firmas_firmaarchivocontable_id_seq`;
  - vista `contabilidad_vistadocumentocontablecargados` con cuatro columnas nuevas **al final**: `esfirmaelectronica boolean`, `esfirmadoelectronicamente boolean`, `idfirma integer`, `esanuladoelectronicamente boolean` (estado Anulado de `firmas_parametrosestado`; permite el color rojo de la grilla).

Mismo estilo que los scripts 1 a 5: sin BEGIN/COMMIT, idempotente, comentarios `--` cortos en español.

- [x] **S1: Columna y completado.** `ALTER TABLE public.contabilidad_documentocontablesolicitado ADD COLUMN IF NOT EXISTS idtercero integer REFERENCES public.terceros_terceromaestro(id);` y luego `UPDATE … s SET idtercero = d.idtercero FROM public.contabilidad_documentocontable d WHERE d.id = s.iddocumentocontable AND s.idtercero IS NULL;`. Queda nullable a propósito: el código viejo sigue insertando sin ella hasta que suba el nuevo.
- [x] **S2: Tabla vínculo.** `CREATE TABLE IF NOT EXISTS public.firmas_firmaarchivocontable (…)`, con las mismas FKs que `firmas_firmaarchivocredito` y un índice `IF NOT EXISTS` sobre `idarchivocontable`.
- [x] **S3: Vista.** `CREATE OR REPLACE VIEW` copiando el script 5 tal cual (una columna por línea) y agregando al final `t.esfirmaelectronica`, `f.esfirmadoelectronicamente` y `f.idfirma`, desde la firma más reciente:

```sql
LEFT JOIN LATERAL (
    SELECT fa.esfirmado AS esfirmadoelectronicamente, fpm.id AS idfirma
    FROM public.firmas_firmaarchivocontable fac
    JOIN public.firmas_procesomaestro fpm ON fpm.id = fac.idprocesomaestro
    JOIN public.firmas_archivo fa ON fa.id = fpm.idarchivo
    WHERE fac.idarchivocontable = a.id
    ORDER BY fpm.fechacreacion DESC
    LIMIT 1
) f ON true
```

- [x] **S4: Correr el script en la base de pruebas y verificar.**
  - `SELECT count(*) FROM contabilidad_documentocontablesolicitado WHERE idtercero IS NULL;` → `0` (V10).
  - `SELECT idarchivo, count(*) FROM contabilidad_vistadocumentocontablecargados GROUP BY 1 HAVING count(*) > 1;` → sin filas.
  - Correr el script dos veces seguidas → sin error (idempotente).

---

### Tarea 2: Tercero en el documento solicitado

**Archivos:**
- Modificar: `Blip.Data/Contabilidad/DocumentoContableSolicitado.cs` (propiedad, estáticos, constructor :93)
- Modificar: `Blip.Data/Contabilidad/DocumentoContableSolicitadoActor.cs` (`CrearSelect` :19, `Insert` :26-28, `Update` :44-53)
- Modificar: `Blip.Data/Contabilidad/DocumentoContableComboActorNegocio.cs:28` (`InsertarConDocumentosSolicitados`)
- Modificar: `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs:39,55` (`AgregarCombo`)
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableSolicitadoWebApiController.cs:58,70` (`Post`)
- Modificar: `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs:280` (`EliminarArchivos`, rama recrear)

**Interfaces:**
- Consume: columna `idtercero` (Tarea 1).
- Produce:
  - `DocumentoContableSolicitado.Idtercero : int?`;
  - `DocumentoContableSolicitado.IdterceroCampo = "public.contabilidad_documentocontablesolicitado.idtercero"` e `IdterceroTipo = DbType.Int32`;
  - constructor con un 9.º parámetro **obligatorio** `int? p_idtercero` al final. Así el compilador obliga a revisar cada sitio de creación.

- [x] **T2.1:** Agregar `Idtercero` a la entidad y al Actor (`CrearSelect`, `Insert`, `Update`). No se agrega al ViewModel: la pantalla no lo usa (YAGNI).
- [x] **T2.2:** `InsertarConDocumentosSolicitados(DocumentoContableCombo nuevoCombo, int p_idtercero)`. En `AgregarCombo`, guardar el resultado de `DocumentoContableActor.ObtenerPorIdSinVerificarExistencia` (:39, hoy se descarta) y pasar su `.Idtercero`.
- [x] **T2.3:** En `Post`, guardar el comprobante consultado en :58 y pasar `p_idtercero: documentoContable.Idtercero`.
- [x] **T2.4:** En `EliminarArchivos` (rama recrear), copiar `documentoSolicitado.Idtercero` al PENDIENTE nuevo.
- [x] **T2.5: Build.** 0 errores. Si algún `new DocumentoContableSolicitado(` no compila, era un sitio de creación no listado: pasarle el tercero de su comprobante.
- [x] **T2.6: Prueba manual (V9).**
  - Dado un comprobante con tercero, cuando se agrega un combo, entonces todos sus documentos quedan con ese `idtercero`.
  - Cuando se agrega un documento a mano: lo mismo.
  - Cuando se elimina un archivo con "recrear": el PENDIENTE nuevo queda con el mismo `idtercero`.
  - Cuando se edita la descripción de un documento: `idtercero` no cambia.
  - Consulta de control: `SELECT id, iddocumentocontable, idtercero FROM contabilidad_documentocontablesolicitado ORDER BY id DESC LIMIT 10;`

---

### Tarea 3: Firma contable de punta a punta

**Archivos:**
- Crear: `Blip.Data/Firmas/FirmaArchivoContable.cs` y `FirmaArchivoContableActor.cs`, copiados de `FirmaArchivoCredito.cs` y su Actor (ASCII).
- Crear: `Negocio/Firmas/FirmaArchivoContableActorNegocio.cs`, copiado de `FirmaArchivoCreditoActorNegocio.cs`.
- Crear: `PruebaPostgreSQL/Controllers/Firmas/FirmaArchivoContableController.cs`, copiado de `FirmaArchivoCreditoController.cs` (el original es ISO-8859; el nuevo va en UTF-8).
- Modificar: `Blip.Entities/Generales.ViewModels/FirmaCarpetaVirtualViewModel.cs:13-17` (UTF-8 con BOM)
- Modificar: `SIIAN.VozData/Handlers/FirmarDocumentoCarpetaVirtualHandler.cs:110-131` (UTF-8 con BOM)
- Modificar: `PruebaPostgreSQL/Views/FirmaProcesoMaestro/FirmarDocumento.cshtml:3-16, 1017-1036` (UTF-8 con BOM)
- Modificar:
  - `Blip.Data/Data.csproj`, después de :2454;
  - `Negocio/Negocio.csproj`, después de :272;
  - `PruebaPostgreSQL/PruebaPostgreSQL.csproj`, después de :8268.

**Interfaces:**
- Consume: `DocumentoContableSolicitado.Idtercero` (Tarea 2) y la tabla vínculo (Tarea 1).
- Produce:
  - `FirmaArchivoContable(int p_id, int? p_idarchivocontable, int? p_idprocesomaestro)`, con `NombreTabla = "public.firmas_firmaarchivocontable"` y secuencia `firmas_firmaarchivocontable_id_seq`;
  - `FirmaArchivoContableActor`: los 12 métodos estándar más `ObtenerPorIdarchivocontable(int?)` y `ObtenerPorIdprocesomaestro(int?)`, ambos `List<FirmaArchivoContable>`;
  - `FirmaCarpetaVirtualViewModel.EsFirmaContable : bool`;
  - `FirmaArchivoContableActorNegocio`, con las mismas firmas públicas que crédito:
    - `Task<FirmaCarpetaVirtualViewModel> FirmarDocumento(int idArchivo)`
    - `Task<(FirmaCarpetaVirtualViewModel, FirmarDocumentoCarpetaVirtualHandler)> EnviarSolicitudFirma(FirmaCarpetaVirtualViewModel pmf, string idUsuario)`
    - `Task<bool> DescargarYReemplazar(int idFirmaMaestro)`
    - `Task ReenviarSolicitudes(int idFirma)`
    - `AnularFirma(int idFirma, string motivoAnulacion)`
  - Controlador `FirmaArchivoContable`, con las mismas acciones y verbos que `FirmaArchivoCreditoController`. La URL de entrada es `/FirmaArchivoContable/FirmarDocumento/?idArchivo={id}`.

- [x] **T3.1: Entidad y Actor del vínculo.** Copia de crédito renombrando `idarchivocredito` a `idarchivocontable`. El FK perezoso apunta a `Archivo` (`generales_archivo`), igual que crédito. Registrar en `Data.csproj`.
- [x] **T3.2: Piezas compartidas.**
  - `EsFirmaContable` en el ViewModel.
  - En el handler, una rama `else if (ArchivoTerceroDatosFormulario.EsFirmaContable) FirmaArchivoContableActor.Insert(new FirmaArchivoContable(0, IdArchivo, firmaMaestroGuardado.Id));`.
  - En la vista, el título `"Firmar Documento Contable"` y la rama `controller = "FirmaArchivoContable"` en `getCurrentController()`.
- [x] **T3.3: `FirmaArchivoContableActorNegocio`.** Copia de crédito con estos cambios y nada más:
  - Banderas: `EsFirmaContable = true`, las demás en `false`.
  - Nuevo helper privado `DocumentoContableSolicitado ObtenerSolicitadoPorIdarchivo(int idArchivo)`:
    - camino: `DocumentoContableArchivoActor.ObtenerPorIdarchivo(idArchivo).FirstOrDefault()` → `DocumentoContableCargadoActor.ObtenerPorIddocumentoarchivo(rel.Id)`, el activo → `DocumentoContableSolicitadoActor.ObtenerPorId(cargado.Iddocumentocontablesolicitado)`;
    - si no hay vínculo: `InvalidOperationException("El archivo no pertenece a un documento contable")`;
    - si `Idtercero == null`: `InvalidOperationException("El documento solicitado no tiene tercero asignado")`.
  - Firmante: `solicitado.Idtercero.Value`, como principal y único (R1). Se borran el bloque de codeudores (crédito :209-228) y su lista en `EnviarSolicitudFirma` (:350-354).
  - Se usa el constructor de 5 parámetros del handler (`datosFirma, file, idUsuario, idTercero, idArchivo`).
  - Asunto por defecto: `solicitado.Descripcion` si no está vacío; si no, `DocumentoTipoActor.ObtenerPorId(solicitado.Idtipodocumento).Nombre`.
  - Búsquedas del vínculo con `FirmaArchivoContableActor.ObtenerPorIdarchivocontable` y `ObtenerPorIdprocesomaestro`.
  - Sin `GeneralDao.Connection` (ver Restricciones). Registrar en `Negocio.csproj`.
- [x] **T3.4: Controlador.** Copia de `FirmaArchivoCreditoController` apuntando a `FirmaArchivoContableActorNegocio`, con `GeneralDao.Connection = null` en el `finally` de cada acción. Registrar en `PruebaPostgreSQL.csproj`.
- [x] **T3.5: Build.** 0 errores.
- [x] **T3.6: Prueba manual** (entrando por URL, la grilla todavía no tiene botón):
  - **M1 (V3):** dado el `idarchivo` de un documento contable firmable, cuando se abre `/FirmaArchivoContable/FirmarDocumento/?idArchivo=X`, entonces la pantalla se titula "Firmar Documento Contable" y el único firmante es el tercero del comprobante.
  - **M2 (V4):** cuando se envía y el tercero firma en VozData, al reabrir la pantalla el archivo pasa a `FIRMADO-…` en la ruta contable y `generales_archivo.url` apunta a él. Consulta: `SELECT * FROM firmas_firmaarchivocontable ORDER BY id DESC LIMIT 5;`.
  - **M3 (V5, V6):** reenviar y anular responden igual que en crédito. Con un plazo vencido, al reabrir queda anulada por expirado.
  - **M4:** con un `idArchivo` de crédito, o con un solicitado sin tercero (`UPDATE` manual a NULL en la base de pruebas), la pantalla muestra el mensaje claro de T3.3.
  - **M5:** con un archivo contable en FTP, enviar y reemplazar funcionan.
  - **M6 (V7):** se firma un documento de crédito y uno de tercero, y abren su propia pantalla con su título de siempre.

---

### Tarea 4: Botón "Firmar" en la grilla del comprobante

**Archivos:**
- Modificar:
  - `Blip.Data/Contabilidad/VistaDocumentoContableCargados.cs` (propiedades, estáticos, constructor :84);
  - `Blip.Data/Contabilidad/VistaDocumentoContableCargadosActor.cs` (`CrearSelect`).
- Modificar: `Blip.Entities/Contabilidad.ViewModels/VistaDocumentoContableCargadosViewModel.cs` (constructor :59).
- Modificar: `PruebaPostgreSQL/Controllers/WebApi/VistaDocumentoContableCargadosWebApiController.cs:37,56` (los dos mapeos posicionales).
- Modificar: `PruebaPostgreSQL/Views/DocumentoContableArchivo/_GestionDocumentos.cshtml:57-58`, más el bloque de script (ISO-8859, editar a nivel de bytes).

**Interfaces:**
- Consume: las columnas nuevas de la vista (Tarea 1) y la URL de la Tarea 3.
- Produce: en la entidad y el ViewModel, `Esfirmaelectronica : bool?`, `Esfirmadoelectronicamente : bool?`, `Idfirma : int?` y `Esanuladoelectronicamente : bool?` como parámetros 16 a 19 del constructor, en ese orden.

- [x] **T4.1:** Agregar los 3 campos a la entidad (con `*Campo`/`*Tipo`), al `CrearSelect`, al ViewModel y a los dos mapeos del WebApi.
- [x] **T4.2:** En la columna de botones de la grilla de cargados, que es una sola dentro del `foreach remoto`:
  - agregar antes de "Ver archivo" `b.Add().Hint("Firmar").Icon("background").CssClass("button-firmar").OnClick("firmarDocumentoContable").Visible(new JS("esDocumentoFirmaElectronica"))`;
  - ajustar el ancho de la columna;
  - agregar `.OnCellPrepared("selectIconButtonFirmar")`.
- [x] **T4.3:** Copiar al script de la vista las funciones `selectIconButtonFirmar` y `esDocumentoFirmaElectronica` de `Views/CargaArchivos/MostrarArchivos.cshtml:655-678`, y `firmarDocumentoContable(e)`, que abre `/FirmaArchivoContable/FirmarDocumento/?idArchivo=${e.row.data.Idarchivo}` con `window.open(url, "_blank")`. Verificar que las clases `button-firmar`, `button-firmar-active` y `button-firmar-inactive` llegan a esta vista; si no, incluir el mismo CSS que usa crédito.
- [x] **T4.4: Build.** 0 errores.
- [x] **T4.5: Prueba manual:**
  - **G1 (V1, V2):** "Firmar" aparece solo en documentos de tipo con firma.
  - **G2:** el ícono cambia de color: sin enviar (normal), esperando firma (naranja), firmado (verde), anulada o vencida (rojo).
  - **G3:** lo mismo en la grilla de remotos.
  - **G4 (V8):** después de firmar, el documento sigue en la grilla de cargados con su mismo estado de solicitado.
  - **G5:** exportar la grilla sigue funcionando.

---

### Tarea 5: Cierre

- [x] **C1:** Repetir M6 y G1-G4 completos sobre la rama final.
- [x] **C2:** Crear `IMPLEMENTACION.md` (archivo por archivo, con la ruta del script) y su fila en el `README.md` de la feature.
- [x] **C3:** Revisar la Definition of Done de `GUIA.md`: build, `.csproj`, verificación con evidencia, filas de README sincronizadas.
