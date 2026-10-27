# notas-siian — índice

Notas técnicas de SIIAN, organizadas **por módulo de negocio** (igual que `Negocio/<Modulo>/`
en el repo), y dentro de cada módulo, una carpeta por feature/iniciativa. Ver
[`GUIA.md`](./GUIA.md) para la convención usada.

| Módulo                          | Features documentadas                                                                                                                                                  |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [soporte](./soporte/)           | hilos-chat-soporte, cierre-ticket-solucionado, fix-ajustes-soporte-estado, notificacion-cambio-estado, dxlist-chat-soporte, soporte-ajustes-dias, asistente-ia-tickets |
| [cartera](./cartera/)           | report-designer-amortizacion                                                                                                                                           |
| [reportes](./reportes/)         | report-designer-formatos                                                                                                                                               |
| [contabilidad](./contabilidad/) | expediente-virtual-configuracion, expediente-virtual-carga                                                                                                             |
| garantias                       | garantias                                                                                                                                                              |
| [tesoreria](./tesoreria/)       | archivos-recaudo                                                                                                                                                       |
|                                 |                                                                                                                                                                        |

| Carpeta raíz (no es módulo de negocio) | Qué es |
|---|---|
| [bases-datos](./bases-datos/) | MCP Postgres solo lectura por base: script replicable, uso y ADR (herramienta, no feature de producto) |
| [mcp-postgres](./mcp-postgres/) | Versión anterior (Docker + `.mcp.json`), reemplazada por `bases-datos` |
| [conceptos](./conceptos/) | Explicaciones transversales, no atadas a un solo módulo |
