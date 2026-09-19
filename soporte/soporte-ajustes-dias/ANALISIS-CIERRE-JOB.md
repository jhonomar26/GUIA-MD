# Análisis — Sacar el cierre de tickets del Cierre de Día (+ ventana en días hábiles)

> Estado: **decisión tomada** — el mecanismo (Fase C) se definió con soporte: proceso **manual**,
> respetando el calendario (ignora sábado/domingo/festivo). Plan de implementación completo en
> [`../cierre-manual-tickets-vencidos/PLAN.md`](../cierre-manual-tickets-vencidos/PLAN.md), que
> también incorpora la Fase A (ventana en días hábiles) de este documento.

---

## Contexto

El requerimiento de Redmine (`REQUERIMIENTO.md`) traía dos casos:

1. **SLA corre en fin de semana** → resuelto en el ciclo anterior (commits `559bb319f`, `683087f71`):
   `horasrestantes` ahora se calcula con calendario hábil vía
   `Negocio/Soporte/SoporteCalendarioActorNegocio.cs` + `SoporteVistaTicketDetalleSlaActorNegocio.cs`.
2. **Tickets en estado *Solucionado* jamás pasan a cerrado** → pendiente. Es lo que se ataca ahora.

El disparador del cierre automático de tickets hoy vive **dentro del Cierre de Día**
(`Negocio/Cierres/CierreDiaViewModel.cs:507-512`, `#region tickets`). Lo que se pide es sacarlo de ahí
para que corra por su cuenta. Al investigarlo aparece que el fin de semana **no es la causa principal**
del defecto reportado, y que hay una inconsistencia real de calendario en otro punto.

---

## Hallazgos

### H1 — El bloque de tickets es el paso 13 de 14 del cierre

`CerrarSistema(idUsuario)` (`Negocio/Cierres/CierreDiaViewModel.cs:55`, ~500 líneas) ejecuta en orden:
cartera → calificación créditos → préstamos → contabilidad → aportes → inventario → mantenimiento
(`VACUUM FULL`) → nómina → backups → CRM automática → **tickets (`:507-512`)** → cierre de calendario
(`:515-524`).

No hay transacción global. **Cualquier excepción en un paso anterior aborta el método y los tickets
nunca se tocan.** Éste es el candidato #1 a "jamás pasan a cerrado".

### H2 — El vencimiento se fija en días corridos, no hábiles

- `Tiempolimitesolucionado = DateTime.Now.AddDays(diasVentana)` — `Negocio/Crm/GestionMaestroCRMActorNegocio.cs:439`
- `Tiempocalificacion = DateTime.Now.AddDays(diasCalificacion)` — mismo archivo, `:230-250`
- Parámetros: `soporte_soporteconfiguracion.diasventanasolucionado` / `.diasventanacalificacion`
  (`Blip.Data/Soporte/SoporteConfiguracion.cs:6-7`).

Ventana otorgada un viernes se come sábado y domingo. **Inconsistente con el SLA**, que sí respeta
jornada y festivos desde el ciclo anterior. Éste es el problema real de fin de semana.

### H3 — La query compara contra medianoche

`GestionMaestroCRMActor.ObtenerTicketsSolucionVencida` / `ObtenerTicketsCalificacionVencida`
(`Blip.Data/Crm/GestionMaestroCRMActorNegocio.cs:681-723`) filtran
`tiempolimitesolucionado < CURRENT_DATE`. Da hasta un día extra de gracia, y **anula la ventaja de
correr el job con frecuencia**: aunque corra cada 15 minutos, sólo dispara en el corte de medianoche.

### H4 — Falla silenciosa si faltan estados

`Negocio/Soporte/SoporteCalificacionActorNegocio.cs:17,20,50,53` → `return` sin log si no existen los
estados `essolucionado` / `escerradosincalificacion` en `crm_estadogestioncrm`. Además el `catch` por
ticket (`:35-39`, `:70-73`) es vacío: si los `Update` fallan siempre, no queda rastro en ningún lado.
**Sin telemetría no se puede confirmar cuál de H1/H4 está ocurriendo en el cliente.**

### H5 — El "hack del viernes" no es necesario

Correr el viernes el barrido de sábado y domingo no aporta: el barrido es un UPDATE idempotente sobre
filas ya vencidas, no trabajo con fecha de efecto. No correrlo el sábado no pierde nada — el lunes
cierra exactamente lo mismo. El hack sólo agrega estado ("¿ya corrí los del finde?") a cambio de cero.

Lo único que sí molesta del fin de semana es el **correo** al cliente (`EnviarCorreoCambioEstado`,
`SoporteCalificacionActorNegocio.cs:67`): con días corridos una ventana puede vencer en sábado y el
cliente recibe "ticket cerrado" fuera de horario. Con H2 corregido (días hábiles) eso desaparece solo:
la ventana nunca vence en sábado, domingo ni festivo, y el día en que corra el job pasa a ser
irrelevante.

### H6 — Infraestructura ya disponible en el repo (no hay que inventar nada)

| Molde | Dónde | Notas |
|---|---|---|
| Timer in-process | `PruebaPostgreSQL/Services/SessionInactivityWatcher.cs` + `Global.asax.cs:36` | `System.Threading.Timer`, guard `Interlocked`, `catch` que no propaga, `GeneralDao.Connection = null` |
| Servicio Windows + endpoint tick | `PruebaPostgreSQL/Controllers/WebApi/CierreAutomaticoWebApiController.cs:31` → `Negocio/Cierres/CierreAutomaticoOrquestador.cs:51` | El poller es `SIIAN.ServicioCierre`, **proyecto fuera de este repo, en otra PC** |
| Mutex por (compañía, fecha) | `Negocio/Cierres/CierreLock.cs:44` | `pg_try_advisory_lock` |
| Calendario hábil | `Negocio/Soporte/SoporteCalendarioActorNegocio.cs:15,77,103` | `ObtenerJornada` (`:151`) es **privado** |

No hay Hangfire, Quartz ni `QueueBackgroundWorkItem`.

---

## Decisiones tomadas

- **Ventana → días hábiles.** Confirmado.
- **Las dos llamadas dentro del Cierre de Día se quedan por ahora** (red de respaldo). Se acepta H1 como
  riesgo conocido; el barrido es idempotente, así que tener dos disparadores no produce doble cierre.
- **Mecanismo del job: pendiente**, hasta aclarar con el cliente qué espera ver (ver preguntas abajo).

---

## Preguntas para el cliente / negocio (bloquean el mecanismo)

1. **¿Con qué latencia esperan que un ticket solucionado pase a cerrado?**
   - "Al final del día" → basta con lo que hay + sacarlo del cierre.
   - "En cuanto vence" (minutos) → exige job frecuente **y** cambiar H3 a `now()`.
2. **La ventana de N días, ¿son días hábiles completos?** Es decir, N días hábiles contados desde el
   momento de marcar como solucionado: ¿vence al final de la jornada del N-ésimo día hábil, o a la misma
   hora del día en que se marcó?
3. **¿El cierre automático debe poder ocurrir fuera de horario laboral?** Afecta cuándo llega el correo
   "su ticket fue cerrado" al cliente.
4. **¿Los tickets ya existentes con `tiempolimitesolucionado` en días corridos se recalculan**, o el
   cambio aplica sólo a los nuevos? (Lo barato y predecible: sólo nuevos.)
5. **¿En qué clientes está instalado el servicio `SIIAN.ServicioCierre`?** Si no está en todos, la
   opción B/C de mecanismo queda descartada de entrada.
6. **¿Hay evidencia de que el Cierre de Día esté fallando antes del paso de tickets?** Revisar
   `generales_calendario` (`fecha`, `horainicio`, `horafin`, `estacerrado`, `procesoconerror`) del
   cliente que reportó — confirma o descarta H1 sin tocar código.

---

## Propuesta de implementación (incremental, verificable por fase)

### Fase A — Ventana en días hábiles *(decidida, sin dependencias)*

**`Negocio/Soporte/SoporteCalendarioActorNegocio.cs`** — método nuevo, hermano de
`CalcularFechaLimiteHabil` (`:15`), reusando el privado `ObtenerJornada` (`:151`):

```csharp
// Suma N días hábiles a partir de p_inicio. Devuelve el fin de la jornada del N-ésimo día hábil.
public static DateTime SumarDiasHabiles(DateTime p_inicio, int p_dias)
```

Carga `SoporteJornadaSemanalActor.ObtenerSemanaCompleta()` y
`SoporteDiasNoHabilesActor.ObtenerExcepcionesEntre(...)` igual que `CalcularFechaLimiteHabil`, avanza
día a día saltando los no laborables y devuelve el fin de la última franja del día destino. Tope de
iteraciones con la constante `MAX_ITERACIONES` ya existente (`:9`).

**`Negocio/Crm/GestionMaestroCRMActorNegocio.cs`** — reemplazar en dos puntos:
- `:439` → `gestion.Tiempolimitesolucionado = SoporteCalendarioActorNegocio.SumarDiasHabiles(DateTime.Now, diasVentana);`
- `:230-250` (`Tiempocalificacion`) → mismo cambio, si negocio confirma que aplica también a la ventana
  de calificación (pregunta 2).

Aplica **sólo a tickets nuevos**; no se recalculan los existentes salvo que negocio lo pida (pregunta 4).

**Verificación:** marcar como solucionado un viernes con `diasventanasolucionado = 2` →
`tiempolimitesolucionado` debe caer el **martes** al cierre de jornada, no el domingo. Insertar un
festivo en `soporte_soportediasnohabiles` y repetir → corre un día más.

### Fase B — Telemetría mínima en el barrido *(desbloquea el diagnóstico real)*

`Negocio/Soporte/SoporteCalificacionActorNegocio.cs`: que los `return` silenciosos (`:17,20,50,53`) y
los `catch` vacíos (`:35-39`, `:70-73`) dejen rastro. Lo más barato que sirve: que ambos métodos
devuelvan un conteo (procesados / fallidos) y que el `catch` por ticket registre el error con el
mecanismo de log ya usado en el módulo, en vez de tragárselo.

Sin esto no se puede afirmar si el defecto reportado es H1 o H4.

### Fase C — Job independiente *(pendiente de las preguntas 1, 3 y 5)*

Opción recomendada si el cliente no exige latencia de minutos y no todos tienen `SIIAN.ServicioCierre`:
**timer in-process**, copiando `PruebaPostgreSQL/Services/SessionInactivityWatcher.cs`
(archivo nuevo en `PruebaPostgreSQL/Services/`, registrado en `PruebaPostgreSQL.csproj`, arrancado en
`Global.asax.cs` junto al watcher existente), intervalo 15–30 min, guard `Interlocked` y
`GeneralDao.Connection = null` en `finally`.

Si esta fase avanza, **es obligatorio** cambiar H3 (`< CURRENT_DATE` → `< now()` en
`Blip.Data/Crm/GestionMaestroCRMActorNegocio.cs:681-723`); si no, correr el job cada 15 minutos no
cambia nada respecto a hoy.

Las llamadas del `#region tickets` en `CierreDiaViewModel.cs:507-512` **se dejan**: el barrido es
idempotente (el ticket sale del filtro `idestado` tras cerrarse), así que el cierre de día queda como
segunda pasada sin riesgo de doble cierre.

---

## Verificación integral

1. **H1, sin tocar código:** `SELECT fecha, horainicio, horafin, estacerrado, procesoconerror FROM generales_calendario ORDER BY fecha DESC LIMIT 15` en el cliente que reportó. Si hay días sin `horafin` o con `procesoconerror`, H1 confirmado.
2. **Estados configurados:** `SELECT id, nombre, essolucionado, escerradosincalificacion, escerrada FROM crm_estadogestioncrm` — debe existir una fila con cada flag en `true` (descarta H4).
3. **Fase A:** marcar solucionado un viernes → `tiempolimitesolucionado` cae el martes al fin de jornada; con festivo configurado, el miércoles.
4. **Fase A, no-regresión:** el SLA (`horasrestantes` en el grid interno) sigue igual — Fase A no toca `SoporteVistaTicketDetalleSlaActorNegocio`.
5. **Fase C:** marcar un ticket con la ventana ya vencida y confirmar que pasa a *Cerrado sin calificación* dentro del intervalo del timer, sin haber corrido el Cierre de Día.

Sin suite de pruebas automatizada en el repo — verificación manual contra la app, como el resto del proyecto.
