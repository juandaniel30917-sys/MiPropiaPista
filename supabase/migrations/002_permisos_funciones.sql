-- Mi Propia Pista · Migración 002 · Quita EXECUTE público a funciones internas
revoke execute on function public.log_change() from public, anon, authenticated;
revoke execute on function public.touch_updated() from public, anon, authenticated;
revoke execute on function public.entries_guard_code() from public, anon, authenticated;
revoke execute on function public.set_entry_code(uuid, text) from public, anon;
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_owner() from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_owner() to authenticated;
grant execute on function public.set_entry_code(uuid, text) to authenticated;
