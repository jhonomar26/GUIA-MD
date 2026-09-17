# Plan: spike dxList para el chat de soporte

## Contexto

`Scripts/siian/tabMensajes.js` pinta el chat de soporte (mensajes + archivos + hilos) a
mano: concatenación de strings HTML (`crearFilaBurbuja`), timeline armado en JS
(`construirTimeline`) y actualizaciones en vivo por SignalR que hacen `$chat.append(...)`
directo al DOM. Funciona, pero cada feature nueva (hilos, archivos en hilo) implica tocar
esa lógica manual y es cada vez más difícil de mantener a medida que el chat crece.

## Investigación ya hecha (no repetir)

- **`dxChat` (widget de chat nativo de DevExtreme): descartado.** Aunque la versión
  instalada (DevExtreme **24.1.7**, confirmada en el header de `dx.all.js`) sí lo soporta
  en teoría, `dxChat` solo se distribuye como módulo ES (`import Chat from
  "devextreme/ui/chat"`), pensado para proyectos con bundler (Vite/Webpack). Este proyecto
  carga DevExtreme como `<script>` global sin bundler — no aparece ninguna referencia a
  "chat" en `dx.all.js`. Meter esto implicaría una cadena de build nueva, fuera de alcance.
- **`dxList` (o `dxScrollView`) con `itemTemplate`: viable.** Ya está en el bundle actual,
  ya se usa en producción vía `Html.DevExtreme().List()` en ~11 vistas (ej.
  `Views/LotePagos/Edicion.cshtml:163`), aunque nunca antes para timeline/chat con scroll
  infinito. Soporta oficialmente en esta versión: `itemTemplate`, `pageLoadMode:
  "scrollBottom"` / `"infinite"`, y operaciones dinámicas sobre `dataSource.store()`
  (`.insert()`, `.push()`) para actualizar sin recargar todo el dataset.
- No hay otro patrón interno mejor: Knockout está cargado en `_Layout.cshtml` pero no se
  usa en ningún lado (`data-bind=` no aparece en ninguna vista) — sería introducir un
  patrón sin precedente ni respaldo en el resto del código. Ningún otro módulo tiene un
  feed/timeline tipo chat; los "históricos" del proyecto son todos `DataGrid` tabular.

## Objetivo del spike

Validar, **sin tocar el chat en producción**, si `dxList` resuelve mejor que la
concatenación manual estos tres puntos concretos (los que hoy son más frágiles):

1. **Timeline mixto (mensajes + archivos) ordenado por fecha** — hoy es
   `construirTimeline()` a mano.
2. **Scroll infinito hacia atrás** — hoy es `cargarMensajesAntiguos()` con cálculo manual
   de `fechaCorteActual` e inserción manual con `$indicator.after($fila)`.
3. **Push en vivo por SignalR** sin recargar todo — hoy es
   `agregarMensajeEnVivo`/`agregarArchivoEnVivo` con `$chat.append` + dedupe manual por
   `data-msg-id`.

No entra en el spike: hilos (`raizActiva`), privacidad, marcado de leídos — eso se conecta
después si el spike resulta viable.

## Cómo hacer el spike sin romper nada

- Crear una vista/página de prueba aislada (ej. `Views/Soporte/SpikeDxList.cshtml` +
  controller mínimo, o incluso un `.html` suelto servido como archivo estático) — **no
  tocar `_TabMensajes.cshtml` ni `tabMensajes.js` todavía**.
- Usar datos de un ticket real vía los endpoints ya existentes
  (`SoporteVistaMensajesTicketWebApi/GetPrincipal`, `SoporteArchivosWebApi/GetArchivosPrincipales`)
  para que el spike sea representativo.
- Armar el `dxList` con `itemTemplate` que replique `crearFilaBurbuja` (misma pinta de
  burbuja, adjuntos con `htmlUnArchivo`).
- Probar scroll infinito con `pageLoadMode: "scrollBottom"` contra la paginación que ya
  expone el backend (`skip`/`take`).
- Simular push en vivo con `dataSource.store().insert(item)` y confirmar que no duplica ni
  requiere `refresh()` completo.

## Criterio de éxito / decisión

- **Si funciona limpio**: migrar `tabMensajes.js` a `dxList` en una tarea aparte (no
  mezclarlo con hilos/archivos), reemplazando `crearFilaBurbuja`/`construirTimeline`/
  `renderItemsTimeline` por el `itemTemplate` + `dataSource`, conservando la lógica de
  negocio (SignalR, `raizActiva`, privacidad) tal cual está.
- **Si no funciona** (ej. el reciclaje de `dxList` no coopera bien con inserciones en
  ambos extremos — scroll atrás + push adelante — o el manejo de altura variable de
  burbujas da problemas): quedarse con el enfoque manual actual, ya funciona y está
  probado; no vale la pena forzar una migración que no da beneficio neto.

## Verificación

1. Spike aislado, sin afectar el chat real (usuarios de soporte no ven cambios mientras
   se prueba).
2. Confirmar visualmente: timeline ordenado, scroll infinito carga hacia atrás sin saltos,
   un item insertado en caliente aparece sin duplicarse y sin recargar todo.
3. Con el resultado (funciona / no funciona), decidir si se abre una tarea de migración
   real o se cierra el spike y se sigue con el enfoque actual.

---

## Resultado del spike (cerrado)

Implementado en `Controllers/Soporte/SoporteDetalleController.cs` (`SpikeDxList`) +
`Views/SoporteDetalle/SpikeDxList.cshtml` — vista aislada, sin tocar `_TabMensajes.cshtml`
ni `tabMensajes.js`. Probado contra datos reales vía
`SoporteVistaMensajesTicketWebApi/GetPrincipal`.

### Problemas encontrados con `dxList`

1. **`.ItemTemplate()` de Razor no usa el prefijo `data.`** — las propiedades del item se
   referencian directo (`<%- nombre %>`), no `<%- data.nombre %>`. Error real:
   `jQuery.Deferred exception: data is not defined`. No es un problema de dxList en sí,
   pero es una trampa fácil de pisar y no está documentada en la skill
   `siian-devextreme-components` (ver nota abajo).
2. **`CustomStore` sin `insert` definido** → `E4011` al intentar simular push en vivo con
   `.store().insert()`. Hubo que cambiar a `.store().push([{type:"insert", data, index}])`
   (API reactiva de DevExtreme que no requiere implementar CRUD en el store).
3. **`pageLoadMode: "scrollBottom"` solo pagina hacia adelante** — no tiene modo nativo
   para "cargar más antiguos hacia atrás mientras el más reciente queda abajo", que es el
   flujo real de un chat. Terminamos invirtiendo el criterio: orden más-nuevo-arriba /
   más-antiguo-abajo (como un feed de notificaciones) en vez del orden de chat estándar,
   solo para que calzara con cómo pagina `scrollBottom`. Forzar el orden de chat real
   habría requerido lógica manual de todos modos.
4. **El `push()` re-renderiza toda la lista**, no reutiliza nodos DOM como
   `$chat.append()` — el scroll se resetea a 0 en cada inserción. Hubo que parchear a mano
   guardando/restaurando `scrollTop` antes y después del `push()`. Es el mismo tipo de
   código manual que ya existe en `agregarMensajeEnVivo`, sin ganancia neta.

**Conclusión: dxList no resuelve mejor que el enfoque manual actual.** Cada uno de los 3
puntos que motivaron el spike (timeline mixto, scroll infinito hacia atrás, push en vivo)
terminó necesitando el mismo tipo de parche manual que `tabMensajes.js` ya tiene, más la
fricción extra de pelear contra las convenciones del widget (orden invertido, API de
reactividad distinta a CRUD). **No se migra.**

### Alternativas externas evaluadas (también descartadas)

- **SaaS de chat** (Stream Chat, Sendbird, TalkJS, CometChat): resuelven scroll/push out
  of the box y se cargan por `<script>` sin bundler, pero implican migrar el modelo de
  datos de mensajería fuera de PostgreSQL (o duplicarlo), costo recurrente ($260-600+/mes),
  y para una cooperativa financiera, dato de cliente en servicio US-hosted es tema de
  cumplimiento a revisar antes de considerar.
- **Self-hosted helpdesk** (Chatwoot): mismo problema — es un helpdesk completo con su
  propio modelo de datos, no un componente que se conecta al backend existente. Sustituiría
  el módulo de soporte entero, no solo el chat.
- **ChatUI (`lesichkovm/chatui`, vanilla JS sin dependencias)**: descartado tras revisión.
  Repo creado enero 2026, 0 estrellas, sin licencia declarada (`license: null`) — riesgo
  legal para uso en software comercial. Además no es un renderer genérico: tiene su propio
  protocolo (`POST /api/handshake`, `POST /api/messages` con widgets serializados en JSON),
  por lo que integrarlo habría requerido reescribir el backend para hablar ese protocolo,
  no solo cambiar la capa de render. Sin paginación/scroll infinito documentado — el
  problema que se buscaba resolver seguía sin resolverse. Sin método claro para insertar
  mensajes en vivo desde JS propio.

### A futuro, si el dolor de mantenimiento crece

Ninguna alternativa evaluada resultó un reemplazo limpio de bajo riesgo. Si en el futuro
`tabMensajes.js` se vuelve genuinamente inmantenible (no solo "se ve feo"), las opciones en
orden de preferencia serían:

1. **Refactor incremental del JS manual** (opción preferida): separar
   `construirTimeline`/`renderItemsTimeline` (render puro), la lógica de paginación
   (`cargarMensajesAntiguos`, `fechaCorteActual`) y el manejo de push en vivo
   (`agregarMensajeEnVivo`, dedupe por `data-msg-id`) en módulos JS más chicos y
   testeables, sin cambiar de librería ni arquitectura. Cero riesgo de dependencia externa
   nueva, cero cambio de modelo de datos.
2. **Volver a evaluar un SaaS de chat solo si** el cumplimiento de datos lo permite
   explícitamente (revisar con el área legal/compliance de la cooperativa primero) y el
   volumen de tickets justifica el costo recurrente. En ese caso Stream Chat es la opción
   con mejor relación DX/precio de las evaluadas (ver comparación en este documento).
   Implicaría migrar o federar el modelo de mensajería fuera de `SoporteMensajes`.
3. **No reintentar `dxList` ni `dxChat`** salvo que DevExtreme lance soporte nativo de
   timeline bidireccional (scroll atrás + push adelante sin re-render completo) en una
   versión futura — hoy (24.1.7) no lo tiene.

### Nota para la skill `siian-devextreme-components`

Vale la pena agregar a la skill el patrón correcto de `.ItemTemplate()`/`.GroupTemplate()`
en Razor: las propiedades del item van sin prefijo (`<%- prop %>`, no `<%- data.prop %>`),
a diferencia de templates JS puros de DevExtreme. Encontrado por prueba y error en este
spike (ver punto 1 arriba).
