# Feature: eliminar archivos del documento equivalente

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-documento-equivalente |
| Menú | Pantalla de archivos del documento equivalente (`~/DocumentoContableArchivo/?iddocumentoequivalente=<id>`) |
| Estado | hecha (2026-10-21, `843ad637f`); queda el recorrido manual en CO101 |

Se eliminan archivos cargados con una observación, con la opción de recrear el pendiente. Queda una constancia y el acta dice "Documento equivalente". Permiso propio.

Depende de: [03-subir-archivo](../03-subir-archivo/) (sin archivos cargados no hay qué eliminar).

| Doc | Qué es |
|---|---|
| [ANALISIS.md](./ANALISIS.md) | Reglas y escenarios de esta parte (negocio, sin código) |
| [PLAN.md](./PLAN.md) | Tareas de punta a punta: base, servicio, pantalla y prueba |
