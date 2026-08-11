# Plan: Guardado del Designer de Amortización — delegación dentro del storage global

## Contexto

Objetivo: que el botón Guardar/Ctrl+S del `ReportDesigner` en
`/FormatosAmortizacion/Diseno?codigo=...` persista en `cartera_formatosamortizacion.layoutdesigner`
sin romper el guardado de los formatos ya migrados (Paz y Salvo, Carta, Pagaré, Nómina, Clientes,
Terceros — tabla `generales_formatos`, storage `FormatoDesignerStorage.cs` registrado global en
`Global.asax.cs`).

**Intento 1 (implementado y descartado con evidencia real):** apuntar el guardado a un Action
propio vía `ReportDesignerSettings.SaveCallbackRouteValues`, evitando tocar el storage global.
Se implementó (`Diseno.cshtml` + `FormatosAmortizacionController.GuardarDesignerAmortizacion`) y
**no funcionó**: el log `App_Data/FormatoDesignerErrors.log` mostró que el guardado seguía
cayendo en `FormatoDesignerStorage.SetData` (el storage global), con el código de Amortización
(`1010`) buscado —y no encontrado— en `FormatosActor` (tabla equivocada). Se confirmó además por
documentación oficial de DevExpress: **`SaveCallbackRouteValues` solo se usa si NO hay ningún
`ReportStorageWebExtension` registrado globalmente**; si hay uno registrado (como en este
proyecto), DevExpress enruta el guardado por su `SetData` sin excepción, sin API documentada para
desactivarlo por instancia. Callback de guardado propio: descartado definitivamente.

**Camino que sí funciona (el que ya preveía el plan original `PLAN_FORMATO_DESIGNER_AMORTIZACION.md`,
"Opción 2"):** agregar una delegación mínima dentro de `FormatoDesignerStorage.SetData` — el único
storage que DevExpress va a invocar de todas formas — que reconozca cuándo el reporte que se está
guardando es de Amortización y delegue a `FormatoAmortizacionDesignerStorage.SetData` ya escrito.
Se distingue por un segundo parámetro oculto embebido en el XML del reporte
(`tipoFormatoDesignerInterno = "amortizacion"`), no por comparar el código contra ambas tablas
(evita la ambigüedad ya descartada en el intento previo de router genérico). Es aditivo: si el
parámetro no existe (todo formato migrado hoy), el comportamiento de `FormatoDesignerStorage` no
cambia en absoluto.

**No se toca `Global.asax.cs`** — sigue habiendo un solo `RegisterExtensionGlobal`. Sí se toca
`FormatoDesignerStorage.cs` (antes evitado deliberadamente), pero solo con un guard-clause al
inicio de `SetData`, sin alterar ninguna línea existente de esa clase.

---

## Fase A — Revertir el intento de `SaveCallbackRouteValues` (no funcional)

- `Views/FormatosAmortizacion/Diseno.cshtml`: quitar `settings.SaveCallbackRouteValues` (vuelve
  a quedar solo `settings.Name = nombreDesigner;` seguido de `.Bind(layoutXml)`).
- `Controllers/Cartera/FormatosAmortizacionController.cs`: eliminar el Action
  `GuardarDesignerAmortizacion` — quedó demostrado que nunca se invoca (DevExpress no llega a
  usarlo mientras haya storage global registrado).

**Verificación:** compila; abrir el Designer sigue funcionando igual (sin cambios en la carga).

## Fase B — Marcar el tipo de formato en el XML embebido

En `PruebaPostgreSQL/Reportes/FormatoAmortizacionDesignerStorage.cs`, método
`AgregarCodigoFormato` (línea 68): agregar, junto al parámetro oculto existente
`codigoFormatoDesignerInterno`, un segundo parámetro oculto:

```csharp
private const string NombreParametroTipoFormato = "tipoFormatoDesignerInterno";
private const string ValorTipoFormato = "amortizacion";

private static void AgregarCodigoFormato(XtraReport report, string codigo)
{
    if (report.Parameters[NombreParametroCodigoFormato] == null)
    {
        report.Parameters.Add(new Parameter { Name = NombreParametroCodigoFormato, Type = typeof(string), Visible = false, Enabled = true, Value = codigo });
    }
    if (report.Parameters[NombreParametroTipoFormato] == null)
    {
        report.Parameters.Add(new Parameter { Name = NombreParametroTipoFormato, Type = typeof(string), Visible = false, Enabled = true, Value = ValorTipoFormato });
    }
}
```

Este parámetro ya viaja embebido en el XML tanto al crear la plantilla base como al recargar un
layout existente (mismo punto donde ya se agrega `codigoFormatoDesignerInterno`, en `GetData`).

**Verificación:** compila. Abrir el Designer de un formato de Amortización y confirmar (por
inspección del XML exportado o breakpoint) que el reporte trae ambos parámetros ocultos.

## Fase C — Delegación en `FormatoDesignerStorage.SetData`

En `PruebaPostgreSQL/Reportes/FormatoDesignerStorage.cs`, al inicio de `SetData` (línea 151,
antes de la lógica actual):

```csharp
public override void SetData(XtraReport report, string url)
{
    // Delegacion aditiva: si el reporte trae el marcador de tipo de Amortizacion, es un
    // storage completamente distinto (cartera_formatosamortizacion, no generales_formatos).
    // Sin este marcador (todo formato migrado hoy) el flujo de abajo sigue exactamente igual.
    if (report.Parameters["tipoFormatoDesignerInterno"]?.Value as string == "amortizacion")
    {
        string codigoAmortizacion = report.Parameters[NombreParametroCodigoFormato]?.Value as string ?? url;
        new FormatoAmortizacionDesignerStorage().SetData(report, codigoAmortizacion);
        return;
    }

    try
    {
        // ... resto del metodo sin cambios ...
```

`SetNewData` no necesita cambios — ya delega en `SetData` (línea 190-194), así que hereda la
delegación automáticamente. `GetData`/`GetUrls`/`CanSetData` **no se tocan**: Amortización nunca
los usa (carga vía `.Bind(layoutXml)` desde su propio controller, confirmado en el intento previo
por el log — el guardado llegó directo a `SetData` con `url='Report'`, nunca pasó por
`GetUrls`/`CanSetData`).

**Verificación:** compila. Abrir `/FormatosAmortizacion/Diseno?codigo=<real>`, modificar el
layout, Ctrl+S. Confirmar:
1. `App_Data/FormatoAmortizacionDesignerErrors.log` — sin nuevas excepciones, o si algo falla,
   el error aparece ahí (no en `FormatoDesignerErrors.log`) — señal correcta de que se delegó.
2. `cartera_formatosamortizacion.layoutdesigner` del código correcto se actualiza.
3. Reabrir el Designer del mismo código y confirmar que el cambio persistió.
4. Abrir y guardar un formato migrado real (p. ej. Paz y Salvo) y confirmar que sigue funcionando
   exactamente igual que antes — cero regresión.

---

## Verificación final (todas las fases)

1. Compilar solución completa: `msbuild PruebaPostgreSQL.sln /p:Configuration=Debug`.
2. Guardar un formato de Amortización → persiste en su tabla, sin tocar `generales_formatos`.
3. Guardar un formato migrado (Paz y Salvo/Carta/Pagaré/Nómina/Clientes/Terceros) → sigue
   guardando igual, sin ninguna diferencia observable.
4. Confirmar en los logs que cada guardado usa el storage/tabla correcta y que no aparecen
   errores cruzados entre ambos flujos.
