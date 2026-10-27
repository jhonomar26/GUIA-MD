# Requerimiento: archivos en documento equivalente

> [← README](./README.md)

## Pedido (2026-10-19)

Hacer en el documento equivalente lo mismo que se hizo con el documento contable: que se le puedan pedir y adjuntar documentos. La parametrización es la misma (agrupaciones, tipos de documento y combos); en el fondo es que esos documentos puedan pertenecer a un documento equivalente.

## Decisiones del usuario

Tomadas en la entrevista, de a una pregunta:

| # | Pregunta | Decisión |
|---|---|---|
| 1 | ¿De quién son los archivos? | Del **documento equivalente**, no del comprobante contable que se genera al contabilizarlo |
| 2 | ¿El estado del documento equivalente limita algo? | No. Igual que contable: se opera en cualquier estado (edición, proceso, aprobado, anulado). Solo hace falta que esté guardado |
| 3 | ¿Permisos? | **Propios** del documento equivalente: agregar más combos, agregar documentos sueltos y eliminar archivos |
| 4 | ¿A quién se asignan? | ~~Automático a los roles con permisos de contabilidad~~ **Corregido 2026-10-20:** el script solo crea los permisos; el administrador los asigna a los roles desde la pantalla de roles |
| 5 | ¿Se ven los archivos del documento equivalente en el comprobante que genera? | No. Son **independientes**: cada uno ve solo los suyos |
| 6 | ¿Se puede borrar un documento equivalente que tiene documentos pedidos o archivos? | No. **Se bloquea** el borrado (sin borrado en cascada) |
| 7 | ¿Botones en la pantalla? | Los mismos de CO101: "Listar Documentos" y "Adjuntar". Sin botón "Volver" (CO101 tampoco lo tiene) |
| 8 | ¿Carpeta virtual (EV101 y EV201)? | **Fuera**. Hoy no muestran los archivos contables, así que tampoco los del documento equivalente |

**Principio que salió de la entrevista:** paridad con documento contable. Solo se replica lo que ya existe para el comprobante; nada más.

## Reglas de diseño (2026-10-21)

Tomadas al revisar el código de `02-solicitar-documentos`. Valen para todas las features de este requerimiento. Detalle en [ADR-003](./ADR-003.md).

- **Modularizar por dueño.** Lo que es del documento contable y lo que es del documento equivalente va en piezas separadas (controlador, permiso, mensajes). Nada de decidir el dueño con un `bool` ni con ternarios repartidos.
- **Lo común, en un solo lugar de `Negocio/`.** Las reglas que comparten los dos dueños no se copian: un método estático que ambos llaman.
- **El dueño lo fija el punto de entrada**, no lo que mande la pantalla.
- **Solo lectura:** una acción por dueño en el mismo controlador; no un controlador por acción.
- **Funciones chicas.** Si un método mezcla permiso, validación, regla de negocio e insert, se parte.

La decisión 8 primero fue "sí". Se corrigió cuando el diseño encontró que la carpeta virtual no lista archivos contables: la pregunta partía de una premisa falsa.
