# Organización de scripts SQL

Objetivo: sencillo y práctico, sin gastar más tiempo organizando que
desarrollando. Basado en el patrón estándar de migraciones (Flyway/Rails/
Django): un archivo por cambio, feature chico, entregas frecuentes. La regla
central es una sola: **la ubicación del archivo/carpeta ES el estado** (pendiente
o enviado). Nada de trackear en un documento aparte.

## Jerarquía de carpetas

```
fix-soporte-tickets/
│
├── scratch/                          ← todo lo NO enviado a producción
│   ├── nuevo-estado/
│   │   ├── 01-alter-columna.sql
│   │   ├── 02-insert-estado.sql
│   │   └── pruebas.sql               ← exploratorio: selects, drops, deletes de prueba
│   └── calendario/
│       ├── 01-create-tablas.sql
│       └── pruebas.sql
│
└── entregables/
    └── 2026-08-26-entregable/        ← una carpeta por entrega a producción
        ├── ajustes-tickets/
        │   └── 01-alter-columna.sql
        └── calendario/
            └── 01-create-tablas.sql
```

**Regla de oro:** si la carpeta del feature está en `scratch/`, todavía no se
envió. Cuando la entregas, la **mueves completa** (no copias) a
`entregables/YYYY-MM-DD-entregable/`, con el mismo nombre. En ese momento deja
de existir en `scratch/`. Así, la única pregunta para saber el estado de algo
es "¿en qué carpeta está?" — no hace falta archivo de tracking, ni recordar
nombres, ni renombrar nada.

## Flujo de trabajo paso a paso

### 1. Empezar un cambio chico

Cuando vayas a tocar la base de datos por un feature, crea su carpeta en
`scratch/`:

```
scratch/nombre-del-cambio/
```

**Mantén el cambio pequeño.** Si notas que la carpeta scratch ya tiene 4-5
archivos numerados y todavía no has entregado nada, es señal de que el
alcance es muy grande — corta ahí, entrega lo que ya está estable, y sigue
con el resto en una carpeta nueva. Entregas frecuentes y chicas es más fácil
de rastrear que una sola gigante al final.

### 2. Desarrollar

Dentro de esa carpeta, cada sentencia (o grupo pequeño de sentencias) que sí
debe llegar a producción va en un archivo numerado:

```
01-alter-columna.sql
02-insert-estado.sql
```

Todo lo exploratorio (verificar datos con `select`, reintentar con `drop`,
limpiar con `delete`) va en un único archivo `pruebas.sql`, aparte. Nunca se
mezcla con los numerados — así nunca se cuela un drop en el entregable.

### 3. Feature listo → mover a entregables

Cuando el cambio está probado y listo para producción:

1. Crea (si no existe) la carpeta de la entrega de hoy:
   `entregables/YYYY-MM-DD-entregable/`
2. Mueve la carpeta completa del feature desde `scratch/` a esa carpeta,
   **sin** `pruebas.sql` (ese se queda en scratch o se borra).
3. Envías esa carpeta de entrega tal cual a producción.

### 4. Si algo salió mal después de enviado

**Nunca se edita** una carpeta ya dentro de `entregables/`. Si falta algo o
hay un error, se crea una carpeta nueva en `scratch/` (ej.
`nuevo-estado-fix/`), se desarrolla igual que el paso 2, y se mueve a la
siguiente entrega cuando esté lista. El historial de entregas queda intacto,
nunca se reescribe.

## Resumen de reglas

| Pregunta | Respuesta |
|---|---|
| ¿Dónde desarrollo? | `scratch/nombre-feature/`, archivos numerados |
| ¿Dónde van las pruebas/drops? | `pruebas.sql`, aparte, nunca numerado |
| ¿Cómo sé si algo ya se envió? | Si está en `entregables/`, ya se envió. Si está en `scratch/`, no. |
| ¿Puedo editar una entrega ya enviada? | No. Se crea carpeta nueva en `scratch/` y se mueve cuando esté lista |
| ¿Qué tan grande debe ser cada feature? | Chico — si scratch acumula muchos archivos sin entregar, corta y entrega |
