# Validación — Fechacierre y filtrado por estado origen en el cierre de tickets

> Ronda de validación sobre `Negocio/Soporte/SoporteCalificacionActorNegocio.cs` (Fase 2 del plan en
> [`PLAN.md`](./PLAN.md)). **Actualizado**: la primera vuelta de esta validación concluyó "no tocar
> `Fechacierre`" y resultó incompleta — una segunda revisión encontró una inconsistencia real en el
> diseño ya existente (pre-fecha de este feature) y se corrigió en 4 archivos. Ver "Duda 1" abajo.

## Duda 1 — ¿`CerrarTicketsVencidosSinCalificar()` debería fijar `Fechacierre = DateTime.Now`?

**Sí.** Conclusión revisada tras encontrar una inconsistencia real en el diseño pre-existente.

El código ya trata "Cerrado" (limbo de calificación) y "Solucionado" como la misma categoría de
estado no-definitivo — confirmado en `Negocio/Crm/GestionMaestroCRMActorNegocio.cs`:

```csharp
// ObtenerEstadoCierre (:53-75)
var puedeReabrir = estadoCerrado.Id == gestion.Idestado || esSolucionado;

// EstaCerradoDefinitivamente (:341-355)
return estadoCerradoConCalificacion.Id == gestion.Idestado
       || estadoCerradoSinCalificacion.Id == gestion.Idestado;
```

Solo "con calificación" y "sin calificación" son definitivos; "Cerrado" (limbo) y "Solucionado" son
ambos reabribles. Bajo esa lógica, `Fechacierre` debe representar el **cierre definitivo**, no el
momento en que el ticket entra a un limbo del que todavía puede salir.

**El diseño pre-existente (confirmado con `git show HEAD` antes de tocar nada) tenía esto asimétrico:**
`MarcarComoResuelto` fijaba `Fechacierre` de inmediato al entrar al limbo "Cerrado" (rama con
calificación), mientras que `MarcarComoSolucionado` nunca la fijaba al entrar a "Solucionado" — incluso
siendo ambos limbos reabribles con la misma semántica. Esa asimetría ya estaba en producción, no se
introdujo en este ciclo.

**Corrección aplicada (4 archivos) para que `Fechacierre` signifique consistentemente "cierre
definitivo" en todos los caminos:**

| Archivo | Cambio |
|---|---|
| `Negocio/Crm/GestionMaestroCRMActorNegocio.cs` — `MarcarComoResuelto` | Ya no fija `Fechacierre` al entrar al limbo "Cerrado" (`TieneCalificacion=true`); solo la fija cuando va directo a "sin calificación" |
| `Negocio/Crm/GestionMaestroCRMActorNegocio.cs` — `ReabrirTicket` (rama calificación vencida) | Ahora fija `Fechacierre = DateTime.Now` al forzar el cierre en caliente (ya lo hacía la rama gemela de solucionado) |
| `Negocio/Portal/PortalSoporteTicketActorNegocio.cs` — `CalificarTicket` | Ahora fija `Fechacierre = DateTime.Now` al pasar a "Cerrado con calificación" (antes no la tocaba) |
| `Negocio/Soporte/SoporteCalificacionActorNegocio.cs` — `CerrarTicketsVencidosSinCalificar` | Fija `Fechacierre = DateTime.Now` al vencer sin calificación (paralelo a lo que ya hacía `CerrarTicketsVencidosSinCalificarSolucionados`) |

Con esto, los 4 puntos donde un ticket llega a un estado definitivo (`Cerrado con calificación` por
2 caminos, `Cerrado sin calificación` por 2 caminos) fijan `Fechacierre` en el momento real del cierre,
y ningún camino la fija antes de tiempo.

## Duda 2 — ¿Los dos métodos podrían tocar tickets en el estado origen incorrecto?

**Sigue sin haber riesgo de mezcla** (esta parte de la validación original se mantiene sin cambios).
`EstadoGestionCRMActorNegocio.cs` expone 4 lookups, cada uno sobre un flag booleano independiente y
mutuamente excluyente:

| Lookup | Flag | Usado por |
|---|---|---|
| `ObtenerEstadoCerrado()` | `escerrada` | `CerrarTicketsVencidosSinCalificar()` |
| `ObtenerEstadoCerradoConCalificacion()` | `escerradaconcalificacion` | `CalificarTicket` |
| `ObtenerEstadoCerradoSinCalificacion()` | `escerradosincalificacion` | destino de ambos cierres por vencimiento |
| `ObtenerEstadoSolucionado()` | `essolucionado` | `CerrarTicketsVencidosSinCalificarSolucionados()` |

Confirmado que son mutuamente excluyentes porque el filtro del selectbox de edición de tickets
(`../cierre-ticket-solucionado/REGLAS.md`) necesita **4 condiciones de exclusión separadas** — si
`escerrada` cubriera también a los estados terminales, una sola condición habría bastado.

Las queries del Actor (`Blip.Data/Crm/GestionMaestroCRMActorNegocio.cs:681-723`,
`ObtenerTicketsCalificacionVencida` / `ObtenerTicketsSolucionVencida`) filtran `idestado = @idEstado`
con el id específico de cada lookup. Conclusión: `CerrarTicketsVencidosSinCalificar()` solo puede tocar
tickets en `Cerrado` (limbo); `CerrarTicketsVencidosSinCalificarSolucionados()` solo tickets en
`Solucionado`. Ningún ticket ya en un estado terminal puede ser alcanzado por ninguno de los dos.

## Punto real, pero fuera de alcance de este archivo

Que un ticket `Solucionado` vencido termine en el mismo estado final (`Cerrado sin calificación`) que
uno que sí pasó por calificación, aunque no tiene relación semántica con calificación, **es una
decisión ya tomada** en el feature previo [`../cierre-ticket-solucionado`](../cierre-ticket-solucionado/)
— documentada en su `REGLAS.md`: *"Estado destino si no hay ventana/calificación:
`Escerradosincalificacion`"*, para ambos caminos. No se introdujo en este ciclo de trabajo.

Cambiarlo (crear un estado terminal propio para "Solucionado sin respuesta") implicaría un rediseño
más grande: nueva fila en `crm_estadogestioncrm` + actualizar todo lo que depende de
`Escerradosincalificacion` (`EsResuelto`, `ObtenerEstadoCierre`, `EstaCerradoDefinitivamente`, filtros
de UI, portal cliente). Confirmado con el usuario: **se mantiene el comportamiento actual**, no se
crea un estado nuevo.

## Conclusión

`Fechacierre` ahora significa lo mismo en los 4 caminos que llevan a un estado definitivo — cambio
aplicado en `MarcarComoResuelto`, `ReabrirTicket`, `CalificarTicket` (portal cliente) y
`SoporteCalificacionActorNegocio.cs`. El filtrado por estado origen (Duda 2) ya era correcto y no
cambió.
