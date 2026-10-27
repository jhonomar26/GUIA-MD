# Análisis: solicitar documentos en el documento equivalente

> [← README](./README.md) · Visión general y numeración de reglas: [ANALISIS del área](../ANALISIS.md)

## Qué hace

Desde un documento equivalente guardado se agregan combos o documentos sueltos. Cada documento nace pendiente, con el tercero del documento equivalente. Los permisos son propios del documento equivalente.

## Reglas que aplica

- **Regla 2.** Sin documento equivalente guardado no se puede pedir nada: el botón está deshabilitado.
- **Regla 3.** Sin límite por estado: se pide igual en edición, proceso, aprobado o anulado.
- **Regla 4.** El primer combo es libre; del segundo en adelante hace falta el permiso propio del documento equivalente.
- **Regla 5 (documentos sueltos).** Solo con el permiso propio; el servidor también lo valida.
- **Regla 6.** Los pedidos llevan el tercero del documento equivalente.
- **Regla 11.** Se recibe el comprobante o el documento equivalente, nunca los dos ni ninguno.
- **Regla 12.** Contable no cambia.

## Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Documento equivalente sin guardar | Se abre la pantalla | "Listar Documentos" deshabilitado |
| E2 | Documento equivalente guardado y anulado | Se pulsa "Listar Documentos" | Abre la pantalla de combos del documento |
| E3 | Documento equivalente sin documentos pedidos | Usuario sin permisos agrega un combo | Se crean los pendientes con el tercero del documento equivalente |
| E4 | El mismo, ya con pendientes | El mismo usuario agrega otro combo | Se rechaza; con el permiso propio, se acepta |
| E5a | Usuario con solo permisos de contabilidad | Agrega un documento suelto en un documento equivalente | Se rechaza |
| E5b | Usuario con solo el permiso del documento equivalente | Agrega un documento suelto en un comprobante | Se rechaza |
