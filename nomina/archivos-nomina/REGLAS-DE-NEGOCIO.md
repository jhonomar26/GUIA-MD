# Reglas de negocio: expediente virtual de nómina

> [← README](./README.md) · Base: [reglas de ahorros](../../ahorrosyaportes/archivos-ahorros/REGLAS-DE-NEGOCIO.md) en su estado final (incluye R19 de correcciones-expediente contable, 2026-11-05). · [ANALISIS](./ANALISIS.md)
> Misma numeración que ahorros para poder comparar. Solo cambia lo que dice **Nómina**.

**Estados:** ✅ acordada · ⏳ pendiente (no entra al modelo hasta que se resuelva).

## La idea en una frase

Cada contrato de nómina tiene un **expediente**: la lista de documentos que el empleado debe entregar, con los archivos que entregó. Se piden, se suben, se controla que no estén vencidos, se firman y, si hace falta, se eliminan dejando constancia.

## 1. Quién es el dueño y quién firma

| # | Regla | Para qué | |
|---|---|---|---|
| R1 | El expediente es **del contrato** (`nomina_contratos`). Todas sus versiones ven el mismo expediente | **Nómina.** Modificar el contrato no debe vaciar el expediente ([ADR-001](./ADR.md)) | ✅ (2026-11-06) |
| R2 | Los documentos se piden **al empleado** del contrato, y él es el único que firma | El contrato no tiene otras personas obligadas | ✅ |
| R3 | No hay restricción según el estado del contrato (edición, activo, retirado): todos reciben pedidos y archivos | **Nómina.** Restringir por estado queda para decisiones futuras | ✅ (2026-11-07) |

## 2. Catálogo

| # | Regla | |
|---|---|---|
| R4 | Tipos de documento agrupados por agrupación | ✅ |
| R5 | Un combo reúne varios tipos que se piden juntos | ✅ |
| R6 | En el combo, cada documento dice si es obligatorio | ✅ |
| R7 | Un tipo puede marcarse **documento único**, pero **no restringe nada**: ni al pedir (suelto o combo), ni al reactivar, ni al recrear. No se copia `DesactivarAnterioresSiEsUnico` de ahorros: allá no tiene efecto por R17. La marca (columna y checkbox) **se deja sin efecto**, igual que ahorros y crédito | ✅ (2026-11-07, decisión del usuario) |
| R8 | Un tipo puede exigir firma; un combo "para firmar" solo admite tipos con firma | ✅ |
| R9 | Un tipo foto solo acepta imágenes | ✅ |
| R10 | Formato personalizado: PDF que el sistema genera solo con los datos del contrato | ✅ (feature al final) |
| R37 | Marcar un combo "para firmar" no revisa los tipos que ya tiene | ✅ |
| R38 | Un tipo no puede ser firma y foto a la vez | ✅ |
| R39 | Un tipo puede vencer a los 0 días del cargue | ✅ |

## 3. Pedir documentos

| # | Regla | |
|---|---|---|
| R11 | Se pide un combo completo a un contrato, o un documento suelto | ✅ |
| R12 | Cada documento pedido queda como pedido a nombre del empleado, con descripción y obligatoriedad | ✅ |
| R13 | Se guarda qué combo se agregó al contrato y cuándo | ✅ |
| R14 | Insertar un pedido suelto o un combo **no revisa** si el tipo es único ni si ya está pedido: sin rechazo y sin omitir tipos del combo | ✅ (2026-11-07, decisión del usuario) |
| R15 | Agregar un segundo combo o un documento suelto requiere permiso especial (permisos propios de nómina) | ✅ |

## 4. Subir archivos

| # | Regla | |
|---|---|---|
| R16 | Solo se sube a un pedido pendiente de ese contrato | ✅ |
| R17 | Un pedido recibe un solo archivo en toda su vida: subir a un pedido que ya tuvo archivo (aunque esté eliminado) se rechaza | ✅ |
| R18 | Firma solo PDF, foto solo imágenes, el resto 13 extensiones. Se valida en el servidor | ✅ |
| R19 | Los archivos de nómina van a su propia carpeta ("carpeta de nómina" en EV001) y su propia tabla | ✅ |
| R20 | Sin ruta de nómina configurada se avisa y no se guarda nada | ✅ |
| R21 | Subir no toca el pedido; solo nace el vínculo y el archivo | ✅ |
| R40 | Al subir hay que escribir una observación | ✅ |

## 5. Vencimiento

| # | Regla | |
|---|---|---|
| R22 | Vence por una sola regla: fecha a mano al subir, o N días después de subirlo | ✅ |
| R23 | La fecha la calcula el servidor | ✅ |
| R24 | Lo vencido sale en Vencidos, sin pedidos retirados | ✅ |
| R25 | Vencer N días después del **fin del contrato** | **Fuera de alcance** (2026-11-07): no se tiene en cuenta en nómina |

## 6. Estados

| # | Regla | |
|---|---|---|
| R26 | El estado se calcula: pendiente, cargado vigente, cargado eliminado, retirado | ✅ |
| R27 | Nunca se borra una fila | ✅ |

## 7. Eliminar y retirar

| #   | Regla                                                                                            |                                                                                                                          |
| --- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| R28 | Eliminar marca el archivo y deja constancia; varios archivos comparten constancia                | ✅                                                                                                                        |
| R29 | Eliminar no devuelve el pedido a pendiente                                                       | ✅                                                                                                                        |
| R30 | Al eliminar se puede crear un pedido nuevo del mismo tipo; se crea **siempre**, sin mirar el tipo único | ✅ — si se cierra [eliminar-retira-pedido](../../contabilidad/archivos-contabilidad/eliminar-retira-pedido/), se revisa |
| R31 | Retirar un pedido solo lo apaga; reactivar se permite **siempre** | ✅ — ídem R30 |
| R32 | Eliminar archivos requiere permiso especial (propio de nómina)                                   | ✅                                                                                                                        |
| R41 | El acta de una constancia lista también los archivos de **nómina**; su carpeta se llama "Nómina" | ✅                                                                                                                        |

## 8. Firma electrónica

| # | Regla | |
|---|---|---|
| R33 | Un documento de tipo firma se envía a firmar al **empleado**; el PDF firmado reemplaza al original | ✅ |

## 9. Borrar un contrato

| #   | Regla                                                                                                                       |                                                                        |
| --- | --------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| R34 | Un contrato con cualquier pedido no se puede borrar. Borrar una versión que no es la última sí se puede (el contrato sigue) | ✅ **Nómina:** hoy borrar la última versión borra el contrato de verdad |
| R35 | El usuario ve un mensaje claro, no un error de base de datos                                                                | ✅                                                                      |
| R36 | Qué hacer cuando de verdad hay que borrar un contrato con expediente | **Fuera de alcance por ahora** (2026-11-07) |

## 10. Lo que NO tiene el expediente de nómina

Codeudores, geolocalización, tabla de tercero por tipo, permiso por estado del contrato (R3), vencimiento por fin de contrato (R25) y documentos de soportes contables. Mismo porqué que en ahorros.

## Pendientes

Ninguna regla bloquea (2026-11-07). R3 sin restricción, R25 y R36 fuera de alcance.

**Nombres en la base:** llevan `nomina` para no chocar con otras partes del código (decisión del usuario, 2026-11-07). Ver [ANALISIS](./ANALISIS.md#nombres).
