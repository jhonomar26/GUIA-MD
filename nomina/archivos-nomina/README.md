# Expediente virtual de Nómina

| Campo | Valor |
|---|---|
| Módulo | nomina |
| Área | archivos-nomina |
| Menú | Se abre desde el grid de contratos (`~/NominaContrato/Contratos`). Configuración: EV008 (por crear) |
| Estado | paso 1 cerrado (2026-11-07); feature 1 con código hecho, falta probar |

Pedir, subir, firmar y eliminar documentos de un **contrato de nómina**. Es un clon del [expediente de ahorros](../../ahorrosyaportes/archivos-ahorros/README.md) cambiando cuenta por contrato y titular por empleado.

## Paso 1: reglas y análisis

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | El pedido textual |
| [REGLAS-DE-NEGOCIO.md](./REGLAS-DE-NEGOCIO.md) | Mismas R# que ahorros; marca lo propio de nómina |
| [ANALISIS.md](./ANALISIS.md) | El contrato en nómina, nombres de tablas y qué se clona |
| [ADR.md](./ADR.md) | ADR-001: dueño = contrato, archivos en tabla propia |

Ninguna regla bloquea. R3 sin restricción; R25 y R36 fuera de alcance. Los nombres en la base llevan `nomina` ([ANALISIS](./ANALISIS.md#nombres)).

## Paso 2: features, en orden

Qué crea cada una, de qué commit de ahorros se clona y riesgos: [PLAN-GENERAL.md](./PLAN-GENERAL.md).

| # | Feature | Qué se ve al terminar | Reglas | Estado |
|---|---|---|---|---|
| 1 | [catalogo](./1-catalogo/PLAN.md) | EV008: agrupaciones, tipos y combos | R4-R9, R22, R37-R39 | código hecho (`4c4b5c20b`); faltan scripts en el servidor y 18 casos en Orca |
| 2 | [solicitar-documentos](./2-solicitar-documentos/PLAN.md) | Botón "Documentos" en el grid de Contratos; agregar combos y sueltos | R1-R3, R11-R15, R34 | plan escrito (2026-11-07) |
| 3 | subir-y-consultar | Subir; Cargados, Pendientes y Vencidos; ruta de nómina | R16-R24, R26, R27, R40 | pendiente |
| 4 | eliminar-con-constancia | Eliminar con constancia; retirar y reactivar pedidos | R28-R32 | pendiente |
| 5 | firma-electronica | Firma VozData con el empleado | R33 | pendiente |
| 6 | acta-constancia-eliminacion | El acta lista los archivos de nómina | R41 | pendiente |
| 7 | bloqueo-borrar-contrato | Borrar un contrato con expediente da mensaje claro | R35 | pendiente |
| 8 | formato-personalizado | PDF generado al agregar un combo | R10 | pendiente |
