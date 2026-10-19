# Plan por fases — Blindar validación de estados de Garantía  
  
Complementa `LOGICA-ESTADOS-GARANTIA.md` (mismo folder). Ahí está el  
"qué debería pasar"; acá el plan para cerrar los huecos encontrados,  
uno por uno, sin romper el flujo principal que ya funciona bien  
(Aprobar/Anular/Liberar).  
  
Marcar `[x]` cada fase al terminarla.  
  
---  
  
## Fase 1 — Garantes: eliminados los endpoints sin uso (hecho a mano)  
  
- [x] Hecho  
  
**Diagnóstico confirmado:** `Post`/`Put`/`Delete` genéricos en  
`VehiculoGarantiaGaranteWebApiController.cs` e  
`InmuebleGarantiaGaranteWebApiController.cs` insertaban/actualizaban/  
borraban garantes sin validar `Estado`. Se verificó por grep que  
ninguna de las 4 vistas del módulo los usaba (todas mapean  
`InsertAction("PostValorAvaluo")` / `DeleteAction("DeleteValorAvaluo")`  
y tienen `AllowUpdating(false)`) — esos métodos ya validan  
`Estado != "CREADA"` vía `GarantiaGaranteActorNegocio`.  
  
**Decisión:** en vez de blindar código muerto, se eliminaron los  
métodos genéricos directamente (más lazy y más seguro que agregarles  
validación). Ya aplicado manualmente por el usuario en ambos  
controllers.  
  
---  
  
## Fase 2 — Blindar el registro principal (Put + Eliminar)  
  
- [x] Hecho  
  
**Ajuste sobre el plan original:** se separó en dos acciones tras  
verificar uso real (grep en Views/Scripts/Content):  
  
- `Post`/`Put`/`Delete` genéricos de `GarantiaGarantiaVehiculoWebApiController.cs`  
  e `...InmuebleWebApiController.cs` — confirmados sin ningún caller (los  
  4 grids Deudor/Codeudores que parecían apuntar ahí en realidad solo  
  usan `GarantiaGarantiaVehiculo/InmuebleWebApi` para un lookup de solo  
  lectura; su CRUD real es contra `VehiculoPersonaGarantiaWebApi`/  
  `InmueblePersonaGarantiaWebApi`). **Eliminados.**  
- `PutActivos`/`DeleteActivos` — sí están en uso por las 4 vistas  
  principales del módulo, sin validación de estado ni en UI ni servidor.  
  **Blindados**: nuevo método `ValidarEditable(idgarantia)` en  
  `ContabilizarGarantiaVehiculoActorNegocio`/`...InmuebleActorNegocio`  
  (mismo patrón que `GarantiaGaranteActorNegocio`), conectado en ambos  
  métodos de ambos controllers. Bloquea editar/eliminar si  
  `Estado != "CREADA"`.  
  
**Objetivo:** que no se pueda editar ni eliminar una garantía (vehículo  
o inmueble) que ya no está "Creada" — ni siquiera forzando el `Estado`  
directo en el payload.  
  
**Qué falta crear:** un método `ValidarEditable(garantia)` en:  
  
- `Negocio/Garantias/ContabilizarGarantiaVehiculoActorNegocio.cs`  
- `Negocio/Garantias/ContabilizarGarantiaInmuebleActorNegocio.cs`  
  
(mismo archivo que ya tiene las guardas de Aprobar/Anular/Liberar —  
una sola fuente de verdad, no una clase nueva).  
  
**Dónde conectarlo:**  
  
- `Put` en `GarantiaGarantiaVehiculoWebApiController.cs:52-91` y  
  `GarantiaGarantiaInmuebleWebApiController.cs:52-93`  
- `DeleteActivos` en ambos controllers (`:249-276` / `:261-284`)  
  
**Riesgo:** medio. Es lógica nueva (aunque simple: un `if Estado !=  
"CREADA" throw`), y toca 2 controllers + 2 clases de negocio.  
  
---  
  
## Fase 3 — Fix menor: asimetría `Idparametro` nulo  
  
- [ ] Pendiente  
  
**Objetivo:** que Inmueble se comporte igual que Vehículo cuando  
`Idparametro` viene null — tirar excepción de negocio clara, no una  
`InvalidOperationException` cruda.  
  
**Dónde:** `ContabilizarGarantiaInmuebleActorNegocio.cs:98` (Liberar) y  
`:177` (Anular) → usar `garantia.Idparametro ?? 0` en vez de  
`.Value`, igual que ya hace Vehículo en `:99`.  
  
**Riesgo:** bajo. Cambio de una línea en 2 lugares, sin tocar  
controllers ni firmas.  
  
---  
  
## Fuera de alcance (por ahora)  
  
**Duplicación de strings de estado** (`"CREADA"/"ACTIVA"/"ANULADA"/  
"LIBERADA"` repetidos en 2 clases de negocio + 3 vistas). Es deuda  
técnica, no bug funcional — no se toca salvo pedido explícito aparte.