# Módulo: Contabilidad

Corresponde a `Negocio/Contabilidad/` en el repo SIIAN.

| Feature | Qué es |
|---|---|
| [expediente-virtual-configuracion](./expediente-virtual-configuracion/) | Configuración de documentos contables (agrupaciones, tipos, combos) igual a la de crédito (F0-F3 implementadas; faltan filtro "formato contable" y script de plantillas) |
| [expediente-virtual-carga](./expediente-virtual-carga/) | Solicitud y carga de documentos en comprobantes contables igual a crédito (F0-F4 en código; F5 y pruebas manuales pendientes) |
| [firma-documentos-contables](./firma-documentos-contables/) | Firma electrónica (VozData) de documentos cargados en comprobantes, igual a crédito (implementado y probado) |
| [paridad-documentos-credito](./paridad-documentos-credito/) | Brechas de documentos contables frente a crédito: constancia, permisos, editar archivos, vencidos (B1-B6 implementadas; pruebas manuales pendientes) |
| [consultas-documentos-sql](./consultas-documentos-sql/) | Pasar a SQL los filtros LINQ sobre tablas completas en `DocumentoContableArchivoWebApiController` y borrar los métodos sin uso (plan escrito) |
| [ciclo-documentos](./ciclo-documentos/) | Estados y reglas vigentes de los documentos contables alineados con crédito; **referencia vigente**; incluye el flujo de eliminación (análisis; C1-C2 pendientes) |
