# Requerimiento: mejoras Garantías

## Pedido original

> - CORRECCION MUNICIPIO
> - CORRECCION EDITAR PROPIETARIO
> - CORRECCION DATOS INNECESARIOS GARANTIA
> - CORRECCION EN PARAMETROS DE GARANTIA
> - CORRECCION TIPO DE DOCUMENTOS
> - CORRECCION BOTON DE REGRESAR

## Indagación — CORRECCION BOTON DE REGRESAR

**P: ¿cuál es el problema real del botón Regresar en `SubirArchivo.cshtml`?**
R: La vista se abre siempre en una pestaña nueva (`window.open(..., '_blank')`) desde
`_GarantiasInmueble.cshtml`, `_GarantiasVehiculosBien.cshtml` y `GestionVehiculo.cshtml`.
El botón usaba `window.history.back()`, pero una pestaña nueva no tiene historial —
el botón no hacía nada.

**P: ¿alcanza con cerrar la pestaña (`window.close()`)?**
R: Funciona pero es implícito — depende de que la pestaña padre siga abierta. Se prefirió
una solución explícita: pasar la URL de origen (`returnUrl`) como parámetro al abrir la
vista, y que el botón navegue ahí. Si no llega `returnUrl` (acceso directo a la URL sin
pasar por los callers conocidos), cae a `window.close()` como fallback.

## Indagación — CORRECCION TIPO DE DOCUMENTOS

**P: ¿qué significa "expira" un Tipo de Documento? ¿el documento deja de ser válido y no se puede volver a cargar?**
R: No. "Expira" aplica al **archivo concreto cargado**, no al tipo en abstracto. Cuando
vence, el archivo sigue existiendo pero deja de contar como respaldo vigente de la
garantía (aparece en el tab "Vencidos") — no bloquea volver a cargar uno nuevo, de hecho
es la señal para hacerlo.

**P: ¿dónde se calculaba esa fecha de vencimiento, y era confiable?**
R: Se calculaba en JavaScript del navegador (`_FormularioSubida.cshtml`) y se enviaba ya
resuelta al backend, que la aceptaba sin validar (`GarantiaArchivoActorNegocio.SubirArchivoLocal`).
Gap de seguridad: una petición manipulada podía mandar cualquier fecha. Se corrigió para
que el backend recalcule/valide la fecha según la regla del Tipo de Documento
(automática o manual), ignorando lo que mande el cliente salvo en el caso de fecha manual
(donde sí se exige que venga informada).

**P: ¿qué significa `Esdocumentounico`, y se estaba validando?**
R: No se validaba en ningún punto del flujo de carga de Garantías (sí en otros módulos
como Terceros, Credito, Pagare). Tras indagar el alcance correcto para Garantías (ver
detalle en [EXPLICACION.md](./EXPLICACION.md)): significa que una **entidad concreta**
(un inmueble, vehículo o garante puntual) no puede tener más de un archivo activo cargado
de ese tipo de documento, sin importar si la solicitud vino directa o por un Combo de
Documentos.

**P: si ya hay uno cargado y se intenta cargar otro, ¿se reemplaza automático (como en Terceros) o se bloquea?**
R: Se bloquea. A diferencia de Terceros (que desactiva el anterior y deja subir el nuevo
sin fricción), en Garantías ya existe un flujo explícito de eliminación
(`GarantiaArchivoActorNegocio.EliminarArchivosGarantias`) que deja el documento en estado
`ELIMINADO`/`PENDIENTE` y habilita recargar. Se prefirió bloquear y exigir ese paso
explícito, por trazabilidad — un documento legal no debería desactivarse en silencio.

## Regla de negocio resuelta

Ver [EXPLICACION.md](./EXPLICACION.md) para el detalle completo (entidades, relaciones,
expiración, documento único). Ver [IMPLEMENTACION.md](./IMPLEMENTACION.md) para el mapa
de archivos tocados.
