# ADR — Consultas de documentos contables en SQL

## ADR-001: Pendientes con consulta directa, sin vista de la base

**Estado:** Aceptado (2026-10-16).

### Contexto

La lista de pendientes de un comprobante se arma hoy en memoria, cruzando los pedidos con todos los tipos de documento. Se evaluaron dos caminos para pasarla a SQL:

- **Vista de la base hecha con el generador de plantillas.** Da paginado, filtros y conteo en el servidor para grillas DevExtreme. Requiere un script en la base de cada cliente, más la entidad, el actor y el modelo de vista generados.
- **Consulta directa** en el actor de negocio de documentos solicitados, igual que la de vencidos.

### Decisión

Consulta directa. Por qué:

1. Los pendientes son siempre de **un** comprobante: pocas filas. Paginar en el servidor no aporta.
2. El precedente lo confirma: la vista de cargados existe, pero su grilla usa la consulta filtrada por comprobante y pagina en la pantalla (ver H4 de [`ANALISIS.md`](./ANALISIS.md)).
3. El selector de subida necesita las extensiones permitidas, que se calculan en C#. El servicio genérico de la vista no las trae, así que habría que adaptarlo igual.
4. No hay script de base que desplegar en cada cliente.

### Consecuencias

- La pestaña y el selector siguen paginando y filtrando en la pantalla, como hoy.
- **Cuándo revisar esta decisión:** si se pide una consulta de pendientes de **todos** los comprobantes (bandeja general o reporte), con miles de filas y filtros. En ese caso la vista sí conviene, y el SELECT de la consulta directa pasa casi tal cual a ser el cuerpo de la vista. Esa decisión iría en un ADR nuevo que reemplace a este.
