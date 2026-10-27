# ADR-001: un expediente con dos dueños posibles

> [← README](./README.md) · Fecha: 2026-10-19 · Estado: aceptado. La parte del enum y el texto `origen` la reemplaza [ADR-002](./ADR-002.md); el resto sigue vigente

## Contexto

El documento equivalente necesita el expediente virtual del comprobante contable (pedir, subir, vencer, firmar y eliminar documentos). Las tablas de documentos pedidos, combos asignados y archivos tienen `iddocumentocontable` obligatorio. El documento equivalente solo tiene comprobante después de contabilizar, y los archivos deben ser suyos, no del comprobante.

## Decisión

Las tres tablas (`contabilidad_documentocontablesolicitado`, `..combo`, `..archivo`) reciben `iddocumentoequivalente` opcional, con FK restrictiva. `iddocumentocontable` pasa a opcional. Un CHECK exige que haya **exactamente uno** de los dos (`num_nonnulls(...) = 1`).

El código es uno solo, parametrizado por un enum `OrigenDocumentoArchivo { Contable = 0, Equivalente = 1 }` en `Blip.Entities`:

- Los métodos que filtran por documento reciben `p_origen` como último parámetro opcional (valor por defecto `Contable`). Los llamadores contables no cambian y su SQL queda igual.
- **El origen se lee de la fila cuando ya existe** (editar, eliminar, firmar, constancia). Solo viaja por parámetro en lecturas por documento y altas. Así nadie se salta el permiso del documento equivalente mandando `origen=contable`.
- El origen llega como texto y se valida a mano: `contable`, `equivalente` o vacío. Cualquier otro valor (incluido "1") responde 400.
- La columna se elige en `Blip.Data` con un `CampoDocumento(origen)` privado por actor; el permiso se elige en `Negocio`. No hay helper central: mezclaría SQL y permisos.
- El tercero del documento sale de un solo método, `ObtenerTerceroDelDocumento(id, origen)`, que reemplaza tres validaciones copiadas.
- Borrar un documento equivalente con expediente: la FK lo impide y el servicio responde 409 con mensaje claro.

## Alternativas descartadas

- **Tablas paralelas:** ~25 archivos duplicados para un comportamiento idéntico.
- **Dueño genérico (tipo + id):** sin FK real; reescribe tablas y migra datos.
- **Colgar del comprobante generado:** no existe antes de contabilizar y los archivos son del documento equivalente.
- **Sobrecarga o método nuevo por origen:** duplica cuerpos o SQL.
- **Enum en `SIIAN.Common`:** ni `Blip.Data` ni `Blip.Entities` lo referencian.
- **Interfaz o estrategia por origen:** una sola variación no lo justifica.

## Consecuencias

- `Iddocumentocontable` pasa de `int` a `int?` en entidades y ViewModels; hay que ajustar sus usos. Si alguien olvida el ancla, el CHECK lo frena en la base.
- Las vistas de cargados y de eliminados se recrean. La de eliminados pasa a `LEFT JOIN` y saca el tercero con `COALESCE` del comprobante o del documento equivalente.
- No cambian la firma, el popup de eliminación ni el reporte de la constancia (solo la etiqueta "Documento equivalente").
- Riesgo de regresión en contable sin pruebas automáticas: se controla comparando el JSON del comprobante 168816 antes y después de cada fase.
- Arreglo de paso: en `EliminarArchivos`, el guard `Iddocumentocontable <= 0` deja de filtrar con `int?`; se cambia a `== null`.
