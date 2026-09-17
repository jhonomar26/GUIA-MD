# Plan: Designer visual para Formatos de Amortización

## Contexto

`FormatosAmortizacion` (tabla `public.cartera_formatosamortizacion`) hoy se edita en `Views/FormatosAmortizacion/Edicion.cshtml` con HTML crudo + placeholders posicionales `{0}`-`{18}` y placeholders dinámicos por concepto `{C{id}}`/`{C{id}_Base}`/`{C{id}_Impuesto}`. El motor de render (`Negocio/ReportesHelper/ReporteAmortizacionHelper.cs`) hace `string.Format`/regex sobre `<tbody>` para clonar filas de cuotas — funciona bien, pero no tiene editor visual de layout.

Otros formatos (Paz y Salvo, Carta, Pagaré, Contrato-Nómina, Clientes, Terceros) ya migraron a un **Designer visual DevExpress** (drag&drop de campos, `JsonDataSource`, layout guardado en Base64). Ese mecanismo centralizado (`PruebaPostgreSQL/Reportes/FormatoDesignerStorage.cs` + `IFormatoDesignerActorNegocio`) está **tipado a `Generales.Formatos`** (tabla `generales_formatos`), y `FormatosAmortizacion` es una tabla completamente separada. Decisión ya tomada: **no forzar la integración en `generales_formatos`** — se crea un storage paralelo dedicado, sin tocar el mecanismo existente ni arriesgar los formatos ya migrados.

Mismo criterio que Contrato-Nómina (`PLAN_DESIGNER_FORMATO_CONTRATO_NOMINA.md`): un mismo registro de `FormatosAmortizacion` sirve para ambos flujos. El flag `Esformatoxml` decide, por registro, si ese formato puntual usa el Designer (`Layoutdesigner` con contenido) o sigue con el flujo HTML clásico.

**Decisión clave sobre la tabla de cuotas (y por extensión Cabecera/Cuerpo/Piepagina):** el Designer de DevExpress no maneja bien columnas dinámicas (los conceptos `{C{id}}` varían por instalación), así que no tiene sentido reconstruir la tabla dentro del Designer. La conclusión, ya validada con el usuario, es más amplia: **los HtmlEditors que ya existen en `Edicion.cshtml` (Cabecera, Cuerpo, Tablaamortizacion, Piepagina) no se tocan ni se duplican** — siguen siendo la única fuente de verdad de contenido/estructura. El Designer solo consume el resultado **ya resuelto** de esos editores contra un préstamo real, expuesto como bloques HTML de una sola pieza (`XRRichText`), y el usuario simplemente los arrastra y posiciona.

Además, y para mantener el mismo patrón que los demás formatos migrados (Pagaré, Nómina, etc.), el esquema del Designer expone **ambas cosas a la vez**:
- Los **campos individuales fijos** ya existentes (`PlaceholdersEstandar`: Identificacion, Nombre, Prestamo, MontoInicial, ..., NombreEmpresa) — para quien quiera armar su propio layout campo por campo, igual que en los otros formatos.
- Los **4 bloques ya resueltos** (`CabeceraHtml`, `CuerpoHtml`, `TablaAmortizacionHtml`, `PiepaginaHtml`) — para quien prefiera simplemente arrastrar lo que ya tenía configurado en los editores existentes, sin rearmar nada.

Ambos caminos conviven en el mismo `JsonSchema`; el admin elige cuál usar (o combina).

---

## ⚠️ El problema central que bloqueó el avance: dos tablas, un solo storage global

`DevExpress.XtraReports.Web.Extensions.ReportStorageWebExtension.RegisterExtensionGlobal(...)`
es un **slot único para todo el sitio** — no admite dos storages activos simultáneamente
(llamarlo dos veces reemplaza el primero, no los suma). `FormatoDesignerStorage` es ese único
storage global, y resuelve todo contra `Generales.Formatos`.

`FormatosAmortizacion` vive en una tabla **independiente** (`cartera_formatosamortizacion`), así
que necesita su propio storage (`FormatoAmortizacionDesignerStorage`, ya escrito) — pero sin un
segundo `RegisterExtensionGlobal` disponible, ese storage no tiene forma nativa de conectarse al
mecanismo de guardado (Ctrl+S) del widget `ReportDesigner`.

### Intentos ya probados (y por qué no se dejaron activos)

1. **Registrar dos veces `RegisterExtensionGlobal`** → descartado de inmediato: la segunda
   llamada pisa la primera, dejando sin storage funcional a Paz y Salvo/Carta/Pagaré/Nómina/
   Clientes/Terceros. Regresión inaceptable.

2. **Delegación por existencia de código** (`FormatoDesignerStorage` prueba `FormatosActor`
   primero; si no existe, prueba `FormatosAmortizacionActor`) → **ambiguo**: si el mismo texto
   de `Codigo` existiera por coincidencia en ambas tablas (son independientes, nada lo impide),
   siempre gana la primera consultada y el guardado real podría terminar en la tabla
   equivocada, o nunca llegar a la de Amortización.

3. **Router genérico con "tipo" embebido en el reporte** (parámetro oculto
   `tipoFormatoDesignerInterno`, análogo al ya existente `codigoFormatoDesignerInterno`, con un
   diccionario `Dictionary<string, ReportStorageWebExtension>` en `FormatoDesignerStorage` para
   que agregar un storage paralelo futuro sea solo "una clase + una línea") → técnicamente
   resolvía la ambigüedad de forma determinística (el tipo viaja embebido en el propio XML del
   reporte, no se decide comparando strings de código entre tablas). **Se revirtió** porque, al
   probarlo, aparecieron problemas en el flujo de **preview** que dependen de las mismas APIs
   que este cambio tocaba indirectamente (`ObtenerDatosAmortizacion` pasó de `idPrestamo` a
   `numeroPrestamo`, y el router agregaba una capa extra sobre el `SetData`/`GetData` ya
   delicado de `FormatoDesignerStorage`). No se alcanzó a diagnosticar la causa raíz antes de
   decidir revertir y dejar una base estable.

### Estado actual (post-revert, commiteable)

- **`PruebaPostgreSQL/Reportes/FormatoDesignerStorage.cs`** y
  **`PruebaPostgreSQL/Reportes/FormatoDesignerBuilder.cs`** — de vuelta a su estado original de
  `master`. Sin router, sin tipo embebido, sin conocimiento de `FormatosAmortizacion`. Cero
  riesgo para los formatos ya migrados.
- **`PruebaPostgreSQL/Global.asax.cs`** — un solo `RegisterExtensionGlobal(new FormatoDesignerStorage())`, igual que siempre.
- **Huérfanos pero conservados** (no registrados, no interfieren con nada, listos para
  retomarse): `PruebaPostgreSQL/Reportes/FormatoAmortizacionDesignerStorage.cs`,
  `FormatosAmortizacionController.Diseno`, `Views/FormatosAmortizacion/Diseno.cshtml`, el botón
  "Diseñador visual" en `Edicion.cshtml`, y el endpoint
  `FormatosAmortizacionWebApiController.ObtenerDatosAmortizacion` (ya recibe `numeroPrestamo`,
  no `idPrestamo` — resuelve el id vía `PrestamoMaestroActor.ObtenerPorNumeroprestamoSinVerificarExistencia`).

**Ya hecho (no repetir):**
- Columna `layoutdesigner text` y `esformatoxml boolean` agregadas a `public.cartera_formatosamortizacion`.
- `Blip.Data/Cartera/FormatosAmortizacion.cs` — propiedades `Layoutdesigner`/`Esformatoxml` + campos estáticos `LayoutdesignerCampo`/`EsformatoxmlCampo`.
- `Blip.Data/Cartera/FormatosAmortizacionActor.cs` — `CrearSelect`/`Insert`/`Update` ya incluyen ambas columnas; `ObtenerPorCodigoSinVerificarExistencia(string)` ya existe.
- `Blip.Entities/Cartera.ViewModels/FormatosAmortizacionViewModel.cs` — ya tiene `Esformatoxml`/`Layoutdesigner`.
- `Controllers/Cartera/FormatosAmortizacionController.cs` — GET/POST de `Edicion` ya leen/escriben `Esformatoxml`.
- `Views/FormatosAmortizacion/Edicion.cshtml` — checkbox "Es formato xml" ya agregado y ya viaja en `guardarTodo()`/POST.
- **`Negocio/ReportesHelper/ReporteAmortizacionHelper.cs`** — `ObtenerValoresParametrosAmortizacion(idPrestamo, idFormato)` ya implementado: resuelve los 15 campos fijos por reflection (reusa `PlaceholdersEstandar`, sin duplicar la lógica de `ReemplazarTexto`) + los 4 bloques HTML (`CabeceraHtml`/`CuerpoHtml`/`TablaAmortizacionHtml`/`PiepaginaHtml`) ya resueltos contra un préstamo real.
- **`Controllers/WebApi/FormatosAmortizacionWebApiController.cs`** — acción `ObtenerDatosAmortizacion(string numeroPrestamo, string codigoFormatoDesignerInterno)` ya implementada (recibe `numeroPrestamo` porque es lo que el usuario final conoce; resuelve el id internamente vía `PrestamoMaestroActor`).
- **`PruebaPostgreSQL/Reportes/FormatoAmortizacionDesignerStorage.cs`** — storage paralelo ya escrito completo (`GetData`/`SetData`/`SetNewData`/`GetUrls`/`CanSetData`/`CrearDataSource`/`CrearReporteBaseAmortizacion`), **pero no registrado en ningún lado** (huérfano a propósito, ver problema central arriba).
- **`Controllers/Cartera/FormatosAmortizacionController.cs`** — acción `Diseno(string codigo)` ya escrita, invoca `new FormatoAmortizacionDesignerStorage().GetData(codigo)` directamente (no depende del dispatcher global).
- **`Views/FormatosAmortizacion/Diseno.cshtml`** — ya escrita, calca `Views/FormatosDesigner/Designer.cshtml` con `Bind(layoutXml)`.
- **`Views/FormatosAmortizacion/Edicion.cshtml`** — botón "Diseñador visual" + JS `abrirDisenador()` ya agregados, apuntan a `FormatosAmortizacion/Diseno?codigo=...`.

No existe `UpdateLayoutDesigner` dedicado — no hace falta: `FormatosAmortizacionActor.Update(item)` ya persiste `Layoutdesigner` como parte del update genérico.

---

## Objetivo restante

Conectar `FormatoAmortizacionDesignerStorage` (ya escrito) al flujo real de guardado (Ctrl+S)
sin arriesgar el mecanismo compartido de los formatos ya migrados, y sin repetir los problemas
de preview que obligaron al revert. Luego: usar el layout diseñado al imprimir (`Esformatoxml`).

Cada fase debe compilar y quedar en un estado consistente antes de pasar a la siguiente.

---

## Fase A (rediseñada) — Resolver el guardado sin storage paralelo global

En vez de retomar el router genérico de `FormatoDesignerStorage` (fuente de los problemas de
preview), evaluar **antes de escribir código** una de estas dos rutas, en orden de preferencia:

### Opción 1 (preferida): Designer con `Bind` explícito de datos, sin depender de `SetData`/`GetUrls` del storage global

Investigar si el widget `ReportDesigner` de DevExpress permite manejar el guardado (Ctrl+S)
**fuera** del mecanismo `ReportStorageWebExtension` — por ejemplo interceptando el evento de
guardado del lado cliente (JS) y haciendo un POST directo a una acción propia del
`FormatosAmortizacionController` (similar a como `GuardarFormatoTemporal` ya hace un POST
custom para el preview clásico), que llame directamente
`FormatoAmortizacionDesignerStorage.SetData` sin pasar por el dispatcher global. Esto evita
tocar `FormatoDesignerStorage`/`FormatoDesignerBuilder` por completo — cero riesgo para los
formatos migrados, y aísla cualquier bug de guardado al código nuevo únicamente.

**Antes de implementar:** confirmar con la documentación de DevExpress (`context7`) si el
evento de guardado del `ReportDesigner` (client-side `MVCxClientReportDesigner`) expone un
hook tipo `SaveActionExecuting`/`CustomizeMenuActions` que permita interceptar Ctrl+S sin
reimplementar el widget.

### Opción 2 (fallback): retomar el router de tipo embebido, pero diagnosticando primero el problema de preview

Si la Opción 1 no es viable, retomar el diseño de la Fase 3 original (`tipoFormatoDesignerInterno`
+ `StoragesDelegados` genérico en `FormatoDesignerStorage`), pero **antes de reactivarlo**:
1. Reproducir el problema de preview reportado en aislamiento (¿es el cambio de
   `idPrestamo`→`numeroPrestamo` en el WebApi, o el router de `FormatoDesignerStorage`, o
   ambos?).
2. Si el problema es específico del cambio de parámetro del WebApi, separar esa decisión de la
   del router — se pueden resolver en commits/pasos independientes en vez de mezclar ambos
   cambios de una sola vez (lección aprendida de este intento).

**Verificación de la fase:** cualquiera sea la opción elegida, debe quedar demostrado con un
caso de prueba real que **guardar un formato de Amortización no afecta ni depende de**
`FormatoDesignerStorage`, y que Paz y Salvo/Carta/Pagaré/Nómina/Clientes/Terceros siguen
guardando exactamente igual que antes de tocar nada de esto.

---

## Fase B — Vista Designer + botón (ya construida, validar end-to-end)

Ya existe: botón en `Edicion.cshtml`, controlador `Diseno`, vista `Diseno.cshtml`. Falta
validar manualmente una vez resuelta la Fase A:
1. Clic "Diseñador visual" abre el Designer con banda base y, en el Field List: los 15 campos
   individuales + `CabeceraHtml`/`CuerpoHtml`/`TablaAmortizacionHtml`/`PiepaginaHtml`.
2. Preview nativo con un `numeroPrestamo` real trae datos reales en ambos tipos de campo.
3. Guardar (Ctrl+S) persiste en `cartera_formatosamortizacion.layoutdesigner` — sin tocar
   `generales_formatos` de ningún formato migrado.

---

## Fase C — Usar el layout diseñado al imprimir

Sin cambios respecto al plan original. Mismo patrón que la Fase 5 de
`PLAN_DESIGNER_FORMATO_CONTRATO_NOMINA.md`:

```csharp
FormatosAmortizacion formato = FormatosAmortizacionActor.ObtenerPorId(idFormato);

if (formato.Esformatoxml != true || string.IsNullOrEmpty(formato.Layoutdesigner))
{
    // flujo clásico existente (TablaHtmlViewModel + ReporteAmortizacionHelper.GenerarHtml), sin cambios
}
else
{
    var reportDesigner = new XtraReport();
    reportDesigner.LoadLayoutFromXml(Convert.FromBase64String(formato.Layoutdesigner));
    if (reportDesigner.Parameters["numeroPrestamo"] != null)
        reportDesigner.Parameters["numeroPrestamo"].Value = numeroPrestamo;
    return View("Formato", reportDesigner);
}
```

Confirmar contra el código real de `CartaCobroController.FormatoPDesigner` antes de escribir la versión final. Archivo probable: el controlador que hoy expone `ObtenerTablaAmortizacionDetalladaHtmlPrestamoPreview` (`TablaAmortizacionController`, confirmar nombre real) y/o `FormatosAmortizacionController.cs`.

**Verificación de la fase:** imprimir con un formato `Esformatoxml=true` ya diseñado renderiza el layout visual con datos reales; un formato con `Esformatoxml=false` (o sin `Layoutdesigner`) sigue funcionando igual que hoy (regresión cero).

---

## Verificación final (todas las fases)

1. Compilar solución completa: `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug`.
2. Flujo end-to-end: dejar `Cabecera`/`Cuerpo`/`Tablaamortizacion`/`Piepagina` configurados como hoy → marcar `Esformatoxml` → abrir Designer → arrastrar alguno de los 15 campos sueltos y los 4 bloques HTML → preview nativo con `numeroPrestamo` real → guardar → imprimir desde el flujo real (no preview) y confirmar que usa el layout guardado.
3. Confirmar que un préstamo vigente (sin datos atípicos) y uno con conceptos dinámicos (impuestos/otros) ambos renderizan bien `TablaAmortizacionHtml`.
4. Confirmar que un formato con `Esformatoxml=false` sigue usando el flujo HTML clásico sin cambios.
5. Confirmar que Paz y Salvo/Carta/Pagaré/Nómina/Clientes/Terceros no sufrieron ninguna regresión — `FormatoDesignerStorage.cs` y `IFormatoDesignerActorNegocio` no se modifican en absoluto, todo lo de Amortización es aditivo en archivos nuevos.
