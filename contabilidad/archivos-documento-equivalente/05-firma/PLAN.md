# Plan: firmar documentos del documento equivalente

> [← README](./README.md) · Análisis: [ANALISIS.md](./ANALISIS.md) · Decisiones: [ADR-001](../ADR.md), [ADR-002](../ADR-002.md) · Plan histórico: [archivo/PLAN.md](../archivo/PLAN.md)

**Antes de programar:** `EXPLICACION.md` (parte lógica) y entrevista; después, paso 3b antes de commitear ([flujo](../../../guia/flujo-de-feature.md)). Skills según la capa: `siian-actor-dapper-metodos`, `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`.

**Regla de todas las tareas:** cada servicio recibe el id del comprobante **o** el del documento equivalente, exactamente uno; si no, 400 ([ADR-002](../ADR-002.md)). Marcas: `[L1]` latin1, `[FUERA]` script SQL fuera del repo, `[CSPROJ]` archivo nuevo a registrar.

## Tareas

- [ ] 1. `FirmaArchivoContableController.FirmarDocumento(idArchivo)`: el dueño y el tercero salen de la fila del archivo. · Se parece a: el mismo método
- [ ] 2. `[L1]` `_GestionDocumentos.cshtml`: la llamada a firmar sin depender del comprobante. · Se parece a: la llamada actual
- [ ] 3. Compilar Debug sin errores.

## Verificación

- [ ] E7 y E7b probados, con captura en `evidencia/`.
- [ ] Contable sin cambios: curls de 0.6 contra `../antes/` idénticos y el mismo recorrido en CO101.
- [ ] Commit propio de esta feature.
