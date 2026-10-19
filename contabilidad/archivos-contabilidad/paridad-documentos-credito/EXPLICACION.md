# Explicación: qué falta y por qué

Cubre las brechas **B4, B5 y B6**. B2 tiene su propia explicación en [EXPLICACION B2.md](EXPLICACION%20B2.md).

## Estado real de las brechas

Al revisar la rama, tres brechas del requerimiento ya estaban hechas:

- **B1** constancia con detalle: commit `cedcba97c`.
- **B2** permiso para documentos individuales: commit `44b917826`.
- **B3** ver archivo solo si es contable: commit `44b917826`.

**B4, B5 y B6** se hicieron después, en el commit `7955091af`. Todas viven en `_GestionDocumentos.cshtml`, que es la pantalla de gestión de documentos contables. Lo que quedó construido está en [IMPLEMENTACION.md](./IMPLEMENTACION.md).

## B4: editar la descripción de un archivo cargado

**En crédito:** la grilla permite editar en línea `Descripcion` y `Esactivo`. Al guardar, `ActuliazarArchivo` carga el `Archivo`, cambia esos campos y registra usuario y fecha de última modificación. No valida permiso.

**En contabilidad:** la grilla es de solo lectura. La columna `Observaciones` ya muestra la descripción del archivo (`a.descripcion` en la vista), así que no hay que tocar la BD.

**Qué se hace:**
1. Acción nueva `ActualizarArchivo` en `VistaDocumentoContableCargadosWebApiController`, el mismo servicio que ya alimenta las grillas Cargados y Remoto. Antes de editar, comprueba que el archivo esté vinculado a un documento contable. Así no se puede editar un archivo de crédito por esta ruta.
2. Grillas Cargados y Remoto: edición en línea, solo la columna `Observaciones`.

**Qué NO se hace:** `Esactivo`. En contabilidad, un archivo "activo" lo decide `DocumentoContableCargado.Esactivo` y el estado de la solicitud. Cambiar `generales_archivo.esactivo` no movería nada: el archivo seguiría en Cargados y el documento no volvería a Pendientes.

**Permiso:** ninguno, igual que crédito.

## B5: pestaña Vencidos completa

Hoy muestra nombre, vencimiento y "Ver". Se agregan descripción, nombre del archivo, fecha de cargue y usuario que cargó. Sin tercero ni codeudores. Es solo lectura. Hay que ampliar la consulta que alimenta la pestaña (`ObtenerVencidosPorIddocumentocontable`) y su ViewModel.

## B6: columna Obligatorio en Pendientes

El servicio ya devuelve `EsObligatorio`. Solo falta mostrar la columna en la grilla.

## Qué no se toca

Código de crédito, tercero y CRM. La BD no cambia.
