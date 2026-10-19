# Organización de scripts SQL  
  
## Jerarquía de carpetas.
En esta carpeta se ubican todos los sql
C:\Users\User\DataGripProjects\fix-soporte-tickets\ORGANIZACION-SQL.md
  
```  
fix-soporte-tickets/  
│  
├── scratch/                          ← trabajo diario, desordenado, tuyo  
│   ├── nuevo-estado.sql  
│   ├── calendario.sql  
│   └── ajustes-tickets.sql  
│  
└── entregables/  
    └── 2026-08-26-entregable/        ← una carpeta por entrega a producción        ├── 1-ajustes-tickets.sql        ├── 2-calendario.sql        ├── 3-nuevo-estado.sql        └── 4-nuevo-estado-fix.sql```  
  
## scratch/ — mientras desarrollas  
  
Un archivo por feature. Todo se mezcla ahí: pruebas, drops, selects exploratorios,  
inserts de prueba, sentencias reales. Sin pensar en orden ni limpieza.  
  
Se divide en 2 bloques con separador de comentario:  
  
```sql  
-- ===== PRUEBAS (no sale de aquí) =====  
select * from crm_estadogestioncrm;  
drop table if exists soporte_soportecategoria;  
delete from crm_gestionmaestrocrm where id=999;  
  
-- ===== FINAL (esto se copia al entregable) =====  
alter table crm_estadogestioncrm  
    add column essolucionado boolean default false not null;  
insert into crm_estadogestioncrm (nombre, essolucionado, ...)  
values ('Solucionado', true, ...);  
```  
  
**Regla:** todo lo exploratorio/destructivo va arriba del separador y se queda ahí.  
Todo lo que debe persistir en producción (create/alter/insert real) va abajo,  
en el bloque `FINAL`.  
  
## entregables/ — lo que se envía a producción  
  
Una carpeta por fecha de entrega: `entregables/YYYY-MM-DD-entregable/`.  
Dentro, scripts numerados `1-`, `2-`, `3-`... indicando el **orden exacto de  
ejecución** que pide producción.  
  
**Nunca se reescribe una carpeta de entrega ya enviada.** Si algo quedó mal  
(drop colado, falta un insert), se agrega el **siguiente número** dentro de  
esa misma carpeta o se crea una carpeta nueva con la fecha del fix — nunca se  
edita un script ya enviado:  
  
```  
entregables/2026-08-26-entregable/  
  1-ajustes-tickets.sql  2-calendario.sql  3-nuevo-estado.sql  4-nuevo-estado-fix.sql   <- corrección, número siguiente, no se toca el 3```  
  
La fecha en el nombre de carpeta te sigue diciendo cuándo empezó esa entrega;  
el número dentro te dice el orden de ejecución que necesita producción.  
  
## Flujo completo  
  
1. Desarrollas en `scratch/nombre-feature.sql`, todo mezclado, marcado en 2 secciones.  
2. Feature lista → copias solo el bloque `FINAL` al siguiente número dentro de  
   `entregables/YYYY-MM-DD-entregable/`.  
3. `scratch/` se resetea o se deja para el próximo feature — nunca se toca  
   una carpeta de `entregables/` ya enviada, solo se le agrega el número  
   siguiente si hace falta un fix.  
  
## Por qué evita el problema del drop colado  
  
El drop/select de prueba está físicamente separado (arriba del separador) del  
código real (abajo) en scratch. Al copiar al entregable, solo tomas el bloque  
`FINAL`, así que nunca se cuela algo exploratorio por accidente. Y como nunca  
reescribes un script ya numerado y enviado, no hay riesgo de que producción  
reciba una versión con algo pegado de más.