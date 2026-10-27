# Feature: solicitar documentos en el documento equivalente

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-documento-equivalente |
| Menú | Se abre desde **Documento Equivalente** (`~/DocumentoEquivalente/EdicionV2`), botón **"Listar Documentos"** |
| Estado | hecha y cerrada (2026-10-22); E3, E4-rechazo, E5a y E5b sin probar en pantalla por decisión del usuario; pruebas en [08-revision-final](../08-revision-final/) |

Desde un documento equivalente guardado se agregan combos o documentos sueltos. Cada documento nace pendiente, con el tercero del documento equivalente. Los permisos son propios del documento equivalente.

Depende de: [01-base-dos-duenos](../01-base-dos-duenos/).

| Doc | Qué es |
|---|---|
| [ANALISIS.md](./ANALISIS.md) | Reglas y escenarios de esta parte (negocio, sin código) |
| [PLAN.md](./PLAN.md) | Tareas de punta a punta: base, servicio, pantalla y prueba |
