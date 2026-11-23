# Resumen de GUIA.md

Basada en **ADR** (una decisión = un doc corto, inmutable) y **Diataxis** (separar por propósito: Reference, Explanation, How-to, Tutorial).

## Estructura

Primero **módulo de negocio** (mismos nombres que `Negocio/<Modulo>/`: soporte, cartera, credito, contabilidad, crm...), dentro una carpeta por feature. Lo que no encaja en un módulo (MCP, scripts) va suelto en la raíz.

```
notas-siian/
  README.md            ← índice raíz
  GUIA.md
  conceptos/           ← Explanation transversal
  mcp-postgres/        ← tooling
  <modulo>/
    README.md          ← 1 fila por feature
    <feature>/
      README.md
      REQUERIMIENTO.md
      ANALISIS.md      (opcional, ANTES de programar)
      ADR.md           (opcional)
      PLAN.md          (opcional)
      IMPLEMENTACION.md
      EXPLICACION.md   (opcional)
```

## Flujo

`REQUERIMIENTO` → `ANALISIS` (si aplica) → `ADR` y/o `PLAN` → `IMPLEMENTACION` → `EXPLICACION` (opcional).
Solo `REQUERIMIENTO.md` se crea de entrada.

## Qué doc usar

| Si... | Usa |
|---|---|
| Cambio de 1 método/query obvio | Ninguno, alcanza el commit |
| Hubo indagación real | `REQUERIMIENTO.md` |
| Entidad con estados/transiciones o reglas cruzadas | `ANALISIS.md` (antes de código) |
| Se decidió entre 2+ enfoques | `ADR.md` |
| Trabajo por fases, alguien podría retomarlo | `PLAN.md` |
| Ya construido, mapa de archivos/métodos | `IMPLEMENTACION.md` |
| Panorama para no técnicos | `EXPLICACION.md` |
| Concepto que aplica a varias features | `conceptos/` |

## Reglas de contenido

- `REQUERIMIENTO` y `PLAN`: términos de negocio/flujo, **sin** nombres de clase/archivo/método/endpoint. Si los escribes en un PLAN, ya estás implementando: pásalo a `IMPLEMENTACION.md`.
- `IMPLEMENTACION.md`: único doc en términos de código; se actualiza (refleja el código actual).
- `ADR.md`: historia, no se reescribe; un cambio = ADR nuevo que "supersede a X".
- Scripts SQL: se enlazan (ruta en `DataGripProjects/fix-soporte-tickets/entregables/...`), no se copian.
- Carpetas en `kebab-case`, cortas, sin fecha.
- Un `README.md` por feature y por módulo: tabla de 1 fila por doc/feature.
- Antes de crear feature nueva, revisar si ya existe una relacionada en el módulo.

## Cómo se hace un ANALISIS.md

Idea de Event Storming + diagramas de estados UML, sin talleres. **Iterativo**: el diagrama es la herramienta de análisis, no el resultado; cada flecha faltante es un hallazgo o pregunta.

Secciones:
1. **Diagrama de estados**: Mermaid `stateDiagram-v2`, etiquetas cortas, detalle en tabla debajo.
2. **Diagrama de dependencias**: quién llama a quién, mismo criterio.
3. **Hallazgos** (H1, H2...): uno por problema, con evidencia (archivo:línea o síntoma).
4. **Reglas a confirmar / preguntas abiertas**: en términos de negocio, se resuelven antes del ADR/PLAN.

No hace falta para cambios de 1 método sin estados ni reglas cruzadas.

## Migrar docs viejos

Solo cuando se toque de nuevo: ahí se le crea su carpeta dentro del módulo.

## Rastrear cambios

Sin fechas manuales, se usa git:
```
git log --oneline -10
git status
git log -1 --stat <ruta>
git log --oneline --diff-filter=A --name-only -- <modulo>/ | grep README.md
```

## Chequeo de sincronización

Antes de cerrar una feature, verificar que está en el `README.md` del módulo (y este en el raíz):
```
diff <(ls -d <modulo>/*/ | xargs -n1 basename) <(grep -oP '\[\K[a-z-]+(?=\])' <modulo>/README.md)
```
Sin salida = sincronizado.
