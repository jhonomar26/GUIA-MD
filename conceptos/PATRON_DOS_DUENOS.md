# Patrón para una funcionalidad que sirve a dos dueños

Cuando una pantalla o un servicio lo comparten el **comprobante contable** y el **documento equivalente**, se aplica el mismo patrón en todas sus operaciones. Decisión y razones: [ADR-002 de `remodelacion-bd`](../contabilidad/archivos-contabilidad/remodelacion-bd/ADR-002.md), que reemplaza al [ADR-003](../contabilidad/archivos-documento-equivalente/ADR-003.md) solo en la capa web.

## Las capas

| Capa | Qué recibe | Qué hace |
|---|---|---|
| WebApi / MVC | `int? iddocumento = null`, `int? iddocumentoequivalente = null` | Llama a **un** método del despachador y responde. Sin lógica |
| Despachador (`ArchivoContableDuenoActorNegocio`) | Los dos `int?` | Valida que llegue **exactamente uno** y delega. Único lugar con el ternario de dueño |
| Clase por dueño (`DocumentoContable...`, `DocumentoEquivalente...`) | Un `int` | Reglas de ese dueño (ruta, permiso, verificación de pertenencia) |
| Clases comunes sin dueño (`Reglas`, `Almacenamiento`, `Subida`) | Lo que haga falta | Reglas que no dependen del dueño |
| `Blip.Data` | Un `int` por método | `...PorIddocumentocontable(int)` y `...PorIddocumentoequivalente(int)` llaman a un `Consultar...(campoDueno, idDueno)` privado |

## Al agregar una operación nueva

1. Una sola acción en el WebApi o MVC, con los dos `int?` y `= null`. Nada de `...Equivalente`.
2. Un método en el despachador que valida y delega.
3. Un método en cada clase por dueño, con un `int`.
4. En `Data`, un método por dueño sobre un `Consultar...` privado.
5. La vista pasa los dos ids en `LoadParams` y llama siempre a la misma acción. Sin `ViewBag.Accion*`.

## Trampas

- **Sin `= null`, WebApi responde 404** si falta uno de los dos parámetros (el selector de acciones los trata como obligatorios).
- **El par `int?` no baja de la capa web.** Si aparece en `Data` o en una clase por dueño, hay que volver a un `int`.

## Pendientes que siguen este patrón

La lista viva está en [`PLAN.md` de `remodelacion-bd`](../contabilidad/archivos-contabilidad/remodelacion-bd/PLAN.md): T2.2 (Vencidos), T3.1 (Eliminar) y T5.2 (alinear `Data` de cargados, estado y combos).
