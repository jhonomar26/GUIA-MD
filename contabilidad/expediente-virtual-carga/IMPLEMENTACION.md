# Implementación — Qué existe hoy (carga de documentos en comprobante)

> Reference. Refleja el código de la rama `feature/expediente-virtual-carga-c1` al 2026-10-02. Se actualiza al construir.
> Leyenda: 🟢 hecho y compila · 🟡 hecho, falta probar en la app · 🔴 decisión abierta.

## 1. Agregar un combo al comprobante 🟡

Pantalla `DocumentoContableCombo/Index` → `PostConSolicitados` → `DocumentoContableComboAsignacionActorNegocio.AgregarCombo` (R13, todo en una transacción).

```mermaid
flowchart TD
    A([Usuario elige combo y confirma]) --> B{Comprobante guardado?}
    B -- no --> X1[/Error: primero guardar/]
    B -- si --> C{Combo existe y activo?}
    C -- no --> X2[/Error: combo inactivo/]
    C -- si --> D{Combo ya en el comprobante?}
    D -- si --> X3[/Error: ya asignado/]
    D -- no --> E{Ya tiene algun combo?}
    E -- no --> G
    E -- si --> F{Usuario con permiso Agregar Mas Combos?}
    F -- no --> X4[/Error: ya hay un combo/]
    F -- si --> G[Crea el combo del comprobante]
    G --> H[Por cada documento activo del combo]
    H --> I{Tipo unico y ya pedido?}
    I -- si --> J[Lo salta 🔴 R11]
    I -- no --> K[Crea documento PENDIENTE con el obligatorio del combo]
    J --> L([Fin: todo o nada])
    K --> L
```

Si algo falla a mitad, la transacción deshace el combo y sus documentos.

## 2. Agregar un documento a mano 🟢

Grilla de solicitados → `DocumentoContableSolicitadoWebApi.Post`. Sin transacción (es una sola fila).

```mermaid
flowchart TD
    A([Usuario agrega fila en la grilla]) --> B{Comprobante guardado?}
    B -- no --> X1[/Error/]
    B -- si --> C{Tipo existe y activo?}
    C -- no --> X2[/Error/]
    C -- si --> D{Tipo unico y ya pedido? 🔴 R11}
    D -- si --> X3[/Error: ya esta solicitado/]
    D -- no --> E[Crea PENDIENTE, obligatorio, sin combo de origen]
```

## 3. Subir un archivo 🟡

`DocumentoContableArchivoController.SubirArchivo`. Sin transacción global: el archivo se guarda antes de registrar el cargado.

```mermaid
flowchart TD
    A([Usuario sube archivo a un pendiente]) --> B{Ruta activa y contable?}
    B -- no --> X1[/Error/]
    B -- si --> C{Documento activo y del comprobante?}
    C -- no --> X2[/Error/]
    C -- si --> D{Ya tiene archivo activo?}
    D -- si, tipo NO unico --> X3[/Error: ya cargado/]
    D -- si, tipo unico --> E
    D -- no --> E{Extension permitida? foto = solo imagenes}
    E -- no --> X4[/Error/]
    E -- si --> F[Calcula fecha de vencimiento]
    F --> G{Ruta remota?}
    G -- si --> H[Sube por FTP]
    G -- no --> I[Guarda en disco]
    H --> J
    I --> J[Crea archivo y lo une al comprobante]
    J --> K{Ya habia carga?}
    K -- si --> L[Archivo anterior queda inactivo R5, reutiliza la carga]
    K -- no --> M[Crea la carga]
    L --> N([Estado CARGADO])
    M --> N
```

## 4. Estados de un documento

```mermaid
stateDiagram-v2
    [*] --> PENDIENTE: se pide
    PENDIENTE --> CARGADO: sube archivo
    CARGADO --> CARGADO: unico, vuelve a subir
    CARGADO --> ELIMINADO: elimina
```

Vencido no es un estado guardado: se calcula en la consulta (R8). La eliminación y sus pestañas son F4 y no están en este documento.

## 5. Qué falta decidir o probar

| Punto | Estado |
|---|---|
| Pruebas V1 a V8 del permiso (ver [`TAREAS.md`](./TAREAS.md)) | 🟡 pendiente en la app |
| ¿Se permite repetir un tipo único (como crédito) o se mantiene R11? Afecta los rombos 🔴 de los flujos 1 y 2 y el texto de `_SubirArchivo.cshtml` | 🔴 abierta |
| Flujo de eliminar y "¿recrear?" (R9) | ⬜ F4 |
