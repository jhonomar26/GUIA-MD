# Implementación — Cierre de tickets en estado "Solucionado"

Commit: `59fefab0405e995c3ba513224e7b659f5dffcf2b`. Reglas de negocio: [`REGLAS.md`](./REGLAS.md).

## Modelo de datos

- `crm_gestionmaestrocrm.tiempolimitesolucionado` — nueva columna `timestamp NULL`.
  Análoga a `tiempocalificacion` pero para la ventana de "Solucionado".
- `crm_estadogestioncrm` — ya existía la columna `essolucionado`; no se tocó el schema,
  solo se agregó el query `ObtenerEstadoSolucionado()`.
- `soporte_soporteconfiguracion.diasventanasolucionado` — ya existía (usado, no creado
  en este commit).

## Archivos por capa

**Blip.Data/Crm/GestionMaestroCRM.cs** — + propiedad `Tiempolimitesolucionado`, campo
estático `TiempolimitesolucionadoCampo`/`Tipo`, parámetro nuevo al final de ambos
constructores (rompe todos los `new GestionMaestroCRM(...)` existentes — ver "Impacto"
abajo).

**Blip.Data/Crm/GestionMaestroCRMActor.cs** — `CrearSelect`/`Insert`/`Update` incluyen
`tiempolimitesolucionado`. + `ObtenerPorIdcategoria(int?)` (no relacionado al feature,
colado en el mismo commit).

**Blip.Data/Crm/EstadoGestionCRMActorNegocio.cs** — + `ObtenerEstadoSolucionado()`:
`WHERE essolucionado = true`, `ObtenerUnoSinVerificarExistencia`.

**Blip.Entities/Crm.ViewModels/GestionMaestroCRMViewModel.cs** — espejo de la entidad:
+ `Tiempolimitesolucionado`, constructor con el nuevo parámetro.

**Blip.Entities/Soporte.ViewModels/CerrarTicketViewModel.cs** — archivo nuevo,
`SolucionarTicketViewModel` (pese al nombre del archivo): `IdGestion`, `IdUsuario`,
`EsperarVentanaSolucion`.

**Negocio/Crm/GestionMaestroCRMActorNegocio.cs**:
- `MarcarComoSolucionado(SolucionarTicketViewModel)` — método nuevo, valida acceso +
  no cerrado + no ya solucionado + sin mensajes pendientes; según
  `EsperarVentanaSolucion` setea estado `Solucionado` (+ `Tiempolimitesolucionado`) o
  `Escerradosincalificacion` directo. Audita con `SoporteAuditoriaActor.ActualizarGestionTiket`.
  **No llama a `EnviarCorreoCambioEstado`** (ver REGLAS.md → Pendiente).
- `ReabrirTicket(...)` — + bloque que revisa `Tiempolimitesolucionado` vencido: si venció,
  cierra el ticket en el momento (`Escerradosincalificacion`) y lanza excepción bloqueando
  la reapertura. Al reabrir con éxito, limpia `gestion.Tiempolimitesolucionado = null`
  (ya limpiaba `Tiempocalificacion`).
- Mensaje de error de "no se puede asignar estado solucionado desde edición" — ya
  existía el guard, el commit solo corrige un `;` sobrante que rompía la compilación.

**Negocio/Soporte/SoporteCalificacionActorNegocio.cs** — +
`CerrarTicketsVencidosSinCalificarSolucion()`: obtiene estado `Solucionado` y
`Escerradosincalificacion`, lista tickets vencidos
(`GestionMaestroCRMActor.ObtenerTicketsSolucionVencida(idEstadoSolucionado)` — método
en el Actor, no mostrado en este diff pero referenciado), los cierra uno por uno con
`try/catch` silencioso por ticket (un fallo no detiene el batch), usuario auditoría
`"sistema"`.

**Negocio/Cierres/CierreDiaViewModel.cs** — engancha
`CerrarTicketsVencidosSinCalificarSolucion()` junto a la ya existente
`CerrarTicketsVencidosSinCalificar()`, dentro de `#region tickets`.

**Negocio/Crm/GestionCrmAutomaticaActorNegocio.cs**,
**Negocio/Crm/GestionMaestoNegocioViewModel.cs** — solo actualización mecánica de las
llamadas al constructor de `GestionMaestroCRM` para pasar `Tiempolimitesolucionado`
(propagan `null`/el valor existente, sin lógica nueva).

**PruebaPostgreSQL/Controllers/WebApi/GestionMaestroCRMWebApiController.cs** — +
`POST MarcarComoSolucionado(SolucionarTicketViewModel)`: toma `IdUsuario` del usuario
autenticado, delega a Negocio, mapea `UnauthorizedAccessException`→403,
`InvalidOperationException`→400, resto→500 (patrón estándar del proyecto). `Get`/`Post`
existentes actualizados para incluir `Tiempolimitesolucionado`.

**PruebaPostgreSQL/Views/SoporteDetalle/Index.cshtml** — botón "Marcar como solucionado"
junto al de "Marcar Resuelto".

**PruebaPostgreSQL/Views/SoporteDetalle/_Popups.cshtml**:
- Filtro del SelectBox de estados en edición: excluye también `Essolucionado = true`
  (ya excluía cerrado/cerrado-con-calificación/cerrado-sin-calificación) — refuerza en
  UI la regla de "no asignar Solucionado desde edición".
- Popup `popupMarcarSolucionado` nuevo con checkbox "Esperar ventana de reapertura" y
  explicación inline de las dos ramas.
- JS: `marcarSolucionado()`, `guardarMarcarSolucionado()` (POST a
  `GestionMaestroCRMWebApi/MarcarComoSolucionado`, recarga la página al éxito),
  `cancelarMarcarSolucionado()`.

## Impacto / riesgo de este commit

El constructor de `GestionMaestroCRM` y de `GestionMaestroCRMViewModel` ganó un
parámetro más al final — **todo call-site existente que construya estos objetos
posicionalmente debe actualizarse** (ya se hizo en los archivos listados arriba, pero
si aparece otro call-site no tocado, no compila — es la señal de que falta, no un bug
silencioso).

## Qué falta / no cubierto por este commit

- Correo al cliente cuando se marca como solucionado o cuando se cierra automático por
  vencimiento (ver REGLAS.md).
- No hay UI visible para editar/ver `SoporteConfiguracion.Diasventanasolucionado`
  documentada acá — se asume que ya existe un formulario de configuración general
  (mismo patrón que `Diasventanacalificacion`).
