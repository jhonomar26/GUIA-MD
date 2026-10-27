# Mantenimiento de las notas

> Migrar docs viejos, rastrear cambios y chequear tablas. · [← Volver a la guía](../GUIA.md)

## Cuándo migrar un doc viejo

No hace falta reorganizar todo de una — cuando se toque un doc suelto de nuevo (nueva
fase, nueva decisión), se le crea su carpeta (dentro del módulo que corresponda) en ese
momento siguiendo esta guía.

**Cambio de convención (2026-10-05):** antes `PLAN.md` era de negocio y `TAREAS.md` el plan
técnico. Ahora `PLAN.md` es el técnico y lo de negocio va en `ANALISIS.md`. En features
viejas: el `PLAN.md` de negocio pasa a `ANALISIS.md` y el `TAREAS.md` se renombra `PLAN.md`,
pero solo cuando se vuelva a tocar la feature.

## Rastrear cambios / qué es lo más reciente

No se guarda fecha manual en los docs — se usa git:
```
git log --oneline -10                                   # últimos commits
git status                                               # qué está sin commitear todavía
git log -1 --stat <ruta>                                 # qué tocó el último commit de un doc puntual
git log --oneline --diff-filter=A --name-only -- <modulo>/ | grep README.md   # orden real de creación de features
```

## Chequeo de sincronización de tablas

Antes de cerrar una feature, verificar que la carpeta quedó reflejada en el `README.md`
del módulo (o del área, si la hay) y ese, a su vez, en el `README.md` raíz — es fácil crear la
carpeta y olvidar la fila. El comando ordena ambos lados, acepta mayúsculas y números, y solo cuenta enlaces a carpetas (`[nombre](./nombre/)`):
```
diff <(ls -d <modulo>/*/ | xargs -n1 basename | sort) <(grep -oP '\[\K[A-Za-z0-9_-]+(?=\]\(\./[^)/]+/\))' <modulo>/README.md | sort)
```
Con área, se corre una vez por el módulo (filas = áreas) y otra por el área
(`<modulo>/<area>/` contra `<modulo>/<area>/README.md`). Si no imprime nada, están sincronizados.
Con pocas features alcanza revisarlo a ojo; si el módulo crece, correrlo antes de cada cierre.
