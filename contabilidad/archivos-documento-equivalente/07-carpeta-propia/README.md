# Feature: carpeta propia para los archivos del documento equivalente

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-documento-equivalente |
| Menú | Parametrización de carpetas virtuales y pantalla de archivos del documento equivalente (`~/DocumentoEquivalenteArchivo/`) |
| Estado | hecho (2026-10-22); E5 verificado solo por código; falta revisión final de código |

Hoy los archivos del documento equivalente se guardan en la misma carpeta que los del comprobante (`~/Uploads/Contabilidad/`). Esta feature les da una ruta propia.

Origen: se detectó el 2026-10-21 al cerrar [04-eliminar-archivos](../04-eliminar-archivos/): `SubirArchivoAPendiente` valida la ruta con `ValidarRutaContable` para los dos dueños. Toca lo hecho en [03-subir-archivo](../03-subir-archivo/).

| Doc | Qué es |
|---|---|
| [ANALISIS.md](./ANALISIS.md) | Qué existe, reglas propuestas y escenarios (negocio, sin código) |
| [EXPLICACION.md](./EXPLICACION.md) | La lógica en lenguaje simple, con diagrama |
| [PLAN.md](./PLAN.md) | Tareas técnicas, archivos y verificación |
