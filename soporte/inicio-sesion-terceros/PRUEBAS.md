# Pruebas: inicio de sesión de terceros

Lista para repetir las pruebas de las tareas 2, 3 y 4 en demo. La evidencia final va en `IMPLEMENTACION.md → ## Verificación`. Aquí solo se marca el resultado.

**Cómo marcar:** ⬜ sin probar · ✅ pasó (fecha) · ❌ falló (anota qué respondió).

## 0. Preparación

- Backend nuevo desplegado en `http://localhost/soporte-tickets` y `pnpm dev` en `portal-siian` (rama `feature/login-usuario-soporte`).
- Postman: `POST /api/portal/auth/registro` y `POST /api/portal/auth/login`. Contraseña común de prueba: la que ya dejaste en las cuentas.
- Cada caso que escribe datos deja su **limpieza** al final del bloque. Corré la limpieza antes del siguiente caso.

Consulta útil para ver el estado de una persona (cambiar `@persona`):

```sql
SELECT c.id AS contacto, c.idtercero AS empresa, c.esactivo, lower(trim(c.email)) AS correo,
       (SELECT string_agg(s.id || ':' || coalesce(s.idempresa::text, 'NULL') || ':' || coalesce(s.email, ''), ' | ')
          FROM soporte_soporteusuariosistema s WHERE s.idtercero = c.idtercerocontacto) AS cuentas
  FROM terceros_tercerocontacto c
 WHERE c.idtercerocontacto = @persona
 ORDER BY c.idtercero, c.id;
```

## 1. Registro (Tarea 2)

| #   | Dado / Cuando / Entonces                                                                                       | Datos demo                                              | Resultado    |
| --- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | ------------ |
| R1  | Contacto activo sin cuenta se registra → 200 y la cuenta queda con la empresa del contacto                     | `1045699610` / `vkana@hotmail.com` → `idempresa` 222    | ✅ 2026-10-10 |
| R2  | Misma persona en dos empresas, un correo por empresa → dos registros, dos cuentas                              | Preparar con el SQL de abajo                            | listo        |
| R3a | Correo que no es de ningún contacto activo → 400 `MSG_SIN_CONTACTO`                                            | `1045699610` / `noexiste@x.co`                          | ✅ 2026-10-10 |
| R3b | Documento de otra persona con un correo válido → 400 `MSG_SIN_CONTACTO` (mismo mensaje, no revela de quién es) | `37080816` / `vkana@hotmail.com`                        | ✅ 2026-10-10 |
| R4  | Correo con mayúsculas o espacios en el contacto (`" A@X.co "`), registro con `a@x.co` → 200                    | Preparar con el SQL de abajo                            | ✅ 2026-10-13 |
| R5  | Cuenta vieja con `idempresa` NULL → 400 `MSG_PENDIENTE_REGISTRO` y no se crea otra cuenta                      | Preparar con el SQL de abajo                            | listo        |
| R6a | Repetir R1 → 400 `MSG_YA_TIENE_CUENTA`                                                                         | Repetir R1                                              | ✅ 2026-10-10 |
| R6b | Persona con cuenta en su empresa → 400 `MSG_YA_TIENE_CUENTA`                                                   | `37080816` / `info@siian.com.co` (cuenta 19, empresa 1) | ✅ 2026-10-10 |
| R7a | Correo activo en dos contactos distintos → 400 `MSG_CORREO_AMBIGUO`                                            | `901260005` / `hernanbolanos@siian.com.co`              | ✅ 2026-10-10 |
| R7b | Dos filas de la **misma** persona y empresa con el mismo correo → 200 (no es ambiguo)                          | Preparar con el SQL de abajo                            | ⬜            |

Limpieza de R1: `DELETE FROM soporte_soporteusuariosistema WHERE idtercero = 223;`

Preparación (adaptar los ids a la persona de prueba):

```sql
-- R2: persona X con un contacto en otra empresa, otro correo
INSERT INTO terceros_tercerocontacto (...) VALUES (...);   -- completar columnas obligatorias de la tabla
-- R4: correo con mayúsculas y espacios
UPDATE terceros_tercerocontacto SET email = ' A@X.co ' WHERE id = @contacto;
-- R5: cuenta sin empresa
UPDATE soporte_soporteusuariosistema SET idempresa = NULL WHERE id = @cuenta;
-- R7b: segunda fila igual (misma persona, misma empresa, mismo correo)
INSERT INTO terceros_tercerocontacto (...) VALUES (...);
```

Limpieza: devolver el valor original del `UPDATE` y borrar las filas insertadas.

## 2. Login, token y avisos (Tarea 3)

| #   | Dado / Cuando / Entonces                                                                                                                                                                                                                                                                                                                                                                                     | Resultado |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| L1  | Cuenta de R4, login con `a@x.co` → 200 con token                                                                                                                                                                                                                                                                                                                                                             | ✅ 2026-10-13 |
| L2  | Contraseña mal → 401 "Credenciales incorrectas" (también con el contacto inactivo: el 401 va antes que `MSG_SIN_ACCESO`)                                                                                                                                                                                                                                                                                     | x         |
| L3  | Cuenta con `idempresa` NULL cuya persona es contacto activo de **una** empresa, login con su correo → 200; en SQL `idempresa` = esa empresa y los mismos tickets                                                                                                                                                                                                                                             | x         |
| L4a | Cuenta con `idempresa` NULL, correo que no es de ningún contacto activo → 403 `MSG_PENDIENTE_LOGIN`; `idempresa` sigue NULL                                                                                                                                                                                                                                                                                  | ✅ 2026-10-13 |
| L4b | Persona contacto de dos empresas con cuenta NULL, entra con el correo de una → 200 y la cuenta queda en esa empresa                                                                                                                                                                                                                                                                                          | ✅ 2026-10-13 |
| L5  | Se cambia el correo de la fila a `c@x.co` en el grid: login con `c@x.co` → 200 (y `email` de la cuenta = `c@x.co`); con `a@x.co` → 401                                                                                                                                                                                                                                                                       | ✅ 2026-10-13 |
| L6  | Fila nueva con `c@x.co` y se inactiva la de `a@x.co`: login con `c@x.co` → 200; con `a@x.co` → 401                                                                                                                                                                                                                                                                                                           | x         |
| L7  | Con token vigente se inactiva la fila: `GET` de tickets → 401 y el chat no reconecta. Se reactiva: el mismo token vuelve a servir. Se borra y se recrea la fila (misma empresa, mismo doc): login 200, misma cuenta (mismo `id`)                                                                                                                                                                             | X         |
| L8  | Fila inactiva, login con su último correo y contraseña bien → 403 `MSG_SIN_ACCESO`; con contraseña mal → 401                                                                                                                                                                                                                                                                                                 | X         |
| L9a | Correo activo en dos contactos distintos → login 403 `MSG_CORREO_AMBIGUO`                                                                                                                                                                                                                                                                                                                                    | x         |
| L9b | Correo en dos filas de la misma persona y empresa → 200                                                                                                                                                                                                                                                                                                                                                      | ✅ 2026-10-13 |
| L10 | Fila de A inactiva con `x@` y fila de B activa con `x@`: login `x@` con la contraseña de B → cuenta de B                                                                                                                                                                                                                                                                                                     | ✅ 2026-10-13 |
| L11 | Cuenta con empresa cuya persona ya no es contacto de ella, pero sí de otra: 403 `MSG_SIN_ACCESO` y `idempresa` no cambia. Se vuelve a cargar como contacto de su empresa: 200 con sus tickets de antes                                                                                                                                                                                                       | ✅ 2026-10-13 |
| L12 | Persona con cuentas en dos empresas: un cambio de estado de un ticket de la empresa B notifica solo al correo de B. Con su fila inactiva, no notifica. Si el contacto activo no tiene correo escrito, tampoco (no cae al último correo guardado en la cuenta)                                                                                                                                                | ⬜         |
| L13 | Compañero con la fila inactiva: no aparece en los destinos de reasignación                                                                                                                                                                                                                                                                                                                                   | ✅ 2026-10-13 |
| L14 | Tickets de cuentas suspendidas siguen en `crm_gestionmaestrocrm` (`count(*)` igual antes y después)                                                                                                                                                                                                                                                                                                          | ✅ 2026-10-13 |
| L15 | Con sesión abierta, otro contacto activo recibe el mismo correo del token: la siguiente petición → 401, vuelve a `/login`, y el login con ese correo da 403 `MSG_CORREO_AMBIGUO` hasta que soporte lo corrija                                                                                                                                                                                                | ✅ 2026-10-13 |
| L16 | Con sesión abierta (entró con `a@x.co`), soporte cambia el correo del contacto a `c@x.co` en el grid: la siguiente petición (ver tickets, **crear ticket**, chat) → 401 y vuelve a `/login`. Login con `a@x.co` → 401; con `c@x.co` → 200                                                                                                                                                                    | ✅ 2026-10-13 |
| L17 | Misma persona y misma empresa con **dos filas activas y correos distintos** (demo: persona 190, `jhonomar1@gmail.com` y `jhonomar109@gmail.com`, cuenta 22): login con cada correo → 200 y la misma cuenta (mismo `id`). Recuperar contraseña y avisos de ticket van al correo de la fila activa más reciente. Se inactiva una fila: ese correo → 401 (también con sesión abierta) y el otro sigue entrando | ✅ 2026-10-13 |

Consulta para L14:

```sql
SELECT count(*) FROM crm_gestionmaestrocrm WHERE idportalusuario IS NOT NULL;
```

## 3. Front (Tarea 4)

| # | Qué se prueba | Resultado |
|---|---|---|
| F1 | Registro pide solo documento, correo y contraseña (sin select de empresa) | ✅ 2026-10-13 |
| F2 | Login entra directo a `/tickets` | ✅ 2026-10-13 |
| F3 | Cuenta pendiente, suspendida o con correo ambiguo: el alert muestra `MSG_PENDIENTE_LOGIN` / `MSG_SIN_ACCESO` / `MSG_CORREO_AMBIGUO` | ✅ 2026-10-13 |
| F4 | Con sesión abierta se inactiva la fila en SIIAN y se navega: vuelve a `/login` | ✅ 2026-10-13 |
| F5 | Igual que F4 pero poniendo el mismo correo en otro contacto activo (L15): vuelve a `/login` | ✅ 2026-10-13 |
| F6 | Con sesión abierta se cambia el correo del contacto: al crear un ticket o navegar vuelve a `/login` (L16) | ✅ 2026-10-13 |

## 4. Antes de dar la tarea por cerrada

- [ ] Todos los casos en ✅ o con el fallo anotado.
- [ ] Datos de demo devueltos a su estado original.
- [x] Evidencia (respuestas de Postman y resultados de SQL) pasada a `IMPLEMENTACION.md → ## Verificación`.
- [ ] Pasos tildados en `PLAN.md`.

## 5. Evidencia de la corrida del 2026-10-13

Corrida en demo (backend `http://25.44.200.158/soporte-tickets`, portal `http://localhost:5173/portal/#/login`), persona 190 (cuentas 22 y 25). Contraseña de prueba común.

| # | Qué se hizo | Resultado observado |
|---|---|---|
| L4b | Login de la cuenta 25 (`idempresa` NULL) con `jhonomar1@gmail.com`, contacto activo de la empresa 46 | 200; en BD la cuenta 25 pasó a `idempresa` 46 |
| L5 | Fila 23: correo `jhonomar1@` → `jhonomar1x@` en el grid | Nuevo correo 200 (cuenta 25, `email` actualizado); viejo 401 |
| L9b | Filas 23 y 29 (misma persona y empresa) con el mismo correo | 200, cuenta 25 |
| L10 | Contacto 1 (persona 7) inactivo con `sacosta.acosta@`; fila 29 (persona 190) activa con ese correo | 200, entra a la cuenta 25, no a la 19 (también desde la interfaz) |
| L11 | Filas 23 y 29 (empresa 46) inactivas; persona 190 sigue activa en empresas 1 y 49. Después se reactiva la 23 | 403 `MSG_SIN_ACCESO`, `idempresa` sigue en 46; reactivada: 200, misma cuenta 25. Los "tickets de antes" no se verificaron: la cuenta 25 tiene 0 |
| L15 | Sesión abierta en el portal; el contacto 1 recibe el mismo correo activo | "Nuevo Ticket" saca a `/login`; login por API 403 `MSG_CORREO_AMBIGUO`; el alert del portal muestra el mismo texto |
| L16 | Token vigente; cambio del correo de la fila 23 en SIIAN | GET tickets y POST ticket con el token viejo → 401; correo viejo 401, nuevo 200. En el portal (F6): vuelve a `/login` |
| L17 | Filas 23 y 29 activas con correos distintos; luego se inactiva la 29 | Ambos correos 200 y misma cuenta 25. El correo vigente de la cuenta es el de la fila activa con mayor `id`. Inactiva: su token y su login 401, el otro 200 |
| F2 | Login desde la interfaz del portal | Entra directo a `/tickets` |
| R4 | Persona 264 (doc 12993285), contacto 8 guardado como ` Tes.R4@X.co ` (espacios y mayúsculas); registro con `tes.r4@x.co` | 200; se creó la cuenta 26 (empresa 210, `email` = `tes.r4@x.co`) |
| L1 | Login de la cuenta 26 con `tes.r4@x.co` | 200 con token, cuenta 26, empresa 210 |
| L4a | Cuenta 6 (`idempresa` NULL, correo `wilsonagc@gmail.com` sin contacto), login por API y por el portal | 403 `MSG_PENDIENTE_LOGIN`; `idempresa` sigue NULL; el alert del portal muestra el texto |
| L13 | Cuenta 22 lista los destinos de reasignación del ticket 137 (empresa 1); se inactiva el contacto 17 (cuenta 4) | Antes: cuentas 19 y 4. Después: solo la 19. La cuenta 23 (sin contacto) no aparece en ningún caso |
| L14 | Contacto 16 (cuenta 13, 15 tickets) inactivo; conteo de `crm_gestionmaestrocrm` con `idportalusuario` | 72 en total y 15 de la cuenta 13, igual antes y después |
| L8 | Contacto 16 inactivo: login con su correo (cuenta 13) con contraseña buena y mala | 403 `MSG_SIN_ACCESO` y 401 |
| F1 | Pantalla de registro del portal | Pide Identificación, Correo, Contraseña y Confirmar contraseña; sin select de empresa |
| F3 | Alerts en el portal: cuenta pendiente (cuenta 6), suspendida (contacto 16 inactivo) y correo ambiguo | Muestran `MSG_PENDIENTE_LOGIN`, `MSG_SIN_ACCESO` y `MSG_CORREO_AMBIGUO` |
| F4 | Sesión abierta con la cuenta 13; se inactiva su contacto 16 en SIIAN; en el portal se pulsa "Nuevo Ticket" | Vuelve a `/login` |

**No cubierto en esta corrida:** envío real de correos (recuperación y avisos de L12/L17: solo se comprobó a qué dirección apuntan); el chat (SignalR) de L16; el 401 en la red de F5/F6 (se dedujo del redirect).

### Hallazgos

1. **Correo repetido entre empresas de la misma persona:** si el mismo correo está activo en dos empresas, el login da 403 `MSG_CORREO_AMBIGUO` aunque sea la misma persona (concuerda con R-C, pero ninguna prueba lo describía).
2. **Guardar en SIIAN falla en demo:** `ERROR: 42703: no existe la columna terceros_telefono.prefijo`. Los contactos sí se guardan antes del error, pero la pantalla lo muestra. Ajeno a esta funcionalidad.
3. L17 decía `jhonomar10@gmail.com`; corregido a `jhonomar1@gmail.com`.

### Datos de demo de esta corrida (no se devolvieron; es un entorno de pruebas)

- Persona 190 (1193419521): fila 23 `jhonomar1@gmail.com` activa; fila 29 `jhonomar109@gmail.com` **inactiva** (original: activa); cuenta 25 en empresa 46 (original: NULL). Los logins de `jhonomar1` y `jhonomar109` funcionan.
- Contacto 1 (persona 7, empresa 1): `sacosta.otro@gmail.com`, activo (original: `sacosta.acosta@gmail.com`, inactivo).
- Contacto 8 (persona 264): ` Tes.R4@X.co ` (original: `tesoreria@confiamoscolombia.com`). Cuenta 26 creada por R4.
- Contacto 10 (persona 214): ` Jh.R4@X.co ` (original: `jhonomar101@gmail.com`). Persona 214 autorizada en `soporte_soporteportalautorizacion` (id 40, nueva).
