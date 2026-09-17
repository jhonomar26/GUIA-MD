# Patrón FK lazy-load en entidades (Blip.Data)

## Qué es

Cada entidad en `Blip.Data/{Modulo}/{Entidad}.cs` resuelve sus FK mediante propiedades
lazy en vez de EF navigation properties o JOIN manual. Al primer acceso, la propiedad
llama al `Actor.ObtenerPorIdSinVerificarExistencia(...)` de la tabla referenciada,
cachea el resultado en un campo privado, y en accesos siguientes no repite el query.

## Convención de nombres

Por cada columna `Id*` que sea FK, la entidad expone una propiedad:

```
{TablaDestino}_{tablaOrigen}{NombreColumna}
```

Ejemplo real en `Blip.Data/Soporte/SoporteArchivos.cs`:

```csharp
public int? Idmensaje { get; set; }
public int? Idmensajeraiz { get; set; }
public int? Idautorcliente { get; set; }
public int Idgestion { get; set; }

private SoporteMensajes soporte_soportemensajesIdmensaje;
public SoporteMensajes Soporte_soportemensajesIdmensaje
{
    get
    {
        if (soporte_soportemensajesIdmensaje != null)
            return soporte_soportemensajesIdmensaje;
        else soporte_soportemensajesIdmensaje = SoporteMensajesActor.ObtenerPorIdSinVerificarExistencia(Idmensaje ?? 0);
        return soporte_soportemensajesIdmensaje;
    }
}
```

Mapeo de columnas → propiedad en esta entidad:
- `Idmensaje` → `Soporte_soportemensajesIdmensaje` (trae el `SoporteMensajes`)
- `Idmensajeraiz` → `Soporte_soportemensajesIdmensajeraiz` (trae el mensaje raíz del hilo)
- `Idautorcliente` → `Soporte_soporteusuariosistemaIdautorcliente` (trae el `SoporteUsuarioSistema`)
- `Idgestion` → `Crm_gestionmaestrocrmIdgestion` (trae el ticket)

`ObtenerPorIdSinVerificarExistencia` retorna `null` si el registro no existe (por eso
siempre se navega con `?.` — evita excepción si el usuario/tercero fue borrado).

## Cómo se usa (encadenado)

Cada entidad referenciada puede a su vez tener sus propias FK lazy. Se pueden encadenar:

```csharp
var archivo = SoporteArchivosActor.ObtenerPorId(idArchivo);

var nombre = archivo
    .Soporte_soporteusuariosistemaIdautorcliente   // 1er query: SoporteUsuarioSistemaActor
    ?.Terceros_terceromaestroIdtercero              // 2do query: TerceroMaestroActor
    ?.Nombreunido;
```

Equivale a esto, pero sin escribirlo a mano:

```csharp
var archivo = SoporteArchivosActor.ObtenerPorId(idArchivo);
var usuarioSistema = SoporteUsuarioSistemaActor.ObtenerPorIdSinVerificarExistencia(archivo.Idautorcliente ?? 0);
var tercero = usuarioSistema != null
    ? TerceroMaestroActor.ObtenerPorIdSinVerificarExistencia(usuarioSistema.Idtercero)
    : null;
var nombre = tercero?.Nombreunido;
```

Uso real en `PruebaPostgreSQL/Controllers/WebApi/SoporteArchivosWebApiController.cs`
(método `SubirArchivo`):

```csharp
var nombreAutor = resultado.Idautorcliente.HasValue
    ? resultado.Soporte_soporteusuariosistemaIdautorcliente?.Terceros_terceromaestroIdtercero?.Nombreunido
    : resultado.AspNetUsersIdautorsoporte?.UserName;
```

## Cuándo usarlo vs. cuándo no

**Sí usarlo:** ya tienes la entidad cargada (un solo registro) y necesitas 1-2 datos de
una FK puntual. Ejemplo: mostrar el nombre del autor de un archivo recién subido.

**No usarlo:** vas a recorrer una lista de N registros y accedes a la FK de cada uno →
problema N+1 queries. En ese caso usar un JOIN explícito en el SQL del Actor.

Ejemplo de la alternativa correcta para listas, ya existente en el proyecto:
`SoporteArchivosActor.ObtenerListaConNombreAutorPorIdgestion` — trae el nombre del autor
con un solo JOIN en la query, en vez de lazy-load por cada fila.

## Cómo identificar la propiedad correcta

Abrir el `.cs` de la entidad en `Blip.Data/{Modulo}/`. El bloque de propiedades lazy
está siempre justo después de las columnas planas (`public int Id { get; set; }`, etc.)
y antes de los campos estáticos (`NombreTabla`, `XxxCampo`, `XxxTipo`).
