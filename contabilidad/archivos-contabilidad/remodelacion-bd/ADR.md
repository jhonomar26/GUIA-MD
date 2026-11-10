# ADR-001: recrear un documento al eliminar, igual que crédito

**Estado:** aceptado (2026-10-27). **Supersede a:** DP3 de [`../ciclo-documentos/ADR.md`](../ciclo-documentos/ADR.md).

## Contexto

Al eliminar un archivo con "crear un documento nuevo", contabilidad copiaba la descripción y el obligatorio del pedido viejo (DP3). Crédito los deja vacíos: descripción vacía y obligatorio siempre. La remodelación tomó como criterio que contabilidad se comporte igual que crédito, salvo lo que es propio de crédito ([`explicacion/reglas-credito.md`](./explicacion/reglas-credito.md), punto 4).

## Decisión

El pedido nuevo copia el dueño, el tipo y el tercero. Nace con la descripción vacía, obligatorio y activo, igual que crédito.

## Consecuencias

- DP3 deja de ser una diferencia a propósito con crédito. Hay que actualizar la sección 11 del [README del área](../README.md) al cerrar la etapa 3.
- Si el usuario quiere conservar la descripción, la escribe de nuevo en la grilla de Solicitados.
