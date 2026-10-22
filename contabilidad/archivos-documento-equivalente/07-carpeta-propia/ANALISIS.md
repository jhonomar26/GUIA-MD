# Análisis: carpeta propia del documento equivalente

> [← README](./README.md) · Área: [ANALISIS](../ANALISIS.md) · Criterio: [ADR-003](../ADR-003.md) (un punto de entrada por dueño)

## Qué existe hoy

- Una sola ruta contable: `generales_parametroscarpetavirtual` id 7, `~/Uploads/Contabilidad/`, con `escontabilidad = true`.
- Al subir, el servidor valida la ruta con `ValidarRutaContable` (activa y contable) para comprobante y documento equivalente por igual.
- Lo único que separa los dueños es la columna `iddocumentoequivalente` de la tabla de archivos. En disco o FTP se mezclan.
- El backup de carpetas virtuales filtra por `escontabilidad`.

## Qué se quiere

Que los archivos del documento equivalente tengan su ruta propia, configurada como las demás, y que no se mezclen con los del comprobante.

## Reglas (confirmadas y hechas, 2026-10-22)

1. **Ruta por dueño.** Subir un archivo a un comprobante solo ofrece rutas del comprobante; a un documento equivalente, solo rutas del documento equivalente.
2. **Sin ruta, no se sube.** Si no hay ruta activa para el dueño, se rechaza con un mensaje claro; no se usa la del otro dueño.
3. **Lo ya subido no se mueve.** Los archivos actuales siguen donde están y se siguen leyendo igual.
4. **Contable no cambia.** El comprobante sigue con su ruta y su recorrido actual (CO101).
5. **Backup.** Las rutas del documento equivalente entran al backup igual que las contables.

## Decidido (2026-10-21)

- Se marca con columna nueva `esdocumentoequivalente`, disjunta de `escontabilidad`.
- La ruta nueva se crea con script SQL, como la de contabilidad.
- Cada dueño tiene su ruta principal (`esprincipal`): sale preseleccionada en el combo y el usuario puede elegir otra. Hoy ninguna ruta está marcada principal; el script marca la de contabilidad y la nueva.
- Lo no subido no se toca: son datos de prueba y los archivos viejos siguen donde están.

## Escenarios de prueba (Dado / Cuando / Entonces)

| # | Dado | Cuando | Entonces |
|---|---|---|---|
| E1 | Ruta propia del documento equivalente configurada | Se sube un archivo a un documento equivalente | Queda en la ruta del documento equivalente |
| E2 | La misma configuración | Se sube un archivo a un comprobante | Queda en `Contabilidad`, como hoy |
| E3 | Sin ruta activa para el documento equivalente | Se intenta subir | Se rechaza con mensaje claro y no se guarda nada |
| E4 | Se manda la ruta del comprobante a un documento equivalente | Se sube | Se rechaza |
| E5 | Archivos subidos antes de esta feature | Se visualiza o elimina | Funciona igual |
| E6 | Backup de carpetas virtuales | Se ejecuta | Incluye la ruta del documento equivalente |
