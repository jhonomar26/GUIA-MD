# Arquitectura general — Portal de Soporte (cliente)

Documentación de cómo está armado el proyecto: capas, flujo de datos, convenciones. Para el detalle de una funcionalidad puntual ver los otros docs de esta carpeta (ej. `drag-drop-archivos.md`).

## Qué es

Frontend del **portal de soporte para clientes finales** de SIIAN (no confundir con el backoffice de agentes). Los clientes ven y crean tickets, chatean con soporte, califican el servicio. Habla con el backend SIIAN vía REST + tiempo real (SignalR).

## 1. Arranque de la app

```
main.jsx
  → MantineProvider (tema UI global)
    → Notifications (toasts globales de Mantine)
      → AuthProvider (contexto de sesión)
        → App.jsx (rutas)
```

`main.jsx` también configura DevExtreme (licencia, idioma español) una sola vez al inicio, antes de montar React.

## 2. Ruteo (`src/App.jsx`)

`HashRouter` (rutas tipo `#/tickets`, no rutas "limpias") — el portal se sirve embebido bajo `/portal/` del backend .NET (`base: '/portal/'` en `vite.config.js`), un `HashRouter` evita configurar rewrites de servidor para rutas SPA.

Dos grupos:

| Grupo | Rutas | Acceso |
|---|---|---|
| Públicas | `/login`, `/registro`, `/recuperar`, `/recuperar/nueva` | Sin sesión |
| Privadas | `/tickets`, `/tickets/nuevo`, `/tickets/:id` | Envueltas en `<PrivateRoute>` |

`PrivateRoute` (`src/components/PrivateRoute.jsx`): si hay `token` en el contexto de auth renderiza los hijos, si no redirige a `/login`. Es todo el "cerrojo" de la app.

## 3. Autenticación

`src/context/AuthContext.jsx` es el **único estado verdaderamente global** de la app — no hay Redux/Zustand ni librería de estado. Guarda `token` + `usuario`, sincronizados con `localStorage` para sobrevivir refrescos de página.

Cómo se desloguea automáticamente (patrón no obvio):

1. `src/api/client.js` es la instancia de axios compartida por toda la app. Interceptor de **request**: mete `Bearer token` en cada llamada, leyendo `localStorage` directo (sin pasar por React).
2. Interceptor de **response**: si cualquier llamada devuelve 401, dispara un evento del navegador — `window.dispatchEvent(new Event('auth:logout'))` — en vez de llamar `cerrarSesion()` directamente.
3. `AuthContext` escucha ese evento (`window.addEventListener('auth:logout', ...)`) y ahí limpia la sesión.

**Por qué el rodeo:** `client.js` es un módulo plano de axios que vive fuera del árbol de React — no puede "ver" el contexto. El evento de `window` es el puente entre el mundo de axios (fuera de React) y el mundo de React (el contexto).

## 4. Capa de API (`src/api/`)

Un archivo por dominio: `auth.js`, `tickets.js`, `client.js` (la instancia base). Son funciones planas que envuelven `client.get/post/...` y devuelven `.data`. No hay React Query, SWR ni nada que cachee o gestione loading por ti.

Consecuencia directa: **cada página/hook maneja su propio loading/error a mano** con `useState` + `useEffect`, llamando estas funciones directo. "Refrescar datos tras una acción" hay que cablearlo manualmente cada vez (patrón `refetch` expuesto por el hook de la página, ver `DetalleTicket/hooks/useTicketDetail.ts`) — no viene gratis de una librería.

## 5. Estructura de una página

```
src/pages/<Nombre>/
  <Nombre>.tsx        ← componente de página: compone hooks + componentes chicos, casi sin lógica propia
  index.ts             ← re-exporta el default (para importar como carpeta)
  hooks/                ← hooks EXCLUSIVOS de esa página (fetch, lógica de esa pantalla)
  components/           ← piezas de UI EXCLUSIVAS de esa página
```

Regla no escrita (se respeta): **si algo se usa en más de una página, sube de nivel**:

| Carpeta | Contiene |
|---|---|
| `src/components/` | Componentes genéricos usados por varias páginas (`AppNavbar`, `PrivateRoute`, `ModalCalificacion`) |
| `src/shared/types/` | Interfaces TypeScript compartidas — fuente única de verdad, las páginas re-exportan en vez de redefinir |
| `src/shared/helpers/` | Funciones puras de formateo/normalización |
| `src/shared/constants/` | Colores, tamaños, constantes de UI |
| `src/shared/components/` | UI genérica reusable |
| `src/hooks/` | Hooks que no pertenecen a una sola página (`useSignalR`, `useCalificacionTicket`, `useNotificacionTab`) |

Dentro de una página, el componente principal (`<Nombre>.tsx`) es casi puro "pegamento": llama 3-5 hooks (cada uno con una responsabilidad — cargar el ticket, cargar mensajes, subir archivos, drag&drop...) y arma el JSX delegando a componentes chicos. Ejemplo de referencia: `DetalleTicket/`.

## 6. Tiempo real — SignalR

`useSignalR` (`src/hooks/useSignalR.ts`) conecta un hub de SignalR del backend por ticket. Solo se usa para **recibir** eventos en vivo (mensaje nuevo, archivo nuevo, cambio de estado) — nunca para enviar.

El envío siempre va por REST (POST). Si el mensaje enviado por REST también llega de vuelta por el socket, se deduplica por `id`. Razón: REST es la fuente de verdad; SignalR es solo aviso para no tener que refrescar la página a mano.

## 7. UI — dos librerías conviviendo

- **Mantine** — librería de UI para todo lo nuevo (formularios, modales, badges, layout).
- **DevExtreme** — solo en `Tickets.tsx` (la grilla de lista de tickets), legado, probablemente compartido con el backoffice de SIIAN. Por eso el proyecto arrastra `jquery` y `devextreme-aspnet-data-nojquery` como dependencias aunque el resto de la app no los necesita.

## 8. JS y TS mezclados

El proyecto migra gradualmente de JS a TS. Siguen en `.js`/`.jsx`: `App.jsx`, `main.jsx`, `AuthContext.jsx`, `PrivateRoute.jsx`, `src/api/*.js`. La mayoría de páginas nuevas (`DetalleTicket`, `NuevoTicket`, `Tickets`) ya están en `.ts`/`.tsx`.

## 9. Build y tooling

- **Vite** — bundler + dev server (`pnpm dev`, `pnpm build`).
- **pnpm** — gestor de paquetes (el repo trae `pnpm-lock.yaml`, no usar `npm install`).
- **TypeScript** (`pnpm typecheck`) y **ESLint** (`pnpm lint`) — chequeos manuales, **no bloquean** `dev` ni `build`. Se agregaron en 2026-09; antes no existía `tsconfig.json` y ESLint no revisaba `.ts`/`.tsx` (o sea, no revisaba casi nada del código real).
  - `typescript` está fijado en `6.0.3` (no la última, `7.x`) porque `typescript-eslint` todavía no soporta TS 7 al momento de escribir esto.
  - `@typescript-eslint/no-explicit-any` está apagado (el proyecto usa `any` en varios puntos de la migración JS→TS, se puede reactivar cuando esté más tipado).
  - Las reglas nuevas orientadas a React Compiler (`react-hooks/set-state-in-effect`, `react-hooks/refs`, `react-hooks/use-memo`, de `eslint-plugin-react-hooks` v7) están en `warn`, no `error` — el patrón "fetch en `useEffect` al montar" que usa toda la app las dispara en masa y no es un bug real, solo una recomendación del compilador nuevo de React.

## Deuda conocida (no es urgente, pero vale saberlo)

- `src/pages/DetalleTicket/helpers.ts` y `constants.ts` son duplicados muertos de `shared/helpers/formatters.ts` y `shared/constants/colors.ts` — no los importa nadie, quedaron de una refactorización anterior.
- Errores de tipos/lint preexistentes en `Login.tsx`, `Tickets.tsx`, `useSignalR.ts`, `usePortalNotificaciones.ts`, `ModalCalificacion.tsx` — visibles ahora que `pnpm typecheck`/`pnpm lint` cubren TS, pero no se tocaron porque son de otras páginas.
