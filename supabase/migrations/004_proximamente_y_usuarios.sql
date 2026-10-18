-- =====================================================================
-- Mi Propia Pista · Migración 004
-- 1. Página «Próximamente» activable desde el panel.
-- 2. Redes sociales por personaje (links.character_id).
-- 3. Gestión de administradores: list_admins() y protección del último owner.
-- =====================================================================

-- 1. Próximamente ------------------------------------------------------
alter table public.site_settings
  add column if not exists coming_soon jsonb not null default '{"enabled": false}'::jsonb;

-- Solo datos verificados en los guiones. Storyline y tagline quedan vacíos:
-- el guion no los incluye y se escriben desde el panel.
update public.site_settings set coming_soon = jsonb_build_object(
  'enabled', true,
  'kicker', 'Cortometraje · En producción',
  'tagline', '',
  'storyline', '',
  'facts', jsonb_build_array(
    jsonb_build_object('campo', 'Formato', 'valor', 'Cortometraje'),
    jsonb_build_object('campo', 'Guion', 'valor', 'Juan Daniel Bermúdez'),
    jsonb_build_object('campo', 'Estado', 'valor', 'En producción'),
    jsonb_build_object('campo', 'Estreno', 'valor', 'Por anunciar')),
  'release_text', 'Próximamente',
  'poster_id', null,
  'background_id', null,
  'show_characters', true,
  'characters_title', 'Personajes',
  'links_title', 'Sigue el corto')
where id = true;

-- 2. Redes por personaje -------------------------------------------------
alter table public.links
  add column if not exists character_id uuid references public.characters(id) on delete cascade;
create index if not exists links_character_idx on public.links (character_id);
comment on column public.links.character_id is
  'Si tiene valor, es una red del personaje (se muestra en su ficha y en Próximamente). Si es nulo, es una red del corto.';
comment on column public.links.placement is
  '''header'' | ''footer'' | ''transmedia'' | ''proximamente''';

-- 3. Administradores -----------------------------------------------------
create or replace function public.list_admins()
returns table (user_id uuid, email text, role public.admin_role, created_at timestamptz, last_sign_in_at timestamptz)
language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.is_owner() then
    raise exception 'Solo un propietario puede ver los administradores' using errcode = '42501';
  end if;
  return query
    select a.user_id, u.email::text, a.role, a.created_at, u.last_sign_in_at
      from public.admin_users a join auth.users u on u.id = a.user_id
     order by a.created_at;
end $$;
revoke execute on function public.list_admins() from public, anon;
grant execute on function public.list_admins() to authenticated;

-- Nunca quedarse sin propietario (por ejemplo, quitándose el rol a uno mismo).
create or replace function public.keep_last_owner()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    if not exists (select 1 from public.admin_users where role = 'owner' and user_id <> old.user_id) then
      raise exception 'Debe quedar al menos un propietario' using errcode = '23514';
    end if;
  end if;
  return coalesce(new, old);
end $$;
revoke execute on function public.keep_last_owner() from public, anon, authenticated;
drop trigger if exists admin_users_keep_owner on public.admin_users;
create trigger admin_users_keep_owner before update or delete on public.admin_users
  for each row execute function public.keep_last_owner();
