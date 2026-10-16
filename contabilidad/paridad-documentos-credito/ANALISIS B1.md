# Análisis: brechas de documentos contables frente a crédito

Se va completando brecha por brecha. Lo de aquí es lectura de código (2026-10-14); nada se ejecutó en la app.

## B1. Constancia de eliminación sin detalle

### Qué pasa hoy

Al eliminar archivos de un comprobante, contabilidad crea la constancia y marca cada archivo con ella (`DocumentoContableArchivoActorNegocio.cs:196-245`). Ahí termina su parte. La constancia queda con "N archivos eliminados" pero **ningún lugar sabe listar los archivos contables**, porque cada consumidor arma su lista a mano con un dominio por línea y contabilidad nunca se agregó.

### Quién consume el detalle

| Consumidor | Dónde | Dominios que incluye | ¿Afecta contabilidad? |
|---|---|---|---|
| **Acta de eliminación (PDF/HTML)**: tabla "Carpeta / Tercero / Tipo documento / Descripción / Fecha / Usuario" | `CreditoMaestroReportesNegocio.ObtenerValoresParametrosEliminacionArchivos` (:869-910). Lo usan `FormatoEliminacionArchivosController`, `FormatosController` (editor) y el diseñador de formatos | Terceros, Crédito, CRM, CRM detalle | **Sí, es el efecto visible**: el acta de una constancia contable sale con la tabla vacía |
| `ConstanciaEliminacionArchivosActorNegocio.ContenidoCarpetasVirtuales(idConstancia, …)` | `Negocio/Generales/ConstanciaEliminacionArchivosActorNegocio.cs:16-52`, expuesto en `ConstanciaEliminacionArchivosController.ArchivosEliminadosPorIdConstancia` | Terceros, Crédito, CRM (sin CRM detalle) | Hoy **nadie lo llama**: no hay vista ni JS que use esa acción. Se corrige igual para no dejar dos listas distintas |

La grilla de constancias (`ContenidoCarpetaVirtual/IndexConsulta.cshtml:376`, pestaña "Constancias eliminación") sí muestra las constancias contables, porque lee la tabla `ConstanciaEliminacionArchivos` completa. El problema aparece al pulsar el botón que genera el acta (`IndexConsulta.cshtml:519-545` → `/FormatoEliminacionArchivos/Formato`).

### Causa

Cada dominio tiene su método `ArchivosCarpetaVirtual<Dominio>(rutas)` que devuelve `ContenidoCarpetaVirtualViewModel`, y los consumidores los suman a mano. Contabilidad no tiene ese método ni está sumada en ninguno de los dos sitios. No es un error de datos: las constancias y las marcas en `generales_archivo.idconstanciaeliminacion` sí están bien.

### Qué hay en contabilidad para armarlo

- `ParametrosCarpetaVirtual.Escontabilidad` ya existe (lo usa `ObtenerRutasContables`). No hace falta columna nueva.
- Cadena de tablas: `generales_archivo` ← `contabilidad_documentocontablearchivo` (`idarchivo`, `iddocumentocontable`) ← `contabilidad_documentocontablecargado` (`iddocumentoarchivo`) → `contabilidad_documentocontablesolicitado` (tipo, descripción, tercero) → comprobante `contabilidad_documentocontable` (`idtercero`).
- Tercero: el del comprobante, que desde la feature de firmas también está guardado en el solicitado (`Idtercero`).
- El archivo eliminado deja el cargado inactivo, pero la fila de `documentocontablearchivo` y la del cargado se conservan (`DocumentoContableEliminado` guarda el historial). Por eso el recorrido por joins sigue funcionando después de eliminar.

### Diferencias con crédito que hay que respetar

- Crédito filtra por ruta (`archivo.url LIKE %ruta%`) porque su tabla de archivos mezcla dominios. Para contabilidad **no hace falta**: el join con `contabilidad_documentocontablearchivo` ya lo acota, y el filtro por `idconstanciaeliminacion` lo reduce a la constancia pedida.
- Crédito solo muestra el número de solicitud y el crédito; contabilidad podría mostrar el número del comprobante (`NrodocumentoCampo`). Por decidir.
- Carpeta virtual: etiqueta nueva "Contabilidad" (crédito usa "Creditos").

### Lo que NO se sabe todavía

- Si la plantilla del acta (formato `Esformatoeliminacionarchivo`) tiene campos que dependan de crédito. Se leyó el código que arma la tabla, no los formatos guardados en la base.
- Si el diseñador de formatos (`EliminacionArchivosFormatoActorNegocio.NombresCampos`) necesita algo para contabilidad. Parece que no: recibe `tablaEliminados` ya armada.

### Alcance propuesto

Decisión (2026-10-14): en vez de armar el SQL a mano con Dapper, **una vista de base de datos** y su entidad + Actor generados con WFAGenerarDao, igual que `contabilidad_vistadocumentocontablecargados`. Los joins quedan en la base y el código solo filtra por constancia.

1. Script SQL `7-vista-archivos-eliminados-contabilidad.sql` (carpeta `scratch`, mismo estilo que 1-6): vista `contabilidad_vistaarchivoseliminados` con `idconstanciaeliminacion`, tercero, tipo de documento, descripciones, archivo, fecha y usuario de cargue. Sin `BEGIN/COMMIT`, idempotente.
2. Entidad y Actor de la vista: generar con `WFAGenerarDao.exe dapper --tabla contabilidad_vistaarchivoseliminados --salida %TEMP%\gen`, difear y copiar `{Entidad}.cs` y `{Entidad}Actor.cs` a `Blip.Data/Contabilidad/` (según `siian-plantillas-generadas`). Registrar en `Data.csproj`. El resto de la familia (ViewModel, controladores, vistas) no se genera.
3. Un método corto que convierte las filas de la vista a `ContenidoCarpetaVirtualViewModel` con `Tipocarpetavirtual = "Contabilidad"`, y se suma a los dos sitios: el acta (`ObtenerValoresParametrosEliminacionArchivos`) y `ConstanciaEliminacionArchivosActorNegocio.ContenidoCarpetasVirtuales`.

Lo que **no** entra: agregar CRM detalle al segundo sitio (le falta hoy, no es de contabilidad), ni la consola central (D3), ni el número del comprobante en el acta (mejora futura para todos los módulos a la vez; decidido 2026-10-15).

### Riesgo

Bajo. Se toca código compartido (el acta), pero solo se agrega una lista más al final; crédito, tercero y CRM siguen con su consulta igual. Verificar que el acta de una constancia de crédito salga idéntica.

### Verificación propuesta

- Eliminar 2 archivos de un comprobante con "recrear" y sin él → generar el acta de esa constancia → la tabla lista 2 filas con carpeta "Contabilidad", tercero, tipo, descripción, fecha de cargue y usuario.
- Generar el acta de una constancia de crédito y una de tercero → igual que antes.
- Constancia con archivos de contabilidad y crédito a la vez: no existe hoy (cada eliminación es de un dominio), pero la consulta no debe cruzarlos.

### Decisiones para ti

- ¿Muestro el número del comprobante en el acta (hoy crédito muestra solo tercero y tipo)? Mi recomendación: no, igual que crédito; la tabla de la plantilla no tiene columna para eso.
