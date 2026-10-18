-- =====================================================================
-- Mi Propia Pista · Migración 001 · Esquema, RLS y Storage
-- Aprobado por Daniel el 2026-10-18. Aplicado al proyecto Supabase «Mi propia pista».
-- Pensado para Supabase (Postgres 15+). Se ejecuta completo en el SQL Editor
-- o como migración en supabase/migrations/.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- Tipos
-- ---------------------------------------------------------------------
create type public.content_status as enum ('draft', 'published', 'archived');
create type public.canon_level    as enum ('canon', 'expandido', 'no_canonico');
create type public.world          as enum ('taller', 'casa', 'exterior', 'pista');
create type public.era            as enum ('antes', 'la_noche', 'cuatro_anios_despues');
create type public.admin_role     as enum ('owner', 'editor');
create type public.asset_kind     as enum ('image', 'video', 'audio', 'document', 'embed');
create type public.entry_type     as enum ('video', 'foto', 'audio', 'mensaje', 'documento',
                                           'publicacion', 'noticia', 'nota', 'registro');
create type public.unlock_rule    as enum ('none', 'after_entries', 'code', 'release_date');
create type public.collection_template as enum ('camara', 'celular', 'feed', 'carpeta');

-- ---------------------------------------------------------------------
-- Administradores y funciones de permisos
-- ---------------------------------------------------------------------
create table public.admin_users (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       public.admin_role not null default 'editor',
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid());
$$;

create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid() and role = 'owner');
$$;

-- Visible para el público: publicado y, si tiene fecha de liberación, ya cumplida.
create or replace function public.is_public(s public.content_status, release_at timestamptz)
returns boolean language sql stable set search_path = public as $$
  select s = 'published' and (release_at is null or release_at <= now());
$$;

create or replace function public.touch_updated()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- Biblioteca multimedia
-- ---------------------------------------------------------------------
create table public.assets (
  id            uuid primary key default gen_random_uuid(),
  kind          public.asset_kind not null,
  bucket        text check (bucket in ('media-public', 'media-private')),
  storage_path  text,
  external_url  text,           -- YouTube, Vimeo, Spotify, SoundCloud…
  provider      text,           -- 'youtube' | 'vimeo' | 'spotify' | …
  title         text,
  alt           text,           -- texto alternativo (obligatorio en imágenes al publicar)
  caption       text,
  poster_id     uuid references public.assets(id) on delete set null,
  width         int,
  height        int,
  duration_s    numeric,
  meta          jsonb not null default '{}'::jsonb,  -- metadatos narrativos libres (dispositivo, hora en ficción…)
  status        public.content_status not null default 'published',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  updated_by    uuid,
  constraint asset_source check (
    (storage_path is not null and bucket is not null and external_url is null)
    or (storage_path is null and external_url is not null)
  )
);

-- ---------------------------------------------------------------------
-- Ajustes globales (una sola fila)
-- ---------------------------------------------------------------------
create table public.site_settings (
  id            boolean primary key default true check (id),
  title         text not null default 'Mi Propia Pista',
  short_title   text not null default 'MPP',
  logo_id       uuid references public.assets(id) on delete set null,
  favicon_id    uuid references public.assets(id) on delete set null,
  og_image_id   uuid references public.assets(id) on delete set null,
  seo           jsonb not null default '{}'::jsonb,   -- description, keywords
  palette       jsonb not null default '{}'::jsonb,   -- tokens por mundo, ver propuesta §2.2
  fonts         jsonb not null default '{"display":"Big Shoulders Display","text":"IBM Plex Sans","mono":"IBM Plex Mono"}'::jsonb,
  animations    jsonb not null default '{"transitions":true,"grain":true,"interference":true,"intro":true}'::jsonb,
  intro         jsonb not null default '{}'::jsonb,   -- líneas de arranque, textos de botones, fondo
  system_texts  jsonb not null default '{}'::jsonb,   -- cargando, error, 404, bloqueado…
  final_screen  jsonb not null default '{}'::jsonb,   -- título, frase, condición
  footer_text   text,
  updated_at    timestamptz not null default now(),
  updated_by    uuid
);
insert into public.site_settings (id) values (true);

-- ---------------------------------------------------------------------
-- Pantallas y módulos
-- ---------------------------------------------------------------------
create table public.screens (
  key          text primary key,  -- 'archivo', 'personajes', 'cronologia', 'archivos', 'vehiculos', 'podcast', 'produccion'
  nav_label    text not null,
  title        text,
  intro        text,
  icon         text,
  world        public.world,
  background_id uuid references public.assets(id) on delete set null,
  in_nav       boolean not null default true,
  visible      boolean not null default true,
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.screen_modules (
  id           uuid primary key default gen_random_uuid(),
  screen_key   text not null references public.screens(key) on delete cascade,
  module_type  text not null,     -- 'destacados', 'frase', 'progreso', 'coleccion', 'texto', 'enlaces'…
  title        text,
  config       jsonb not null default '{}'::jsonb,
  visible      boolean not null default true,
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

-- ---------------------------------------------------------------------
-- Universo narrativo
-- ---------------------------------------------------------------------
create table public.characters (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name         text not null,
  role         text,                 -- «Hermano mayor de Matías»
  ages         text,                 -- «16 · 20 cuatro años después»
  summary      text,
  bio          text,                 -- texto enriquecido (HTML saneado)
  world        public.world,
  portrait_id  uuid references public.assets(id) on delete set null,
  cover_id     uuid references public.assets(id) on delete set null,
  fields       jsonb not null default '[]'::jsonb,   -- [{campo, valor}]
  status       public.content_status not null default 'draft',
  canon        public.canon_level not null default 'canon',
  release_at   timestamptz,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.character_relations (
  id           uuid primary key default gen_random_uuid(),
  from_id      uuid not null references public.characters(id) on delete cascade,
  to_id        uuid not null references public.characters(id) on delete cascade,
  label        text not null,
  status       public.content_status not null default 'published',
  sort_order   int not null default 0,
  unique (from_id, to_id),
  check (from_id <> to_id)
);

create table public.scenes (
  id           uuid primary key default gen_random_uuid(),
  number       int not null unique,
  heading      text not null,        -- «EXT. CARRETERA RURAL – DÍA»
  era          public.era not null,
  world        public.world not null,
  summary      text,
  status       public.content_status not null default 'draft',
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.quotes (
  id           uuid primary key default gen_random_uuid(),
  text         text not null,        -- literal del guion
  character_id uuid references public.characters(id) on delete set null,
  scene_id     uuid references public.scenes(id) on delete set null,
  featured     boolean not null default false,
  status       public.content_status not null default 'draft',
  canon        public.canon_level not null default 'canon',
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.timeline_events (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  date_label   text,                 -- fecha dentro de la ficción, texto libre
  era          public.era not null,
  description  text,
  world        public.world,
  scene_id     uuid references public.scenes(id) on delete set null,
  cover_id     uuid references public.assets(id) on delete set null,
  status       public.content_status not null default 'draft',
  canon        public.canon_level not null default 'canon',
  release_at   timestamptz,
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.vehicles (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name         text not null,
  owner_id     uuid references public.characters(id) on delete set null,
  summary      text,
  specs        jsonb not null default '[]'::jsonb,   -- [{campo, valor}]; vacíos no se muestran
  state        text,
  cover_id     uuid references public.assets(id) on delete set null,
  status       public.content_status not null default 'draft',
  canon        public.canon_level not null default 'canon',
  release_at   timestamptz,
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.collections (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (slug ~ '^[a-z0-9-]+$'),
  title        text not null,        -- «GoPro de Leonardo»
  description  text,
  template     public.collection_template not null default 'carpeta',
  owner_id     uuid references public.characters(id) on delete set null,
  world        public.world,
  cover_id     uuid references public.assets(id) on delete set null,
  status       public.content_status not null default 'draft',
  release_at   timestamptz,
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.entries (
  id             uuid primary key default gen_random_uuid(),
  code           text not null unique check (code ~ '^[A-Z0-9-]+$'),   -- «GP-013»
  type           public.entry_type not null,
  collection_id  uuid references public.collections(id) on delete set null,
  title          text not null,
  summary        text,
  body           text,               -- texto enriquecido; en archivos con código va en entry_secrets
  date_label     text,               -- fecha/hora dentro de la ficción
  world          public.world,
  cover_id       uuid references public.assets(id) on delete set null,
  meta           jsonb not null default '{}'::jsonb,   -- remitente, dispositivo, duración…
  unlock         public.unlock_rule not null default 'none',
  unlock_after   uuid[] not null default '{}',        -- para 'after_entries'
  unlock_hint    text,
  status         public.content_status not null default 'draft',
  canon          public.canon_level not null default 'canon',
  release_at     timestamptz,                          -- para 'release_date'
  sort_order     int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  updated_by     uuid
);

create table public.entry_media (
  entry_id     uuid not null references public.entries(id) on delete cascade,
  asset_id     uuid not null references public.assets(id) on delete cascade,
  sort_order   int not null default 0,
  primary key (entry_id, asset_id)
);

create table public.entry_links (
  id           uuid primary key default gen_random_uuid(),
  entry_id     uuid not null references public.entries(id) on delete cascade,
  character_id uuid references public.characters(id) on delete cascade,
  scene_id     uuid references public.scenes(id) on delete cascade,
  event_id     uuid references public.timeline_events(id) on delete cascade,
  vehicle_id   uuid references public.vehicles(id) on delete cascade,
  target_entry_id uuid references public.entries(id) on delete cascade,
  check (num_nonnulls(character_id, scene_id, event_id, vehicle_id, target_entry_id) = 1)
);

-- Contenido protegido de verdad (regla 'code'). Nunca legible por el público.
create table public.entry_secrets (
  entry_id     uuid primary key references public.entries(id) on delete cascade,
  code_hash    text not null,        -- crypt(codigo, gen_salt('bf'))
  body         text,
  asset_ids    uuid[] not null default '{}',
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

-- ---------------------------------------------------------------------
-- Transmedia y producción
-- ---------------------------------------------------------------------
create table public.podcast_episodes (
  id           uuid primary key default gen_random_uuid(),
  number       int,
  title        text not null,
  description  text,
  audio_id     uuid references public.assets(id) on delete set null,  -- archivo o embed externo
  cover_id     uuid references public.assets(id) on delete set null,
  duration_label text,
  status       public.content_status not null default 'draft',
  release_at   timestamptz,
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.links (
  id           uuid primary key default gen_random_uuid(),
  label        text not null,
  url          text not null check (url ~* '^(https?://|/)'),
  icon         text,                 -- clave del selector de iconos: 'youtube', 'instagram', 'spotify', 'tiktok', 'vimeo', 'mail', 'web'…
  placement    text[] not null default '{footer}',   -- 'header' | 'footer' | 'transmedia' | 'intro'
  status       public.content_status not null default 'draft',
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.credits (
  id           uuid primary key default gen_random_uuid(),
  person       text not null,
  role         text not null,
  department   text,
  url          text,
  status       public.content_status not null default 'draft',
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

create table public.press_items (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null check (kind in ('festival', 'premio', 'prensa', 'proyeccion')),
  title        text not null,
  outlet       text,
  date_label   text,
  url          text,
  laurel_id    uuid references public.assets(id) on delete set null,
  status       public.content_status not null default 'draft',
  sort_order   int not null default 0,
  updated_at   timestamptz not null default now(),
  updated_by   uuid
);

-- ---------------------------------------------------------------------
-- Borradores de contenido publicado y auditoría
-- ---------------------------------------------------------------------
create table public.content_drafts (
  table_name   text not null,
  row_id       text not null,
  data         jsonb not null,
  updated_at   timestamptz not null default now(),
  updated_by   uuid default auth.uid(),
  primary key (table_name, row_id)
);

create table public.audit_log (
  id           bigint generated always as identity primary key,
  at           timestamptz not null default now(),
  user_id      uuid default auth.uid(),
  table_name   text not null,
  row_id       text,
  action       text not null,
  diff         jsonb
);

create or replace function public.log_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_log (table_name, row_id, action, diff)
  values (tg_table_name,
          coalesce((to_jsonb(new)->>'id'), (to_jsonb(old)->>'id'), (to_jsonb(new)->>'key'), (to_jsonb(old)->>'key')),
          tg_op,
          case tg_op when 'DELETE' then to_jsonb(old) else to_jsonb(new) end);
  return coalesce(new, old);
end $$;

-- ---------------------------------------------------------------------
-- Desbloqueo con código (único camino para leer entry_secrets)
-- ---------------------------------------------------------------------
create or replace function public.unlock_entry(p_code text, p_answer text)
returns jsonb language plpgsql stable security definer set search_path = public, extensions as $$
declare
  e public.entries;
  s public.entry_secrets;
begin
  select * into e from public.entries
   where code = p_code and unlock = 'code' and public.is_public(status, release_at);
  if not found then return null; end if;
  select * into s from public.entry_secrets where entry_id = e.id;
  if not found or s.code_hash <> crypt(lower(trim(p_answer)), s.code_hash) then
    return null;
  end if;
  return jsonb_build_object(
    'body', s.body,
    'assets', coalesce((select jsonb_agg(to_jsonb(a)) from public.assets a where a.id = any(s.asset_ids)), '[]'::jsonb)
  );
end $$;
revoke all on function public.unlock_entry(text, text) from public;
grant execute on function public.unlock_entry(text, text) to anon, authenticated;

-- Fija el código de un archivo (solo admin); guarda el hash, nunca el texto.
create or replace function public.set_entry_code(p_entry uuid, p_code text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  insert into public.entry_secrets (entry_id, code_hash)
  values (p_entry, crypt(lower(trim(p_code)), gen_salt('bf')))
  on conflict (entry_id) do update set code_hash = excluded.code_hash, updated_at = now(), updated_by = auth.uid();
end $$;
revoke all on function public.set_entry_code(uuid, text) from public;
grant execute on function public.set_entry_code(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- Triggers updated_at/updated_by y auditoría
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['assets','site_settings','screens','screen_modules','characters','scenes',
                           'quotes','timeline_events','vehicles','collections','entries','entry_secrets',
                           'podcast_episodes','links','credits','press_items']
  loop
    execute format('create trigger %I_touch before update on public.%I for each row execute function public.touch_updated()', t, t);
  end loop;
  foreach t in array array['assets','site_settings','screens','screen_modules','characters','character_relations',
                           'scenes','quotes','timeline_events','vehicles','collections','entries','entry_media',
                           'entry_links','podcast_episodes','links','credits','press_items','admin_users']
  loop
    execute format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.log_change()', t, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['admin_users','assets','site_settings','screens','screen_modules','characters',
                           'character_relations','scenes','quotes','timeline_events','vehicles','collections',
                           'entries','entry_media','entry_links','entry_secrets','podcast_episodes','links',
                           'credits','press_items','content_drafts','audit_log']
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Escritura y lectura completa: solo administradores (todas las tablas salvo admin_users y audit_log)
do $$
declare t text;
begin
  foreach t in array array['assets','site_settings','screens','screen_modules','characters','character_relations',
                           'scenes','quotes','timeline_events','vehicles','collections','entries','entry_media',
                           'entry_links','entry_secrets','podcast_episodes','links','credits','press_items','content_drafts']
  loop
    execute format('create policy admin_all on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

-- Lectura pública de lo publicado
create policy public_read on public.assets           for select to anon, authenticated using (status = 'published' and bucket is distinct from 'media-private');
create policy public_read on public.site_settings    for select to anon, authenticated using (true);
create policy public_read on public.screens          for select to anon, authenticated using (visible);
create policy public_read on public.screen_modules   for select to anon, authenticated using (visible);
create policy public_read on public.characters       for select to anon, authenticated using (public.is_public(status, release_at));
create policy public_read on public.character_relations for select to anon, authenticated using (
  status = 'published'
  and exists (select 1 from public.characters c where c.id = from_id and public.is_public(c.status, c.release_at))
  and exists (select 1 from public.characters c where c.id = to_id   and public.is_public(c.status, c.release_at)));
create policy public_read on public.scenes           for select to anon, authenticated using (status = 'published');
create policy public_read on public.quotes           for select to anon, authenticated using (status = 'published');
create policy public_read on public.timeline_events  for select to anon, authenticated using (public.is_public(status, release_at));
create policy public_read on public.vehicles         for select to anon, authenticated using (public.is_public(status, release_at));
create policy public_read on public.collections      for select to anon, authenticated using (public.is_public(status, release_at));
create policy public_read on public.entries          for select to anon, authenticated using (public.is_public(status, release_at));
create policy public_read on public.entry_media      for select to anon, authenticated using (
  exists (select 1 from public.entries e where e.id = entry_id and public.is_public(e.status, e.release_at) and e.unlock <> 'code'));
create policy public_read on public.entry_links      for select to anon, authenticated using (
  exists (select 1 from public.entries e where e.id = entry_id and public.is_public(e.status, e.release_at)));
create policy public_read on public.podcast_episodes for select to anon, authenticated using (public.is_public(status, release_at));
create policy public_read on public.links            for select to anon, authenticated using (status = 'published');
create policy public_read on public.credits          for select to anon, authenticated using (status = 'published');
create policy public_read on public.press_items      for select to anon, authenticated using (status = 'published');
-- entry_secrets y content_drafts: sin política pública.

-- admin_users: cada admin se ve a sí mismo; solo un owner gestiona la tabla.
create policy self_read   on public.admin_users for select to authenticated using (user_id = auth.uid() or public.is_owner());
create policy owner_write on public.admin_users for all    to authenticated using (public.is_owner()) with check (public.is_owner());

-- audit_log: solo lectura para administradores; se escribe por trigger.
create policy admin_read on public.audit_log for select to authenticated using (public.is_admin());

-- En archivos con regla 'code', el cuerpo público se vacía: el texto real vive en entry_secrets.
create or replace function public.entries_guard_code()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.unlock = 'code' then new.body := null; end if;
  return new;
end $$;
create trigger entries_guard_code before insert or update on public.entries
  for each row execute function public.entries_guard_code();

-- ---------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit)
values ('media-public',  'media-public',  true,  52428800),
       ('media-private', 'media-private', false, 52428800)
on conflict (id) do nothing;

create policy media_public_read on storage.objects for select to anon, authenticated
  using (bucket_id = 'media-public');
create policy media_admin_insert on storage.objects for insert to authenticated
  with check (bucket_id in ('media-public', 'media-private') and public.is_admin());
create policy media_admin_update on storage.objects for update to authenticated
  using (bucket_id in ('media-public', 'media-private') and public.is_admin())
  with check (bucket_id in ('media-public', 'media-private') and public.is_admin());
create policy media_admin_delete on storage.objects for delete to authenticated
  using (bucket_id in ('media-public', 'media-private') and public.is_admin());
create policy media_private_admin_read on storage.objects for select to authenticated
  using (bucket_id = 'media-private' and public.is_admin());
-- Los medios privados de un archivo desbloqueado se sirven con URL firmada desde una
-- Edge Function que vuelve a validar el código (se agrega en la etapa de construcción).

-- ---------------------------------------------------------------------
-- Primer administrador (ejecutar a mano UNA vez, después de crear tu usuario
-- en Authentication → Users con tu correo):
--
--   insert into public.admin_users (user_id, role)
--   select id, 'owner' from auth.users where email = 'TU_CORREO' ;
-- ---------------------------------------------------------------------
