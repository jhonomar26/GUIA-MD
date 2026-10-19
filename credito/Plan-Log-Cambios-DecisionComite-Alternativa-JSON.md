# Plan alternativo — Log de cambios en Decisión Comité (snapshot JSON)

Alternativa independiente a `Plan-Log-Cambios-DecisionComite.md` (mismo
folder). Ese plan usa un trigger PostgreSQL que audita campo por campo
(`credito_auditoriacambio`, 1 fila por campo cambiado, con resolver de
FKs a nombre legible). Este plan resuelve lo mismo con mucho menos
código, a cambio de correr el diff al leer en vez de al guardar.

**No reemplaza al otro plan, es una opción B.** Se elige uno de los
dos antes de tocar producción — no se implementan ambos.

Marcar `[x]` cada fase al terminarla.

---

## Idea central

En vez de que la base de datos detecte campo por campo qué cambió (vía
trigger + `jsonb_object_keys` + tabla resolver), cada vez que se guarda
se serializa el objeto **tal cual se envió** (`vm.Elemento` /
`SolicitudFondeo`) a JSON y se inserta como una fila nueva —un snapshot
completo, no un diff. El "qué cambió" se calcula **al momento de
mostrar el historial**, comparando cada snapshot contra el
inmediatamente anterior de la misma solicitud, con una consulta
`jsonb` (sin trigger, sin resolver, sin loop en cada guardado).

**Trade-off explícito frente al plan del trigger:** esto solo audita lo
que pasa por los 2 puntos de guardado que vamos a tocar
(`GuardarComiteSinTransaccionScope` y el POST/PUT de
`SolicitudFondeoWebApiController`). Si algo modifica
`credito_decisioncomite`/`credito_solicitudfondeo` por otra vía (script,
otro proceso), no queda registro — a diferencia del trigger, que audita
cualquier `UPDATE` a la tabla sin importar quién lo dispare.

---

## Fase 1 — Base de datos: tabla de snapshots

- [x] Hecho

**Objetivo:** una tabla para guardar el JSON de cada guardado, sin
lógica en la base (nada de función ni trigger).

**Qué falta crear:** `credito_decisioncomitehistorial`:

```sql
CREATE TABLE public.credito_decisioncomitehistorial (
    id          SERIAL PRIMARY KEY,
    idsolicitud INT NOT NULL,
    origen      VARCHAR(50) NOT NULL,   -- 'DecisionComite' | 'Fondeo'
    idusuario   VARCHAR(128) REFERENCES "AspNetUsers" ON DELETE SET NULL,
    fecha       TIMESTAMP NOT NULL DEFAULT now(),
    datos       JSONB NOT NULL,
    CONSTRAINT fk_cdch_creditomaestro FOREIGN KEY (idsolicitud)
        REFERENCES public.credito_creditomaestro (id)
);

CREATE INDEX ix_credito_decisioncomitehistorial_idsolicitud
    ON public.credito_decisioncomitehistorial (idsolicitud, fecha DESC);
```

`idsolicitud` referencia `credito_creditomaestro.id` con FK real — se
verificó que en los dos orígenes (`DecisionComite` y `Fondeo`) ese valor es
siempre el mismo id (`DecisionComite.Idsolicitud` y
`SolicitudFondeo.Idcreditomaestro` resuelven al mismo `CreditoMaestro` vía el
mismo lazy-load), así que una sola tabla con `origen` como discriminador es
correcto — no hace falta partir en dos tablas.

Una sola tabla para las 2 secciones (`origen` distingue cuál), en vez
de una tabla por sección — no hay razón para separarlas, ninguna trae
lógica propia.

**Riesgo:** bajo. Una tabla nueva, sin trigger, sin tocar nada
existente.

**Vista para el diff** (el cálculo de "qué cambió" vive acá, no en C#):

```sql
CREATE VIEW public.credito_vistadecisioncomitehistorial AS
SELECT h.id, h.idsolicitud, h.origen, h.idusuario, h.fecha,
       (SELECT jsonb_object_agg(
                  k, jsonb_build_object('antes', prev.datos->k, 'despues', h.datos->k))
        FROM jsonb_object_keys(h.datos) AS k
        WHERE prev.datos IS NOT NULL
          AND prev.datos->k IS DISTINCT FROM h.datos->k
       ) AS cambios
FROM public.credito_decisioncomitehistorial h
LEFT JOIN LATERAL (
    SELECT datos FROM public.credito_decisioncomitehistorial h2
    WHERE h2.idsolicitud = h.idsolicitud AND h2.origen = h.origen AND h2.fecha < h.fecha
    ORDER BY h2.fecha DESC LIMIT 1
) prev ON true;
```

Compara cada snapshot contra el anterior de la **misma solicitud y
mismo `origen`** (el `AND h2.origen = h.origen` evita comparar un
snapshot de Fondeo contra uno de DecisionComite — cada cadena de
diffs es independiente por origen). Arma un `jsonb` solo con las
claves distintas; el primer guardado de una solicitud+origen sale con
`cambios = NULL` (no hay "anterior" — se puede mostrar como "creado").

Se generó vía WFAGenerarDao apuntando a esta vista, igual que
`VistaCreditosUnidadFamiliar`: `VistaDecisionComiteHistorial.cs` /
`VistaDecisionComiteHistorialActor.cs` /
`VistaDecisionComiteHistorialViewModel.cs` /
`VistaDecisionComiteHistorialWebApiController.cs` (stack estándar,
filtro/orden/paginación DevExtreme gratis vía `ObtenerWherePorData`).

---

## Fase 2 — Backend C#: guardar el snapshot y leer el historial

- [x] Hecho

**Depende de:** Fase 1.

**Qué se implementó:**

- `Blip.Data\Credito\DecisionComiteHistorialActorNegocio.cs` (partial
  del Actor generado, **no** el archivo estándar — ese lo regenera
  WFAGenerarDao y perdería cualquier método custom) — un solo método:
  `Insertar(int idsolicitud, string origen, string idusuario, string datosJson)`,
  Dapper directo vía `GeneralDao.Connection`.
- La lectura con diff **no** usa un método C# custom — va directo a
  `VistaDecisionComiteHistorialWebApi` (ver Fase 1), que ya trae
  `Cambios` calculado por la vista y soporta filtro/orden/paginación
  DevExtreme sin código adicional.

**Dónde se conectó el insert:**

- `Negocio\Credito\CreditoMaestroViewModelActorNegocio.cs`, dentro de
  `GuardarComiteSinTransaccionScope` (línea ~7214, junto al
  `CreditoMaestroActor.Update(creditoMaestro)`):
  `DecisionComiteHistorialActor.Insertar(vm.Elemento.Idsolicitud, "DecisionComite", idusuario, JsonConvert.SerializeObject(vm.Elemento))`.
  `vm.Elemento` es `DecisionComiteViewModel` (Blip.Entities) — POCO sin
  lazy-load, seguro de serializar tal cual.
- `SolicitudFondeoWebApiController` (Post y Put): mismo insert con
  `origen = "Fondeo"`, pero **no** se serializa la entidad `itemBase`
  completa — ver bug corregido abajo.

**Bug encontrado y corregido (2026-09-28): fuga de datos sensibles en
el snapshot de Fondeo.** `JsonConvert.SerializeObject(itemBase)`
serializaba la entidad `SolicitudFondeo` completa, y Json.NET llama a
todos los getters públicos — incluido el lazy-load
`Credito_obligacionesfinancierasIdobligacion`, que en cascada resuelve
obligación → entidad financiera → `AspNetUsers` (¡con `PasswordHash` y
`SecurityStamp`!) → tercero completo (identificación, dirección, fecha
de nacimiento, etc.). Terminaba guardado en la tabla de auditoría un
hash de contraseña y PII completa de un tercero. Corregido: ahora se
serializa un objeto anónimo con solo las columnas planas (`Id`,
`Idcreditomaestro`, `Idobligacion`, `Valor`, `Esrecursopropio`,
`Esactivo`, `Fechacreacion`), nunca la entidad. El lado de
`DecisionComite` no tenía este riesgo porque `vm.Elemento` ya es una
ViewModel sin lazy-load (verificado leyendo la clase completa).

**Pendiente 1 (bug, corregido 2026-09-28):** el snapshot de `origen =
'DecisionComite'` perdía el contenido de `vm.Casos`. En
`GuardarComiteSinTransaccionScope` el texto realmente persistido en
`credito_decisioncomite.descripcionexcepciones` es `sb.ToString()`
(`Descripcionexcepciones` + cada item de `vm.Casos` concatenado), pero
el insert de historial serializaba `vm.Elemento` tal cual llegó del
request, **antes** de que `sb` se calculara. Corregido agregando
`vm.Elemento.Descripcionexcepciones = sb.ToString();` antes del insert
de historial (línea ~7215 de
`Negocio\Credito\CreditoMaestroViewModelActorNegocio.cs`).

**Pendiente 2 (ruido, corregido 2026-09-28):** falsos positivos de diff
en campos `DateTime` (`Fechacreacion` en Fondeo, `Fechaprimerpago`/
`Fechasistema` en DecisionComite). Un mismo instante puede serializarse
con o sin offset de zona horaria según el `DateTime.Kind` (`Local` si
viene recién creado con `DateTime.Now`, `Unspecified` si viene de una
lectura por Dapper de una columna `TIMESTAMP`). Eso hace que la vista
marque como "cambiado" un campo que en realidad no cambió. Corregido
agregando `new JsonSerializerSettings { DateTimeZoneHandling =
DateTimeZoneHandling.Unspecified }` a los 3 `JsonConvert.SerializeObject`
de los 2 puntos de guardado (`CreditoMaestroViewModelActorNegocio.cs` y
`SolicitudFondeoWebApiController.cs` Post/Put).

**Riesgo:** bajo. Un insert nuevo en 2 puntos ya identificados, sin
cambiar la lógica de negocio existente alrededor.

---

## Fase 3 — UI: grid de historial

- [x] Hecho

**Depende de:** Fase 2.

**Qué se creó:** partial `Views\DecisionComite\Partials\_InformacionHistorial.cshtml`
con un botón "Ver historial" que abre un `Popup` (patrón igual al
`popupmotordecicion` del Index) con el DataGrid adentro — no queda
visible en la pantalla principal. Columnas Fecha/Origen/Usuario, con
una fila expandible (`MasterDetail`) que muestra `cambios` — cada clave
con "antes"/"después" en un grid anidado. Sin resolver de combos: los 5
campos de "Datos Cambio Cuota" muestran el id crudo del combo, no el
nombre (ver "Fuera de alcance").

**Dónde conectarlo:** misma línea que en el plan del trigger, después
de `_DetallesSolicitudFondeoDecision`.

**Riesgo:** bajo.

---

## Fuera de alcance (por ahora)

**Resolver de nombres legibles para los 5 combos de "Datos Cambio
Cuota".** El plan del trigger lo resuelve gratis con un `JOIN` en la
base. Acá, si hace falta, se resolvería en C# al momento de armar la
fila del grid (una consulta a cada catálogo por id) — no se hace en
esta primera versión.

**Cambios que no pasan por los 2 puntos de guardado instrumentados.**
A diferencia del trigger, esta versión no audita nada que modifique la
tabla por fuera de `GuardarComiteSinTransaccionScope` y el WebApi de
Fondeo.

## Cuándo conviene esta alternativa vs. el trigger

Esta gana en simplicidad: menos archivos, nada de PL/pgSQL, nada de
tabla resolver, el diff se computa solo cuando alguien abre el
historial. Pierde cobertura (solo audita 2 puntos de entrada) y nombres
legibles de combos out-of-the-box. Si en algún momento aparece otro
camino que modifique estas tablas (batch, otro proceso), el trigger es
la única de las dos que lo captura sin que nadie tenga que acordarse
de instrumentarlo ahí también.
