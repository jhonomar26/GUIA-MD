# Plan: documento único como crédito

> El tipo único se maneja como en crédito, en contabilidad y en ahorros (H7) · [← README](../README.md) · Regla: [R19](../REGLAS-DE-NEGOCIO.md) · Mapa: L4 · Sin tests automáticos: matriz en Orca

La carpeta conserva el nombre `2-eliminar-retira-pedido`, pero R19 descartó retirar el pedido (R13, R15-R18). Reemplaza la T7 del plan original (casos 13-15). Sin scripts SQL.

## Specs

- S1. "la desicion es dejarlo al igual que credito": un tipo único se puede volver a pedir a mano, por combo, al reactivar y al recrear, sin revisar si ya hay otro pedido activo del tipo. Implementa R19 (a).
- S2. "que desactive los anteriores y quede el actualmente": al subir un archivo a un pedido de tipo único, los archivos anteriores de ese mismo pedido quedan con `esactivo = false` ("Literal crédito, por pedido"). Implementa R19 (b).
- S3. "tanto en ahorros como en contabilidad": aplica al comprobante, al documento equivalente y a la cuenta de ahorro.

## Casos

Cada caso se recorre en contabilidad (comprobante y equivalente) y en ahorros.

| # | Regla | Dado | Cuando | Entonces | Contabilidad | Ahorros |
|---|---|---|---|---|---|---|
| 1 | R19 a | tipo único cargado | elimina con "No" y pide el tipo a mano | lo agrega; el pedido viejo sigue "cargado eliminado" | Pasa (L11) | Pasa (L9) |
| 2 | R19 a | caso 1 hecho | agrega un combo que trae ese tipo | crea el pedido del tipo | Pasa (L11) | Pasa (L9) |
| 3 | R19 a | tipo único cargado | elimina con "Sí" | nace el pedido nuevo pendiente, sin aviso | Pasa (L11) | Pasa (L10) |
| 4 | R19 a | tipo único pendiente | pide otro igual a mano | lo agrega (antes: rechazo "ya esta solicitado") | Pasa (L11) | Pasa (L9) |
| 5 | R19 a | pedido único retirado y otro activo del tipo | reactiva el retirado | se reactiva (se deshace la T5 de la etapa 1) | Pasa (L11) | Pasa (L9) |
| 6 | R19 b | pedido único pendiente | sube un archivo | queda vigente y activo; no hay anteriores que desactivar | Pasa (L11) | Pasa (L10) |
| 7 | R19 b | pedido no único pendiente | sube un archivo | igual que hoy | Pasa (L11) | Pasa (L10) |

## Tareas

- [x] T0. R19 confirmada = A (L6) y (b) por pedido (L8). Sin `EXPLICACION.md`: el usuario pidió el cambio directo (L6).
- [x] T1 (S1, S3). Quitar el bloqueo de tipo único en contabilidad y ahorros; borrar los métodos sin uso. Inline. Compila (L6). Casos 1-5 pendientes en Orca. Sin commit.
- [x] T2 (S2, S3). `DesactivarAnterioresSiEsUnico` en `RegistrarArchivo` de `ArchivoContableAlmacenamientoActorNegocio` y `ArchivoAhorroSubidaActorNegocio`. Inline. Compila (L8). Casos 6-7 pendientes en Orca. Sin commit.
- [x] T3. Casos 1-7 recorridos en el servidor de pruebas: ahorros (L9-L10) y comprobante contable (L11). Documento equivalente sin recorrer (comparte el mismo código). Sin capturas en `evidencia/`: el resultado se leyó de las APIs de cada pantalla.

## Log

- L1 (2026-11-05). Pedido textual en [REQUERIMIENTO.md](../REQUERIMIENTO.md#pedido-2-2026-11-05-eliminar-retira-el-pedido).
- L2 (2026-11-05). Verificado en la base de pruebas: `contabilidad_vistadocumentoseliminadoscombo` y `ahorrosyaportes_vistadocumentoseliminadoscuentacombo` filtran `s.esactivo = true`; las listas generales (`contabilidad_vistaarchivoseliminados`, `ahorrosyaportes_vistaarchivoseliminadosahorrosaportes`) no. El estado (`...solicitadoestado`, `...ahorroestado`) calcula cargado y eliminado sin mirar `s.esactivo`, así que un pedido retirado sigue saliendo "cargado eliminado".
- L3 (2026-11-05). Creada primero como carpeta suelta `archivos-contabilidad/eliminar-retira-pedido/`; movida aquí como feature 2 con la reorganización del área (L15 de la feature 1). Sus reglas R1-R6 pasan a R13-R18.
- L4 (2026-11-05). Usuario, al pedir confirmar R15-R17: "lo mejor es hacerlo como esta en credito, es que siento que esta parte de unico al haberla hecho diferente si nos trajo nuevas necesidades, igual la idea seria dejar aqui lo mas sano". Revisado en código (solo lectura):
  - Crédito **no bloquea repetir un tipo**, ni a mano ni por combo ni al recrear (`DocumentoCreditoActorNegocioViewModel.cs:38-41`, `ComboDocumentoCreditoActorNegocio.cs:25-26, 68-70`, `CargaArchivosActorNegocio.cs:178-194`).
  - Su `esdocumentounico` solo actúa al subir: `ArchivoActorNegocio.VerificarDocUnico` (`Negocio/Generales/ArchivoActorNegocio.cs:19-33`) pone `esactivo=false` a los archivos anteriores **del mismo pedido** (busca por `credito_creditodocumentacion.iddocumento`, no por tipo). La subida web solo ofrece pedidos sin archivo (`CargaArchivosController.MostrarArchivos:114-124`), así que en la web casi nunca se dispara; actúa en la sincronización móvil (`CreditoMaestroViewModelActorNegocio.cs:6018-6027`) y en formato personalizado.
  - Al eliminar en crédito, el pedido sigue activo; para volver a cargar se pide el tipo de nuevo.
  - Contabilidad y ahorros ya copian de crédito "un pedido se llena una sola vez" (`TieneArchivo` y las vistas de pendientes). Lo único distinto es el bloqueo de tipo único, que causa H7.
  - Adoptar crédito = quitar: contabilidad `DocumentoContableSolicitadoAsignacionActorNegocio` (agregar a mano y reactivar, la T5 de la etapa 1) y el salto del combo en `Blip.Data/Contabilidad/DocumentoContableComboActorNegocio.cs:23-26`; ahorros `DocumentoAhorroCuentaAsignacionActorNegocio.cs:68-70, 101-107`, `CuentaAhorroComboAsignacionActorNegocio.cs:44-46` y el salto al recrear en `ArchivoAhorroEliminacionActorNegocio.cs:142-147` (+ aviso `:58-60`). `ExisteTipoEnDocumento` y `ExisteTipoActivoEnCuenta`/`ExistePendienteDelTipoEnCuenta` quedan sin uso.
- L5 (2026-11-05). Usuario, ante qué función cumpliría el campo: "deja esto documentado por lo pronto, pregunte si lo correcto es dejarlo como en credito y no complicarnos o lo dejamos como esta actualmente en contabilidad y ahorros, aunque me da mas la sensacion de lo primero, es algo que ya funciona y es cosa del usuario comodidad". Queda R19 por confirmar; sin código.
- L6 (2026-11-05). Usuario: "la desicion es dejarlo al igual que credito asi que cambiemos esto". R19 = A. Quitado el bloqueo de tipo único: contabilidad `DocumentoContableSolicitadoAsignacionActorNegocio` (agregar a mano y reactivar: se deshace la T5 de la etapa 1), `DocumentoContableComboActorNegocio` (combo); ahorros `DocumentoAhorroCuentaAsignacionActorNegocio` (agregar y reactivar), `CuentaAhorroComboAsignacionActorNegocio` (combo), `ArchivoAhorroEliminacionActorNegocio` (recrear sin salto ni aviso). Borrados `ExisteTipoEnDocumento` (+ `ObtenerCampoDelDueno` privado, solo lo usaba ese), `ExisteTipoActivoEnCuenta` y `ExistePendienteDelTipoEnCuenta`. MSBuild sin errores. Sin probar en Orca, sin commit.
- L7 (2026-11-05). Usuario: "Que funcione tal cual está en crédito parce, que desactive los anteriores y quede el actualmente únicamente esto si necesitamos tambien hacerlo". Pendiente: en crédito desactiva por **pedido**, y aquí un pedido nunca recibe un segundo archivo (`TieneArchivo`), así que copiado literal no haría nada; se pregunta si es por tipo en el mismo documento.
- L8 (2026-11-05). Usuario eligió "Literal crédito, por pedido". `RegistrarArchivo` (contabilidad y ahorros) llama a `DesactivarAnterioresSiEsUnico(idPedido)`: lee el tipo del pedido en la base (crédito lo recibe del navegador) y, si es único, pone `esactivo = false` a los archivos ya ligados al pedido con los métodos estándar (`ObtenerPorIddocumentocontablesolicitado` / `ObtenerPorIddocumentoahorrocuenta`, `ObtenerPorId`, `Update`); sin SQL nuevo. Archivos ISO-8859 editados por bytes. MSBuild sin errores. Specs, Casos y Tareas reescritos para R19.
- L9 (2026-11-05). Pruebas en el servidor de pruebas, ahorros, cuenta 1947 (`/rep1/DocumentoAhorroCuenta/?idcuenta=1947`), estado leído con `VistaDocumentoAhorroEstadoWebApi/GetPorCuenta`. DOCUMENTO 1 es único y ya tenía dos pedidos activos (uno "cargado eliminado", otro cargado vigente). Caso 1/4: "Agregar Documento" DOCUMENTO 1 ("prueba R19 unico repetido", id 35) se guardó sin mensaje y quedó pendiente. Caso 5: `Put` del grid con `Esactivo=false` y luego `true` sobre el id 35 → 200 y 200, queda activo. Caso 2: "Agregar combo" COMBO 1 → creó DOCUMENTO 1, 2 y 3 aunque ya había tres DOCUMENTO 1 activos. Quedan: caso 3 (borra un archivo), casos 6-7 (subir) y todo contabilidad.
- L10 (2026-11-05). Usuario autorizó eliminar: "Sí, eliminálo". Ahorros, cuenta 1947, mismas llamadas que arma la pantalla (el check del grid no tomó la selección desde Orca). Caso 3: `EliminarArchivos` con `Recrear=true` sobre el archivo 12 (pedido "documento 1 pendiente") → 200 "Archivos eliminados correctamente." sin aviso; nació un DOCUMENTO 1 pendiente aunque ya había dos pendientes del tipo. Casos 6-7: `SubirArchivo` con un PDF mínimo a los pedidos 35 (DOCUMENTO 1, único) y 17 (DOCUMENTO 2) → 200 "Archivo subido y registrado correctamente."; los dos salen en Cargados con Activo = true. Ahorros completo; falta contabilidad (comprobante y equivalente).
- L11 (2026-11-05). Contabilidad, comprobante 168819 (`/rep1/DocumentoContableCombo/?iddocumento=168819`); DOCUMENTO 2 UNICO ya tenía dos pendientes activos (94, 95). Caso 1/4: "Agregar Documento" DOCUMENTO 2 UNICO → pedido 97 sin rechazo. Caso 5: `Put` del grid sobre 97, `Esactivo` false y luego true → 200 y 200, queda activo. Caso 2: Combo 1 → creó 98-100, entre ellos DOCUMENTO 2 UNICO (100). Casos 6-7: `SubirArchivo` PDF mínimo a 97 (único) y 98 (DOCUMENTO 3 FIRMA) → 200 y los dos quedan cargados. Caso 3: `EliminarArchivos` con `recrear=true` sobre el archivo 24 (de 97, subido en esta prueba) → 200 "Archivos eliminados correctamente." y nació el pendiente 101 de DOCUMENTO 2 UNICO. No se recorrió documento equivalente: usa los mismos métodos (`AgregarDocumentoIndividual`, `InsertarConDocumentosSolicitados`, `MarcarEliminados`, `RegistrarArchivo`).
