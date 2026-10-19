# Plan — Adoptar piezas de Redmine dentro del módulo de tickets

> **Estado: planificado. Ninguna fase implementada.**
> Decisión: [`ADR.md`](./ADR.md) (ADR-002). Pedido original: [`REQUERIMIENTO.md`](./REQUERIMIENTO.md).
> Reglas de negocio de fondo (roles, flujo): [`ANALISIS.md`](./ANALISIS.md).

## En una frase

El ticket sigue funcionando igual que hoy. Se le suman las piezas de Redmine que sirven: **tareas** dentro del ticket, cada una en un **proyecto**; **grupos** y **roles por proyecto** sobre los asesores que ya existen; y un **flujo de estados** controlado, tanto para las tareas como para el propio ticket.

## Modelo

```
Proyecto ──< Tarea >── Ticket (su lógica no cambia)
              tipo · estado · asignado · fechas · horas · historial

Asesores (ya existen) + Grupos + Rol por proyecto
Clientes del portal: sin cambios
```

- Un ticket puede tener **varias tareas**, cada una con su propio asignado y estado, y en proyectos distintos si el trabajo cruza áreas.
- La tarea pertenece al **proyecto**; el ticket no. "Tickets de un proyecto" son los que tienen tareas en él.
- Los clientes del portal siguen como hoy: crean tickets, conversan, adjuntan y califican. No necesitan proyectos ni roles.

## Qué se adopta de Redmine (v1) y qué no

| Redmine | v1 | Cómo se adapta |
|---|---|---|
| Usuarios | Sí | Los asesores de soporte que ya existen. No se crea nada nuevo |
| Grupos | Sí | Agrupan asesores, para dar acceso a varios de una vez |
| Proyectos + rol por proyecto | Sí | Rol efectivo por usuario en cada proyecto: unión de permisos de su membresía directa y la de cada grupo del que forme parte |
| Petición | Sí, como **tarea** | Siempre nace de un ticket y pertenece a un proyecto |
| Tipo | Sí | Desarrollo, Soporte, Tarea, Reunión |
| Estado | Sí, catálogo propio de tareas | Nueva, En trámite, En revisión, Resuelta, Cerrada |
| Prioridad | La del ticket | La tarea la muestra; no tiene una propia |
| Horas | Sí | Estimadas en la tarea; invertidas = suma de lo registrado |
| Flujo de trabajo | Sí, en **dos niveles** | Tareas: matriz por Rol + Tipo. Ticket: matriz única sobre sus estados |
| Comentarios | Se reusa | Mensajes privados del chat del ticket (ya existen) |
| Campos personalizados | Después | No hacen falta para arrancar |
| Campos obligatorios o de solo lectura | Después | — |
| Tareas sin ticket, tipos por proyecto, subtareas, adjuntos propios de la tarea | Después | — |

## Reglas de negocio

1. **Unión de roles por proyecto.** El rol efectivo de un asesor en cada proyecto es la unión de permisos de su membresía directa y la de cada grupo del que forme parte y que también sea miembro del proyecto (detalle en `ANALISIS.md` §3). Sin ninguna membresía, no ve las tareas del proyecto.
2. **Crear una tarea** exige dos cosas: tener acceso al ticket (ser su gestor o subgestor) **y** tener el permiso "crear tareas" en el proyecto elegido.
3. **Asignado:** debe ser miembro del proyecto. Se valida al crear la tarea o al cambiar el asignado, no en cada guardado, para que sacar a alguien del proyecto no deje sus tareas sin poder editarse.
4. **Estados de la tarea:** toma el estado inicial al crearse. Al entrar a un estado cerrado se registra la fecha de cierre; al reabrir, se borra.
5. **Flujo de tareas:** se permiten los saltos que la matriz del rol habilita para el tipo de la tarea. Quedarse en el mismo estado siempre se permite.
6. **Flujo del ticket:** una matriz única dice qué cambios de estado se permiten. Ejemplo: un ticket "En desarrollo" no puede cerrarse sin pasar antes por pruebas.
   - Aplica solo a tickets de soporte, no a las gestiones de CRM, que comparten el mismo catálogo de estados.
   - La respetan los cambios que hace una persona: editar el ticket, marcarlo solucionado, marcarlo resuelto, reabrirlo.
   - **No** la respetan los procesos del sistema: el cierre de vencidos y la reapertura cuando el cliente escribe.
   - Las reglas que el ticket ya tiene hoy se conservan (por ejemplo, entrar y salir de Solucionado solo por su botón).
7. **Acople ticket ↔ tareas:** un ticket no puede marcarse Solucionado ni Resuelto mientras tenga tareas abiertas. Reabrir el ticket no reabre sus tareas.
8. **Administración:** grupos, roles, proyectos, catálogos y matrices se configuran en la pantalla de Parámetros de soporte que ya existe, con el permiso de menú de SIIAN. Dentro de cada proyecto rige el rol.
9. **Semillas obligatorias:** la matriz de tareas trae un flujo por defecto, y la del ticket arranca **replicando lo que hoy se permite**. Sin eso, al desplegar se bloquearían todos los cambios de estado.

---

## F0 — Preparación

- Rama del feature y carpeta de SQL.
- Menú "Tareas" (mis tareas y tareas del proyecto).

**Verificación:** el menú aparece solo para el rol configurado.

## F1 — Grupos y roles

- Grupos de asesores: crear, agregar y quitar asesores.
- Roles con permisos de un catálogo fijo: ver, crear, editar y eliminar tareas; registrar y ver horas; gestionar miembros.
- Semilla: Coordinador, Colaborador, Observador.

**Verificación:** los permisos de un rol se guardan y se leen bien; no se duplican asesores en un grupo.

## F2 — Proyectos y membresías

- Crear proyectos.
- Agregar miembros: un asesor o un grupo, con un rol.

**Verificación:**
- El mismo asesor tiene roles distintos en dos proyectos y ve permisos distintos en cada uno.
- Si es miembro directo y además por grupo, tiene la unión de permisos de ambos roles.
- Si entra por dos grupos con roles distintos, tiene la unión de permisos de ambos.
- Sin membresía, no ve el proyecto.

## F3 — Tareas dentro del ticket

- Catálogos de tipos y estados de tarea, con semilla.
- Pestaña "Tareas" en el detalle del ticket: listar, crear y editar sus tareas.
- Cada tarea: asunto, descripción, proyecto, tipo, estado, asignado, fechas de inicio y fin, horas estimadas.
- Registro de horas e historial propio de cada tarea.
- Grillas "Mis tareas" y "Tareas del proyecto".
- En esta fase el estado de la tarea se cambia libremente. **No se libera a los usuarios hasta tener F4.**

**Verificación:**
- Sin permiso en el proyecto, no se puede crear la tarea.
- Un asignado que no es miembro se rechaza.
- Las horas invertidas suman bien.
- El historial registra cada cambio.
- Se rechaza una fecha de fin anterior a la de inicio.

## F4 — Flujo de tareas

- Editor de matriz: se elige Rol + Tipo y se marcan los saltos permitidos entre estados.
- Semilla con el flujo por defecto (ver `ANALISIS.md` §3).
- El selector de estado de la tarea solo ofrece los saltos permitidos, y el guardado los vuelve a validar.

**Verificación:**
- "Nueva → Resuelta" se rechaza si la matriz exige pasar por "En trámite".
- Un salto no permitido se rechaza aunque llegue por otro camino que no sea la pantalla.

## F5 — Flujo del ticket

No depende de F1–F4: se puede adelantar si urge.

- Editor de matriz única sobre los estados del ticket.
- Estado de pruebas, según lo que se decida en P1.
- Semilla que replica los cambios que hoy se permiten.
- Los cuatro caminos manuales de cambio de estado consultan la matriz.

**Verificación:**
- Un ticket "En desarrollo" no llega a cerrado sin pasar por pruebas.
- El cierre de vencidos sigue cerrando igual que antes.
- Las gestiones de CRM no se ven afectadas.
- Recién desplegado (con la semilla), todo cambio que hoy funciona sigue funcionando.

## F6 — Acople ticket ↔ tareas

- Marcar Solucionado o Resuelto revisa que no queden tareas abiertas.

**Verificación:** con una tarea abierta no se puede marcar Solucionado ni Resuelto; con todas cerradas, sí.

---

## Preguntas abiertas

Cada una trae una propuesta por defecto. Si no hay objeción, se sigue con esa.

| # | Pregunta | Propuesta |
|---|---|---|
| P1 | ¿"Pruebas" es un estado nuevo del ticket, o es el actual "Entregado a gestión soporte"? | Reusar "Entregado a gestión soporte" si significa eso; si no, crear el estado nuevo |
| P2 | ¿El asignado de una tarea ve el ticket completo (chat, archivos)? | En v1, la tarea muestra asunto, descripción y cliente del ticket. Si necesita el chat, el gestor lo agrega como subgestor, algo que ya existe. Después se evalúa un acceso de solo lectura |
| P3 | ¿La tarea tiene prioridad propia? | No, usa la del ticket |
| P4 | ¿Se crean tareas sin ticket, como una reunión interna? | No en v1 |
| P5 | ¿La matriz del ticket cambia según el asesor? | No, es única |

## Fuera de alcance (se agrega cuando haga falta)

- Campos personalizados y reglas de campo obligatorio o de solo lectura.
- Tareas sin ticket.
- Tipos habilitados por proyecto.
- Subtareas y relaciones entre tareas.
- Adjuntos propios de la tarea (se usan los del ticket).
- Notificaciones por correo al asignado.
- Acceso del cliente a las tareas.

## Verificación general

No hay suite automatizada. Cada fase cierra con:
1. SQL ejecutado en la BD demo.
2. Build de la solución.
3. Prueba manual según la verificación de la fase.
4. `IMPLEMENTACION.md` de la fase en esta carpeta.

---

## Anexo técnico (verificado en el repo, para quien implemente)

> Este anexo es la única parte con nombres de código. Al construir, pasa a `IMPLEMENTACION.md`.

**Nombres y tablas**
- WFAGenerarDao quita el prefijo del módulo (`soporte_x` → `X`). Ya existen `Proyecto` (Contabilidad), `TareaAgenda` (Crm) y muchos `Rol*`/`Grupo*`. Por eso todas las tablas nuevas usan `soporte_soporte*` → entidades `Soporte*`.
- Tablas: `grupo`, `grupousuario`, `rol`, `permiso` (fijo, sin CRUD), `rolpermiso`, `proyecto`, `proyectomiembro` (usuario XOR grupo, un rol por fila; el rol efectivo de la persona en el proyecto sale de unir los permisos de todas sus filas aplicables), `tipotarea`, `estadotarea` (con `escerrado`), `tarea` (`idgestion` e `idproyecto` NOT NULL), `tareahoras`, `tareaauditoria`, `flujotarea` (rol, tipo, origen, destino), `flujoticket` (origen, destino → `crm_estadogestioncrm`).
- Usuarios: `soporte_usuarioasesor` (`Idusuariosistema` → `AspNetUsers`, `Activo`). Ids de usuario `varchar(128)`.
- Prioridad del ticket: `soporte_soporteprioridad` (baja, media, alta, critica).

**Dónde se engancha la lógica del ticket**
- Caminos manuales de cambio de estado, en `Negocio/Crm/GestionMaestroCRMActorNegocio.cs`: `ActualizarDatosSoporte`, `MarcarComoSolucionado`, `MarcarComoResuelto`, `ReabrirTicket`. Ahí van la matriz del ticket (F5) y el acople (F6).
- Reglas fijas ya existentes: `ActualizarDatosSoporte:143-163`. Se conservan.
- Exentos: `CerrarTicketsVencidos` (`Negocio/Soporte/SoporteCalificacionActorNegocio.cs:88`) y `ReabrirPorMensaje`.
- `crm_estadogestioncrm` se comparte con CRM: la matriz filtra por `esticketsoporte = true`.
- Acceso al ticket: `UsuarioTieneAccesoTicket` (gestor o subgestor, `Blip.Data/Crm/GestionMaestroCRMActorNegocio.cs:646`). Sirve también para escribir: **no** agregarle a los asignados de tareas.
- Comentarios internos: `SoporteMensajes.Esprivado`.

**Patrones a respetar**
- WebApi generados solo tienen `[Authorize]`: escrituras de tareas, roles y matrices por MVC + negocio; WebApi solo `Get`, filtrado por permisos.
- `ValidaMenu = true` en `Index`; las acciones de escritura se registran como funcionalidad (`LogAttribute.cs:77`).
- Denegar como `SoporteDetalleController`: `TempData["ErrorAcceso"]` + redirección en páginas; JSON en AJAX.
- Transacciones: `TransactionManager.ExecuteTransaction`.
- Pestañas nuevas en `Views/SoporteParametros` (patrón `_Tab*.cshtml`) y en `Views/SoporteDetalle`.
- SQL según `ORGANIZACION-SQL.md`. PostgreSQL 11 / Npgsql 2.2.7. Registrar cada `.cs` en su csproj.
- Skills antes de codificar: `siian-plantillas-generadas`, `siian-actor-pattern`, `siian-actor-dapper-metodos`, `siian-mvc-controllers`, `siian-devextreme-components`, `siian-devextreme-behavior`, `pagina-tabs`, `datagrid-navegacion-externa`.
