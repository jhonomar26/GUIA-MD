

Por qué el ticket no puede ser la petición — la razón más fuerte no es la que te di antes

Te di la de la autenticación separada (portal vs. AspNetUsers), que es real, pero es secundaria. La razón de fondo es otra, y es más simple de ver:

Un ticket necesita partirse en varias piezas de trabajo independientes — el ejemplo que armamos: arreglo puntual + desarrollo + reunión, cada una con su propio asignado y su propio estado. Eso significa que necesitás una tabla hija de todos modos, la llames "petición" o no la llames de ninguna forma. No es una limitación de SIIAN ni una excusa para no tocar el ticket viejo: es así en cualquier diseño, incluso si arrancaras de cero sin ningún sistema legado. El propio Redmine, cuando necesita partir un issue en piezas, usa sub-issues — o sea, más filas, no la misma fila.

Entonces la pregunta "¿por qué no hacemos que el ticket sea la petición?" tiene esta respuesta corta: porque igual necesitás una tabla hija para las piezas de trabajo, así que separarla desde el nombre de tabla no te cuesta nada extra que no fueras a pagar de todas formas.

Sobre si esto aporta algo

Acá sí te debo ser más duro, porque venís dudando de esto desde hace rato y merece una respuesta de fondo, no una reafirmación.

Lo que tenés hoy, concreto: un ticket ya funciona, Redmine ya funciona, y lo único roto es el puente entre los dos + la administración de usuarios duplicada. Eso es un problema chico y puntual. Lo que estamos analizando (10 fases, roles por proyecto, flujo Rol+Tipo+Estado, campos personalizados) es una solución grande y genérica. Cuando el problema es chico y la solución es grande, la desconfianza que sentís está bien fundada — no es que "no le encontrás la vuelta", es que el tamaño no cierra.