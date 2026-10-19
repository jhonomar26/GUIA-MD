# Avance — Mejoras al módulo de Garantías

Resumen de todo lo realizado hasta el 22 de septiembre de 2026 sobre el módulo de
Garantías (inmuebles y vehículos).

## Pedido original

Se solicitaron 7 correcciones:

1. Corrección del municipio
2. Corrección al editar el propietario
3. Corrección de datos innecesarios en la garantía
4. Corrección en los parámetros de garantía
5. Corrección de tipos de documentos
6. Corrección del botón de regresar
7. Corrección de documento único

**Estado: las 7 correcciones están terminadas.** Además, en el camino se encontraron y
corrigieron otros problemas que no estaban en el pedido original pero que afectaban el
correcto funcionamiento del módulo — se detallan al final.

---

## 1. Corrección del municipio

**Problema:** al registrar un bien inmueble, el listado de municipios no dependía del
departamento elegido (mostraba todos los municipios del país) y no se podía buscar por
nombre.

**Solución:** ahora el listado de municipios se filtra automáticamente según el
departamento seleccionado, y se puede escribir para buscar tanto el departamento como el
municipio.

## 2. Corrección al editar el propietario

**Problema:** al editar el propietario de un vehículo, el cambio no quedaba bien
asociado al bien correspondiente. También había inconsistencias en cómo se mostraba la
información del propietario en inmuebles y en vehículos.

**Solución:** se corrigió que la edición del propietario quede correctamente vinculada al
bien, y se unificó/simplificó la forma en que se presenta esa información en pantalla.

## 3. Corrección de datos innecesarios en la garantía

**Problema:** los formularios y listados de garantías mostraban u ofrecían editar campos
que no son relevantes para el proceso real, generando confusión.

**Solución:** se depuró la pantalla dejando visibles solo los datos que realmente se
necesitan cargar o consultar.

## 4. Corrección en los parámetros de garantía

**Problema:** la pantalla de configuración de parámetros de garantía era antigua, poco
clara y mezclaba todas las configuraciones (clasificación, clase de vehículo, tipos de
documento) en un mismo lugar.

**Solución:** se reorganizó la pantalla en pestañas separadas por tema, más simple de
usar, y se corrigieron problemas de desplazamiento y ventanas emergentes dentro de esas
pestañas.

## 5. Corrección de tipos de documentos

Fue la corrección más profunda, porque implicó revisar y ajustar las reglas de negocio.

**Problemas encontrados:**
- La pantalla de configuración de documentos era una sola vista muy larga y difícil de
  mantener.
- No existía forma de indicar qué formatos de soporte (PDF, escritura, certificado, etc.)
  son válidos para cada tipo de documento.
- La fecha de vencimiento de un documento cargado la calculaba el navegador del usuario y
  el sistema la aceptaba sin revisar — esto es un riesgo, porque alguien podría manipular
  esa fecha antes de enviarla.
- No se estaba validando la regla de "documento único": se podían cargar varias veces el
  mismo documento para el mismo bien o garante, cuando debería permitirse solo uno activo
  a la vez.

**Solución:**
- Se reorganizó la pantalla en secciones más pequeñas y manejables.
- Se agregó la posibilidad de asociar formatos de soporte válidos a cada tipo de
  documento, marcando cuáles son obligatorios.
- El sistema ahora calcula y valida la fecha de vencimiento del lado del servidor,
  ignorando lo que envíe el navegador (salvo cuando la fecha debe cargarse manualmente,
  caso en el que se exige que el usuario la informe).
- Se bloqueó la carga de un documento "único" si ya existe uno activo para esa misma
  garantía — para reemplazarlo, primero hay que eliminar el existente. Esto evita que un
  documento legal se reemplace en silencio sin dejar rastro.
- Se corrigió el campo de selección múltiple (tagbox) de "tipos de soporte permitidos"
  para cada tipo de documento, que tenía un error y no funcionaba correctamente.

## 6. Corrección del botón de regresar

**Problema:** la pantalla de carga de archivos se abre siempre en una pestaña nueva del
navegador, y el botón "Regresar" no hacía nada porque esa pestaña no tiene una página
anterior a la cual volver.

**Solución:** el botón ahora vuelve a la pantalla exacta desde donde se abrió; si por
algún motivo no puede determinar esa pantalla, cierra la pestaña.

## 7. Corrección de documento único

Esta corrección quedó resuelta junto con el punto 5 — es la misma regla de negocio
(bloquear la carga de un documento repetido en vez de reemplazarlo).

---

## Otros problemas encontrados y corregidos en el camino

Durante el trabajo sobre las 7 correcciones se detectaron y resolvieron problemas
adicionales, no pedidos explícitamente pero necesarios para que el módulo funcione bien:

- **Se podían editar o eliminar garantías ya aprobadas.** Se descubrió que, aunque el
  botón formal de aprobar/anular/liberar respetaba las reglas del negocio, existían otras
  formas de acceder a los mismos datos (edición directa, edición de garantes) que no
  revisaban en qué estado estaba la garantía. Esto significaba que, en teoría, se podía
  editar o borrar una garantía que ya estaba aprobada, o modificar sus garantes después
  de aprobada, anulada o liberada — algo que no debería ser posible. Se corrigió la
  mayoría de estos casos; queda un ajuste menor pendiente (ver más abajo).
- **Se centralizó y reforzó el proceso contable de las garantías**, para que aprobar,
  anular o liberar una garantía sea una operación completa y consistente (si algo falla a
  mitad de camino, no queda la operación a medias).
- **Se mejoró el flujo de aprobación de una garantía**, centralizándolo en una única
  ventana emergente en vez de tenerlo repartido en la pantalla.
- **Se corrigió la consulta de garantes** asociados a un tercero, que antes se resolvía
  de forma menos eficiente y con datos no siempre correctos.
- **Se corrigió un problema de inicio de sesión** en la pantalla de parámetros de
  garantía.
- **Se corrigieron varios archivos que habían quedado con la codificación de texto dañada**
  (tildes y caracteres especiales mostrados incorrectamente).
- **Se documentaron y corrigieron dos problemas visuales recurrentes de las grillas**
  (listados) del módulo: columnas que no se veían bien al haber muchas, y un selector
  dentro de la grilla que dependía de otro selector de la misma fila y a veces fallaba.
  Estas correcciones también se van a poder reutilizar en otras pantallas del sistema que
  tengan el mismo tipo de grilla.

## Pendiente

- Un ajuste menor en la validación de estados para garantías de inmueble (un caso puntual
  que hoy muestra un error técnico genérico en vez de un mensaje claro).
- Una limpieza interna de código (nombres de estados repetidos en varios lugares) que no
  afecta el funcionamiento, solo el mantenimiento futuro.

No queda pendiente ningún punto del pedido original: **las 7 correcciones solicitadas
están terminadas.**
