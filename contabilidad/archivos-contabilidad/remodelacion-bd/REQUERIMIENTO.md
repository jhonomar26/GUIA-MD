# Requerimiento: subida de archivos sobre el modelo nuevo

## Pedido original (2026-10-27)

> D:\rep1\SIIAN\PruebaPostgreSQL\Views\DocumentoContableCombo\Index.cshtml ya tenemos la parte de configuracion de D:\rep1\SIIAN\PruebaPostgreSQL\Views\DocumentoContableArchivo\Index.cshtml nos hace falta correguir la parte de subida de archivos ten en cuenta la guia para analizar todo lo que debemos de ajustar, podemos tomar como ejemplo la parte de creditoD:\rep1\SIIAN\PruebaPostgreSQL\Views\DocumentoCreditoCredito\Index.cshtml ayudame con esto

> si o si es necesario crea spects claros y separados igual la idea es ir tarea por tarea

## En palabras de negocio

La base del expediente virtual contable ya se remodeló (ver [`EXPLICACION.md`](./EXPLICACION.md)): el estado de cada documento pedido ya no se guarda, se calcula a partir del archivo. La pantalla donde se **piden** los documentos (combos y solicitados) ya funciona con el modelo nuevo.

Falta la pantalla donde se **suben, consultan y eliminan** los archivos de un comprobante contable o de un documento equivalente. Hoy no funciona: subir, ver pendientes, ver vencidos y eliminar apuntan a cosas que ya no existen.

Se arregla con crédito como referencia de comportamiento, tarea por tarea.
