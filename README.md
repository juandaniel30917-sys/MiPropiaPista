# Mi Propia Pista · cómo abrir esta carpeta

```
mi-propia-pista/
  index.html      ← la web (ábrela con doble clic o con «Go Live» en VS Code)
  css/            estilos
  js/             la aplicación (web pública y panel)
  assets/         icono y archivos fijos
  supabase/       base de datos (migraciones) y funciones del servidor, ya aplicadas
```

- La web ya está conectada a Supabase. El panel se abre con la tuerca de arriba a la derecha (o en `index.html#/admin`).
- Las fotos, videos y textos no van en esta carpeta: se suben y editan desde el panel y quedan guardados en Supabase.
- `js/app.js` es código compilado: para modificar la web se edita el código fuente (React) y se vuelve a generar esta carpeta con `npm run build:live`.

---

# Mi Propia Pista · web transmedia

Sitio público con rutas reales y un panel de administración privado en `/admin`. Todo el contenido (textos, multimedia, enlaces, iconos, colores, orden de las secciones y la página «Próximamente») vive en Supabase y se edita desde el panel.

- **Supabase:** proyecto «Mi propia pista» (`wxfzyyvjtrflfrhwswam`). El esquema, las políticas, los buckets, el contenido inicial y las dos funciones de servidor ya están aplicados.
- **Frontend:** React 18, Vite 5, TypeScript, React Router 6, Framer Motion, TanStack Query, dnd-kit, DOMPurify.

## Arrancar en tu computador

Necesitas Node 18 o superior.

```bash
cp .env.example .env.local     # y completa los dos valores (ver abajo)
npm install
npm run dev                    # http://localhost:5173
npm run build                  # genera dist/ para publicar
```

### Carpeta lista para abrir (doble clic o Live Server)

`npm run build:live` genera `web-lista/` con la estructura clásica: `index.html`, `css/`, `js/`, `assets/` y `supabase/`. Se abre con doble clic o con **Go Live** en VS Code, ya conectada a Supabase. Usa direcciones con `#` (por ejemplo `index.html#/admin`). Para la web definitiva usa `npm run build` y publica en Vercel o Netlify.

### Variables de entorno

| Variable | Dónde se obtiene | ¿Es secreta? |
|---|---|---|
| `VITE_SUPABASE_URL` | Supabase → Project Settings → API → Project URL (`https://wxfzyyvjtrflfrhwswam.supabase.co`) | No |
| `VITE_SUPABASE_ANON_KEY` | Supabase → Project Settings → API Keys → clave *publishable* (`sb_publishable_…`) o *anon* | No, es pública por diseño |

La clave `service_role` **no se usa en el navegador ni va en ningún archivo del proyecto**. Solo la usan las funciones de servidor, y Supabase se la entrega automáticamente.

## Publicar (Vercel o Netlify)

1. Sube esta carpeta a un repositorio de GitHub (el `.gitignore` ya excluye `.env.local`).
2. En Vercel o Netlify, importa el repositorio. Comando de build: `npm run build`. Carpeta de salida: `dist`.
3. Agrega las dos variables de entorno de la tabla anterior en la configuración del sitio.
4. Las rutas directas (`/personajes/matias`, `/admin`…) ya funcionan: `vercel.json` y `public/_redirects` envían todo a `index.html`.

## Configurar Supabase Auth (una vez, en el panel de Supabase)

Estos ajustes no se pueden aplicar desde aquí y conviene hacerlos antes de publicar:

1. **Authentication → Sign In / Providers → Email:** desactiva **Allow new users to sign up**. Así nadie puede crearse una cuenta desde fuera. Aunque alguien se registrara, no tendría permisos: el acceso al panel depende de la tabla `admin_users`, que solo puede modificar un propietario.
2. **Authentication → URL Configuration:**
   - *Site URL*: la dirección final de la web (por ejemplo `https://mipropiapista.cl`).
   - *Redirect URLs*: agrega `https://TU-DOMINIO/admin/restablecer` y `http://localhost:5173/admin/restablecer`. Las usan la recuperación de contraseña y las invitaciones.

## Crear el primer administrador

1. En Supabase → **Authentication → Users → Add user → Create new user**, escribe tu correo y una contraseña (marca *Auto Confirm User*).
2. En **SQL Editor**, ejecuta (con tu correo):

   ```sql
   insert into public.admin_users (user_id, role)
   select id, 'owner' from auth.users where email = 'TU_CORREO';
   ```

3. Entra a la web, toca la tuerca de arriba a la derecha e inicia sesión. Desde **Cuenta → Usuarios** puedes invitar a más personas como *editor* (edita contenido) o *propietario* (además gestiona usuarios). La invitación les llega por correo para crear su contraseña.

## Página «Próximamente»

Está **activada**, porque el corto sigue en producción. Muestra «Próximamente», el subtítulo, los íconos de las redes (del corto y de los personajes que elijas) y los botones «Más información» (sinopsis sin final) y «Créditos». Mientras está activa:

- cualquier dirección pública lleva a esa portada (título, antetítulo, tagline, storyline, ficha, póster, redes del corto y personajes con sus redes);
- la base de datos tampoco entrega por API el resto del archivo (cronología, archivos, frases, escenas…), solo lo que la portada usa;
- tú, con sesión de administrador, puedes ver la web completa con **Vista previa**.

Se activa o desactiva en **Sitio → Próximamente**. Las redes se agregan en **Sitio → Enlaces y redes**: déjale el campo «De quién es» vacío y marca «Página Próximamente» para las del corto, o elige un personaje para sus redes.

## Pistas y códigos

En **Contenido → Pistas y códigos** puedes crear un archivo que solo se abre con un código que aparece en el cortometraje: subes el material (queda en el almacenamiento privado), escribes el código y una pista opcional, y listo. La tabla de abajo muestra todos los archivos bloqueados, permite cambiar cómo se abre cada uno y poner un código nuevo. Los códigos se guardan cifrados: no se pueden volver a ver, así que anótalos.

## Arquitectura

```
src/
  lib/        cliente Supabase, carga de datos (bundle), sesión y rol, progreso del visitante, saneado HTML
  components/ layout, tema (colores y tipografías desde la base de datos), multimedia, login
  pages/      Intro, Próximamente, Archivo, Personajes, Cronología, Archivos/Colecciones, Motos, Podcast, Producción
  admin/      panel: editor genérico por recurso, multimedia, diseño, próximamente, usuarios
supabase/
  migrations/ 001 esquema + RLS + buckets · 002 permisos · 003 contenido inicial · 004 próximamente y usuarios · 005 cierre por API
  functions/  invite-admin · unlock-media
```

- El panel se descarga aparte (carga diferida): los visitantes nunca reciben su código.
- La web pública lee todo en paralelo y filtra lo publicado. Lo que decide qué es público es RLS, no la interfaz.
- **Borradores y vista previa:** un elemento nuevo nace como borrador. En uno ya publicado, «Guardar borrador» guarda los cambios en `content_drafts` sin tocar la web; «Publicar cambios» los aplica. «Vista previa» abre la web con `?vista-previa=1`, que muestra borradores solo si hay sesión de administrador (la base de datos no se los entrega a nadie más).
- **Progreso del visitante** (archivos abiertos y desbloqueados) en `localStorage` (`mpp_progreso_v2`). Es lo único que se guarda en el navegador.
- **Desbloqueos:** `after_entries` es narrativo (se abre tras ver otros archivos); `code` es protección real: el texto vive en `entry_secrets`, el código se guarda con hash (bcrypt) y solo la función `unlock_entry` lo devuelve; `release_date` lo oculta la base de datos hasta la fecha.
- **Video:** nunca se reproduce solo con sonido. YouTube, Vimeo, Spotify y SoundCloud se integran con su reproductor.

## Tablas y políticas

| Tabla | Público (anon) | Administrador |
|---|---|---|
| `site_settings`, `screens` | Lectura | Todo |
| `characters`, `links`, `assets` | Lectura de lo publicado | Todo |
| `screen_modules`, `character_relations`, `scenes`, `quotes`, `timeline_events`, `vehicles`, `collections`, `entries`, `entry_media`, `entry_links`, `podcast_episodes`, `credits`, `press_items` | Lectura de lo publicado, **y solo con Próximamente desactivada** | Todo |
| `entry_secrets`, `content_drafts` | Nada | Todo |
| `admin_users` | Nada | Cada uno ve su fila; solo un propietario la modifica. Siempre queda al menos un propietario |
| `audit_log` | Nada | Lectura (lo escribe un trigger en cada cambio) |

- RLS está activo en todas las tablas. `is_admin()` e `is_owner()` consultan `admin_users`; nadie puede darse permisos editando su propio perfil.
- **Storage:** `media-public` (lectura pública, escritura de administradores) y `media-private` (solo administradores; los visitantes reciben URLs firmadas de 10 minutos desde `unlock-media` después de dar el código correcto). Límite de 50 MB por archivo.
- **Funciones de servidor:** `invite-admin` comprueba que quien llama es propietario y envía la invitación. `unlock-media` vuelve a validar el código antes de firmar URLs.

## Qué falta (lo tienes que aportar tú)

- Storyline y tagline del corto: los guiones no los incluyen, así que están vacíos (Sitio → Próximamente).
- Redes sociales del corto y de los personajes, si las hay.
- Material real: videos, fotos, audios, póster y logo (Multimedia).
- Marca, modelo y cilindrada de las motos, y qué moto usó Leonardo en el accidente (el guion técnico lo deja sin definir).
- Episodios del podcast, créditos completos y prensa.
- Las 22 escenas están cargadas como borrador para no adelantar la historia; publica las que quieras.
- Los 13 textos del sitio anterior que no están en el guion están como borrador «no canónico». Revísalos y publícalos solo si los apruebas.
