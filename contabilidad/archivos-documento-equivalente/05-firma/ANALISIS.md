# Análisis: firmar documentos del documento equivalente

> [← README](./README.md) · Visión general y numeración de reglas: [ANALISIS del área](../ANALISIS.md)

## Qué hace

Un PDF cargado de un tipo con firma electrónica se envía a firmar al tercero del documento equivalente. La firma en sí no cambia.

## Reglas que aplica

- **Regla 6.** Firma el tercero del documento equivalente.
- **Dueño desde la fila.** El dueño se lee del archivo, no de lo que mande la petición.
- **Regla 12.** La firma contable no cambia.

## Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E7 | PDF cargado de tipo con firma en un documento equivalente | Se firma | Firma el tercero del documento equivalente |
| E7b | PDF cargado de un comprobante | Se firma | Igual que hoy |
