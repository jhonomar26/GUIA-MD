# DataGrid editable en DevExtreme: guía para entenderlo y usarlo

Esta guía resume lo que fuimos aprendiendo con la pantalla **Documentos del Contrato** (nómina) y lo que recomienda la documentación oficial de DevExtreme. Cada idea trae un ejemplo.

> Marca de confianza: lo que dice "(doc)" salió de la documentación oficial. Lo que dice "(probado)" ya funciona en SIIAN. Los nombres del builder de Razor (`.FormItem`, etc.) se tomaron de la doc de JavaScript y hay que compilarlos antes de darlos por buenos.

---

## 1. La idea central: el grid genera el formulario

Un `DataGrid` editable puede editar de cuatro maneras (`Editing.Mode`):

| Modo | Cómo se ve | Cuándo usarlo |
|---|---|---|
| `Row` | La fila se vuelve editable en línea | Pocos campos, todos simples (texto, número, check) |
| `Cell` / `Batch` | Cada celda se edita y se guarda en lote | Capturas rápidas tipo planilla |
| `Form` | Un formulario ocupa el lugar de la fila | Combos, varios campos, textos largos |
| `Popup` | El mismo formulario, en una ventana | Igual que Form, sin mover el grid |

**Regla práctica:** en cuanto el grid necesita un combo con búsqueda, pasa a `Form` o `Popup`. En `Row` los combos dan más problemas (se montan con JS, se descuadran los anchos, se pierde el valor al cambiar de fila).

---

## 2. Dos formas de armar el formulario

### Forma A — Formulario armado a mano (`Editing.Form`) *(probado)*

Vos decidís qué campos van, en qué orden y cómo se ven. Es lo que usamos en nómina:

```csharp
.Editing(e => e
    .Mode(GridEditMode.Form)
    .AllowAdding(Model.PuedeAgregar)
    .AllowUpdating(Model.PuedeAgregar)
    .UseIcons(true)
    .Form(f => f.ID("formDocsSolicitados")
        .ColCount(2)
        .LabelLocation(FormLabelLocation.Top)
        .Items(items =>
        {
            items.AddSimpleFor(m => m.Idtipodocumento)
                .Label(l => l.Text("Tipo de documento"))
                .Editor(ed => ed.SelectBox()
                    .DataSource(ds => ds.WebApi().Controller("DocumentoArchivoNominaWebApi").LoadAction("Get").Key("Id"))
                    .DisplayExpr("Nombre")
                    .ValueExpr("Id")
                    .SearchEnabled(true)
                    .SearchExpr(new string[] { "Nombre" })
                    .Placeholder("Buscar tipo de documento..."));
            items.AddSimpleFor(m => m.Esobligatorio).Label(l => l.Text("Obligatorio"));
            items.AddSimpleFor(m => m.Descripcion).ColSpan(2);
        }))
)
```

Puntos clave:

- `.Form(...)` **solo se aplica** con `Mode(Form)` o `Mode(Popup)`. Con `Row` se ignora en silencio (doc).
- `ColCount(2)` = dos columnas. `ColSpan(2)` = ese campo ocupa las dos.
- Solo entran los campos **editables**. Lo calculado o de solo lectura se queda en el grid.

### Forma B — Configuración en la columna (`formItem`) *(doc, sin compilar en SIIAN)*

No declarás el formulario; el grid lo genera con las columnas y cada columna dice cómo se ve:

```csharp
.Columns(columns =>
{
    columns.AddFor(m => m.Idtipodocumento)
        .Caption("Tipo de documento")
        .Lookup(lk => lk
            .DataSource(ds => ds.WebApi().Controller("DocumentoArchivoNominaWebApi").LoadAction("Get").Key("Id"))
            .DisplayExpr("Nombre").ValueExpr("Id"))
        .FormItem(fi => fi.ColSpan(2));   // solo afecta cómo se ve en el formulario

    columns.AddFor(m => m.Descripcion).FormItem(fi => fi.ColSpan(2));
})
.Editing(e => e.Mode(GridEditMode.Form))   // sin .Form(...)
```

### ¿Cuál elegir?

| | A: `.Form(...)` a mano | B: `formItem` en la columna |
|---|---|---|
| Control del formulario | Total | Menor |
| Combo con varios campos de búsqueda | Fácil (SelectBox completo) | Más limitado |
| Código | Más | Menos |
| Riesgo de pisar manejadores del grid | Algo (ver sección 5) | Menor |
| Estado en SIIAN | Funciona | Por probar |

**Recomendación:** A cuando el combo es de búsqueda múltiple o el formulario es particular. B cuando solo querés ajustar el orden o el ancho.

---

## 3. Combos (SelectBox) dentro del grid

### 3.1 Lookup de columna vs SelectBox del formulario

- `Lookup` de columna: sirve para **mostrar** el texto en la celda (en vez del id). Expone `dataSource`, `displayExpr`, `valueExpr` y `allowClearing`. No tiene `searchExpr`.
- `SelectBox` del formulario: sirve para **editar**. Tiene todas las opciones (búsqueda, paginación, plantillas).

Por eso usamos los dos a la vez: el `Lookup` pinta el nombre en la celda y el `SelectBox` del formulario edita.

### 3.2 Buscar por uno o varios campos

`SearchExpr` recibe un array. El texto que escribe el usuario se compara contra todos *(doc)*:

```csharp
items.AddSimpleFor(m => m.Idtipodocumento)
    .Editor(ed => ed.SelectBox()
        .DataSource(ds => ds.WebApi().Controller("DocumentoArchivoNominaWebApi").LoadAction("Get").Key("Id"))
        .DataSourceOptions(opt => opt.Paginate(true).PageSize(20))
        .ValueExpr("Id")
        .DisplayExpr(new JS("function(item) { return item ? item.Nombre + ' - ' + item.Nombregrupo : ''; }"))
        .SearchEnabled(true)
        .SearchExpr(new string[] { "Nombre", "Nombregrupo" })
        .Placeholder("Buscar por nombre o grupo..."));
```

Cuidado: **cada campo de `SearchExpr` tiene que llegar en los datos** que devuelve el `Get`. Si el ViewModel solo trae el `Id` del grupo y no su nombre, no se puede buscar por nombre del grupo. Hay que agregar el campo al ViewModel primero.

### 3.3 Catálogos grandes

```csharp
.DataSourceOptions(opt => opt.Paginate(true).PageSize(20))
```

Carga por lotes en vez de traer todo. Si el servidor se ve lento al teclear, el `SelectBox` tiene `searchTimeout` (milisegundos de espera antes de consultar) *(doc)*.

### 3.4 Registros inactivos: el caso que más confunde

Un pedido guardado puede tener un tipo que después se inactivó. Si el combo del formulario carga **solo activos**, ese pedido muestra el campo en blanco porque el valor no está en la lista.

Solución usada en nómina:

1. El combo del formulario lista **todos** los tipos (`Get`), así siempre resuelve el nombre.
2. Un `OnEditorPreparing` mínimo cambia la fuente a **solo activos** cuando la fila es nueva, y deja el campo en solo lectura cuando la fila ya existe:

```javascript
function editorDocumentoSolicitado(e) {
    if (e.parentType !== "dataRow" || e.dataField !== "Idtipodocumento") return;
    if (!e.row.isNewRow) {
        e.editorOptions.readOnly = true;      // el tipo no se cambia en un pedido existente
        return;
    }
    e.editorOptions.dataSource = DevExpress.data.AspNet.createStore({
        key: "Id",
        loadUrl: urlRelativa + "/api/DocumentoArchivoNominaWebApi/GetActivos"
    });
}
```

`OnEditorPreparing` también se dispara para los editores del formulario (`e.parentType === "dataRow"`).

### 3.5 Nombrar bien las acciones del API

Evitá parámetros booleanos ambiguos. `GetActivosParaCombo(bool esParaFirmar)` confundía: `false` no *excluía* los de firma, simplemente no filtraba por firma. Una acción sin parámetros y con nombre claro (`GetActivos`) se entiende sola.

---

## 4. Buscador del grid

Usá el panel de búsqueda nativo, sin JS:

```csharp
.SearchPanel(sp => sp.Visible(true).Width(230).Placeholder("Buscar..."))
```

Antes lo hacíamos empujando un `dxTextBox` a la barra de herramientas desde JS (`OnToolbarPreparing`) y llamando a `searchByText`. Funciona, pero es código de más que el grid ya trae resuelto.

El botón "Agregar Documento" sí se personaliza en `OnToolbarPreparing`, porque cambiar el texto del botón nativo `addRowButton` exige conservar su `onClick`.

---

## 5. Validación

### 5.1 Las reglas van en la columna *(doc)*

```csharp
columns.AddFor(m => m.Idtipodocumento)
    .ValidationRules(v => v.AddRequired());      // correcto
```

La doc marca como **incorrecto** poner `validationRules` dentro de los ítems de `editing.form`. Por eso quitamos el `.IsRequired(true)` del ítem y lo movimos a la columna.

### 5.2 Reglas que dependen de más de un campo o del servidor

`OnRowValidating` corre después de las reglas de columna. Se cambian `e.isValid` y `e.errorText`:

```javascript
function onRowValidating(e) {
    if (e.isValid && e.newData.Descripcion && e.newData.Descripcion.length > 200) {
        e.isValid = false;
        e.errorText = "La descripcion debe contener maximo 200 caracteres.";
    }
}
```

Para consultar al servidor, asignás una promesa a `e.promise`:

```javascript
function onRowValidating(e) {
    if (e.newData.Email) {
        e.promise = $.ajax({ url: "/api/ValidarEmail", data: { email: e.newData.Email } })
            .done(function (r) { e.isValid = r.isValid; e.errorText = r.errorText; });
    }
}
```

### 5.3 La validación del servidor sigue mandando

La del navegador es comodidad; la que protege es la del `Negocio/`. En nómina `ValidarPermiso` y `AgregarDocumento` rechazan lo inválido aunque el JS no lo haya frenado.

---

## 6. Qué no hacer con `editorOptions`

*(doc)* El grid arma los editores de las columnas con sus propios manejadores. Por eso:

- No pongas **`onValueChanged`** dentro de `columns[].editorOptions` ni de `formItem.editorOptions`: el grid lo sobrescribe.
- No pongas **`template`** ahí. Para un editor propio, usá `editCellTemplate`.
- Diferencia:
  - `columns[].editorOptions` afecta al editor de la celda **y** al de la fila de filtros.
  - `columns[].formItem.editorOptions` afecta solo al formulario.

En SIIAN usamos `.Editor(ed => ed.SelectBox()...)` dentro de `.Form(...).Items(...)` y funciona. Solo recordá no meter `onValueChanged` ahí.

---

## 7. Rendimiento *(doc)*

| Situación | Qué hacer |
|---|---|
| Miles de filas | `.RemoteOperations(true)`: filtrar, ordenar, paginar y agrupar en el servidor. El `Get` debe aplicar `loadOptions` |
| Pocas filas (un contrato tiene decenas de pedidos) | `.RemoteOperations(false)`: todo en el navegador, más simple |
| Scroll virtual de filas | Solo si la paginación está desactivada o `pageSize` es grande |
| Más de 20 columnas fuera de pantalla | `Scrolling(s => s.ColumnRenderingMode(GridColumnRenderingMode.Virtual))` |
| Edición con `setCellValue` o `refresh()` frecuentes | `.RepaintChangesOnly(true)` |

Con `RemoteOperations(true)`, si tu `Get` no usa `DataSourceLoader.Load(...)` con las opciones, el grid pide una página y recibe todo (o al revés). Es la causa más común de "pagina rara".

---

## 8. Dónde va el JS

El JS de un grid va en el `<script>` del partial que contiene ese grid, no en el `Index` maestro.

```
Index.cshtml           -> solo lo compartido (urlRelativa, idContrato, agregarCombo, subirArchivos)
_TabSolicitados.cshtml -> editorDocumentoSolicitado, toolbarDocsSolicitados, onInitNewRowDocsSolicitados
_TabCargados.cshtml    -> verArchivoCargado
```

Así, cada pestaña se entiende y se mantiene por sí sola, y borrar una pestaña no deja funciones huérfanas en el `Index`.

---

## 9. Colores y estilo de la pantalla

Paleta corporativa (la del adjuntar archivo):

| Uso | Color |
|---|---|
| Cabeceras de grid, pestaña, botón primario | `#0281ba` |
| Hover y pestaña seleccionada | `#026a9c` |
| Acento intermedio | `#4da3cc` |
| Títulos | Negro (`#212529`) |

Los títulos van en negro. El azul se reserva para superficies (cabeceras, pestaña activa, botones), no para texto de título.

---

## 10. Lista de chequeo antes de dar por terminado un grid editable

- [ ] ¿Hay un combo? Entonces `Mode(Form)` o `Popup`, y el combo como ítem del formulario.
- [ ] ¿El combo busca por más de un campo? `SearchExpr` con array, y los campos llegan en el `Get`.
- [ ] ¿Puede haber registros inactivos ya guardados? El combo del formulario lista todos; las filas nuevas filtran activos.
- [ ] ¿La regla de obligatorio está en la columna (`ValidationRules`) y no en el ítem del formulario?
- [ ] ¿El permiso y las reglas se validan también en `Negocio/`?
- [ ] ¿El buscador es `SearchPanel` y no un `dxTextBox` a mano?
- [ ] ¿Hay `onValueChanged` o `template` dentro de `editorOptions` de una columna o ítem ligado? Sacarlos.
- [ ] ¿El JS está en el partial que usa esa función?
- [ ] ¿Se compiló? Una acción nueva del API da 404 hasta recompilar.

---

## Dónde consultar más

- Documentación oficial: <https://js.devexpress.com/> (sección DataGrid → Editing → Customize Edit Form).
- Skill del proyecto: `siian-devextreme-components`, apartado "SelectBox (FK) dentro de un DataGrid editable".
- Ejemplos en el repo: `Views/DocumentoArchivoNominaContrato/_TabSolicitados.cshtml` y el formulario de Subgestores del CRM (`GestionMaestroCRMWebApi` con `SearchExpr` de `Numeroticket` y `Asunto`).
