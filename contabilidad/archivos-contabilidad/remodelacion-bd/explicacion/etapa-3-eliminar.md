# Etapa 3: eliminar y crear un documento nuevo (S8, S9)

> Parte de negocio, antes de programar. Specs en [`ANALISIS.md`](../ANALISIS.md), tarea T3.1 en [`PLAN.md`](../PLAN.md).

## Quién participa

- **El usuario con el permiso** *Eliminar Documentos Cargados Contabilidad* (o el del documento equivalente). Sin él, el botón no se ve y el sistema rechaza igual.
- **El sistema**, que vuelve a validar permiso y pertenencia de cada archivo, y es quien borra el archivo físico.

## Qué pasa y en qué orden

```mermaid
sequenceDiagram
    actor U as Usuario
    participant P as Pantalla (Cargados)
    participant S as Sistema
    U->>P: Marca 2 archivos, escribe la observación
    P->>U: ¿Desea crear un nuevo documento con las mismas características?
    U->>P: Sí / No
    P->>S: Archivos + observación + respuesta (dueño: el de la pantalla)
    S->>S: ¿Tiene el permiso? ¿Cada archivo es del dueño y no está eliminado?
    S->>S: Una sola constancia (quién, cuándo, por qué, cuántos)
    S->>S: Cada archivo queda eliminado, ligado a la constancia
    S->>S: Si respondió Sí: un pedido nuevo pendiente por archivo
    S->>S: Borra el archivo físico (disco o FTP) y recalcula el espacio usado
    S-->>P: Listo
    P->>P: Recarga: archivos fuera de Cargados; los nuevos en Pendientes
```

1. **Validar todo antes de tocar algo.** Permiso, y que cada archivo sea del dueño de la pantalla y siga vigente. Si uno falla, no se elimina ninguno (hoy la validación de pertenencia está apagada: H3).
2. **Constancia única** para todos los archivos de esa operación.
3. **Eliminar es marcar:** el archivo queda `eliminado` con su constancia. El pedido y el vínculo **no se tocan**.
4. **Crear nuevo (Sí):** por cada archivo, un pedido nuevo con el mismo dueño, tipo y tercero; descripción vacía y obligatorio. Con **No**, no se crea nada.
5. **Borrar el físico** y recalcular el espacio usado (local y FTP).

## Con datos

| Momento | Pedido 10 (Cédula) | Archivo 100 | Pedido 11 | Pendientes |
|---|---|---|---|---|
| Antes | activo | vigente | — | — |
| Elimina con **Sí** | activo (sin cambios) | eliminado + constancia 7 | nuevo, activo, descripción vacía, obligatorio | solo el 11 |
| Elimina con **No** | activo (sin cambios) | eliminado + constancia 7 | no existe | ninguno |

## Casos raros

- **Mandar el número de un archivo de otro comprobante.** Se rechaza todo (H3).
- **Un archivo ya eliminado en la selección.** Hoy se salta en silencio; se rechaza (ya no es "eliminable").
- **Falla el borrado del físico a mitad.** La base se revierte, pero los archivos ya borrados no vuelven. Mismo hueco que crédito; **decisión del usuario (2026-10-27): se deja igual**, la lógica se toma de crédito y el cómo se puede mejorar después.
- **Permiso.** Se busca por la ruta de la funcionalidad (`~/DocumentoContableArchivo/BorrarDocumentosSeleccionados`); no hace falta que exista una acción con ese nombre.
