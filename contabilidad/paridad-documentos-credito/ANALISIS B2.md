# Análisis B2: permiso para agregar y editar documentos individuales

Brecha B2 del `REQUERIMIENTO.md`. Lectura de código del 2026-10-15; nada se ejecutó en la app.

## Qué ya existe

| Pieza | Hoy | Conclusión |
|---|---|---|
| Crédito y Pagaré | Agregar un documento suelto (sin combo) exige un permiso propio, distinto al de agregar combos. Sin él, la pantalla no ofrece el botón. | **Se imita** |
| Contabilidad, combos | Agregar un combo completo ya exige un permiso propio ("Agregar Mas Combos"). El primer combo de un comprobante siempre se puede agregar. | **No se toca** |
| Contabilidad, documentos sueltos | Cualquier usuario con acceso a la pantalla puede agregar un documento y editar su descripción, obligatorio y activo. | **Se cierra** |
| Servicio de guardado de documentos | No consulta ningún permiso. Un usuario sin permiso podría guardar igual saltándose la pantalla. | **Se cierra** |

## Qué falta

Un permiso nuevo, "Agregar Documentos Individuales" de contabilidad, asignable por usuario como los demás. Con él se decide quién puede agregar un documento suelto y quién puede editar uno ya solicitado.

## Reglas de negocio

1. **Un solo permiso para agregar y editar.** Agregar y editar son parte del mismo poder: modificar la lista de documentos que se piden a mano.
2. **Sin excepción por primer documento.** A diferencia de los combos, no hay "el primero siempre se puede": crédito tampoco la tiene para documentos sueltos. Quien no tiene el permiso no agrega documentos sueltos, aunque el comprobante esté vacío. Sigue pudiendo agregar el primer combo.
3. **Sin permiso, la pantalla lo impide y el servicio también.** Se ocultan "agregar" y "editar" en la grilla, y si alguien llama al servicio directo, recibe un error claro. Ocultar el botón solo no alcanza.
4. **Ver no cambia.** El usuario sin permiso sigue viendo la lista y los archivos cargados.
5. **Los documentos que vienen de un combo también son editables con este permiso.** Hoy la grilla no distingue el origen, y no se agrega esa distinción: lo que cambia es quién puede.
6. **Usuarios existentes pierden el acceso hasta que se les asigne.** Es la consecuencia esperada de proteger algo que estaba abierto.

## Decisión tomada

Permiso nuevo, no el de combos (2026-10-15). Reutilizar el de combos le daría a quien agrega combos la capacidad de editar documentos sin que nadie lo decidiera. Crédito y Pagaré también los separan.

## Riesgo

Bajo, pero con una consecuencia operativa: al desplegar, **nadie** puede agregar ni editar documentos sueltos hasta que se cree el permiso y se asigne. Hay que dejar el script del permiso y la asignación a los perfiles correctos en la misma entrega.

Asignación inicial (2026-10-15): al desplegar, el permiso nuevo se da a los mismos usuarios que hoy tienen "Agregar Mas Combos".

## Pendiente de confirmar con negocio

Nada.

## Verificación

- Usuario **con** el permiso: agrega un documento suelto y edita descripción, obligatorio y activo. Queda guardado.
- Usuario **sin** el permiso: la grilla no muestra agregar ni editar. Una llamada directa al servicio de guardado responde error y no guarda nada.
- Usuario sin el permiso en un comprobante vacío: puede agregar el primer combo, no un documento suelto.
- Crédito, Pagaré, Tercero y CRM: sin cambios (esta brecha no toca código compartido).
