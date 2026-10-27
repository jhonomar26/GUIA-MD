# Archivos en documento equivalente: cómo se organiza

| Campo | Valor |
|---|---|
| Módulo | contabilidad |
| Área | archivos-documento-equivalente |
| Menú | Se abre desde **Documento Equivalente** (`~/DocumentoEquivalente/EdicionV2`): "Listar Documentos" (combos) y "Adjuntar" (archivos) |
| Estado | en curso |

Lleva al documento equivalente lo mismo que ya tiene el comprobante contable (CO101): pedir documentos, subirlos, vencimiento, firma y eliminación con constancia. Misma parametrización, permisos propios.

**Se trabaja por features chicas y verticales:** cada una lleva su base, su servicio, su pantalla y su prueba, con commit propio. Una no arranca hasta que la anterior esté probada (decisión del 2026-10-20: el plan de 4 fases por capas era demasiado grande para revisar).

## Features, en orden

| # | Feature | Qué es | Estado |
|---|---|---|---|
| 1 | [01-base-dos-duenos](./01-base-dos-duenos/) | La base y el código aceptan los dos dueños; nadie ve cambios | vigente |
| 2 | [02-solicitar-documentos](./02-solicitar-documentos/) | "Listar Documentos": agregar combos y documentos sueltos | hecha y cerrada; E3, E4-rechazo, E5a y E5b sin probar por decisión (ver [08](./08-revision-final/)) |
| 3 | [03-subir-archivo](./03-subir-archivo/) | "Adjuntar": pendientes, vencidos, cargados y subida | hecha; evidencia parcial (E1, E6b) |
| 4 | [04-eliminar-archivos](./04-eliminar-archivos/) | Eliminar con recrear, constancia y acta | hecha, falta recorrido CO101 |
| 5 | [05-firma](./05-firma/) | Firma con el tercero del documento equivalente | hecha y cerrada; firma probada a mano por el usuario |
| 6 | [06-bloqueo-borrado](./06-bloqueo-borrado/) | Mensaje claro al borrar un documento con expediente | descartada: nunca se elimina; queda la protección de la BD |
| 7 | [07-carpeta-propia](./07-carpeta-propia/) | Ruta de carpeta propia para los archivos del documento equivalente | hecha; falta revisión final de código |
| 8 | [08-revision-final](./08-revision-final/) | Cierra lo abierto de 01-07: pruebas, regresión de contable y limpieza | pendiente |

## Documentos de todo el área

| Doc | Qué es |
|---|---|
| [REQUERIMIENTO.md](./REQUERIMIENTO.md) | Pedido y decisiones del usuario |
| [ANALISIS.md](./ANALISIS.md) | Qué existe, qué falta, las 12 reglas y los escenarios E1-E13 (cada feature toma los suyos) |
| [ADR.md](./ADR.md) | ADR-001: un solo expediente con dos dueños posibles, en vez de copiar tablas |
| [ADR-002.md](./ADR-002.md) | ADR-002: el dueño lo dicen los ids, sin parámetro de origen |
| [ADR-003.md](./ADR-003.md) | ADR-003: un punto de entrada por dueño en la capa web, reglas comunes en Negocio |
| `antes/` | Foto de referencia del comprobante 168816 y del acta 282: cada feature compara contra ella |
| [archivo/](./archivo/) | Plan y explicación originales en 4 fases, ya reemplazados |

## Estado

- 2026-10-19: análisis, diseño y plan cerrados con gentle SDD. Rama `feature/contabilidad-archivos-documento-equivalente`.
- 2026-10-20: script 10 aplicado en demo y probado (P1-P5). Código de la base commiteado (`12f4dce85`, `a558c80a4`); `base-dos-duenos` cerrada y vigente. ADR-002 reemplaza el parámetro de origen. El plan se parte en las 6 features de arriba.
- Los artefactos originales están en engram, proyecto `siian`: `sdd/archivos-documento-equivalente/{explore,proposal,spec,design,tasks,decision}`.
