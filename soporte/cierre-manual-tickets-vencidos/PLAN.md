# Plan — Cierre manual de tickets vencidos (respetando el calendario)

> Ver [`REQUERIMIENTO.md`](./REQUERIMIENTO.md) para la decisión acordada.
> Ver [`../soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md`](../soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md)
> para el diagnóstico (H1-H6) que originó este plan.
> Ver [`VALIDACION-ESTADO-CIERRE.md`](./VALIDACION-ESTADO-CIERRE.md) para el detalle de la corrección
> de `Fechacierre` aplicada junto con la Fase 2 (toca también `MarcarComoResuelto`, `ReabrirTicket` y
> `CalificarTicket`, fuera de este archivo).
>
> **Estado: Fases 1, 2, 3, 4 y 5 implementadas.**

## Diseño

El cierre de tickets deja de vivir dentro del Cierre de Día — se elimina de ahí por completo
(`CierreDiaViewModel.cs:507-512`, `#region tickets`). Pasa a ser exclusivamente manual, disparado
desde un botón, con un único punto de orquestación:

```
SoporteCalendarioActorNegocio.EsDiaLaboral(fecha)     ← nuevo, gate de calendario
        │
        ▼
SoporteCalificacionActorNegocio.CerrarTicketsVencidos()   ← nuevo, orquesta + telemetría
        │                         │
        ▼                         ▼
CerrarTicketsVencidosSinCalificar()   CerrarTicketsVencidosSinCalificarSolucion()
   (ya existen, cambian de void → int para poder informar cuántos se cerraron)
```

Único consumidor de `CerrarTicketsVencidos()`: el botón manual en pantalla (Fase 4). El Cierre de Día
ya no lo llama — deja de ser un due­ño más de esta regla.

---

## Fase 1 — Calendario: `EsDiaLaboral` ✅ implementada

**Archivo:** `Negocio/Soporte/SoporteCalendarioActorNegocio.cs`

Método público nuevo, hermano de `CalcularFechaLimiteHabil` (`:15`) y `CalcularHorasHabilesEntre`
(`:77`), reusando el privado `ObtenerJornada` (`:151`) y el mismo patrón de carga de calendario:

```csharp
/// <summary>
/// Indica si la fecha dada es día laboral según el calendario configurado
/// (jornada semanal + excepciones). No considera franja horaria, solo el día completo.
/// </summary>
public static bool EsDiaLaboral(DateTime p_fecha)
{
    Dictionary<int, SoporteJornadaSemanal> semana = SoporteJornadaSemanalActor.ObtenerSemanaCompleta();
    Dictionary<DateTime, SoporteDiasNoHabiles> excepciones =
        SoporteDiasNoHabilesActor.ObtenerExcepcionesEntre(p_fecha.Date, p_fecha.Date);
    return ObtenerJornada(p_fecha.Date, semana, excepciones).Labora;
}
```

**Verificación:** con la jornada base (Lun-Vie laboral, Sáb-Dom no laboral) → `EsDiaLaboral(sábado)` =
`false`, `EsDiaLaboral(lunes)` = `true`. Insertar un festivo en `soporte_soportediasnohabiles` con
`eslaboral = false` → `EsDiaLaboral(esa fecha)` = `false` aunque sea entre semana.

---

## Fase 2 — Orquestación + telemetría mínima ✅ implementada

**Archivos:** `Negocio/Soporte/SoporteCalificacionActorNegocio.cs`,
`Negocio/Soporte/ResultadoCierreTicketsVencidos.cs` (DTO en archivo propio, no en el mismo que el
diseño original proponía).

1. `CerrarTicketsVencidosSinCalificar` y `CerrarTicketsVencidosSinCalificarSolucionados` (renombrado
   con "ados" durante la implementación) pasaron de `void` a `int`, y ganaron un parámetro
   `string idUsuario` para auditar quién disparó el cierre manual (antes se auditaba con `null`,
   correcto solo cuando corría desde el Cierre de Día como "sistema").
2. `CerrarTicketsVencidos(string idUsuario)` orquesta con el gate de calendario, igual al diseño
   original.
3. **Cambio adicional que no estaba en el diseño original de esta fase:** `CerrarTicketsVencidosSinCalificar`
   ahora también fija `gestion.Fechacierre = DateTime.Now` al cerrar por vencimiento — se encontró que
   el diseño previo (no tocarla) era una inconsistencia real pre-existente, corregida en 4 archivos.
   Ver [`VALIDACION-ESTADO-CIERRE.md`](./VALIDACION-ESTADO-CIERRE.md) para el detalle completo.

**Verificación:** un sábado, `CerrarTicketsVencidos(idUsuario)` devuelve `Ejecutado = false` y no
modifica ningún ticket aunque haya vencidos. Un lunes con 2 tickets vencidos → `Ejecutado = true`,
`TicketsCerradosSinCalificar + TicketsCerradosSolucionados = 2`, cada uno con `Fechacierre` = ahora.

---

## Fase 3 — Cierre de Día: eliminar el bloque de tickets ✅ implementada

**Archivo:** `Negocio/Cierres/CierreDiaViewModel.cs` (`#region tickets`, `:507-512`) — eliminado,
reemplazado por un comentario que explica dónde quedó la regla y apunta a este `PLAN.md`.

El Cierre de Día deja de tocar tickets. Un solo dueño de la regla: el botón manual (Fase 4).

**Verificación:** correr el Cierre de Día con tickets vencidos → no cambian de estado (antes sí se
cerraban ahí). Confirma que el bloque quedó fuera y que el resto del cierre sigue funcionando igual.

---

## Fase 4 — Acción manual (botón) ✅ implementada

**Ubicación propuesta:** `PruebaPostgreSQL/Views/SoporteParametros/` — ya existe
`_TabConfiguracionSoporte.cshtml` (pantalla donde se administra `SoporteConfiguracion`, incluyendo
`Diasventanasolucionado`/`Diasventanacalificacion`), servida por
`Controllers/Soporte/SoporteParametrosController.cs:15` (`Index`). Es el lugar natural para un botón
de mantenimiento relacionado — misma pantalla de administración de soporte, evita crear una vista
nueva. Se ajusta al ejecutar (invocar skill `siian-devextreme-components` / `siian-mvc-controllers`
antes de tocar la vista/controlador).

**Backend:** acción nueva `[HttpPost] CerrarTicketsVencidos()` en el WebApi de soporte que ya exista
para esta pantalla (`SoporteConfiguracionWebApiController` u otro del módulo, a confirmar al
implementar) → delega a `SoporteCalificacionActorNegocio.CerrarTicketsVencidos()` → responde el
`ResultadoCierreTicketsVencidos` para que la UI muestre el mensaje (`dxAlert`/`notify`, patrón ya
usado en el módulo).

**Frontend:** botón "Ejecutar cierre de tickets vencidos" en `_TabConfiguracionSoporte.cshtml`, con
confirmación (`dxConfirm`) antes de disparar — dado que es una acción que cierra tickets, mismo patrón
que otras acciones sensibles del módulo (`marcarSolucionado()` en `_Popups.cshtml` de
`SoporteDetalle`). Al responder, mostrar el mensaje del resultado (incluye el caso "hoy no es día
laboral").

**Verificación:** clic en el botón un día laboral con tickets vencidos → mensaje "Se cerraron N
ticket(s)", grid de tickets refleja el cambio de estado. Clic en fin de semana (o forzando la fecha de
prueba) → mensaje "Hoy no es día laboral...", nada cambia.

---

## Fase 5 — Ventana de solucionado en días hábiles ✅ implementada

Diseñada en `../soporte-ajustes-dias/ANALISIS-CIERRE-JOB.md` (Fase A de ese documento).

- `Negocio/Soporte/SoporteCalendarioActorNegocio.cs`: método nuevo `SumarDiasHabiles(DateTime p_inicio, int p_dias)`,
  hermano de `CalcularFechaLimiteHabil` — avanza día a día saltando no laborables (reusa `ObtenerJornada`)
  y devuelve el fin de la última franja del N-ésimo día hábil.
- `Negocio/Crm/GestionMaestroCRMActorNegocio.cs` (`MarcarComoSolucionado`): `Tiempolimitesolucionado =
  SoporteCalendarioActorNegocio.SumarDiasHabiles(DateTime.Now, diasVentana);` en lugar de
  `DateTime.Now.AddDays(diasVentana)`.
- `Negocio/Crm/GestionMaestroCRMActorNegocio.cs` (`MarcarComoResuelto`): `Tiempocalificacion` también usa
  ahora `SumarDiasHabiles(DateTime.Now, diasCalificacion)` en lugar de `AddDays` — negocio confirmó que
  aplica igual que la ventana de solucionado.
- Aplica solo a tickets nuevos marcados desde ahora; no se recalculan los existentes.

**Verificación:** marcar solucionado un viernes con `diasventanasolucionado = 2` → el límite cae el
martes al fin de jornada, no el domingo.

---

## Orden de ejecución

1. Fase 1 (`EsDiaLaboral`) — ✅ hecha.
2. Fase 2 (orquestación + fix de `Fechacierre` en 4 archivos) — ✅ hecha.
3. Fase 3 (eliminar bloque del Cierre de Día) — ✅ hecha.
4. Fase 4 (botón) — ✅ hecha, en `SoporteConfiguracionWebApiController` + `_TabConfiguracionSoporte.cshtml`.
5. Fase 5 (días hábiles en la ventana) — ✅ hecha.

## Verificación integral

- Un ticket marcado solucionado el viernes con ventana de 2 días hábiles → vence el martes.
- Ejecutar el botón manual el martes → el ticket se cierra (`Cerrado sin calificación`), mensaje con
  conteo correcto.
- Ejecutar el botón manual un sábado (o con fecha de prueba) → no cierra nada, mensaje "no es día
  laboral".
- Correr el Cierre de Día → ya no toca tickets en absoluto; si nadie ejecuta el botón manual, un
  ticket vencido se queda en su estado hasta que alguien lo dispare.
