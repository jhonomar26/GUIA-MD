# Análisis: firmas en la tabla de amortización

> Estado: **futuro desarrollo**, sin código. Nace de revisar dónde se guarda y de dónde sale la firma del deudor en los Formatos de Amortización.

## Problema

Hoy toda tabla de amortización en HTML termina con un bloque de firmas, **siempre**. El formato no tiene forma de decir "este no lleva firmas". Si quien diseña el formato ya puso su propio bloque de firma o no quiere ninguno, igual sale el bloque automático y queda duplicado o sobrando.

## 0. Qué ya existe

| Hoy en SIIAN | Conclusión |
|---|---|
| Cada formato guarda sus textos (cabecera, cuerpo, tabla, pie) como HTML tal cual lo escribió el usuario. | Se reutiliza. |
| Cada formato ya tiene interruptores de "incluir cabecera" e "incluir pie de página". | **Se extiende**: el interruptor de firmas es el mismo concepto. |
| Al generar el reporte se agrega al final un bloque de firmas con línea, nombre y cédula del deudor y de los codeudores activos. No se lee de ningún almacén: se arma al momento. | Se reutiliza tal cual cuando el interruptor esté encendido. |
| Si el reporte no trae bloque de firmas, se agrega un "Acepto: ____ Cédula" genérico del deudor. | Se reutiliza, pero también queda bajo el interruptor. |
| El módulo de Firmas (firma electrónica de pagarés, créditos, contables) trabaja sobre archivos, no sobre formatos de amortización. | No sirve para esto; no se toca. |

La firma que sale **no es una firma digitalizada**: es un espacio en blanco para firmar a mano, con nombre y cédula impresos.

## Qué falta (nuevo)

Un interruptor **"Incluir firmas"** por formato, con el mismo comportamiento que "incluir cabecera" e "incluir pie de página". Se justifica como nuevo porque hoy no hay manera de apagar el bloque sin editar código.

## Reglas de negocio propuestas

| # | Regla |
|---|---|
| R1 | El interruptor es **por formato**, no global: cada formato decide si lleva firmas. |
| R2 | Encendido: comportamiento actual, sin cambios (bloque de deudor y codeudores activos; "Acepto" genérico si no hay bloque). |
| R3 | Apagado: el reporte termina sin ningún bloque de firmas, ni el completo ni el "Acepto" genérico. |
| R4 | Los formatos que ya existen quedan **encendidos**, para que nada cambie de un día para otro. |
| R5 | Un formato nuevo nace encendido. |
| R6 | La vista previa del formato respeta el interruptor tal como está en pantalla, aunque no se haya guardado. |

## Hallazgos

- **H1.** El bloque de firmas se agrega sin condición: `Negocio/ReportesHelper/ReporteAmortizacionHelper.cs:205-214`.
- **H2.** Cabecera y pie ya tienen su interruptor, firmas no: el de cabecera se lee en `ReporteAmortizacionHelper.cs:166`.
- **H3.** La vista previa no manda al servidor los campos que no participan del reporte; hay que incluir el interruptor nuevo ahí también (`Views/FormatosAmortizacion/Edicion.cshtml:343-356`), o la vista previa mostrará siempre firmas.
- **H4.** El deudor sale del préstamo y los codeudores de los activos del crédito: `Negocio/Cartera/PrestamoMaestroReportesNegocio.cs:486-487`. Un préstamo sin crédito asociado queda sin codeudores; hoy no está claro si eso es correcto.

## Preguntas abiertas

1. **R4** está asumida (formatos existentes encendidos). Falta confirmarla con quien administra los formatos.
2. ¿Apagado debe quitar **también** el "Acepto" genérico, o solo el bloque con codeudores? (R3 propone quitar ambos.)
3. ¿Otros formatos con el mismo patrón (pagaré, cartas, otrosí) merecen el mismo interruptor? Fuera de alcance acá; se anota para no olvidarlo.

## Verificación

| Caso | Evidencia esperada |
|---|---|
| Formato existente sin tocar | El reporte sale igual que antes, con firmas (comparar antes/después). |
| Interruptor apagado y guardado | El reporte termina sin ningún bloque de firmas. |
| Interruptor apagado sin guardar, vista previa | La vista previa sale sin firmas. |
| Interruptor encendido con codeudores activos | Salen deudor y codeudores, de a dos por fila. |
| Formato nuevo | Nace encendido. |

## Siguiente paso

Cerrar las preguntas 1 y 2 y recién ahí `superpowers:writing-plans` → `PLAN.md`. Es un cambio chico (una columna y un condicional), así que el plan debería ser corto.
