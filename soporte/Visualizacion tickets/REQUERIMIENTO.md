

**Descripción del Problema**

Se reporta una inconsistencia en los filtros por estado dentro del portal de consulta de tickets del cliente. La usuaria Daniela (DCAPITAL / CAD MUSIC) indica que la plataforma no le despliega las solicitudes registradas cuando selecciona la vista "En Trámite".

Se solicita revisar no solo el estado "En Trámite", sino validar exhaustivamente todos los demás filtros de estado (Pendientes, Resueltos, Cerrados, etc.) para descartar o corregir que la misma falla de filtrado afecte otras vistas.

**Comportamiento Observado**

Al seleccionar el filtro "En Trámite", la vista aparece vacía o no retorna información.

Al seleccionar la opción "Ver Todos", el sistema despliega la lista completa, confirmando que los tickets existen y se encuentran registrados bajo el estado "En Trámite".

**Pasos para Reproducir y Validar**

Iniciar sesión en el portal de soporte con el usuario del cliente (Daniela - DCAPITAL / CAD MUSIC / IPLAS).

Navegar al módulo de seguimiento de tickets.

Seleccionar el filtro "En Trámite" y comprobar que no carga registros.

Cambiar a "Ver Todos" para confirmar la presencia de los tickets en la base de datos.

Probar el resto de los botones/filtros por estado (Pendientes, Resueltos, Cerrados, etc.) para verificar si también presentan fallas de consulta o si retornan la información correctamente.

**Resultado Esperado**

Cada filtro de estado debe devolver de manera precisa únicamente los tickets asociados al estado seleccionado pertenecientes a la cuenta del usuario.