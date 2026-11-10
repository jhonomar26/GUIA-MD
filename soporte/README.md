# Módulo: Soporte

Corresponde a `Negocio/Soporte/` y `Negocio/Crm/` (gestión de tickets) en el repo SIIAN.

| Feature | Qué es |
|---|---|
| [hilos-chat-soporte](./hilos-chat-soporte/) | Respuestas en hilo dentro del chat de un ticket |
| [cierre-ticket-solucionado](./cierre-ticket-solucionado/) | "Marcar como solucionado" con ventana de reapertura |
| [fix-ajustes-soporte-estado](./fix-ajustes-soporte-estado/) | Fixes sobre Solucionado: reapertura por mensaje, candado de edición, refresco de UI |
| [notificacion-cambio-estado](./notificacion-cambio-estado/) | Correo al cliente cuando un ticket cambia de estado |
| [soporte-ajustes-dias](./soporte-ajustes-dias/) | SLA en horas hábiles (deja de contar fin de semana/festivos); solucionado→cerrado pendiente |
| [cierre-manual-tickets-vencidos](./cierre-manual-tickets-vencidos/) | Cierre de tickets vencidos (sin calificar/solucionado) manual, respetando calendario, ventana en días hábiles |
| [dxlist-chat-soporte](./dxlist-chat-soporte/) | Spike: `dxList` vs. render manual para el chat — descartado, no se migra |
| [Visualizacion tickets](./Visualizacion%20tickets/) | Filtro de estado "En Trámite" vacío por filtro fantasma persistido en `localStorage` |
| [inicio-sesion-terceros](./inicio-sesion-terceros/) | Acceso al portal según los contactos del tercero (documento + correo); sin preguntar la empresa |
| [peticiones-redmine](./peticiones-redmine/) | Adoptar piezas de Redmine en tickets: tareas por proyecto, grupos, roles y flujo de estados (planificado, [`ADR.md`](./peticiones-redmine/ADR.md)) |
| [prioridades-por-sla](./prioridades-por-sla/) | El portal solo ofrece prioridades con SLA para el motivo; sin SLA no se crea el ticket y se elimina el tiempo de 72h automático |
| [tiempo-respuesta-sla](./tiempo-respuesta-sla/) | El SLA suma tiempo de respuesta + resolución para la fecha límite; no se mide la respuesta |
| [RESUMEN-rama-login-usuario-soporte.md](./RESUMEN-rama-login-usuario-soporte.md) | Resumen de todo lo hecho en la rama `feature/login-usuario-soporte` (SIIAN + portal) |
| [coherencia-dashboard-portal](./coherencia-dashboard-portal/) | El tablero del portal cuenta sobre los mismos tickets que la grilla; ticket sin entorno ya no desaparece; "Vencidos" igual que en soporte (en curso) |
| [asistente-ia-tickets](./asistente-ia-tickets/) | Idea a futuro: asistente que resuelve problemas comunes con lo ya respondido antes de pasar a un asesor |
