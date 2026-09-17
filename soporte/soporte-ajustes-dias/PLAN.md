# Plan de ajustes — Tickets de soporte (SLA y estados)

> Fuente: `REQUERIMIENTO.md` (Redmine). Dos defectos en la plataforma de tickets.

## Contexto

1. **SLA cuenta tiempo en fin de semana.** El "tiempo restante" sigue corriendo sábado y domingo.
   Prueba: viernes 6pm vs lunes 8am → ~2.5 días de diferencia, cuando esos días no son laborables.
2. **Solucionados no pasan a cerrado.** Tickets *solucionado* nunca transicionan a *Resuelto/Cerrado*.

---

## Diagnóstico caso 1 (SLA fin de semana)

**Flujo actual:**
- `fechalimite` **ya se calcula en horas hábiles** (C#):
  `SoporteSlaActorNegocio.ObtenerFechaLimiteSLA` → `SoporteCalendarioActorNegocio.CalcularFechaLimiteHabil(inicio, horas)`,
  que camina jornada semanal (`soporte_soportejornadasemanal`) + excepciones (`soporte_soportediasnohabiles`).
- **El bug**: `horasrestantes` en la vista `soporte_soportevistaticketdetalle` usa **reloj de pared**
  (`fechalimite - CURRENT_TIMESTAMP`). No respeta el calendario → suma sábado/domingo/festivos.
  Es inconsistente con cómo se construyó `fechalimite`.

**Por qué la solución es C# y no SQL:**
- La lógica de calendario ya existe en C# (`SoporteCalendarioActorNegocio`) → **fuente única de verdad**.
  Una función PL/pgSQL la duplicaría en otro lenguaje y se desincronizan.
- El grid interno (`SoporteVistaTicketDetalleWebApiController.Get`) hace:
  `DataSourceLoader.Load(listaViewModel, loadOptions)` → **ordena/filtra/pagina en memoria (C#)**,
  no traduce a SQL. Por lo tanto calcular `horasrestantes` en el ViewModel **sí** es ordenable/filtrable.
- `estadosla` (OK/VENCIDO) = `now > fechalimite`, reloj de pared, **es correcto**. Se queda en la vista.

**Consumidores de la vista (para dimensionar impacto):**
| Endpoint | Método Actor | Sort/Filter |
|---|---|---|
| `SoporteVistaTicketDetalleWebApiController.Get` | `ObtenerListaPorPermiso` → `CrearListaViewModel` | en memoria (loadOptions) |
| `SoporteVistaTicketDetalleWebApiController.GetIdGestor` | `ObtenerListaPorGestor` → `CrearListaViewModel` | en memoria (loadOptions) |
| `SoporteVistaTicketDetalleClienteWebApiController.Get` | (otra vista/entidad) | **no expone** horasrestantes |

Ambos endpoints internos pasan por `CrearListaViewModel` → un solo punto para corregir.

---

## FASE 1 — Base de datos (ajuste mínimo)

**Objetivo:** que la vista no siga publicando un `horasrestantes` engañoso (reloj de pared).
El valor real lo pondrá C# (Fase 3).

**Archivo:** `soporte_soportevistaticketdetalle` (definición base en `scratch/1-vista-dashboard.sql`).

**Cambios:**
1. **Descartar** las funciones que se probaron en el scratch — NO se aplican a la BD:
   `soporte_horaslaborables` y `soporte_interseccionsegundos`. (La lógica vive en C#.)
2. En el `CASE` de `horasrestantes`, dejar el `ELSE` en `NULL` (la columna sigue existiendo porque
   el `CrearSelect()` del Actor la referencia, pero deja de calcular reloj de pared):
   ```sql
   CASE
       WHEN g.fechalimite IS NULL THEN NULL::numeric
       WHEN eg.escerrada OR eg.escerradaconcalificacion OR eg.escerradosincalificacion OR eg.essolucionado THEN NULL::numeric
       ELSE NULL::numeric              -- lo calcula C# en CrearViewModel
       END                                                            AS horasrestantes,
   ```
3. `estadosla` **se deja igual** (reloj de pared, correcto).

> El resto de la vista (joins, GROUP BY, columnas) no cambia. `CREATE OR REPLACE VIEW` con la misma
> lista de columnas.

**Verificación:** la vista se reemplaza sin error; `SELECT horasrestantes FROM soporte_soportevistaticketdetalle`
devuelve NULL en todos; el grid sigue trayendo la columna.

---

## FASE 2 — C#: método de horas hábiles entre dos instantes

**Objetivo:** calcular horas laborables entre `desde` y `hasta` reusando el calendario existente.

**Archivo:** `Negocio/Soporte/SoporteCalendarioActorNegocio.cs`

**Cambio:** agregar método hermano de `CalcularFechaLimiteHabil`, más una sobrecarga con diccionarios
precargados (para no recargar por fila al iterar una lista). Reusa los privados existentes
`ObtenerJornada` y `ConstruirFranjas`.

```csharp
// Horas laborables entre dos instantes. Negativo si p_desde > p_hasta (ticket vencido).
public static double CalcularHorasHabilesEntre(DateTime p_desde, DateTime p_hasta)
{
    DateTime lo = p_desde <= p_hasta ? p_desde : p_hasta;
    DateTime hi = p_desde <= p_hasta ? p_hasta : p_desde;
    Dictionary<int, SoporteJornadaSemanal> semana = SoporteJornadaSemanalActor.ObtenerSemanaCompleta();
    Dictionary<DateTime, SoporteDiasNoHabiles> excepciones =
        SoporteDiasNoHabilesActor.ObtenerExcepcionesEntre(lo, hi);
    return CalcularHorasHabilesEntre(p_desde, p_hasta, semana, excepciones);
}

// Sobrecarga con calendario precargado (usar al calcular sobre una lista).
public static double CalcularHorasHabilesEntre(
    DateTime p_desde, DateTime p_hasta,
    Dictionary<int, SoporteJornadaSemanal> p_semana,
    Dictionary<DateTime, SoporteDiasNoHabiles> p_excepciones)
{
    int signo = p_desde <= p_hasta ? 1 : -1;
    DateTime ini = signo == 1 ? p_desde : p_hasta;
    DateTime fin = signo == 1 ? p_hasta : p_desde;

    double totalHoras = 0;
    DateTime dia = ini.Date;
    while (dia <= fin.Date)
    {
        JornadaDia jornada = ObtenerJornada(dia, p_semana, p_excepciones);
        if (jornada.Labora)
        {
            foreach (Franja franja in jornada.Franjas)
            {
                DateTime desde = ini > franja.Inicio ? ini : franja.Inicio;   // recorte inferior
                DateTime hasta = fin < franja.Fin ? fin : franja.Fin;         // recorte superior
                if (hasta > desde)
                    totalHoras += (hasta - desde).TotalHours;
            }
        }
        dia = dia.Date.AddDays(1);
    }
    return signo * totalHoras;
}
```

**Verificación (self-check con calendario base Lun–Vie 08–12 y 14–18):**
- Vie 09:00 → 17:00 = **6.0** (mañana 3h + tarde 3h)
- Vie 17:00 → Lun 09:00 (salta sáb/dom) = **2.0**
- Sábado completo = **0.0**
- Insertar festivo en `soporte_soportediasnohabiles` → ese día no suma.

---

## FASE 3 — C#: usar el cálculo al proyectar el ViewModel

**Objetivo:** que el grid muestre `horasrestantes` en horas hábiles y sea ordenable/filtrable.

**Ajuste de capa (corregido durante implementación):** el cálculo NO puede ir en
`Blip.Data/Soporte/SoporteVistaTicketDetalleActorNegocio.cs` — ese archivo es `partial` del Actor
(capa Data) y `Blip.Data` no puede importar `Negocio` (rompería la dirección de dependencias
`PruebaPostgreSQL → Negocio → Blip.Data` y crearía referencia circular de proyecto). `Blip.Data`
se dejó como proyección **pura** (`CrearViewModel`/`CrearListaViewModel` sin calendario, sin cambios).

El cálculo vive en una clase **nueva** en Negocio, mismo patrón que `SoporteVistaDashboardActorNegocio`
(orquesta: llama al Actor de Blip.Data, luego enriquece con lógica de negocio). Nombre distinto al
del archivo de Data (no clonar el nombre entre capas) — el sufijo `Sla` deja claro qué hace esta clase.

**Archivo nuevo:** `Negocio/Soporte/SoporteVistaTicketDetalleSlaActorNegocio.cs`
(registrado en `Negocio/Negocio.csproj`)
- `ObtenerListaPorPermiso(idUsuario, puedeVerTodos)` y `ObtenerListaPorGestor(idGestor)`: traen filas
  vía `SoporteVistaTicketDetalleActor` (Blip.Data), proyectan con `CrearViewModel`, calculan
  `Horasrestantes` con `SoporteCalendarioActorNegocio.CalcularHorasHabilesEntre` (Fase 2).
  `semana` se carga **una vez** por request.
- Regla "cerrado": `Estadosla == null` (viene de la vista, Fase 1) ⇒ ticket cerrado/solucionado ⇒
  `horasrestantes` queda `null`.

**Archivo modificado:** `PruebaPostgreSQL/Controllers/WebApi/SoporteVistaTicketDetalleWebApiController.cs`
- `Get` y `GetIdGestor` llaman a `SoporteVistaTicketDetalleSlaActorNegocio` (Negocio) en vez de saltar
  directo a `SoporteVistaTicketDetalleActor` (Blip.Data).

**Verificación:** abrir el grid interno un lunes → un ticket abierto el viernes no descontó sáb/dom;
ordenar por `horasrestantes` funciona (orden = por urgencia); compila sin ciclos de proyecto.

---

## FASE 4 — Caso 2: solucionado no pasa a cerrado  *(requiere investigación + definición)*

**Objetivo:** que un ticket *solucionado* transicione a *Resuelto/Cerrado* según la regla de negocio.

**Investigar primero:**
- Estados en `crm_estadogestioncrm` y sus flags (`essolucionado`, `escerrada`,
  `escerradoconcalificacion`, `escerradosincalificacion`) — cuál es el estado final esperado.
- Dónde se dispara hoy la transición solucionado → cerrado (¿job programado tras N días hábiles?
  ¿acción del cliente al calificar? ¿acción del gestor?) y por qué no avanza.

**Definir con negocio (bloqueante):** la condición del paso a cerrado. Opciones típicas:
- A los X días hábiles en *solucionado* sin respuesta del cliente (usaría el calendario de Fase 2).
- Al calificar el cliente.
- Manual por el gestor.

**Verificación:** a definir según la regla acordada.

---

## FASE 5 — Verificación integral

- Reproducir el escenario del requerimiento (viernes 6pm → lunes 8am): `horasrestantes` no avanzó
  en fin de semana.
- Insertar un festivo y confirmar que tampoco descuenta.
- Caso 2 según la regla de la Fase 4.

---

## Orden de ejecución y archivos tocados

1. **Fase 1** (BD) — `soporte_soportevistaticketdetalle` (`scratch/1-vista-dashboard.sql` como referencia).
2. **Fase 2** (C#) — `Negocio/Soporte/SoporteCalendarioActorNegocio.cs`.
3. **Fase 3** (C#) — nuevo `Negocio/Soporte/SoporteVistaTicketDetalleSlaActorNegocio.cs` +
   `Blip.Data/Soporte/SoporteVistaTicketDetalleActorNegocio.cs` (revertido a proyección pura) +
   `PruebaPostgreSQL/Controllers/WebApi/SoporteVistaTicketDetalleWebApiController.cs`.
4. **Fase 4** (C#/BD) — pendiente de investigación; archivos por determinar.
5. **Fase 5** — verificación.

Caso 1 completo y verificable con Fases 1–3. Caso 2 (Fase 4) arranca después, tras definir la regla.

## Notas / deuda

- Los Actor de esta entidad usan `catch (Exception ex) { throw ex; }` (pierde stack trace), contra
  `CLAUDE.md`. Fuera de alcance; anotado por si se toca el archivo.
- Verificar que `SoporteJornadaSemanalActor.ObtenerSemanaCompleta` y
  `SoporteDiasNoHabilesActor.ObtenerExcepcionesEntre` son públicos y reutilizables (ya se usan en
  `CalcularFechaLimiteHabil`).
