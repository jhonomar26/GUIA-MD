# ADR — Firma electrónica de documentos contables

## ADR-001: Copiar la firma de crédito como un dominio más, sin pieza genérica

**Estado:** Aceptado.

### Contexto

La firma electrónica ya existe para crédito, tercero, CRM (gestión y detalle) y pagaré. Todos comparten el proveedor (VozData), el registro de solicitudes y firmantes, los estados y la pantalla de firma. Cada dominio tiene además su propia copia de la lógica, su controlador y su vínculo "archivo ↔ solicitud" ([`ANALISIS.md`](./ANALISIS.md) H1).

Había dos caminos para sumar contabilidad:
1. Copiar crédito como se hizo con tercero y CRM.
2. Extraer una pieza genérica de las cinco copias y enchufar contabilidad ahí.

### Decisión

Se copia crédito como un dominio más: un vínculo nuevo para archivos contables, una copia de la lógica de firmar adaptada (firma solo el tercero del comprobante) y un caso más en la pantalla y el servicio compartidos.

### Consecuencias

- Crédito, tercero, CRM y pagaré no se tocan, salvo el caso nuevo en las piezas compartidas. Hay que verificar que sigan firmando igual (V7).
- Se suman unas 400 líneas casi duplicadas. La deuda ya existía con cuatro copias; ahora son cinco.
- Si más adelante se quiere la pieza genérica, es un trabajo aparte con sus propias pruebas, no parte de esta feature.
- Se hereda que el estado solo se actualiza al abrir la pantalla de firma (H2).
