# Requerimiento: pasar a SQL las consultas LINQ de documentos contables

## Pedido original

> lo que sí es incorrecto y lo vamos a dejar como futuro es cambiar estas partes de linq a sql, es mucho más limpio y mejor que hacer los joins y todos estos procesos con linq

Lo detectamos al cerrar B5 de `paridad-documentos-credito` (2026-10-16). Es un feature aparte para no alargar ese requerimiento.

## Origen

Lectura de `PruebaPostgreSQL/Controllers/WebApi/DocumentoContableArchivoWebApiController.cs` en la rama `feature/contabilidad-detalle-constancia-eliminacion`. No se midió el rendimiento, solo se leyó el código.

Varios métodos llaman a `ObtenerRegistros()` y traen la tabla completa, después filtran y cruzan en memoria con LINQ. El peor caso es `generales_archivo`, que comparten crédito, terceros y CRM.

## Métodos afectados

| Método | Qué hace hoy | ¿Se usa? |
| --- | --- | --- |
| `ObtenerPorDocumento` (línea 94) | Trae **todo** `generales_archivo` y lo cruza con `Any()` dentro de `Where()` (O(n·m)) | No se encontró uso en vistas ni JS |
| `ObtenerSolicitadosPendientes` (línea 158) | Trae todos los solicitados, todos los cargados y todos los tipos; cruza en memoria | No se encontró uso en vistas ni JS |
| `ObtenerSolicitadosPendientesEstado` (línea 215) | Trae todos los solicitados y todos los cargados activos de todos los documentos | No se encontró uso en vistas ni JS |
| `ObtenerSolicitadosPendientesPorId` (línea 255) | Filtra los solicitados por documento (bien), pero trae todos los tipos y hace el join en un diccionario | Sí: `_GestionDocumentos.cshtml:103`, `_SubirArchivo.cshtml:46` |

La búsqueda de uso fue con `rg` sobre `.cshtml`, `.js` y `.cs` de `PruebaPostgreSQL`, sin incluir `bin/`.

## Alcance

1. **Métodos sin uso:** confirmar que nada los llama (apps externas, móvil) y **borrarlos**, no migrarlos.
2. **`ObtenerSolicitadosPendientesPorId`:** pasar el join con `DocumentoTipo` y el filtro `Esactivo` del tipo a una consulta SQL en `Blip.Data/Contabilidad/DocumentoContableSolicitadoActorNegocio.cs`. El controlador solo arma `Extensiones`.

Patrón a seguir: `ObtenerVencidosPorIddocumentocontable` y `ObtenerConEstadoVisible` del mismo ActorNegocio (SQL con campos estáticos y `DynamicParameters`).

## Preguntas abiertas

- ¿Algún cliente externo (móvil, API) llama a los tres métodos sin uso?
- ¿Revisamos también otros controladores de contabilidad con el mismo patrón, o solo este?

## Criterios de aceptación

- **Dado** un documento contable, **cuando** se abre Pendientes o el selector de subida, **entonces** se ven los mismos documentos que antes del cambio.
- **Dado** el controlador, **cuando** se revisa, **entonces** ningún método trae una tabla completa con `ObtenerRegistros()` para filtrarla en memoria.
- **Dado** que se borran métodos, **cuando** se compila la solución, **entonces** no hay referencias rotas.

## No-gos

- Cambiar reglas de negocio (qué cuenta como pendiente, R9 y R13).
- Tocar las brechas de `paridad-documentos-credito`.
