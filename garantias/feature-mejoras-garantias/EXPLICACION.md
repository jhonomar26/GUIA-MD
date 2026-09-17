# Lógica de negocio — Gestión de Documentos y Tipos de Soporte de Garantías

## Propósito

Esta pantalla configura **qué documentos exige el sistema para respaldar una garantía**,
cómo se agrupan, qué formatos de soporte son válidos para cada uno, y cómo pueden
combinarse varios documentos como un paquete obligatorio.

## Entidades y su rol

- **Grupo Documento**: categoría que agrupa Tipos de Documento afines (ej. "legales",
  "financieros"). Solo tiene nombre y estado activo/inactivo — es un catálogo de
  clasificación.

- **Tipo de Soporte**: catálogo fijo de formatos o evidencias que puede tener un
  documento (ej. PDF, Escritura, Certificado). En esta pantalla es de solo consulta; se
  administra en otro lugar.

- **Tipo de Documento**: es la entidad central. Representa un documento concreto que
  puede exigirse (ej. "Escritura pública", "Avalúo comercial"). Cada uno define:
  - a qué Grupo Documento pertenece
  - si expira o no, y bajo qué regla (ver más abajo)
  - si es de documento único (ver más abajo)
  - qué Tipos de Soporte son aceptados para él

- **Combo de Documentos**: agrupa varios Tipos de Documento como un paquete que se exige
  junto (ej. "documentos para garantía hipotecaria" = escritura + avalúo + certificado de
  libertad). Dentro del combo, cada documento incluido puede marcarse como obligatorio o no.

## Relaciones entre entidades

- **Grupo Documento → Tipo de Documento**: un grupo puede tener muchos tipos de documento
  (relación uno a muchos). Un tipo de documento pertenece a un solo grupo.

- **Tipo de Documento ↔ Tipo de Soporte**: relación de muchos a muchos. Un tipo de
  documento puede aceptar varios soportes, y un mismo soporte puede aplicar a varios
  tipos de documento. Esta relación vive en una tabla intermedia que además indica si ese
  soporte es obligatorio para ese documento en particular.

- **Combo de Documentos ↔ Tipo de Documento**: también de muchos a muchos. Un combo
  agrupa varios tipos de documento, y un mismo tipo de documento puede aparecer en varios
  combos distintos. La tabla intermedia guarda si ese documento es obligatorio dentro de
  ese combo específico.

## Reglas de negocio sobre expiración

La expiración no aplica al Tipo de Documento en abstracto, sino a **cada archivo concreto
que se carga** contra ese tipo (reflejado en el tab "Vencidos" de la pantalla de carga de
archivos).

Un Tipo de Documento puede o no expirar:

- **Si no expira**: el archivo cargado no tiene fecha de vencimiento — no aplica ningún
  control de vigencia.
- **Si expira**, hay dos formas mutuamente excluyentes de calcular cuándo:
  - **Vencimiento automático**: se define un número de días después de la fecha en que
    el archivo fue cargado; el sistema calcula la fecha de vencimiento por sí solo, en el
    servidor, sin depender de lo que envíe quien carga el archivo.
  - **Fecha manual**: quien carga el archivo debe indicar la fecha de vencimiento
    directamente (obligatorio en este caso); no se configuran días automáticos, porque
    sería contradictorio tener ambas reglas a la vez.

Que un archivo "expire" no lo invalida ni lo elimina del sistema: sigue existiendo, pero
deja de contar como respaldo vigente de la garantía. Es una señal para que se cargue una
versión actualizada, similar a un certificado con fecha de vencimiento impresa.

## Regla de negocio sobre documento único

Un Tipo de Documento puede marcarse como **único**. El alcance de esta regla es: **una
entidad concreta (ej. un inmueble, un vehículo, un garante puntual) solo puede tener un
archivo activo cargado de ese tipo de documento a la vez**, sin importar si la solicitud
de ese documento vino directa o a través de un Combo de Documentos.

- Si ya existe un archivo activo cargado de ese tipo para esa entidad, el sistema
  **rechaza la carga de uno nuevo** — no lo reemplaza automáticamente. Para poder cargar
  uno distinto, primero debe eliminarse el existente.
- La unicidad es **por entidad**, no global al tipo de documento: la misma entidad no
  puede tener dos veces el mismo documento único, pero otra entidad distinta sí puede
  tener su propio archivo cargado de ese mismo tipo, sin conflicto.
- Si el documento único se solicita tanto de forma directa como dentro de un combo para
  la misma entidad, sigue contando como una sola unidad: cargarlo por cualquiera de las
  dos vías satisface la unicidad y bloquea intentar cargarlo de nuevo por la otra.

## Flujo típico de configuración

1. Crear (o verificar que existan) los **Grupos Documento** necesarios para clasificar.
2. Verificar que los **Tipos de Soporte** requeridos ya existan en el catálogo (si falta
   alguno, se gestiona fuera de esta pantalla).
3. Crear el **Tipo de Documento**, asignándole su grupo, su regla de expiración, si es
   único, y los tipos de soporte que acepta.
4. Opcionalmente, agrupar varios Tipos de Documento dentro de un **Combo de Documentos**,
   marcando cuáles de ellos son obligatorios dentro de ese paquete.

Este orden refleja dependencias reales: un documento necesita su grupo y soportes
definidos antes de poder configurarse, y un combo necesita que los documentos que agrupa
ya existan.
