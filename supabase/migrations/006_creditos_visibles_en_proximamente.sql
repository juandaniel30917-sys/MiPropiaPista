-- =====================================================================
-- Mi Propia Pista · Migración 006
-- Los créditos publicados se muestran también en la portada «Próximamente».
-- =====================================================================
alter policy coming_soon_gate_anon on public.credits using (true);
alter policy coming_soon_gate on public.credits using (true);
