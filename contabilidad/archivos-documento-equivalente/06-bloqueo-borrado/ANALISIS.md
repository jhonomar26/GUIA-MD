# Análisis: bloquear el borrado de un documento equivalente con expediente

> [← README](./README.md) · Visión general y numeración de reglas: [ANALISIS del área](../ANALISIS.md)

## Qué hace

Si un documento equivalente tiene documentos pedidos o archivos, no se puede borrar: la base lo impide y el usuario ve un mensaje claro en vez de un error técnico.

## Reglas que aplica

- **Regla 10.** Un documento equivalente con documentos pedidos o archivos no se puede borrar; el usuario ve un mensaje claro.

## Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E11 | Documento equivalente con documentos pedidos | Se intenta borrar | Mensaje claro; nada se borra |
| E11b | Documento equivalente sin expediente | Se borra | Se borra como hoy |
