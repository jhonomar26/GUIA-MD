# Análisis: subir archivos al documento equivalente

> [← README](./README.md) · Visión general y numeración de reglas: [ANALISIS del área](../ANALISIS.md)

## Qué hace

Sobre un pendiente del documento equivalente se sube su archivo. La pantalla muestra pendientes, vencidos y cargados (locales y remotos) solo de ese documento.

## Reglas que aplica

- **Regla 2.** Sin documento equivalente guardado no se sube nada.
- **Regla 9.** Cada pantalla ve solo lo suyo: al contabilizar no se copian archivos al comprobante generado.
- **Reglas R1-R17 contables.** Extensiones, vencimiento y carga se comportan igual que en el comprobante.
- **Regla 11.** Se recibe el comprobante o el documento equivalente, nunca los dos ni ninguno.
- **Regla 12.** Contable no cambia.

## Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Documento equivalente sin guardar | Se abre la pantalla | "Adjuntar" deshabilitado |
| E6 | Pendiente de tipo con firma | Sube un archivo no PDF | Se rechaza con las extensiones válidas |
| E6b | Pendiente de tipo sin firma | Sube un archivo válido | Pasa a cargado y aparece en cargados del documento equivalente |
| E10 | Documento equivalente con 2 archivos | Se contabiliza | El comprobante generado no los muestra |
