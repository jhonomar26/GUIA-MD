# Plan por fases — Log de cambios en Decisión Comité

Complementa el diagnóstico de por qué la idea de lista enlazada / "id
anterior" no alcanza (no captura qué campo cambió ni el valor
anterior de forma consultable). Acá el plan de implementación, fase
por fase, clonando el mecanismo de auditoría que ya funciona en
producción para Terceros (`terceros_auditoriacambio` + trigger
genérico), adaptado al módulo Crédito.

Marcar `[x]` cada fase al terminarla.

---

## Fase 1 — Base de datos: tabla de auditoría + trigger genérico

- [ ] Pendiente

**Objetivo:** que cada `INSERT`/`UPDATE`/`DELETE` sobre
`credito_decisioncomite` y `credito_solicitudfondeo` quede registrado
solo, sin que el código C# tenga que enterarse.

**Diagnóstico confirmado:** ambas tablas se sobrescriben en sitio
(`DecisionComiteActor.Update`, dentro de
`GuardarComiteSinTransaccionScope` en
`Negocio\Credito\CreditoMaestroViewModelActorNegocio.cs:~7140`) sin
dejar rastro del valor anterior. El proyecto ya resuelve esto para
Terceros con `Scripts\auditoria_tercero.sql` (tabla
`terceros_auditoriacambio` + función trigger
`fn_auditoria_tercero_log()`), pero esa función asume que la PK de la
fila auditada se llama `id` — falso para `credito_decisioncomite`
(PK real: `idsolicitud`). Reusarla tal cual haría que la auditoría
fallara en silencio (la función traga excepciones).

**Ya creado** en `D:\rep1\SIIAN\Scripts\AuditoriaCredito\` (idempotente
y transaccional, mismo criterio de separación que
`Scripts\TarifarioServiciosAdicionales`, ver su `LEEME.md`):

- `01-tablas.sql` — estructura: `credito_auditoriacambio` (`idsolicitud,
  tabla, idregistro, campo, valoranterior, valornuevo,
  descripcionanterior, descripcionnueva, operacion, idusuario, fecha,
  correlacion`), `credito_auditoriacambio_resolver` (FK → nombre
  legible, sin filas) y `credito_auditoriacambio_tabla` (nombre técnico
  → descripción amigable de sección, con su seed de 2 filas).
- `02-funcion-trigger.sql` — lógica: función
  `fn_auditoria_credito_log()`, con la columna PK y la columna de
  agrupación recibidas por `TG_ARGV` (no hardcodeadas como `'id'`, a
  diferencia de la de Terceros) — así una sola función sirve para
  `credito_decisioncomite` (`idsolicitud`/`idsolicitud`) y
  `credito_solicitudfondeo` (`id`/`idcreditomaestro`) — más los 2
  triggers que la conectan.
- `03-seed-resolver.sql` — datos: las 5 filas de resolver de los combos
  de "Datos Cambio Cuota" (`idfrecuenciapagointeres`/
  `idfrecuenciapagocapital` → `generales_frecuenciaspago`;
  `iddestinocredito` → `cartera_destinocredito`; `idtipocreditotasa` →
  `cartera_tipocreditoclientedestinotasa`; `idformapago` →
  `tesoreria_conceptosformadepago`).

Separados a propósito: estructura, lógica y datos de configuración
cambian por razones distintas (agregar un combo nuevo es tocar solo
`03`, sin re-desplegar la función).

**Dónde conectarlo:** 2 triggers nuevos, uno por tabla —
`tr_auditoria_decisioncomite` y `tr_auditoria_solicitudfondeo`. No se
toca `credito_creditomaestro` en esta fase (queda en "Fuera de
alcance").

**Verificación manual (sin tocar C#):** correr los 3 scripts en orden
(`psql ... -f 01-tablas.sql`, luego `02`, luego `03`), cada uno termina
con su propia consulta de verificación. Después, a mano en psql:
`UPDATE credito_decisioncomite SET montoaprobado = montoaprobado + 1
WHERE idsolicitud = <id de prueba>` y confirmar fila nueva en
`credito_auditoriacambio` con `campo`, `valoranterior`, `valornuevo`
correctos. Repetir sobre `credito_solicitudfondeo`. Confirmar también
que un rollback de transacción no deja fila huérfana (la auditoría
vive en la misma transacción del `UPDATE`). Detalle completo en
`Scripts\AuditoriaCredito\LEEME.md`.

**Riesgo:** bajo. Es un trigger nuevo sobre 2 tablas puntuales, no
toca ningún flujo existente; la función nunca propaga excepción hacia
afuera (mismo patrón defensivo que la de Terceros).

---

## Fase 2 — Backend C#: lectura del historial

- [ ] Pendiente

**Objetivo:** exponer el contenido de `credito_auditoriacambio` de
una solicitud puntual, listo para consumir desde un grid.

**Depende de:** Fase 1 mergeada y ejecutada en la BD de prueba.

**Qué falta crear (calco 1:1 del precedente de Terceros, solo
renombrando `Idtercero`→`Idsolicitud`):**

- `Blip.Data\Credito\AuditoriaCreditoCambioEntidadNegocio.cs` —
  entidad `AuditoriaCreditoCambio` + `AuditoriaCreditoCambioViewModel`
  (props calculadas `Operaciontexto`, `ValoranteriorMostrar`,
  `ValornuevoMostrar`, `TablaMostrar`).
- `Blip.Data\Credito\AuditoriaCreditoCambioActorNegocio.cs` —
  `AuditoriaCreditoCambioActor.ObtenerPorIdsolicitud(int idsolicitud)`,
  Dapper directo vía `GeneralDao.Connection` (es lectura de reporting,
  no CRUD estándar — mismo precedente que Terceros, no aplica
  `ObtenerLista(sql, parametros, 0)`).
- `PruebaPostgreSQL\Controllers\WebApi\AuditoriaCreditoWebApiController.cs`
  — `[LogApi(AlmacenaLog = false)] [Authorize]`,
  `Get(DataSourceLoadOptions loadOptions, int idsolicitud)`.

**Dónde conectarlo:** registrar los 2 `.cs` nuevos en `Data.csproj`
(`<Compile Include="...">`). Ningún cambio en
`CreditoMaestroViewModelActorNegocio.cs` ni en
`DecisionComiteController.cs`.

**Verificación manual (sin UI):** `GET
/api/AuditoriaCredito?idsolicitud=<id>` directo (Postman/browser),
confirmar JSON con las filas insertadas a mano en la Fase 1, combos
resueltos a nombre legible.

**Riesgo:** bajo. Archivos nuevos, solo lectura, sin tocar el flujo de
guardado.

---

## Fase 3 — UI: grid de historial en la pantalla de Decisión Comité

- [ ] Pendiente

**Objetivo:** que el usuario vea el historial sin salir de la
pantalla de Decisión Comité.

**Depende de:** Fase 2 mergeada (el grid apunta al WebApi nuevo).

**Qué falta crear:**
`PruebaPostgreSQL\Views\DecisionComite\Partials\_InformacionHistorial.cshtml`
— DataGrid DevExtreme de solo lectura, agrupado por `TablaMostrar`
("Decisión Comité" / "Información de Fondeo"), columnas
Fecha/Usuario/Sección/Operación/Campo/Valor anterior/Valor nuevo.
Calco de `_InformacionHistorial.cshtml` de TerceroMaestro, sin
`TabPanel` (esta vista no usa tabs, son secciones apiladas).

**Dónde conectarlo:** una línea en
`Views\DecisionComite\Index.cshtml`, después de
`@Html.Partial("Partials/_DetallesSolicitudFondeoDecision", Model)`:

```
@Html.Partial("Partials/_InformacionHistorial", Model.Elemento.Idsolicitud)
```

**Verificación end-to-end:** en la pantalla real, modificar 1 campo
de cada sección (Datos Familiares/Colaboradores, Excepciones, Cambio
de Cuota) + Información de fondeo, guardar, refrescar, confirmar que
el grid nuevo muestra usuario/fecha/campo/valor anterior/valor nuevo,
combos legibles (ej. "Mensual", no "3").

**Riesgo:** bajo. Un partial nuevo + una línea de enganche, sin tocar
el form principal ni su submit.

---

## Fuera de alcance (por ahora)

**`credito_creditomaestro` sin instrumentar.** La tocan muchos otros
flujos del ciclo de vida del crédito (desembolso, etapas, etc.), ajenos
a esta pantalla — auditarla ahora generaría volumen fuera de lo
pedido. Extenderlo después es 1 sola línea `CREATE TRIGGER` con
`TG_ARGV=('id','id')`, sin tocar la función. No se toca salvo pedido
explícito aparte.

**Patrón "desactivar + insertar" de `SolicitudFondeo` en creación.**
Convive sin conflicto con el trigger nuevo (cada `UPDATE`/`INSERT`
genera su propia entrada correcta de auditoría) — no se simplifica en
este cambio.
