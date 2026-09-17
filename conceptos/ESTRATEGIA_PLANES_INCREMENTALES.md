# Estrategia: planes grandes vs. ejecución incremental

## Problema

Un plan grande escrito de una sola vez (ej. `docs/hilos-chat-soporte.md`, con 7 fases:
BD, entidad, negocio, controllers, SignalR, frontend soporte, frontend portal) tiende a:

- Asumir cosas del código que ya cambiaron o nunca fueron así (el plan es una foto del
  momento en que se escribió, no del código real al momento de ejecutar).
- Esconder errores entre muchas fases: si algo falla en la Fase 2, puede no notarse hasta
  la Fase 5, cuando ya es más caro de rastrear y corregir.
- Empujar a "completar el plan" en vez de validar cada pieza contra el estado real del
  código antes de seguir.

Caso real: al ejecutar la Fase 6 (frontend) del plan de hilos, la mayoría de mensajes ya
estaba implementada (no lo reflejaba el plan), y aparecieron gaps que el plan no prevé
(endpoint de archivos de hilo, URL de subida dinámica, enrutamiento de archivos en vivo).
Resolverlos de a uno, verificando el código antes de tocarlo, fue más rápido y más seguro
que intentar aplicar la Fase 6 completa de corrido.

## Estrategia

### 1. El plan grande es un mapa, no una receta de ejecución

Sirve para:
- Entender el panorama completo (reglas de negocio, dependencias entre capas, decisiones
  ya tomadas — ej. "no se crea tabla Hilo", "R1-R7" en `hilos-chat-soporte.md`).
- Saber en qué orden tiene sentido avanzar (BD → entidad → negocio → controllers → front).

No sirve para:
- Ejecutarlo de punta a punta sin pausas de verificación.
- Asumir que lo que describe sigue siendo cierto en el código — **siempre confirmar contra
  el archivo real antes de modificarlo**, aunque el plan diga que "falta hacer X".

### 2. Dividir en tareas pequeñas, una capa o un endpoint a la vez

En vez de "implementar Fase 6 completa", trocear así:

1. Explorar el estado real de esa pieza puntual (¿ya existe? ¿qué le falta?).
2. Proponer el cambio mínimo para esa pieza.
3. Aplicarlo.
4. Verificar (compilar, probar el endpoint, revisar el flujo en el navegador si aplica).
5. Recién ahí pasar a la siguiente pieza.

Ejemplo de troceo real usado en hilos + archivos:
1. Backend: agregar `idMensajeraiz` al flujo de subida (`SubirArchivo`).
2. Backend: separar el listado principal del listado de hilo (`GetArchivosPrincipales` /
   `GetArchivosHilo`), en vez de traer todo y filtrar en frontend.
3. Frontend: URL de subida dinámica según el hilo activo.
4. Frontend: cargar archivos del hilo al abrirlo.
5. Frontend: enrutar el push en vivo (SignalR) de archivos por hilo.

Cada uno se completó y se confirmó antes de pasar al siguiente.

### 3. Preguntar antes de asumir alcance

Antes de arrancar una tarea grande, acotar explícitamente qué capas/módulos entran y
cuáles no (ej. "solo backend, solo lado soporte, portal después"). Si aparece una duda de
diseño a mitad de camino (ej. "¿cargamos todo y filtramos en frontend, o pedimos solo lo
necesario?"), resolverla ahí mismo en vez de seguir con el plan original a ciegas.

### 4. Señales de que conviene frenar y trocear más

- El siguiente paso toca una capa distinta a la que se acaba de tocar (backend → frontend,
  Negocio → Blip.Data).
- El plan asume algo sobre el código que no se ha confirmado en esta sesión.
- Aparece una pregunta de diseño no resuelta en el plan original.
- El cambio afecta a más de un consumidor existente (ej. renombrar un endpoint que ya
  tiene un caller en JS).

## Resumen

| | Plan grande | Ejecución |
|---|---|---|
| Usar para | Contexto, reglas de negocio, orden general | — |
| No usar para | — | Ejecutar de corrido sin verificar cada pieza |
| Unidad de trabajo | Fase completa | Una pieza (endpoint, método, ajuste de UI) verificada antes de seguir |
