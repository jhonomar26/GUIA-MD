# Reglas de negocio: expediente virtual de ahorros y aportes

> [← README](./README.md) · Fuentes: [PLAN-v1](./archivo/PLAN-v1.md) (qué se pensó copiar de crédito), [ANALISIS](./ANALISIS.md) (qué se alineó con contabilidad) y [REQUERIMIENTO](./REQUERIMIENTO.md).
> Es el "qué se espera" en palabras de negocio, **antes** del modelo y del código. Cada regla dice su porqué y si está acordada o falta confirmar.

**Estados:** ✅ acordada · ⏳ pendiente (no entra al modelo hasta que se resuelva).

## La idea en una frase

Cada cuenta de ahorro (CDT, ahorro a la vista, aporte) tiene un **expediente**: la lista de documentos que su titular debe entregar, con los archivos que entregó. Se piden, se suben, se controla que no estén vencidos, se firman y, si hace falta, se eliminan dejando constancia.

## 1. Quién es el dueño y quién firma

| # | Regla | Para qué | |
|---|---|---|---|
| R1 | El expediente es **de la cuenta**. Todas las cuentas (CDT, ahorro, aporte) funcionan igual | Un solo mecanismo en vez de uno por producto | ✅ |
| R2 | Los documentos se piden **al titular** de la cuenta, y él es el único que firma | La cuenta no tiene codeudores ni otras personas obligadas | ✅ |
| R3 | No hay permiso distinto según la etapa de la cuenta | A diferencia del crédito, la cuenta no tiene etapas | ✅ |

## 2. Qué documentos existen (el catálogo)

| #   | Regla                                                                                                  | Para qué                                                                                                     |                                                    |
| --- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------- |
| R4  | Hay **tipos de documento** (Cédula, RUT...), agrupados por **agrupación**                              | Ordenar el catálogo y poder buscarlo                                                                         | ✅                                                  |
| R5  | Un **combo** reúne varios tipos que se piden juntos                                                    | Pedir "el paquete de apertura" de una vez                                                                    | ✅                                                  |
| R6  | En el combo, cada documento dice si es **obligatorio**                                                 | No todo lo del paquete es indispensable                                                                      | ✅                                                  |
| R7  | Un tipo puede marcarse **documento único** | Hoy es solo una marca del catálogo | ✅ **Reemplazada (R19 contable, 2026-11-05, commit `9e1b92c44`)**: el tipo único **no se valida en ningún punto**: ni al pedir suelto, ni por combo, ni al reactivar, ni al recrear. Al subir existe `DesactivarAnterioresSiEsUnico`, pero no tiene efecto porque un pedido nunca tiene un archivo anterior (R17) |
| R8  | Un tipo puede exigir **firma electrónica**. Un combo marcado "para firmar" solo admite tipos con firma | Que nadie pida firmar un documento que no se puede firmar                                                    | ✅ (regla de crédito y contabilidad)                |
| R9  | Un tipo puede ser **foto**: solo acepta imágenes                                                       | Evitar que suban un PDF donde se espera una foto                                                             | ✅                                                  |
| R10 | Un tipo puede tener un **formato personalizado**: un PDF que el sistema genera solo y deja subido      | Documentos que el sistema ya sabe armar con los datos de la cuenta (feature 6)                               | ✅                                                  |
| R37 | Marcar un combo como "para firmar" **no revisa** los tipos que ya tiene; solo se controla al **agregar** un tipo (debe tener firma) | Igual que crédito y contabilidad. Se deja sencillo; si en la práctica molesta, se revisa | ✅ (2026-10-29) |
| R38 | Un tipo **no puede ser firma y foto a la vez** | La firma solo acepta PDF y la foto solo imágenes (R18): sería imposible subirlo. Contabilidad no lo impide; ahorros sí | ✅ (2026-10-29) |
| R39 | Un tipo puede vencer a los **0 días** del cargue (nace vencido) | Igual que contabilidad. Es decisión del usuario al configurar el tipo | ✅ (2026-10-29) |

## 3. Pedir documentos

| #   | Regla                                                                                                 | Para qué                                              |                                                                            |
| --- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- |
| R11 | Se pide un **combo completo** a una cuenta, o un **documento suelto**                                 | Cubrir tanto el caso normal como la excepción         | ✅                                                                          |
| R12 | Cada documento pedido queda como un **pedido** a nombre del titular, con descripción y obligatoriedad | Saber qué falta y de quién                            | ✅                                                                          |
| R13 | Se guarda **qué combo** se agregó a la cuenta y cuándo                                                | Poder responder "¿qué se le exigió a esta cuenta?"    | ✅ (de contabilidad)                                                        |
| R14 | Pedir un tipo único que la cuenta ya tiene **no se valida**: se crea el pedido | Consecuencia de R7 | ✅ **Reemplazada (R19 contable, 2026-11-05, commit `9e1b92c44`)**: el tipo único **no se valida en ningún punto**: ni al pedir suelto, ni por combo, ni al reactivar, ni al recrear. Al subir existe `DesactivarAnterioresSiEsUnico`, pero no tiene efecto porque un pedido nunca tiene un archivo anterior (R17) |
| R15 | Agregar un **segundo combo** o un **documento suelto** requiere un permiso especial                   | Que no cualquiera cambie lo que se exige a una cuenta | ✅ confirmada (2026-10-28): ahorros lleva los mismos permisos que crédito y contabilidad |

## 4. Subir archivos

| # | Regla | Para qué | |
|---|---|---|---|
| R16 | Solo se sube a un **pedido pendiente** de esa cuenta | El archivo siempre responde a algo que se pidió | ✅ |
| R17 | **Un pedido recibe un solo archivo en toda su vida** | El estado queda sin ambigüedad: nunca hay "el archivo anterior" | ✅ |
| R18 | Extensiones: la firma solo PDF, la foto solo imágenes, el resto una lista de **13 extensiones**. Se valida en el **servidor** | En crédito cliente y servidor no coinciden (caso `.png`) | ✅ |
| R19 | Los archivos de ahorros van a **su propia carpeta** y su propia tabla. Una ruta de crédito se rechaza | No mezclar expedientes de productos distintos | ✅ ([ADR-001](./ADR.md)) |
| R20 | Si la cuenta no tiene ruta de ahorros configurada, se avisa con un mensaje claro y **no se guarda nada** | Evitar archivos huérfanos o filas a medias | ✅ |
| R21 | Subir un archivo **no toca** el pedido; solo nace el vínculo y el archivo | El pedido es lo que se exige, no el estado | ✅ |
| R40 | Al subir un archivo hay que escribir una **observación** | Dejar constancia de qué se entregó. Igual que contabilidad | ✅ (2026-10-30) |

## 5. Cuándo vence un documento

| #   | Regla                                                                                                                  | Para qué                                                |                                                                                                               |
| --- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| R22 | Si un tipo vence, vence por **una sola** regla: una **fecha escrita a mano** al subir, o **N días después de subirlo** | Que la fecha de vencimiento nunca sea ambigua           | ✅                                                                                                             |
| R23 | La fecha de vencimiento la calcula **el servidor**, no la pantalla                                                     | En crédito la calcula la pantalla y eso permite errores | ✅                                                                                                             |
| R24 | Lo vencido aparece en **Vencidos**, y **no** se muestran los pedidos retirados                                         | No molestar con lo que ya nadie exige                   | ✅                                                                                                             |
| R25 | Un tipo que vence **N días después del fin de la cuenta**                                                              | En crédito: el seguro dura mientras dura el crédito     | ⏳ pendiente de comentar (P3). **Por ahora no entra**: no hay una fecha única de "fin de cuenta" |

## 6. Estados de un documento

| # | Regla | Para qué | |
|---|---|---|---|
| R26 | El estado **se calcula**, no se guarda: **pendiente** (pedido activo, nunca recibió archivo), **cargado vigente**, **cargado eliminado**, **retirado** | Nada que mantener sincronizado | ✅ |
| R27 | **Nunca se borra una fila**: se agrega o se cambia una bandera | Conservar el historial completo | ✅ |

## 7. Eliminar y retirar

| # | Regla | Para qué | |
|---|---|---|---|
| R28 | Eliminar un archivo lo **marca** como eliminado y deja una **constancia** (quién, cuándo, por qué). Varios archivos eliminados juntos comparten una constancia | Poder auditar sin perder el registro | ✅ |
| R29 | Eliminar **no devuelve el pedido a pendiente**: sigue "cargado eliminado" | El historial dice la verdad: sí hubo un archivo | ✅ |
| R30 | Al eliminar se puede **crear un pedido nuevo** del mismo tipo, mismo titular, descripción vacía y obligatorio | Es la única vía para volver a subir ese documento | ✅ igual que crédito: se crea **siempre**, sin mirar si el tipo es único (`ArchivoAhorroEliminacionActorNegocio.cs:127-147`). La excepción del 2026-11-03 (omitir si había otro pendiente) se quitó con la R19 contable |
| R31 | **Retirar** un pedido solo apaga ese pedido; no toca archivos ni otros pedidos. Se hace a mano. **Reactivar** un pedido retirado se permite siempre | Dejar de exigir algo sin borrar nada | ✅ Reactivar no valida el tipo único (`DocumentoAhorroCuentaAsignacionActorNegocio.cs:81-101`); la validación del 2026-11-03 se quitó con la R19 contable |
| R32 | Eliminar archivos requiere un permiso especial | Operación sensible | ✅ confirmada (2026-10-28): igual que crédito y contabilidad |
| R41 | El **acta** de una constancia (la que se imprime con "Generar formato") lista también los archivos de **ahorros** eliminados con esa constancia | Hoy la constancia de ahorros existe pero el acta sale sin sus archivos | ✅ la carpeta del acta se llama "Ahorros y aportes" (2026-11-04) |

## 8. Firma electrónica

| # | Regla | Para qué | |
|---|---|---|---|
| R33 | Un documento de tipo "firma" se envía a firmar al **titular**; el PDF firmado **reemplaza** al original | Que el expediente quede con la versión firmada | ✅ (detalle en la feature 5) |

## 9. Borrar una cuenta

| #   | Regla                                                                                             | Para qué                                                                                               |                               |
| --- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------- |
| R34 | Una cuenta con **cualquier pedido** (activo o retirado) **no se puede borrar**. La base lo impide | Hoy la cuenta se borra de verdad (no hay marca de eliminada); sin esta regla se perdería el expediente | ✅                             |
| R35 | El usuario ve un mensaje claro, no un error de base de datos                                      | Experiencia                                                                                            | ✅ (feature 7)                 |
| R36 | Qué puede hacer el usuario cuando **necesita** borrar de verdad una cuenta con expediente         | Hoy no existe forma de borrar un pedido, solo de retirarlo                                             | ⏳ pendiente a futuro (2026-10-28): es un problema real, se comenta más adelante (feature 7) |

## 10. Lo que NO tiene el expediente de ahorros

| Pieza de crédito | Por qué no |
|---|---|
| Codeudores como firmantes | La cuenta solo tiene titular |
| Geolocalización y "para convenios" | Son de la app móvil y del portal de convenios de crédito |
| Tabla de tercero por tipo | Repite el titular que ya está en el pedido |
| Permiso "editar datos" por etapa | La cuenta no tiene etapas |
| Documentos de soportes contables | Son de contabilidad |

## Pendientes

Decisión del 2026-10-28: el resto de las reglas están bien. R25 y R36 no bloquean el arranque. R37-R39 (huecos del catálogo, 2026-10-29) quedaron resueltas.

| # | Qué falta | Estado |
|---|---|---|
| Futuro (R17, R30) | ¿Reemplazar el archivo en el mismo pedido en vez de crear un pedido nuevo al eliminar? | Decisión a futuro (2026-10-30); por ahora igual que crédito y contabilidad |
| P3 / R25 | ¿Algún documento debe vencer después del fin de la cuenta? | Se comenta con negocio. Por ahora no entra al modelo; si se confirma, feature 8 |
| R36 | ¿Cómo se borra una cuenta que ya tiene expediente? | Se deja para después (feature 7) |

**Permisos (R15, R32):** ahorros necesita los mismos permisos especiales que crédito y contabilidad. El permiso de cada acción se crea en la feature que la construye (agregar combo y documentos sueltos: feature 2; eliminar: feature 4).
