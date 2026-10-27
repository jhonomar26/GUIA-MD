# Plan: solicitar documentos en el documento equivalente

> [← README](./README.md) · Análisis: [ANALISIS.md](./ANALISIS.md) · Explicación: [EXPLICACION.md](./EXPLICACION.md) · Decisiones: [ADR-001](../ADR.md), [ADR-002](../ADR-002.md) · Plan histórico: [archivo/PLAN.md](../archivo/PLAN.md)

**Antes de programar:** `EXPLICACION.md` (parte lógica) y entrevista; después, paso 3b antes de commitear ([flujo](../../../guia/flujo-de-feature.md)). Skills según la capa: `siian-actor-dapper-metodos`, `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`.

**Regla de todas las tareas:** cada servicio recibe el id del comprobante **o** el del documento equivalente, exactamente uno; si no, 400 ([ADR-002](../ADR-002.md)). Marcas: `[L1]` latin1, `[FUERA]` script SQL fuera del repo, `[CSPROJ]` archivo nuevo a registrar.

**Decisión 2026-10-20:** misma vista, controlador MVC aparte para el documento equivalente (contable no se toca), servicios WebApi compartidos. Ver [EXPLICACION.md](./EXPLICACION.md#una-pantalla-dos-entradas-decidido-2026-10-20).

## Tareas

- [x] 1. `[FUERA]` `11-permisos-solicitar-documento-equivalente.sql`, idempotente: funcionalidades `~/DocumentoEquivalenteCombo/AgregarCombo` y `~/DocumentoEquivalenteCombo/AgregarDocumentoIndividual` con sus acciones. **No asigna roles**: el administrador los habilita desde la pantalla de roles. Corrido en demo (2026-10-20): funcionalidades 147 y 148, acciones 265 y 266, sin roles asignados. · Se parece a: script 9
- [x] 2. `Negocio/Contabilidad/DocumentoContableComboAsignacionActorNegocio.cs`: constantes del documento equivalente; `TienePermisoAgregarMasCombos`, `TienePermisoAgregarDocumentosIndividuales` y `PuedeAgregarCombo` según cuál id viene. · Se parece a: los mismos métodos contables
- [x] 3. Mismo archivo: `ObtenerTerceroDelDocumento(idContable, idEquivalente)` y `AgregarCombo`: exactamente un id, documento guardado, tercero correcto, todo o nada. · Se parece a: `AgregarCombo` actual
- [x] 4. `DocumentoContableComboWebApiController`: `PostConSolicitados` pasa los dos ids y devuelve `Iddocumentoequivalente`; permiso y 400 los aplica `AgregarCombo`. La lista (`GetPorDocumento`) no se tocó: ninguna vista la usa. · Se parece a: el mismo controlador
- [x] 5. `DocumentoContableSolicitadoWebApiController`: los dos ids en `GetPorIdDocumento` y `Post`; en `Put` el dueño y el permiso salen de la fila; 400; 403 sin permiso; tercero con `ObtenerTerceroDelDocumento`. · Se parece a: el mismo controlador
- [x] 5b. `DocumentoContableCargadoWebApiController.GetPorIdDocumento` y `DocumentoContableEliminadoWebApiController.GetEliminadosPorIdDocumento`: los dos ids; 400. Las consultas ya los aceptan desde 01. · Se parece a: `GetPorIdDocumento` de solicitados
- [x] 6. `[CSPROJ]` MVC nuevo `Controllers/Contabilidad/DocumentoEquivalenteComboController.Index(iddocumentoequivalente)`: encabezado del documento equivalente (tipo, número, tercero, fecha), permisos propios y `View("~/Views/DocumentoContableCombo/Index.cshtml")`. El `Index` contable no cambia. · Se parece a: `DocumentoContableComboController.Index`
- [x] 7. `[L1]` `Views/DocumentoContableCombo/Index.cshtml`: título, `LoadParams` de las tres grillas con el id del dueño, ancla en `onInitNewRow` y `agregarCombo`, texto de confirmación, "Adjuntar Archivos" oculto en documento equivalente (hasta 03), botones según permiso. · Se parece a: la misma vista en contable
- [x] 8. `Views/DocumentoEquivalente/EdicionV2.cshtml` (UTF-8): botón **"Listar Documentos"** después de la línea ~619, deshabilitado con `Id == 0`, que abre `~/DocumentoEquivalenteCombo/?iddocumentoequivalente=@Id`. · Se parece a: `listarDocumentos()` de `DocumentoContable/CreateV2.cshtml`
- [x] 9. Compilar Debug sin errores.

## Verificación

- [x] E1, E2 y E4 (con permiso) probados en pantalla, con captura en `../08-revision-final/evidencia/`. E3, E4-rechazo, E5a y E5b no se probaron (decisión del usuario, 2026-10-22).
- [x] ~~Servicios con los dos ids y con ninguno → 400~~ Ya no aplica: ADR-003 dejó un servicio por dueño; el aislamiento se verificó leyendo con el id 1085 (equivalente 17, comprobante 0).
- [ ] Contable sin cambios: curls de 0.6 contra `../antes/` idénticos y el mismo recorrido en CO101.
- [ ] Commit propio de esta feature.
