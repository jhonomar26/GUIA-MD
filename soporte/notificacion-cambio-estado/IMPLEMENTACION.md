# Implementación — Correo al cliente por cambio de estado de ticket

Commit: `6b3931d3875578e52c8bf3c31fd87e8d1873e5d0`. Reglas de negocio: [`REGLAS.md`](./REGLAS.md).

Cambio quirúrgico: 2 archivos, sin entidad/tabla/migración nueva, sin controller nuevo.
Reutiliza `EnviarCorreoActorNegocio.EnviarCorreo` (`Negocio/Generales/`), ya existente.

## `Negocio/Crm/GestionMaestroCRMActorNegocio.cs`

- **Método nuevo**: `EnviarCorreoCambioEstado(GestionMaestroCRM gestion, GestionMaestroCRM gestionAnterior)`.
  ```csharp
  if (gestionAnterior.Idestado == gestion.Idestado) return;
  var usuarioPortal = SoporteUsuarioSistemaActor.ObtenerPorIdtercero(gestion.Terceros_terceromaestroIdtercero.Id);
  if (usuarioPortal == null || string.IsNullOrWhiteSpace(usuarioPortal.Email)) return;
  var estadoAnterior = EstadoGestionCRMActor.ObtenerPorId(gestionAnterior.Idestado);
  var estadoNuevo = EstadoGestionCRMActor.ObtenerPorId(gestion.Idestado);
  // arma cuerpoHtml, llama EnviarCorreoActorNegocio.EnviarCorreo(...)
  ```
- **Se invoca desde** (siempre después de `GestionMaestroCRMActor.Update(gestion)`,
  pasando `gestion` ya actualizado + el snapshot `gestionAnterior` tomado antes del cambio):
  - `ActualizarDatosSoporte(...)` — edición normal.
  - `MarcarComoResuelto(...)`.
  - `ReabrirTicket(...)` — 3 puntos: auto-cierre por calificación vencida, auto-cierre
    por solucionado vencido, y la reapertura exitosa.
  - `MarcarComoSolucionado(...)`.

## `Negocio/Soporte/SoporteCalificacionActorNegocio.cs`

- `using Negocio.Crm;` agregado.
- `CerrarTicketsVencidosSinCalificar()` y `CerrarTicketsVencidosSinCalificarSolucion()`
  — ambos, dentro de su `foreach`/`try`, después del `Update`, llaman
  `GestionMaestroCRMActorNegocio.EnviarCorreoCambioEstado(gestion, gestionAnterior)`.
  El `catch (Exception) { }` que ya envolvía cada iteración (para que un ticket con
  error no tumbe el batch) ahora también absorbe fallos del envío de correo.

## Qué NO cambió

- No hay tabla de log de correos enviados.
- No hay plantilla editable ni configuración de "activar/desactivar notificación por
  estado" — es todo o nada, código fijo.
- `EnviarCorreoActorNegocio.EnviarCorreo` no se tocó — firma
  `EnviarCorreo(string para, string asunto, string mensaje, bool isHtml = false) : bool`.

## Riesgo / seguimiento sugerido

- Si en el futuro se necesita "no notificar en tal estado" o plantilla por estado, el
  punto de extensión es `EnviarCorreoCambioEstado` — está centralizado, un solo lugar
  para agregar esa lógica sin tocar los 6 call-sites.
- Considerar loguear cuando `EnviarCorreo` devuelve `false` (hoy se ignora el resultado
  en todos los call-sites) — ver REGLAS.md → "No cubierto".
