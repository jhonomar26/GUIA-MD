# Formatos personalizados con Designer visual — visión general

Este documento explica, sin entrar en código, qué problema resuelve esta funcionalidad, cómo
está organizada hoy y qué limitación conocida tiene. Para el detalle técnico (métodos, archivos,
parámetros) ver [`REFERENCIA.md`](./REFERENCIA.md) (formatos generales) y
[`../../cartera/report-designer-amortizacion/PLAN_GUARDADO.md`](../../cartera/report-designer-amortizacion/PLAN_GUARDADO.md) (Amortización).

## Qué problema resuelve

Antes, cambiar el diseño de un formato (Paz y Salvo, Carta, Pagaré, etc.) requería tocar código.
El Designer visual de DevExpress le permite a un usuario de negocio arrastrar campos, cambiar
textos, logo, orientación, sobre un formato existente, sin depender de un desarrollador. El
resultado de ese diseño se guarda como el layout del formato y se usa después para generar el
documento real (carta, pagaré, tabla de amortización, etc.) con datos reales de un préstamo o
tercero.

## Dos familias de formatos, dos tablas distintas

Hoy existen dos grupos de formatos que usan el Designer, y **no comparten tabla**:

1. **Formatos generales** (`generales_formatos`): Paz y Salvo, Carta, Pagaré, Nómina, Clientes,
   Terceros, Eliminación de Archivos. Todos viven en la misma tabla; lo que cambia entre ellos es
   qué campos ofrece cada uno y de dónde saca sus datos.
2. **Formatos de Amortización** (`cartera_formatosamortizacion`): una tabla y un flujo
   completamente aparte, con su propia página y su propio grid de administración.

Para el usuario de negocio, abrir el Designer se ve igual en ambos casos. Por debajo, cada
familia tiene su propio mecanismo de guardado — porque cada una persiste en una tabla distinta y
el sistema necesita saber, sin ambigüedad, cuál usar en cada acción (abrir, guardar, guardar
como, listar).

## Cómo funciona cada familia

**Formatos generales:** sin importar desde qué página se abra o guarde el Designer, todas las
acciones (abrir, guardar, guardar como, listar, validar) pasan por un único punto central que ya
sabe distinguir entre los distintos tipos de formato dentro de esa misma tabla. Agregar un tipo
nuevo dentro de esta familia es sencillo: se declara qué campos ofrece y de dónde saca sus datos,
y el punto central lo reconoce automáticamente sin tener que tocar la lógica de guardado.

**Formatos de Amortización:** al abrir, el sistema llama directo a su propio mecanismo (no pasa
por el punto central de los formatos generales) y, en ese momento, deja marcado dentro del propio
diseño qué tipo de formato es. Esa marca viaja junto con el diseño de ahí en adelante. Así, al
guardar, el sistema ya sabe con certeza en qué tabla debe persistir, sin tener que adivinar ni
comparar el código contra ambas tablas (compararlo sería ambiguo: un mismo código podría existir
por coincidencia en las dos tablas).

La única situación donde esa marca no está disponible es en acciones donde solo se recibe un
código de texto, sin el diseño completo (por ejemplo, al listar formatos para el diálogo "Guardar
como", o al validar antes de guardar). Ahí el sistema decide por la página/ruta desde la que se
abrió el Designer — cada familia abre desde una ruta fija y distinta — en vez de por el código.

## Estado actual y su límite conocido

El modelo de hoy distingue exactamente estas dos familias. Esa distinción vive en unos pocos
puntos puntuales del punto central de formatos generales, y funciona bien para dos familias —
no representa un costo ni una complejidad real en este momento.

Si en el futuro aparece una **tercera familia** de formatos con su propia tabla (no un tipo más
dentro de `generales_formatos`, sino otra tabla nueva, como pasó con Amortización), esos puntos
puntuales empezarían a repetirse cada vez que se agregue una familia más. En ese momento
convendría generalizar la forma en que se reconocen las familias, en vez de seguir agregando una
comprobación más por cada una. No es necesario resolver eso ahora — anticiparlo sin una tercera
familia real sería complejidad sin uso.

## Un problema de acceso encontrado en el camino

Al conectar el Designer de Amortización con sus datos, se encontró que el mecanismo de datos que
usa DevExpress para hacer preview del formato hace su propia llamada al servidor, por fuera de la
sesión del usuario que tiene abierto el navegador. Un endpoint que exige inicio de sesión bloquea
esa llamada sin dar ningún error visible en pantalla — el preview simplemente sale vacío. La
solución fue separar claramente dos responsabilidades que antes estaban en el mismo lugar: la
administración del formato (que sí exige que el usuario esté autenticado) y el suministro de
datos al motor de reportes (que no puede exigir sesión de usuario, y en su lugar se valida con
una clave interna compartida entre el servidor y el motor de reportes).
