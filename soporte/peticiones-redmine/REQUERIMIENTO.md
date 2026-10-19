Abstracción del sistema Redmine
1. Actores y Autenticación (¿Quiénes interactúan?)
• Usuarios: Identidades únicas en el sistema (colaboradores o coordinadores). Por sí solos no poseen permisos globales, solo representan la cuenta de un individuo.
• Grupos de Usuarios: Agrupaciones lógicas de usuarios que facilitan la administración y asignación masiva de permisos dentro de los proyectos.
2. Entorno y Control de Acceso (¿Dónde y qué pueden hacer?)
• Proyectos: El espacio o contenedor principal de trabajo. En él se realiza la asociación contextual:
Proyecto → (Usuario / Grupo) + Rol
• Roles: Definición de perfiles con un conjunto específico de permisos. El alcance del rol es por proyecto, lo que significa que un mismo usuario puede tener permisos diferentes en proyectos distintos.
3. Unidades de Trabajo y Clasificación (¿Qué se ejecuta?)
• Peticiones (Issues): Es la unidad fundamental de seguimiento. Contiene la información técnica y administrativa de la tarea (asunto, descripción, estado, fecha inicio, fecha fin, horas estimadas/invertidas, usuario asignado).
• Tipo de Petición: Categoría que clasifica la naturaleza del trabajo (Desarrollo, Soporte, Tarea, Reunión, etc.). Define qué campos y flujos aplican a esa petición.
• Prioridad de Petición: Escala parametrizable por el administrador (Baja, Media, Alta, Urgente) que establece la jerarquía y urgencia de atención de la tarea.
• Estado (Status): El valor puntual en el que se encuentra la petición dentro del ciclo de vida (Nueva, En trámite, En revisión, Resuelta, Cerrada).
• Campos Personalizados: Atributos adicionales que se pueden agregar a las peticiones o proyectos para capturar información específica no nativa (ej. ID de Cliente, URL del repositorio, Impacto, Ticket).
4. Gobierno y Reglas de Negocio (¿Cómo cambia el estado?)
• Flujo de Trabajo: Matriz de control que rige las transiciones de estado permitidas.
o Garantiza la trazabilidad e impide saltos inconsistentes en el ciclo de vida (por ejemplo, exige pasar por En trámite antes de llegar a Resuelta).
o Controla qué campos son obligatorios o editables según el Rol del usuario y el Tipo de petición.
