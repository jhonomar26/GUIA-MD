# Feature: bloquear el borrado de un documento equivalente con expediente

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-documento-equivalente |
| Menú | Documento Equivalente (`~/DocumentoEquivalente`), acción de borrar |
| Estado | descartada (2026-10-22): un documento equivalente nunca se elimina y nadie llama a `DocumentoEquivalenteWebApi.Delete`. Queda solo la protección de la BD (3 FK `RESTRICT`) |

Si un documento equivalente tiene documentos pedidos o archivos, no se puede borrar: la base lo impide y el usuario ve un mensaje claro en vez de un error técnico.

Depende de: [02-solicitar-documentos](../02-solicitar-documentos/) (para tener un documento con expediente).

| Doc | Qué es |
|---|---|
| [ANALISIS.md](./ANALISIS.md) | Reglas y escenarios de esta parte (negocio, sin código) |
| [PLAN.md](./PLAN.md) | Tareas de punta a punta: base, servicio, pantalla y prueba |
