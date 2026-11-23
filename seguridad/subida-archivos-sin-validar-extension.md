# Hallazgo de seguridad: subida de archivos sin validar extensión

**Estado:** sin corregir, documentado para decidir. No se aplicó ningún cambio de código ni de configuración. No se ejecutó ninguna subida de prueba contra el servidor.

**Cómo se encontró:** investigando la skill de Claude Code `owasp-security` (https://github.com/agamm/claude-code-owasp, no instalada en el proyecto) se siguió su flujo de revisión a mano sobre los controladores de subida de archivos de SIIAN.

## El problema

Varios flujos de subida de archivos guardan el archivo con la extensión que manda el cliente, dentro de `~/Uploads/...`, una carpeta del propio sitio web. Nada en la configuración de IIS impide que ASP.NET ejecute un `.aspx` dejado ahí.

Confirmado por lectura de `PruebaPostgreSQL/Web.config` (sin ejecutar nada):
- No se quita el handler de páginas ASP.NET (`PageHandlerFactory`) en ningún punto del archivo.
- `requestFiltering` solo limita tamaño de contenido (`maxAllowedContentLength`), no bloquea extensiones.
- `Uploads/` no tiene su propio `web.config`.

Eso es el comportamiento por defecto de IIS/ASP.NET: sin una excepción explícita, cualquier `.aspx` dentro del sitio se ejecuta como página, en cualquier carpeta.

## Cadena de explotación

1. Cuenta válida con acceso a una pantalla de subida vulnerable (ver tabla). **No se verificó qué roles llegan a esas pantallas.**
2. Sube un archivo `.aspx` con código.
3. El endpoint no valida extensión, así que se guarda tal cual.
4. Sin `web.config` en `Uploads`, IIS lo ejecuta al abrir su URL.
5. El código corre con la identidad del pool de aplicaciones: puede leer `Web.config` (cadena de conexión, claves JWT) y la base de datos.

Es explotable en teoría; falta confirmar el punto 1 (alcance real por rol) y, si se decide probar, hacerlo con autorización explícita en el servidor de pruebas (no en producción).

Variante menor: en PQRS el nombre de archivo del cliente entra directo a `Path.Combine`, lo que abre además un path traversal (`..\..\..\x`).

## Resultado por flujo (revisados 5 de ~40 puntos de subida del repo)

| Flujo | Archivo | Estado | Detalle |
|---|---|---|---|
| Documento equivalente/contable | `Negocio/Contabilidad/DocumentoContableArchivoActorNegocio.cs:144` | Bien | Valida con `ValidarArchivoConTiposPermitidos` (lista blanca por tipo), nombra con Guid |
| Soporte | `Negocio/Soporte/SoporteArchivosActorNegocio.cs:262-273` | Bien | Lista blanca, tamaño máximo, Guid. Es el mejor modelo del repo |
| Crédito (ruta validada) | `Negocio/Credito/CargaArchivosActorNegocio.cs:~408` | Bien | Lista blanca `.docx .xlsx .txt .pdf .jpg .jpeg` |
| Crédito (otras rutas) | `DocumentoCreditoHelper.cs:255`, `SubirArchivoMovilCarpetaVirtual` | Por verificar | Llaman a la subida de bajo nivel sin validación propia; falta confirmar si validan antes |
| Gestión | `Negocio/Generales/ArchivoGestionActorNegocio.cs:41-44, 100-105` | **Probable problema** | Nombre con Guid, pero la extensión viene del cliente sin lista blanca |
| PQRS CRM | `PruebaPostgreSQL/Controllers/WebApi/PQRSArchivoCRMWebApiController.cs:123-130` | **Probable problema** | Sin validar extensión, nombre del cliente en la ruta (path traversal) |

Quedan sin revisar el resto de los puntos de subida listados por `rg` (ArchivoPlano*, Pagare, Garantías, Inventario, Planeación, etc.).

## Arreglo propuesto (no aplicado)

**1. Bloquear ejecución en `Uploads/` — un solo archivo, protege todos los flujos a la vez:**

```xml
<!-- PruebaPostgreSQL/Uploads/web.config (no existe hoy) -->
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <clear />
      <add name="SoloEstaticos" path="*" verb="GET,HEAD" modules="StaticFileModule"
           resourceType="File" requireAccess="Read" />
    </handlers>
  </system.webServer>
</configuration>
```
Efecto: dentro de `Uploads/` y subcarpetas, todo archivo se sirve como descarga estática, nunca como página ejecutable.

**2. Validar extensión + nombre con Guid en los flujos probables (PQRS, Gestión)**, copiando el patrón de Soporte:
```csharp
var extension = Path.GetExtension(nombreCliente)?.ToLower();
if (string.IsNullOrEmpty(extension) || !ExtensionesPermitidas.Contains(extension))
    throw new Exception("Tipo de archivo no permitido.");
var nombreArchivo = $"{Guid.NewGuid():N}{extension}";   // nunca el nombre del cliente
```

**3. A mediano plazo:** centralizar la regla de validación en un solo método de `Negocio/Generales`, para que el próximo flujo de subida no repita el hueco.

## Próximo paso

Antes de aplicar nada: decidir si se prueba en el servidor de pruebas (25.44.200.158/rep1) y con qué autorización. El fix 1 es de bajo riesgo (un archivo nuevo, no toca código existente); el fix 2 toca controladores en producción y requiere pruebas manuales normales del flujo de subida/descarga.
