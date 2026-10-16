# Módulo: Contabilidad

Corresponde a `Negocio/Contabilidad/` en el repo SIIAN.

| Feature | Qué es |
|---|---|
| [expediente-virtual-configuracion](./expediente-virtual-configuracion/) | Configuración de documentos contables (agrupaciones, tipos, combos) igual a la de crédito (planificado) |
| [expediente-virtual-carga](./expediente-virtual-carga/) | Solicitud y carga de documentos en comprobantes contables igual a crédito (F1 en curso) |
| [firma-documentos-contables](./firma-documentos-contables/) | Firma electrónica (VozData) de documentos cargados en comprobantes, igual a crédito (implementado y probado) |
| [paridad-documentos-credito](./paridad-documentos-credito/) | Brechas de documentos contables frente a crédito: constancia, permisos, editar archivos, vencidos (requerimiento) |
| [consultas-documentos-sql](./consultas-documentos-sql/) | Pasar a SQL los filtros LINQ sobre tablas completas en `DocumentoContableArchivoWebApiController` y borrar los métodos sin uso (pendiente) |
| [ciclo-documentos](./ciclo-documentos/) | Estados y reglas vigentes de los documentos contables alineados con crédito; incluye el flujo de eliminación (análisis) |
