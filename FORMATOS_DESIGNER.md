# Formatos personalizados — Designer visual (Paz y Salvo + Carta/Mora)

Piloto de personalización de formatos vía el **DevExpress End-User Report Designer**, integrado sobre la entidad `Formatos`. Permite que un usuario arrastre/suelte campos, cambie textos, logo, orientación, etc. sobre un formato existente sin tocar código. Soporta actualmente **Paz y Salvo** y **Carta/Mora**.

## Piezas involucradas

```
Controllers/FormatosDesignerController.cs           → Sirve las vistas del designer/preview
Views/FormatosDesigner/Designer.cshtml               → Widget DevExpress ReportDesigner (edición visual)
Reportes/FormatoDesignerStorage.cs                   → Puente entre el designer y la tabla Formatos (persistencia + dispatch por tipo)
Reportes/FormatoDesignerBuilder.cs                   → Constantes compartidas entre todos los tipos (numeroPrestamo)
Reportes/ActoresNegocio/IFormatoDesignerActorNegocio.cs → Contrato: un tipo de formato sabe construir su reporte base y su datasource
Reportes/ActoresNegocio/PazSalvoFormatoActorNegocio.cs  → Implementación para Paz y Salvo
Reportes/ActoresNegocio/CartaFormatoActorNegocio.cs     → Implementación para Carta/Mora
Controllers/CartaCobroController.cs                 → Uso real: generar la carta con datos de un préstamo
```

## Cómo agregar un formato nuevo

1. Exponer un dataset con nombres para ese tipo (`ObtenerValoresParametrosXxx` en `Negocio/Cobranzas/ReportesViewModelNegocio.cs` + endpoint `ObtenerDatosXxx` en `CartaCobroWebApiController.cs`, protegido con `RequireApiKeyInterna`) — reusar la lógica de negocio existente, no reescribirla (ver `ObtenerPlaceholdersCarta` como ejemplo de extracción para reuso).
2. Crear `XxxFormatoActorNegocio.cs` en `Reportes/ActoresNegocio/` implementando `IFormatoDesignerActorNegocio` (copiar `CartaFormatoActorNegocio.cs` como plantilla).
3. Sumar `new XxxFormatoActorNegocio()` a la lista `ActoresNegocio` en `FormatoDesignerStorage.cs`.
4. Registrar los 3 archivos nuevos en `PruebaPostgreSQL.csproj` (`<Compile Include="..." />` — MSBuild clásico no descubre archivos automáticamente).

`FormatoDesignerStorage.cs` no cambia — `GetData`/`GetUrls`/`CanSetData` ya operan genéricamente sobre la lista de ActoresNegocio.

## El botón "Preview" nativo del widget sí funciona — ojo con parámetros `Enabled = false`

El botón **Preview propio del widget `ReportDesigner`** (dentro de `/FormatosDesigner/Designer?codigo=PZ`) **sí resuelve datos reales** al ingresar un valor válido en el prompt del parámetro (`numeroPrestamo`, `numerosolicitud`, etc.) — esto se creía una limitación de DevExpress imposible de arreglar, pero en la práctica el problema era un `Parameter.Enabled = false` en el proyecto, no el widget en sí.

Causa real (detectada en Pagaré): a diferencia de Paz y Salvo/Carta (que solo dependen de **un** `QueryParameter` visible, `numeroPrestamo`), el `JsonDataSource` de Pagaré depende de **dos**: el `numerosolicitud` visible y el `codigoFormatoDesignerInterno` oculto que `FormatoDesignerStorage.AgregarCodigoFormato` inyecta en todo reporte del Designer. Ese segundo parámetro se creaba con `Enabled = false` — y el motor de DevExpress **no resuelve en vivo el `Expression` de un `QueryParameter` si el `Parameter` correspondiente está deshabilitado**, aunque tenga un `Value` ya asignado en código. Resultado: el WebApi de Pagaré recibía `codigo = null`, fallaba, y el `catch` devolvía las 9 claves vacías → reporte en blanco.

Fix: `AgregarCodigoFormato` ahora crea el parámetro con `Enabled = true` (sigue con `Visible = false`, que es lo que realmente oculta el prompt de impresión — `Enabled` no afecta esa visibilidad, solo si el motor lo tiene en cuenta al resolver expresiones). Con eso el preview nativo también funciona para Pagaré.

**Regla para futuros tipos de formato**: si un `IFormatoDesignerActorNegocio` nuevo agrega parámetros propios al reporte (además de los que ya inyecta `FormatoDesignerStorage`), verificar que **todos** estén `Enabled = true` — `Visible = false` solo para ocultarlos del prompt si no aplica que el usuario los edite.

## 1. Abrir el designer

`GET /FormatosDesigner/Designer?codigo=PZ`

`FormatosDesignerController.Designer` llama `FormatoDesignerStorage.GetData(codigo)` él mismo (para tener los bytes del layout ya armado) y pasa a la vista `ViewBag.Codigo`, `ViewBag.Layout` (XML del layout como string) y `ViewBag.NombreDesigner` (`"reportDesigner_" + Guid.NewGuid()`, único por carga de página — ver sección de concurrencia más abajo). La vista (`Designer.cshtml`) monta el widget:

```csharp
@Html.DevExpress().ReportDesigner(settings => { settings.Name = nombreDesigner; }).Bind(layoutXml).GetHtml()
```

`.Bind(string)` **solo acepta el XML del layout, no el código del formato** — el widget queda sin "url" propia, así que Guardar (Ctrl+S) siempre pasa por `SetNewData`/`GetUrls` ("Guardar como"). Por eso `FormatoDesignerStorage.GetUrls()` filtra al código que se abrió leyendo el `Referer` de la pestaña (ver sección `GetUrls()` más abajo), y `SetData` usa el parámetro oculto embebido en el propio reporte (`NombreParametroCodigoFormato`) para saber en qué registro guardar sin depender de ese "url".

## 2. `FormatoDesignerStorage` — cómo carga y guarda

Es un `ReportStorageWebExtension` registrado globalmente en `Global.asax.cs`:

```csharp
ReportStorageWebExtension.RegisterExtensionGlobal(new FormatoDesignerStorage());
```

DevExpress llama automáticamente a sus métodos cuando el widget necesita abrir, guardar, listar o validar un reporte. No se invocan a mano desde ningún Controller.

### `GetData(string url)` — abrir (`url` = Codigo del formato)

1. Busca el `Formatos` por código.
2. Resuelve el `IFormatoDesignerActorNegocio` correspondiente (`ActoresNegocio.FirstOrDefault(a => a.EsDelTipo(formato))`). Si ninguno coincide (tipo no soportado en el Designer), lanza excepción.
3. **Si ya tiene `Layoutdesigner` guardado** (Base64 de un XML de layout DevExpress):
   - Carga ese XML en un `XtraReport` vacío con `LoadLayoutFromXml`.
   - **Importante:** `LoadLayoutFromXml` **reemplaza** toda la colección `Parameters` del reporte con lo que traiga el XML — no hace merge. Layouts guardados antes de que existiera el parámetro con nombre solo traen el parámetro `parameter1` por defecto de DevExpress.
   - Por eso, después de cargar el XML, se agrega a mano `FormatoDesignerBuilder.NombreParametroNumeroPrestamo` si no está presente (`report.Parameters[nombre] == null`), y se reemplaza el `DataSource` por `actorNegocio.CrearDataSource()` si no es ya un `JsonDataSource`.
   - Se vuelve a serializar (`SaveLayoutToXml`) y esos bytes son los que ve el designer.
4. **Si no tiene layout aún**: devuelve `actorNegocio.CrearReporteBase()` — plantilla en blanco con los parámetros/campos de ese tipo + un layout de ejemplo (título, campos alineados, firma).

### `SetData(XtraReport report, string url)` — guardar

Serializa el reporte tal cual lo dejó el usuario (`SaveLayoutToXml`) a Base64 y lo guarda en `Formatos.Layoutdesigner` vía `FormatosActor.UpdateLayoutDesigner(id, layout)`.

### `GetUrls()` — diálogo Abrir/Guardar como

Recorre `ActoresNegocio` y, por cada uno, lista los formatos activos de ese tipo (`FormatosActor.ObtenerFormatosActivosPorFlag(actorNegocio.CampoFlagSql)`). Clave y valor son ambos el `Codigo` (no el `Nombre`) — el diálogo de guardado reenvía el *valor mostrado* como `url`, así que si se pusiera el `Nombre` ahí, `SetData` fallaría buscando por nombre en vez de por código.

### `CanSetData(string url)`

Valida que el formato exista y que algún `IFormatoDesignerActorNegocio` lo reconozca (`ActoresNegocio.Any(a => a.EsDelTipo(formato))`).

> **Nota:** se evaluó y se descartó (por ahora) filtrar por compañía activa del usuario en `GetData`/`SetData`/`GetUrls`/`CanSetData` — se probó una implementación (`ObtenerIdCompaniaActiva` vía claim de Identity → `UsuarioComplemento` → `Sucursal` → `Idcompania`, fail-closed si no resuelve) y se revirtió porque no era necesaria para el piloto. Si se retoma multi-compañía sobre el Designer, ese es el punto de entrada a reconstruir.

### Concurrencia entre pestañas — `Name` único del widget

`SessionState` está deshabilitado para este backend (`Global.asax.cs`), así que el Designer **no puede depender de `Session`** para nada (ni para recordar el tipo de formato actual, ni para aislar pestañas). Dos consecuencias en el código:

- `FormatosDesignerController.Designer` genera un `ViewBag.NombreDesigner = "reportDesigner_" + Guid.NewGuid().ToString("N")` por cada carga de página, y `Designer.cshtml` lo usa como `settings.Name`. DevExpress documenta `Name` como identificador único de la instancia del extension — reusar un literal fijo (`"reportDesigner"`) en varias pestañas abiertas del mismo usuario rompe ese contrato y el backend puede confundir el documento en edición entre pestañas concurrentes.
- La identificación de "qué formato/tipo se está editando" para `GetUrls()` **no** se guarda en `Session` (se probó y se quitó `Session[FormatoDesignerStorage.SessionKeyTipoActual]` + `FormatoDesignerStorage.ResolverActorNegocio`); en su lugar se resuelve sin estado en el servidor leyendo el `Referer` de la petición ajax (ver `GetUrls()` arriba) o el parámetro oculto embebido en el propio reporte (`NombreParametroCodigoFormato`, ver `SetData`).

Regla para cualquier extensión futura del Designer: si hace falta "recordar algo entre llamadas" del mismo usuario, no usar `Session` — usar el `Referer`, un parámetro embebido en el reporte, o un token de corta duración (`HttpRuntime.Cache`, mismo patrón que `FormatosController.GuardarFormatoTemporal`/`PreviewPazYSalvo`).

## 3. `IFormatoDesignerActorNegocio` — un ActorNegocio por tipo de formato

Cada tipo de formato soportado en el Designer (Paz y Salvo, Carta/Mora, ...) tiene su propia clase en `Reportes/ActoresNegocio/` que implementa:

```csharp
public interface IFormatoDesignerActorNegocio
{
    bool EsDelTipo(Formatos formato);
    string CampoFlagSql { get; }       // Formatos.EsformatoXxxCampo
    JsonDataSource CrearDataSource();
    XtraReport CrearReporteBase();
}
```

`PazSalvoFormatoActorNegocio.CrearReporteBase()` define los **10 campos con nombre** de Paz y Salvo (mismo orden que `ObtenerValoresParametrosPazSalvo`):

```
Identificacion, NombreCliente, TipoIdentificacion, NroCredito, FechaActual,
FechaActualSinDia, FechaApertura, FechaUltimoPago, MunicipioUbicacion, MunicipioSucursal
```

`CartaFormatoActorNegocio.CrearReporteBase()` define los **30 campos con nombre** de Carta/Mora (mismo orden que `ObtenerValoresParametrosCarta` en `ReportesViewModelNegocio.cs`).

En ambos casos el layout inicial pone cada campo como un `XRLabel` con un `ExpressionBinding` `[NombreDelCampo]` sobre el `JsonDataSource` — así el valor se resuelve en tiempo de impresión. `FormatoDesignerStorage` no conoce estos detalles: solo llama a `CrearDataSource()`/`CrearReporteBase()` sobre el `IFormatoDesignerActorNegocio` que corresponda.

## 4. Usar el formato ya diseñado (generar la carta real)

Esto **no pasa por el designer ni por `FormatoDesignerStorage`**. Es un flujo aparte, de solo lectura + datos reales:

`GET /CartaCobro/FormatoPDesigner?numeroPrestamo=0004167&formato=123`

```csharp
public ActionResult FormatoPDesigner(string numeroPrestamo, int formato)
{
    Formatos formatoBase = FormatosActor.ObtenerPorIdSinVerificarExistencia(formato);
    if (formatoBase == null) return HttpNotFound(...);

    // Fallback si nunca se diseñó nada en el designer
    if (string.IsNullOrEmpty(formatoBase.Layoutdesigner))
        return FormatoP(numeroPrestamo, formato);

    var report = new XtraReport();
    report.LoadLayoutFromXml(bytes del Layoutdesigner);   // trae diseño visual + Parameters ya nombrados

    var valores = ReportesViewModelNegocio.ObtenerValoresParametrosPazSalvo(numeroPrestamo); // datos reales del préstamo
    foreach (var kv in valores)
        if (report.Parameters[kv.Key] != null)
            report.Parameters[kv.Key].Value = kv.Value;

    return View("Formato", report);
}
```

**Ojo con los parámetros de la URL:**
- `formato` es el **Id numérico** de `Formatos` (no el `Codigo` string). Pasar `formato=PZ` deja el binder en `0` → `ObtenerPorIdSinVerificarExistencia(0)` devuelve `null` → 404.
- Es un controller **MVC clásico** (no WebApi), enrutado por convención `{controller}/{action}`. La URL siempre necesita el segmento del controller: `/CartaCobro/FormatoPDesigner`, no `/FormatoPDesigner`.
- No es JSON/AJAX — retorna la vista renderizada directamente (navegación de página completa o `target="_blank"`).

## Resumen del ciclo de vida

```
1. Usuario abre  /FormatosDesigner/Designer?codigo=PZ
2. Widget llama GetData("PZ")        → arma reporte base o carga+repara layout guardado
3. Usuario diseña visualmente, da Guardar
4. Widget llama SetData(report,"PZ") → serializa y guarda en Formatos.Layoutdesigner
5. Para generar la carta real:
   /CartaCobro/FormatoPDesigner?numeroPrestamo=X&formato=<id numérico>
   → carga el layout guardado + inyecta valores reales + renderiza
```
