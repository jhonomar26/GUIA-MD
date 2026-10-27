> **Histórico (2026-10-20).** La parte de la Fase 1 vive ahora en [01-base-dos-duenos](../01-base-dos-duenos/archivo/EXPLICACION.md). La de la Fase 2 se rehace por feature.

# Explicación: Fase 1, preparar los datos para dos dueños (script 10 + PR1)

> [← README](../README.md) · Plan: [PLAN.md](./PLAN.md) · Decisión: [ADR.md](../ADR.md)

## Parte lógica (sin código)

### Qué problema resuelve esta fase

Hoy el expediente virtual (documentos pedidos, combos y archivos) cuelga **siempre** de un comprobante contable. Las tres tablas tienen `iddocumentocontable` obligatorio.

Un documento equivalente no tiene comprobante hasta que se contabiliza, y sus archivos son suyos, no del comprobante. Entonces la base necesita aceptar otro dueño. Esta fase solo prepara los datos; **nadie ve ningún cambio**.

### Cómo es hoy y cómo queda

```mermaid
flowchart LR
    subgraph Hoy
        C1[Comprobante contable] --> S1[Pedidos / Combos / Archivos]
    end
    subgraph Queda
        C2[Comprobante contable] -->|dueño opcional| S2[Pedidos / Combos / Archivos]
        E2[Documento equivalente] -->|dueño opcional| S2
    end
```

Cada fila tendrá **dos columnas de dueño** y exactamente una llena:

| Fila | `iddocumentocontable` | `iddocumentoequivalente` |
|---|---|---|
| De un comprobante (todo lo que existe hoy) | lleno | vacío |
| De un documento equivalente | vacío | lleno |
| Ninguno o los dos | **la base lo rechaza** | |

Esa regla la impone la base (un CHECK), no el código. Si alguien olvida llenar el dueño, falla al guardar en lugar de dejar un archivo huérfano.

### Qué hace el script 10 (fuera del repo, se corre en demo)

1. Agrega la columna nueva a las tres tablas.
2. Hace opcional `iddocumentocontable`.
3. Crea la FK del documento equivalente **restrictiva**: no se puede borrar un documento equivalente que tenga expediente (el servicio lo traducirá a un 409 en la Fase 2). Las FK contables actuales son `CASCADE` y **no se tocan**.
4. Crea índices sobre la columna nueva. Hoy solicitado y archivo ni siquiera tienen índice sobre el dueño contable; no se agrega porque no es parte de este cambio.
5. Recrea las dos vistas (cargados y eliminados). La de eliminados pasa a `LEFT JOIN`, porque un archivo de documento equivalente no tiene comprobante, y toma el tercero del comprobante **o** del documento equivalente.
6. Es idempotente (se puede correr dos veces) y trae su script de reversión.

### Qué hace el PR1 (código)

El código sigue hablando de un solo dueño, pero ahora sabe que existen dos:

```mermaid
flowchart LR
    A[Llamador contable existente: solo el id del comprobante] -->|sin cambios| B[Método con el id del documento equivalente opcional]
    B --> C[SQL idéntico al de hoy]
    D[Llamador futuro, Fase 2: el id del documento equivalente] --> B
    B --> E[SQL sobre la columna del documento equivalente]
```

- No hay ningún parámetro de "origen": el dueño lo dice el id que viene. Si viene el del documento equivalente, es de documento equivalente; si viene el del comprobante, es contable. Los dos juntos o ninguno se rechazan.
- Las 7 consultas del actor de solicitados reciben el id del documento equivalente como último parámetro **opcional**. Quien ya las llama no se entera: con solo el comprobante el SQL es el mismo.
- `Iddocumentocontable` pasa de `int` a `int?` en entidades y ViewModels, y aparece `Iddocumentoequivalente`. Esto es lo más pesado de la fase: hay que arreglar cada lugar que usaba el valor como `int`, solo con `.Value` o `?? 0`, sin cambiar la lógica.

### Qué no cambia

- Ninguna pantalla, ningún permiso, ninguna respuesta.
- El comprobante 168816 devuelve el JSON idéntico: 1 pendiente, 0 vencidos, 4 cargados locales, 0 remotos y 7 eliminados (foto en `antes/`).
- La firma, el popup de eliminación y el acta de la constancia 282.

### Qué se mide al terminar

| Paso | Qué se compara | Esperado |
|---|---|---|
| 1.4 | Pruebas SQL antes de aplicar el script | Fallan (la columna no existe) |
| 1.5 | Mismas pruebas después, y script 10 por segunda vez | Pasan y no cambia nada |
| 1.6 | Los JSON de 168816 con el código viejo y la base nueva | Idénticos a `antes/` |
| 1.7 | Reversión dentro de una transacción con `ROLLBACK` | Funciona y no deja rastro |
| 1.20 | Los JSON de 168816 con el código nuevo | Idénticos a `antes/` |
| 1.21 | `git diff --stat` | ~200 líneas, sin tildes rotas en los 9 archivos latin1 |

Si 1.6 o 1.20 difieren, no se avanza.

### Riesgos de esta fase

- El paso a `int?` es el cuello de botella: es mecánico pero toca muchos archivos.
- Compilar actualiza el servidor de pruebas compartido, por eso el script 10 se aplica **antes** del PR1.
- Los archivos latin1 se editan a nivel de bytes, uno por uno, revisando el diff.

## Parte de código

Pendiente: se escribe después de programar la fase.

---

# Explicación: Fase 2, que el servidor sepa de cuál dueño habla (script 11 + PR2)

> [← README](../README.md) · Plan: [PLAN.md](./PLAN.md) · Reglas: [ANALISIS.md §4](../ANALISIS.md#4-reglas)

## Parte lógica (sin código)

### Qué problema resuelve esta fase

Tras la fase 1 la base ya acepta los dos dueños, pero el servidor sigue pensando que todo es de un comprobante. Esta fase le enseña a recibir **el id de uno o del otro**. No hay un dato aparte llamado "origen": si la petición trae el id del documento equivalente es de documento equivalente, si trae el del comprobante es contable, y no puede traer los dos ni ninguno. Con ese id el servidor decide a quién pertenece, qué permiso pide y de qué tercero se trata. Todavía no hay pantalla nueva: se prueba con llamadas directas al servicio.

Antes de eso se cierran los pendientes de la fase 1 (los dos ids en la subida y en el borrado, y en las consultas de pedidos y cargados), porque todo lo demás se apoya en ellos.

### Quién decide qué

```mermaid
sequenceDiagram
    participant U as Usuario (pantalla o servicio)
    participant S as Servidor
    participant B as Base de datos
    U->>S: pide algo + el id del comprobante O el del documento equivalente
    S->>S: ¿vino exactamente uno de los dos? Si no, rechaza (400)
    S->>S: ¿tiene el permiso de ESE tipo de documento? Si no, rechaza (403)
    S->>S: ¿el archivo o pedido pertenece a ESE documento? Si no, rechaza
    S->>B: opera con la columna de dueño correcta
    B-->>S: ok
    S-->>U: resultado
```

El orden importa: primero se valida todo y **recién después** se toca la base. Si algo falla, no queda nada a medias.

### Las reglas que se aplican acá

| Qué | Cómo queda |
|---|---|
| Permisos | Cada tipo de documento tiene los suyos. Tener permiso de contabilidad **no** sirve en un documento equivalente, ni al revés. El script 11 da los permisos nuevos a los roles que ya tenían el contable |
| Primer combo | Libre. Del segundo en adelante, con el permiso propio de ese tipo de documento |
| Tercero | Para pedidos y firma se usa el tercero del documento equivalente |
| Subir archivo | Se ata al dueño que trae la petición |
| Eliminar con "recrear" | La constancia es una sola; los pendientes nuevos quedan en **el mismo** documento equivalente |
| Archivo de otro documento | Se rechaza: no basta con conocer el id de un archivo |
| Firma | La firma no cambia; el dueño se lee de la fila del archivo |
| Borrar un documento equivalente | Si tiene pedidos o archivos, la base lo impide y el usuario ve un mensaje claro (409), no un error técnico |
| Solo el id del comprobante | Todo se comporta como hoy: contable no cambia |

### Qué no cambia

- El comprobante contable (CO101) y sus pantallas.
- Al contabilizar o duplicar un documento equivalente **no se copia** nada de su expediente.
- Ninguna pantalla nueva todavía: eso es la fase 3.

### Qué se mide al terminar

1. Los curls de antes del comprobante 168816 y el acta de la constancia 282 dan **lo mismo** que antes.
2. Una petición con los dos ids, o con ninguno, se rechaza con 400 sin tocar datos.
3. Un usuario solo con permisos contables es rechazado sobre un documento equivalente, y al revés.
4. Un archivo de otro documento es rechazado.

### Riesgos de esta fase

- **Compilar actualiza el servidor compartido:** el script 11 va antes del código que lo usa.
- **Recrear al eliminar** es la parte con más piezas: copiar mal el dueño dejaría pendientes huérfanos o en el comprobante equivocado.
- Varios archivos están en latin1 y se editan de a uno, a nivel de bytes.

## Parte de código

_Se escribe después de que la parte lógica quede entendida._
