# Guía Conceptual: Cómo Funciona el End-User Report Designer

**Documentado por:** Omar Jhon
**Fecha:** 15 de julio de 2026
**Propósito:** Entender el modelo mental antes de diseñar reportes — qué pasa "por debajo" cuando editas en el navegador.

---

## 1. La idea central

No es un editor mágico de PDFs. Es un **editor visual de un objeto `XtraReport`** (la misma clase C# que usas en `Reportes/XtraReportFormato.cs`, `XtraReportFlujo.cs`, etc.), pero en vez de escribir C#/Designer.cs a mano, lo arma un usuario arrastrando cosas en el navegador.

```
Editar en navegador  ≈  Editar XtraReportX.Designer.cs a mano
                         (mismo resultado, distinto método)
```

Todo lo que ves en pantalla (bandas, labels, tablas) es **la representación visual** de un objeto en memoria. Al terminar, ese objeto se serializa y se guarda. Al volver a abrir, se deserializa y se vuelve a pintar igual.

---

## 2. Las 3 piezas que siempre están presentes

| Pieza | Qué es | Dónde vive en tu código |
|---|---|---|
| **El Reporte** (`XtraReport`) | El objeto que contiene bandas, controles, estilos | En memoria durante edición; serializado en disco/BD al guardar |
| **El Datasource** | De dónde saca los campos (Nombre, Fecha, etc.) | SQL, JSON, o un `List<T>` en C# — se conecta una vez, antes de diseñar |
| **El Storage** (`ReportStorageWebExtension`) | Quién decide cómo/dónde se guarda el XML del reporte | Clase C# que tú implementas — es el único punto realmente "tuyo" en toda la arquitectura |

Si entiendes estas 3 piezas, entiendes el 90% del sistema. Todo lo demás (toolbar, Field List, Filter Editor) son solo **formas de modificar el objeto `XtraReport` sin código**.

---

## 3. Qué pasa cuando guardas ("Save")

```
1. Usuario hace clic en "Save"
        ↓
2. El navegador serializa TODO el reporte actual a XML
   (posiciones, tamaños, fuentes, filtros, agrupaciones — todo)
        ↓
3. Se envía ese XML al servidor (via el endpoint interno DXXRD.axd)
        ↓
4. El servidor llama a TU clase Storage:
   storage.SetData(report, "nombreDelFormato")
        ↓
5. TU código decide dónde persistir ese XML:
   - En este PoC: archivo .repx en App_Data/
   - En producción: normalmente una columna BYTEA en PostgreSQL
```

**Punto clave**: DevExpress nunca decide "dónde" guardar. Solo te entrega el XML ya armado y te pregunta "¿qué hago con esto?" — tu clase `ReportStorageWebExtension` responde esa pregunta.

### Qué pasa cuando abres ("Open")

Es el proceso inverso:

```
1. Usuario elige un reporte de la lista (o entra por URL con el nombre)
        ↓
2. El servidor llama a TU clase Storage:
   byte[] xml = storage.GetData("nombreDelFormato")
        ↓
3. Ese XML se deserializa a un objeto XtraReport
        ↓
4. El navegador pinta la UI a partir de ese objeto
```

`GetUrls()` es simplemente la función que le dice al Designer "estos son los nombres disponibles para el diálogo Open/Save As".

---

## 4. Qué controla cada parte de la interfaz (mapa mental)

No necesitas memorizar el toolbar completo. Solo 5 conceptos:

| Lo que ves en pantalla | Qué modifica realmente | Ejemplo concreto |
|---|---|---|
| **Field List** (panel campos) | Vincula un control a una columna del datasource | Arrastro "Nombre" → crea un `XRLabel` con `.DataBindings` apuntando a esa columna |
| **Bands** (Cabecera/Detalle/Pie) | Define QUÉ SE REPITE y cuántas veces | `DetailBand` se repite 1 vez por fila del datasource; `ReportHeader` una sola vez |
| **Filter Editor** | Genera una condición SQL-like sin que el usuario escriba SQL | Visualmente arma `[Estado] = 'Activo' AND [Fecha] >= @FechaInicio` |
| **Report Parameters** | Variables que el usuario final llena antes de generar | Un `DateEdit` para que el usuario elija el rango de fechas al imprimir |
| **Formatting Rules** | Apariencia condicional sin código | "Si `[Monto] > 1000000` → texto en rojo" — es un `if` visual |

**Insight importante**: nada de esto es exclusivo del navegador. Es exactamente lo mismo que hace un desarrollador en Visual Studio con el Report Designer de escritorio — solo que aquí lo hace un usuario sin instalar nada.

---

## 5. Qué DEBES tener en cuenta antes de usarlo en serio

### 5.1 El Datasource se define ANTES, no durante el diseño

El usuario no puede "inventar" de dónde vienen los datos sobre la marcha (salvo que tenga permiso de usar el Data Source Wizard, que en producción normalmente se restringe). Tú, como desarrollador, decides:

- Qué tablas/vistas están disponibles para elegir
- Qué campos son visibles (puedes ocultar columnas sensibles)

Esto se controla enlazando un datasource ya armado en C#, o restringiendo el wizard a ciertas conexiones.

### 5.2 Placeholders personalizados (`{0}`, `{1}`...) NO existen en este mundo

Esto ya lo detectamos en el estudio de viabilidad. El Designer trabaja con **campos reales del datasource**, no con placeholders de texto libre. Si necesitas algo tipo `{0}` → tendrías que modelarlo como un **Report Parameter** (variable con nombre), no como texto mágico.

### 5.3 Permisos: quién puede guardar, sobre qué

`CanSetData(url)` en tu Storage es el único lugar donde controlas esto. Si no filtras ahí, **cualquier usuario que llegue a la vista puede sobrescribir cualquier reporte**. En producción esto debe validar:

```csharp
public override bool CanSetData(string url)
{
    // ej: solo el creador o un admin puede sobrescribir
    return UsuarioActual.EsAdmin || url.StartsWith($"usuario_{UsuarioActual.Id}_");
}
```

### 5.4 El XML guardado no es "texto plano editable"

Es un formato binario/XML propietario de DevExpress (`.repx`). No se edita a mano ni se versiona bien en Git como texto. Si necesitas versionado, guarda metadata aparte (quién, cuándo) en una tabla SQL, no dependas del diff del XML.

### 5.5 Cada reporte guardado es independiente

No hay "herencia" automática entre reportes creados en el Designer. Si mañana cambias el datasource (agregas una columna), los reportes ya guardados **no se enteran solos** — hay que reabrir y volver a enlazar si se quiere usar el campo nuevo.

### 5.6 Rendimiento: el reporte se re-renderiza completo cada vista previa

A diferencia de un formulario web normal, cada "Preview" ejecuta la query completa del datasource y genera el documento desde cero. Si el datasource es pesado (millones de filas), hay que paginar o filtrar en el datasource antes de entregarlo al reporte — el Designer no optimiza eso por ti.

---

## 6. Cuándo SÍ conviene usar esto (y cuándo no)

| Escenario | ¿Usar Designer? |
|---|---|
| Usuario necesita crear un informe ad-hoc con campos que él elige | ✅ Sí — para eso existe |
| Reporte con estructura fija que solo cambia texto/colores | ❌ No — mejor una vista Razor simple como ya tienes |
| Placeholders de texto tipo `{0}` en cartas | ❌ No — no encaja con el modelo de datos del Designer |
| Reporte con lógica de negocio compleja antes de mostrar datos | ⚠️ Parcial — la lógica debe vivir en el datasource (C#), no en el Designer |
| Usuario sin conocimiento técnico necesita autoservicio | ✅ Sí — es exactamente el caso de uso previsto |

---

## 7. Resumen de una sola frase

> El Report Designer web es un editor visual que arma y desarma un objeto `XtraReport` en XML; tú controlas de dónde vienen los datos (datasource) y a dónde va el resultado guardado (Storage) — todo lo demás es interfaz para no escribir ese XML a mano.

---

## 8. Dónde seguir aprendiendo (oficial)

- **Interfaz completa explicada**: https://docs.devexpress.com/XtraReports/113888/web-reporting/end-user-report-designer-for-web/interface-elements
- **Cómo se guarda/carga (Custom Storage)**: https://docs.devexpress.com/XtraReports/10001/detailed-guide-to-devexpress-reporting/store-and-distribute-reports/store-report-layouts-and-documents/custom-report-storage
- **Demo interactivo**: https://demos.devexpress.com/aspnetcore/Demo/Reporting/ReportDesigner/

## 9. Relacionado en este proyecto

- `ESTUDIO_DEVEXPRESS_REPORT_DESIGNER.md` — viabilidad y código de implementación completo
- `Reportes/PruebaReportDesignerStorage.cs` — Storage de prueba (guarda en `App_Data/PruebaFormatosDesigner/`)
- `Controllers/PruebaReportDesignerController.cs` — rutas `/PruebaReportDesigner/Designer` y `/PruebaReportDesigner/Preview`
