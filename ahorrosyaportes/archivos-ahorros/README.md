# Expediente virtual de Ahorros y Aportes

| Campo | Valor |
|---|---|
| Módulo | ahorrosyaportes |
| Área | archivos-ahorros |
| Menú | Se abre desde la pantalla de cuentas CDT por tercero (`~/CuentaAhorroCDT/CuentaPorTercero`). Configuración: EV007 (por crear) |
| Estado | vigente (cerrado 2026-11-04 con casos pendientes, ver [IMPLEMENTACION](./IMPLEMENTACION.md)) |

Pedir, subir, firmar y eliminar documentos de una **cuenta de ahorro** (CDT, ahorro, aporte). **Crédito** (EV002) es la referencia de comportamiento y **contabilidad** ([remodelación](../../contabilidad/archivos-contabilidad/remodelacion-bd/EXPLICACION.md)) la referencia del modelo de datos y de cómo se reparte el código.

## Paso 1: reglas y análisis (hecho)

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | El pedido textual |
| [REGLAS-DE-NEGOCIO.md](./REGLAS-DE-NEGOCIO.md) | R1-R40 con su porqué y estado. Se lee antes que todo |
| [ANALISIS.md](./ANALISIS.md) | Qué existe, cómo funciona (diagramas), lo propio de ahorros en detalle y el mapa del modelo con la feature que crea cada tabla |
| [ADR.md](./ADR.md) | ADR-001: archivos en tabla propia, como contabilidad |

Reglas abiertas (ninguna bloquea la feature 1): R25 (vencer después del fin de la cuenta, feature 8) y R36 (borrar una cuenta con expediente, feature 7).

## Paso 2: features, en orden

Cada una lleva BD + backend + pantalla + prueba y crea solo sus tablas. Se cierra (matriz de casos recorrida en Orca) antes de abrir la siguiente. La carpeta `<n>-<feature>/` se crea al arrancarla.

| # | Feature | Qué se ve al terminar | Reglas | Estado |
|---|---|---|---|---|
| 1 | [catalogo](./1-catalogo/) | EV007: agrupaciones, tipos y combos, con sus reglas de vencimiento | R4-R9, R22, R37-R39 | ✅ cerrada (17/17 casos, 2026-10-29) |
| 2 | [solicitar-documentos](./2-solicitar-documentos/) | Botón "Documentos" en el grid CDT; agregar combos y documentos sueltos a una cuenta | R1-R3, R11-R15, R34 | código hecho; falta T3 (permisos, los corre el usuario) y T8 (casos en Orca) |
| 3 | [subir-y-consultar](./3-subir-y-consultar/) | Subir a un pendiente; pestañas Cargados, Pendientes y Vencidos; ruta de Ahorros | R16-R24, R26, R27, R40 | hecha, 19 de 20 casos probados en Orca (2026-11-03); falta el caso 16 (FTP) |
| 4 | [eliminar-con-constancia](./4-eliminar-con-constancia/) | Eliminar con constancia y crear un pedido nuevo; retirar un pedido | R28-R32 | código hecho, 11 de 16 casos probados (2026-11-03); faltan 1, 2, 11, 12 y 14, la pestaña Eliminados del 7 y las capturas |
| 5 | [firma-electronica](./5-firma-electronica/) | Firma VozData con el titular como firmante | R33 | cerrada (2026-11-04): probados casos 1, 2 y 9 de 10; faltan 3-8 y 10 (envían solicitudes reales) |
| 6 | formato-personalizado | PDF generado y subido solo al agregar un combo | R10 | pendiente |
| 7 | bloqueo-y-otras-pantallas | Borrar una cuenta con documentos da un mensaje claro; botón en las demás pantallas de cuentas | R35, R36 | pendiente |
| 8 | vencimiento-fin-cuenta | Vencer N días después del fin de la cuenta. **Solo si se confirma R25** | R25 | en duda |
| 9 | [acta-constancia-eliminacion](./9-acta-constancia-eliminacion/) | "Generar formato" de una constancia de ahorros lista sus archivos | R41 | cerrada por decisión del usuario (2026-11-04): código revisado y build en 0 errores; casos en Orca sin recorrer |
| 10 | [eliminar-retira-pedido](../../contabilidad/archivos-contabilidad/eliminar-retira-pedido/) | Eliminar un archivo retira su pedido; vive en contabilidad porque aplica a los dos módulos | cambia R30 y R31 | en curso: R3-R5 por confirmar. **En ahorros no está hecho**: hoy eliminar no retira el pedido (`ArchivoAhorroEliminacionActorNegocio.cs:111-133`) |

6 y 8 son adaptaciones propias de ahorros (contabilidad no las tiene); por eso van al final.

## Archivo

| Doc | Qué es |
|---|---|
| [archivo/PLAN-v1.md](./archivo/PLAN-v1.md) | Plan original (2026-10-23), anterior a la remodelación contable |
| [archivo/1-requisitos-y-base-de-datos/](./archivo/1-requisitos-y-base-de-datos/) | La primera feature con el formato viejo (solo tablas). Su contenido pasó a `ANALISIS.md` y `REGLAS-DE-NEGOCIO.md` el 2026-10-29 |
