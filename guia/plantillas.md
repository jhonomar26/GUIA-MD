# Plantillas: el generador WFAGenerarDao

Cuando cambiamos la base de datos, **regeneramos las plantillas y pegamos lo que sirve**. No todo sirve tal cual: parte se adapta a mano. Aun así ahorra mucho código, y es la forma más rápida de encontrar lo que falta (columna nueva, FK, estáticos).

## Dónde está

| Qué | Ruta |
|---|---|
| Proyecto | `D:\plantillas\WFAGenerarDao\` |
| Configuración del generador (conexiones, salida, namespaces) | `D:\plantillas\WFAGenerarDao\GeneralDao.cs` |
| Plantillas (una clase por archivo generado) | `D:\plantillas\WFAGenerarDao\GeneracionPlantillas\` |
| Ejecutable | `D:\plantillas\WFAGenerarDao\bin\Debug\WFAGenerarDao.exe` |
| Salida por defecto | `D:\Dao` |

## `GeneralDao.cs`: lo que hay que mirar antes de generar

- **`connectionStringDBReal`** apunta a una base concreta (hoy `demo-25-09-2026`). El generador lee el esquema de **esa** base: si la columna nueva no existe ahí, no sale en lo generado. Se cambia con `--db-real` o editando el archivo.
- **`connectionString`** (base `configuraciones`) guarda la configuración por tabla. El comando `config` **escribe** ahí; ver advertencia abajo.
- **`directorio`** = `D:\Dao`: donde cae lo generado. Nunca apuntarlo al repo.
- **`EspacioNombresMVC`**, **`EspacionNombresPrincipal`** y **`NombrePKIncremental`** definen namespaces y la PK que asumen las plantillas.
- **`ObtenerConexionPorEsquema`**: el esquema `cierre` genera `GeneralDao.ConnectionCierre`; el resto `GeneralDao.Connection`.

## Qué pegar y qué adaptar

| Archivo generado | ¿Se pega? |
|---|---|
| `{Entidad}.cs` y `{Entidad}Actor.cs` | Sí, completos (se pierden los comentarios: reponerlos si valen) |
| `{Entidad}ViewModel.cs` | **No**: se difea y se parchea (reordena el ctor y borra `[Display]`, validaciones y proyecciones) |
| `{Entidad}Controller.cs`, `WebApiController`, vistas | **No**: son stubs; sirven de referencia |
| `{Entidad}ActorNegocio.cs` | No se genera: es 100% manual |

Siempre generar a un directorio temporal y comparar con `diff --strip-trailing-cr -u` (el generador escribe CRLF).

## Comandos

```
WFAGenerarDao.exe dapper --tabla <tabla> --salida <dir temporal>
```

`listar`, `config`, `entidad`, `dapper`, `mvc`, `todo`. `config` escribe en la BD `configuraciones`: correrlo **sin** `--borrar-campos` o se pierden los nombres de ViewModel ajustados a mano.

## Detalle completo

Protocolo para agregar/quitar/renombrar una columna, regla del constructor posicional y verificador de constructores: skill `siian-plantillas-generadas` (`.claude/skills/siian-plantillas-generadas/SKILL.md` en el repo SIIAN).
