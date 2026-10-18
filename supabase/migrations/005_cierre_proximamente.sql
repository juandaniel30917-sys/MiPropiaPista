-- =====================================================================
-- Mi Propia Pista · Migración 005
-- Mientras «Próximamente» está activa, la base de datos solo entrega al
-- público lo que esa portada necesita (ajustes, pantallas, personajes,
-- redes y medios). El resto del archivo queda cerrado también por API,
-- no solo escondido en la interfaz. Los administradores lo ven todo.
-- =====================================================================

create or replace function public.site_open()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select not coalesce((coming_soon->>'enabled')::boolean, false) from public.site_settings where id), true);
$$;
grant execute on function public.site_open() to anon, authenticated;

-- Políticas restrictivas: se suman (AND) a las de lectura pública existentes.
do $$
declare t text;
begin
  foreach t in array array['screen_modules','character_relations','scenes','quotes','timeline_events','vehicles',
                           'collections','entries','entry_media','entry_links','podcast_episodes','credits','press_items']
  loop
    -- anon no puede ejecutar is_admin(), por eso lleva su propia política.
    execute format('create policy coming_soon_gate on public.%I as restrictive for select to authenticated using (public.site_open() or public.is_admin())', t);
    execute format('create policy coming_soon_gate_anon on public.%I as restrictive for select to anon using (public.site_open())', t);
  end loop;
end $$;

-- El desbloqueo con código tampoco funciona con la web cerrada.
create or replace function public.unlock_entry(p_code text, p_answer text)
returns jsonb language plpgsql stable security definer set search_path = public, extensions as $$
declare
  e public.entries;
  s public.entry_secrets;
begin
  if not public.site_open() then return null; end if;
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
