# Implementación: Formatos Personalizados (Logo, Orientación, Placeholders)

**Documentado por:** Omar Jhon  
**Fecha:** 15 de julio de 2026  
**Commits base:** 0a2713b6a → f316c1815  
**Rama:** feat/formatos-personalizados

---

## Resumen

Completada implementación de 3 características para formatos personalizados en SIIAN:
1. **Insertar placeholders** en editores de texto (todas 8 vistas)
2. **Logo + propiedades** (posición, tamaño)  
3. **Orientación horizontal** (landscape en reportes)

Todos los cambios **comparten una sola tabla** (`generales_formatos`), **una sola entidad** (`Formatos`), y **un único reporte** (`XtraReportFormato`). Lo que varía es solo la **UI de edición** (7 vistas ramificadas + 1 genérica).

---

## Fases Implementadas

### Fase 1: Backend + Propiedades (commit 0a2713b6a)

**Qué cambió:**
- **Entidad**: `Blip.Entities/Generales.ViewModels/FormatosViewModel.cs` 
  - Propiedades agregadas: `Logoposicion`, `Logotamano`, `Orientacionhorizontal`
- **Controladores**:
  - `Controllers/FormatosController.cs` — mapeo GET/POST para las 3 props
  - `Controllers/WebApi/CartaCobroWebApiController.cs` — lógica de preview y sustitución placeholders
  - `Controllers/WebApi/FormatosWebApiController.cs` — persistencia
- **Reportes**:
  - `PruebaPostgreSQL/Reportes/XtraReportFormato.cs` — métodos para aplicar orientación y logo
- **Lógica**: `Negocio/Cobranzas/ReportesViewModelNegocio.cs` — sustitución placeholders (regex), preview en memoria

**Impacto**: Backend listo para 8 tipos de formato; reportes usan automáticamente orientación/logo sin cambios por tipo.

---

### Fase 2: Logo + Propiedades en UI (commit 6758678b1)

**Qué cambió:**
- **Vistas** (todas 8: Edicion.cshtml + 7 ramificadas):
  - `EdicionFormatoCarta.cshtml`
  - `EdicionFormatoCartaClientes.cshtml`
  - `EdicionFormatoCartaTerceros.cshtml`
  - `EdicionFormatoEliminacionArchivos.cshtml`
  - `EdicionFormatoNomina.cshtml`
  - `EdicionFormatoPagare.cshtml`
  - `EdicionFormatoPaz.cshtml`
  
  Cada una agregó:
  - RadioGroup: `Logoposicion` (Izquierda/Derecha/Arriba/Abajo)
  - NumberBox: `Logotamano` (0-100, %)
  - CheckBox: `Orientacionhorizontal`

- **Reportes**: 
  - `XtraReportPagarePersonalizado.cs/.Designer.cs` — soporte logo en reporte personalizado Pagare

---

### Fase 3: Orientación Horizontal (commit 3866046cc)

**Qué cambió:**
- **Reporte central**: `PruebaPostgreSQL/Reportes/XtraReportFormato.cs`
  - Método `AplicarOrientacionHorizontal(bool orientarHorizontal)` 
  - Ajusta ancho banda, márgenes, fuentes al cambiar a landscape

- **Controladores + Helpers** (limpiar consumo de orientación):
  - `CartaCobroController.cs` — usa flag directo de BD
  - `CartaCobroHelper.cs` — simplifica paso de orientación
  - `EnviarCorreosWebApiController.cs` — usa flag de BD
  - `EnviosFormatosCrmWebApiController.cs` — usa flag de BD
  - `PazYSalvoSucursalVrtlWebApiController.cs` — usa flag de BD
  - `ReportePersonalizadoExpedienteVirtual.cs` — usa flag de BD

- **Vistas** (todas 8): agregaron CheckBox `Orientacionhorizontal` visible

---

### Fase 4: Insertar Placeholders en Editores (commit f316c1815)

**Qué cambió:**
- **Vistas** (todas 8 ramificadas + genérica):
  - `Edicion.cshtml` — agregó SelectBox + botón
  - `EdicionFormatoCarta.cshtml` → `EdicionFormatoPaz.cshtml` — cada una con su lista de placeholders

  Cada vista incluye:
  - SelectBox con `{N}` placeholders específicos del tipo (ej: `EdicionFormatoCarta` 30 campos, `EdicionFormatoPaz` 10 campos)
  - Botón "Insertar" → JS inserta `{N}` en editor seleccionado
  - Botón "Limpiar" → vacía editor

---

## Estado Final

### ✅ Completado

| Componente | Estado | Ubicación |
|---|---|---|
| **BD + Entidad** | ✅ Persistencia de 3 props | `FormatosViewModel` |
| **Reportes** | ✅ Logo + orientación aplicados | `XtraReportFormato.cs` |
| **Backend Preview** | ✅ Sustitución placeholders + vista previa | `ReportesViewModelNegocio.cs` + `CartaCobroWebApiController` |
| **UI Logo/Orientación** | ✅ 8 vistas con controles | Todas vistas Edicion*.cshtml |
| **UI Placeholders** | ✅ SelectBox + insertador por vista | Todas vistas Edicion*.cshtml |
| **Regresión** | ✅ Reportes sin orientación usan default | `AplicarOrientacionHorizontal` condicional |

### 🔄 Flujo End-to-End

1. Usuario abre `Formatos/EdicionFormatoCarta` (o ramificada)
2. Edita HTML en 3 editores: Cabecera, Cuerpo, Pie
3. Insertar campos: SelectBox → Insertar → `{0}` se copia al editor
4. Configurar logo: RadioGroup (posición) + NumberBox (tamaño %)
5. Configurar orientación: CheckBox horizontal
6. Guardar → Persiste en `generales_formatos` (3 columnas: logoposicion, logotamano, orientacionhorizontal)
7. Generar carta real (`CartaCobroController.Formato`) → `XtraReportFormato`:
   - Sustituye `{0}`, `{1}`, etc. con datos reales
   - Posiciona logo según `logoposicion` + `logotamano`
   - Aplica landscape si `orientacionhorizontal = true`

---

## Cambios por Área

### Base de Datos
- Tabla `generales_formatos` — 3 columnas nuevas (ya migradas):
  - `logoposicion` (int) — 1=Izq, 2=Der, 3=Arriba, 4=Abajo
  - `logotamano` (int) — 0-100%
  - `orientacionhorizontal` (bool)

### Entidades (Blip.Entities)
- `FormatosViewModel.cs` — 3 propiedades bindeadas

### Reportes (PruebaPostgreSQL/Reportes)
- `XtraReportFormato.cs` — métodos `AplicarOrientacionHorizontal()`, lógica de posicionamiento logo
- `XtraReportPagarePersonalizado.cs` — logo en reporte Pagare

### Controladores
- `FormatosController.cs` — GET/POST mapean 3 props
- `CartaCobroController.cs` — consumidor simplificado
- `CartaCobroWebApiController.cs` — preview + sustitución
- `FormatosWebApiController.cs` — persistencia

### Vistas (Views/Formatos)
- `Edicion.cshtml` — genérica (fallback)
- `EdicionFormatoCarta.cshtml` — ramificada tipo Mora
- `EdicionFormatoCartaClientes.cshtml` — ramificada tipo Clientes
- `EdicionFormatoCartaTerceros.cshtml` — ramificada tipo Terceros
- `EdicionFormatoEliminacionArchivos.cshtml` — ramificada tipo EliminacionArchivos
- `EdicionFormatoNomina.cshtml` — ramificada tipo Nomina
- `EdicionFormatoPagare.cshtml` — ramificada tipo Pagare
- `EdicionFormatoPaz.cshtml` — ramificada tipo PazySalvo

Todas incluyen:
- SelectBox + placeholders por tipo
- RadioGroup (Logoposicion)
- NumberBox (Logotamano)
- CheckBox (Orientacionhorizontal)

### Lógica de Negocio
- `ReportesViewModelNegocio.cs` — sustitución placeholders con regex, manejo de excepciones `FormatException`

---

## Testing Recomendado

1. **Edición UI**: Abrir cada una de las 8 vistas → editar HTML, insertar placeholders, guardar logo/orientación
2. **Persistencia**: Recargar vista → confirmar datos guardados
3. **Generación**: Crear carta real con orientación landscape → confirmar ancho banda correcto
4. **Regresión**: Generar cartas de formatos sin orientación → usar default portrait
5. **Placeholder**: Generar carta con múltiples placeholders (`{0}`, `{5}`, etc.) → confirmar sustitución correcta

---

## Notas

- Las 8 vistas comparten la **misma tabla** y **mismo reporte**, pero cada una tiene su **lista de placeholders** específica.
- El reporte `XtraReportFormato` es único — detecta automáticamente orientación/logo de BD sin cambios por tipo.
- Orientación landscape: ajusta ancho banda, márgenes, fuentes. Usa condicional para evitar romper reportes sin orientación.
- Placeholder `{N}` donde N es índice 0-basado del campo según tipo. Cada tipo tiene su correspondencia (ej: en Mora, `{0}`=Préstamo, `{1}`=Deudor; en Paz, `{0}`=Tercero, `{1}`=Documento).
