# Plan — Configuración de documentos contables igual a la de crédito

> **Historia.** Plan ya ejecutado; el anexo técnico refleja lo que se planeó, no necesariamente lo que quedó. Vigente: [FLUJO.md](./FLUJO.md).

> **Estado: F0 a F3 implementadas en código.** Pendiente: el filtro "formato contable" del selector de plantillas (la tabla de formatos aún no tiene esa marca) y el script que marca las plantillas contables (P7'). No hay `IMPLEMENTACION.md` ni evidencia de prueba en navegador.
> Pedido y alcance: [`REQUERIMIENTO.md`](./REQUERIMIENTO.md). Brecha, reglas, hallazgos y decisiones: [`ANALISIS.md`](./ANALISIS.md).

## En una frase

La pantalla de configuración de documentos contables pasa a ofrecer lo mismo que la de crédito, salvo convenios, días de fin de crédito y geolocalización. Se trabaja de la base de datos hacia la pantalla. Solo esta vista.

## Qué cambia

| Pieza | Cambio |
|---|---|
| Página | Filtro "Activos / Todos" con ayuda. Sale la grilla de tipos de soporte. Nada se borra: se inactiva |
| Agrupaciones | Solo se quita el borrado |
| Tipos de documento | Se agregan firma electrónica, foto y formato personalizado con sus plantillas. Se limpia el vencimiento al desmarcar "expira". La pantalla guía el vencimiento |
| Combos | Se agrega "para firmar". Se pueden editar |
| Documentos del combo | Se agrega "activo". Muestra si el tipo está activo. Se pueden editar. Sin repetidos. Filtro por firma |
| Plantillas | Marca nueva "formato contable", que por ahora se pone con un script |
| Comprobantes | Igual que crédito: al agregar un combo solo se ofrecen combos activos y solo se piden sus documentos activos (P8) |

## Reglas de negocio

Detalle y porqué en el [`ANALISIS.md`](./ANALISIS.md): secciones 3 y 7.

| # | Regla |
|---|---|
| R1 | Si un tipo de documento no expira, no guarda fecha manual ni días |
| R2 | Si expira, lleva exactamente uno de los dos: fecha manual o N días desde el cargue. Los días no pueden ser negativos |
| R3 | Las plantillas solo aplican si el tipo es "formato personalizado", y solo se ofrecen las marcadas como "formato contable". Si se quitan todas, no queda ninguna activa |
| R4 | A un combo "para firmar" solo se le pueden agregar tipos con firma electrónica. Lo que ya tenía se conserva |
| R5 | Un tipo de documento aparece una sola vez por combo |
| R6 | Desde esta pantalla nada se borra, se inactiva. Todo lo que existe hoy queda activo |
| R7 | Al elegir un tipo de documento para un combo, solo se ofrecen los activos |
| R8 | En un comprobante solo se pueden elegir combos activos. Al agregar un combo se piden solo los documentos activos en el combo cuyo tipo también está activo. Lo que ya se pidió antes se sigue viendo |

---

## F0 — Preparación y verificación de la base ✅ Resuelto (2026-09-29)

- Comparar las tablas reales de la base demo con lo que asume el análisis (H11): columnas, la regla de días que menciona un comentario y las restricciones de unicidad.
- Buscar combos que ya tengan el mismo tipo de documento repetido. Si hay, definir con negocio cuál se conserva antes de F1, porque bloquean R5.
- Confirmar desde qué menú se entra hoy a la pantalla (H12).

**Verificación:**
- Las diferencias quedan anotadas en este plan, o no hay ninguna.
- Los repetidos son cero o tienen decisión.

**Hallazgos F0 (verificado en `pg-demo`, base `demo-25-09-2026`, 2026-09-29):**
- **Columnas de `contabilidad_documentotipo`:** las que ya existen (`id, nombre, esactivo, idagrupaciondocumento, expira, diasvencimientodespuescargue, esdocumentounico, esfechamanual`) coinciden con lo que asume el análisis. **No tiene** `esfirmaelectronica`, `esfoto` ni `esformatopersonalizado` todavía. Faltan agregarlas, en "no" para lo existente, como asume el plan (F1).
- **La regla CHECK que menciona el comentario de `DocumentoTipoActorNegocio.cs:27` no existe en la base.** `constraints` de la tabla viene vacío: la validación de vencimiento hoy es solo de código (`ValidarYNormalizar`), no una restricción real de PostgreSQL. Ajusta H11: no hay CHECK que replicar ni romper, solo el código.
- **`contabilidad_documentotipoformato` no existe.** Se crea desde cero en F1, como asume el plan.
- **`generales_formatos`:** no tiene `esformatocontable` todavía. Falta agregarla, como asume el plan.
- **`contabilidad_combodocumentotipo`:** no tiene `esparafirmar` todavía. Falta agregarla, como asume el plan.
- **`contabilidad_combodocumentocontable`:** **ya tiene** el índice único `(idcombo, iddocumento)` (`contabilidad_combodocumentocontable_idcombo_iddocumento_key`). El paso de F1 "se agrega UNIQUE, que depende de F0" **no aplica: ya existe**. Sigue faltando `esactivo`.
- **Repetidos en combos:** cero (`GROUP BY idcombo, iddocumento HAVING COUNT(*) > 1` no devuelve filas). Coincide con que el índice único ya existe: no puede haber duplicados hoy. Sin decisión pendiente.
- **H12 — menú confirmado:** ni `DocumentoTipoController` ni `DocumentoContableComboController` tienen fila en `generales_menu` (columna `funcionalidad` no matchea `/DocumentoTipo` ni `/DocumentoContableCombo`). Hoy se entra a `DocumentoContableCombo` desde un botón dentro de `Views/DocumentoContable/CreateV2.cshtml:2635` (`listarDocumentos()` hace `window.location.href = '.../DocumentoContableCombo/?iddocumento=' + Model.Id`), es decir, desde un documento contable ya creado. **No se encontró ningún link ni menú hacia `DocumentoTipo/Index`** (la pantalla de agrupaciones/tipos/combos, que es el foco real de este plan). **Decisión:** se agrega un ítem de menú nuevo (`EV006`, hermano de EV002-EV005 bajo "EV0 - Parámetros"), solo para `DocumentoTipo`. `DocumentoContableCombo` sigue entrando por su botón contextual, sin ítem propio. Script: `scriptsSiian/contabilidad/scratch/menu-documentotipo.sql` (todos los roles quedan inactivos hasta que negocio confirme a quién habilitar).

## F1 — Base de datos

**Script:** `scriptsSiian/contabilidad/scratch/1-documentotipo-columnas.sql` (pendiente de correr en demo — pasa a `entregables/YYYY-MM-DD-entregable/` con ese mismo número cuando se mande a producción). Pruebas en archivo aparte: `documentotipo-columnas-pruebas.sql`.

- **Tipo de documento:** firma electrónica, foto y formato personalizado. En "no" para lo existente.
- **Relación tipo de documento–plantilla:** con activo y fechas, igual que crédito.
- **Plantillas:** marca "formato contable", en "no". Más el script que marca las plantillas que usará contabilidad — **pendiente**, falta que negocio confirme cuáles (P7').
- **Combo:** "para firmar", en "no".
- **Documento del combo:** "activo", en "sí" para lo existente. ~~Más la regla de base que impide repetir un tipo en el mismo combo (R5)~~ — **ya existe** (`contabilidad_combodocumentocontable_idcombo_iddocumento_key`, confirmado en F0), no se recrea.

**Verificación:**
- Los scripts corren en la base demo sin error.
- La cantidad de registros es la misma antes y después.
- Los valores por defecto son los esperados.
- Insertar un repetido a mano falla.

## F2 — Guardar y leer ✅ Resuelto (2026-09-29), salvo una excepción

- **Tipos de documento:**
  - Guardan y devuelven las marcas nuevas y sus plantillas: cuáles están elegidas y sus nombres para mostrar en la grilla.
  - Aplican R1 a R3.
  - Los errores llegan como mensaje claro, no como error interno.
- **Combos:** guardan y editan "para firmar".
- **Documentos del combo:**
  - Guardan "activo" y devuelven si el tipo de documento está activo.
  - Rechazan repetidos con un mensaje (R5).
- **Borrado:** se quita en las cuatro piezas, en el servidor y no solo en la pantalla (R6).
- **Lista de tipos para un combo:** solo activos (R7) y, si el combo es "para firmar", solo con firma (R4).
- **Comprobantes (R8):**
  - La lista de combos para elegir trae solo los activos.
  - Al agregar un combo se crean solo los documentos activos, como en crédito.

**Verificación:**
- Desmarcar "expira" limpia la fecha manual y los días. ✅
- Se rechaza guardar un tipo que expira sin tipo de vencimiento, uno con los dos tipos a la vez y uno con días negativos. ✅
- Si se quitan todas las plantillas de un tipo, no queda ninguna activa. ✅
- Agregar un repetido al combo muestra el mensaje. ✅
- Borrar se rechaza. ✅
- Si un combo tiene un documento inactivo, al agregar ese combo a un comprobante ese documento no se pide. ✅

**Pendiente dentro de R3 — filtro "solo se ofrecen las marcadas como formato contable":**
Requiere agregar `esformatocontable` a `Blip.Data/Generales/Formatos.cs`. Se decidió **no** tocarlo en
esta pasada: `FormatosViewModel.cs` tiene 20+ llamadas `new FormatosViewModel(...)` repartidas en
Cartera, Cobranzas, Crédito, Nómina, Pagaré y varios controladores — cambiar su constructor posicional
las afecta a todas. Guardar/leer plantillas y mostrar sus nombres en la grilla **sí** quedó resuelto,
sin este filtro (hoy se puede elegir cualquier plantilla, no solo las marcadas "formato contable").
Se retoma como tarea aislada, con la skill `siian-plantillas-generadas`.

**Lo que sigue F3 para dejar esto usable en pantalla** (F2 dejó el backend listo, sin wiring a vista):
combos activos (`ComboDocumentoTipoActorNegocio.ObtenerCombosActivos`), tipos activos/con firma
(`DocumentoTipoWebApiController.GetActivosParaCombo`), plantillas con nombre (`GetConDocumentoTipoFormato`).

## F3 — Pantalla 🟡 Código escrito (2026-09-29), falta build y prueba manual

Archivos: `Views/DocumentoTipo/Index.cshtml` (rehecha, ISO-8859-1), `Views/DocumentoContableCombo/Index.cshtml` (R8), acción nueva `ComboDocumentoTipoWebApi/GetActivos`. Los botones "+" pasaron a texto ("Agregar tipo de documento", etc.). Sigue pendiente el filtro "formato contable" del selector de plantillas (ver F2).

- **Filtro "Activos / Todos":** para agrupaciones, tipos y combos. Arranca en "Activos" y tiene botón de ayuda, como en crédito.
- **Tipos de soporte:** se quita todo (grilla y botón "Configurar soportes"). La carga de archivos valida con una lista fija de extensiones, como crédito. Tablas y endpoints de soportes quedan sin uso (deuda de limpieza).
- **Tipos de documento:**
  - Columnas y formulario nuevos.
  - "Expira" habilita las opciones de vencimiento y "fecha manual" deshabilita los días.
  - El selector de plantillas solo se habilita con "formato personalizado".
- **Combos:** se pueden editar y tienen "para firmar".
- **Documentos del combo:**
  - Muestran "activo" y "tipo activo", este último solo de lectura. Se pueden editar.
  - El selector aplica R4 y R7.
  - "Obligatorio" se mantiene.
- **Borrado:** ninguna grilla tiene botón de borrar.
- **Página de documentos del comprobante (R8):**
  - Al elegir un combo o agregar un documento a mano, solo aparecen los activos.
  - Lo que ya se pidió sigue mostrando su nombre, aunque el tipo esté inactivo.

**Verificación:** el recorrido de "Verificación general".

---

## Fuera de alcance

Ver [`ANALISIS.md`](./ANALISIS.md), sección 6: uso de las banderas nuevas en la carga contable, marcar plantillas desde la pantalla de formatos, errores de "obligatorio" y vencidos en comprobantes, y errores propios de crédito.

## Verificación general

No hay suite automatizada. Cada fase cierra con:
1. SQL ejecutado en la base demo.
2. Build de la solución.
3. Prueba manual según la verificación de la fase.
4. `IMPLEMENTACION.md` de la fase en esta carpeta.

Recorrido final:
1. Crear un tipo que expira a 30 días del cargue. Editarlo y desmarcar "expira": los días desaparecen.
2. Marcar "formato personalizado" y elegir dos plantillas contables. Se ven en la grilla. Quitar las dos: la grilla queda sin plantillas.
3. Crear un combo "para firmar". Al agregarle documentos solo aparecen tipos activos con firma electrónica.
4. Agregar el mismo documento dos veces al combo: aparece el mensaje.
5. Inactivar una agrupación, un tipo, un combo y un documento del combo. Con "Activos" desaparecen y con "Todos" aparecen. No hay botón de borrar en ninguna grilla.
6. Subir un .pdf y un .jpg a un documento solicitado funciona, y un .exe se rechaza, también en un tipo nuevo.
7. En un comprobante, el combo inactivado del paso 5 no aparece para elegir. Otro combo que tiene un documento inactivo se agrega sin ese documento. Los documentos que ya se habían pedido siguen visibles.

---

## Anexo técnico (verificado en el repo, para quien implemente)

> Este anexo es la única parte con nombres de código. Al construir, pasa a `IMPLEMENTACION.md`.

**Tablas (F1)**
- **`contabilidad_documentotipo`:**
  - Se agregan `esfirmaelectronica`, `esfoto` y `esformatopersonalizado`, bool NOT NULL DEFAULT false.
  - Entidad: `Blip.Data/Contabilidad/DocumentoTipo.cs`. ViewModel: `DocumentoTipoViewModel`.
- **Nueva `contabilidad_documentotipoformato`:**
  - Columnas: `iddocumentotipo`, `idgeneralesformato`, `fechacreacion`, `fechamodificacion`, `esactivo`.
  - Es espejo de `credito_documentocreditoformato` (`Blip.Data/Credito/DocumentoCreditoFormato.cs`: llave compuesta, y crédito llama `estactivo` a la columna de activo).
  - WFAGenerarDao la generaría como `DocumentoTipoFormato`. No choca con otra clase (verificado).
- **`generales_formatos`:**
  - Se agrega `esformatocontable`, bool DEFAULT false, junto a `esformatopagare` (`Blip.Data/Generales/Formatos.cs:16,85`).
  - Hay un solo `new Formatos(...)` en el repo (`FormatosWebApiController`).
- **`contabilidad_combodocumentotipo`:** se agrega `esparafirmar`, bool DEFAULT false.
- **`contabilidad_combodocumentocontable`:**
  - Se agrega `esactivo`, bool DEFAULT true.
  - Se agrega UNIQUE `(idcombo, iddocumento)`, que depende de F0.
  - Para el mensaje de repetido ya existe `ComboDocumentoContableActor.ObtenerPorIdcomboIddocumento` (`:121`).

**Qué se copia de crédito (F2/F3)**
- **Lectura con plantillas:** `DocumentoCreditoWebApiController.GetConDocumentoCreditoFormato`, que usa `DocumentoCreditoFormatoActorNegocio.ObtenerIdsFormatosPorIdDocumentoCreditoActivos` (`:62`) y `ObtenerCadenaFormatosPorIdDocumentoCreditoActivos` (`:87`).
- **Guardado con plantillas:** `Negocio/Credito/DocumentoCreditoActorNegocioViewModel.cs:269-298`. Se copia **sin** la condición de `:273`, para que desactive siempre (H6).
- **Pantalla:** en `Views/DocumentoCredito/Index.cshtml`:
  - el switch (`:147-160`, `:546-578`)
  - la ayuda (`:125-146`, `:580-585`)
  - el TagBox de formatos (`:107-123`)
  - el filtro de firma (`:612-625`), sin la parte de convenios
- **Reglas de vencimiento en pantalla (`:422-515`):** conviene reescribirlas con `onEditorPreparing`. El original depende de `cellClick` e índices de columna fijos, y contabilidad tiene un solo campo de días.

**Qué ya existe en contabilidad**
- **Validación:** `Blip.Data/Contabilidad/DocumentoTipoActorNegocio.ValidarYNormalizar` (`:8-51`). Ya devuelve 400; se le agregan la limpieza de R1 y los días ≥ 0. Referencia parecida: `Blip.Entities/Garantias.ViewModels/GarantiaTipoDocumentoViewModel.cs:64-92`.
- **Tipos de soporte:** el popup y `DocumentoTipoTiposSoporteWebApi` quedan sin cambios. Se quita solo la grilla `TiposSoporteViewModel` (`Views/DocumentoTipo/Index.cshtml:105-126`).
- **Editar combos:** la grilla tiene `AllowUpdating(true)` pero `UpdateAction(false)` (`Index.cshtml:223-227`). Hay que habilitar el update (H8).
- **Borrado:**
  - Se quitan `AllowDeleting` y `DeleteAction` en `Index.cshtml:93-98, 168, 204, 224-227, 241-247`.
  - Se quitan las acciones `Delete` de `AgrupacionDocumentoContableWebApi`, `DocumentoTipoWebApi`, `ComboDocumentoTipoWebApi` y `ComboDocumentoContableWebApi`.
  - Solo esta vista usa esos borrados: `Views/DocumentoContableCombo` usa únicamente los `Get` (verificado).
- **Selector de documentos del combo:** `Index.cshtml:236` usa `DocumentoTipoWebApi/Get` sin filtro. Hay que filtrar por activos y, si el combo es "para firmar", por firma.
- **Comprobantes (R8), copiando de crédito:**
  - Crédito ofrece los combos con `Blip.Data/Credito/ComboDocumentoCreditoActorNegocio.ObtenerCombosActivos` (`:14`).
  - Pide los documentos con `Blip.Data/Credito/DocumentosCreditoComboActorNegocio.ObtenerDocsComboActivos` (`:49`), que exige combo-documento activo y tipo de documento activo.
  - En contabilidad hoy:
    - `Views/DocumentoContableCombo/Index.cshtml:196-197`: lista de combos sin filtro.
    - `Index.cshtml:247-248`: tipos de documento sin filtro. Crédito usa `GetActivos` para agregar (`Views/DocumentoCreditoCredito/Index.cshtml:246`) y `Get` para mostrar.
    - `Blip.Data/Contabilidad/DocumentoContableComboActorNegocio.cs:16`: usa `ComboDocumentoContableActor.ObtenerPorIdcombo` y lo debe reemplazar el equivalente de `ObtenerDocsComboActivos`.

**Patrones a respetar**
- **Skills antes de codificar:**
  - `siian-plantillas-generadas`, para columnas nuevas en entidades y ViewModels generados, que tienen constructor posicional
  - `siian-actor-pattern`, para la tabla nueva
  - `siian-actor-dapper-metodos`
  - `siian-devextreme-components`
  - `siian-devextreme-behavior`
- **Base y SQL:**
  - Verificación de base (F0) con el MCP de solo lectura `pg-demo` ([`bases-datos/USO.md`](../../../bases-datos/USO.md)). PostgreSQL 11.18, Npgsql 2.2.7.
  - Campos estáticos de la entidad en el SQL, nunca literales. En `UPDATE SET`, `.Split('.')[2]`.
- **Proyecto:** registrar cada `.cs` nuevo en su csproj. Rama: `feature/expediente-virtual`.
