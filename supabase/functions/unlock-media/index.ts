// Entrega URLs firmadas (10 min) de los medios privados de un archivo con código.
// Vuelve a comprobar el código con la misma función de la base de datos que usa la web:
// sin código correcto no se firma nada. La clave service_role solo existe aquí, en el servidor.
import { createClient } from 'npm:@supabase/supabase-js@2.45.4';
import { cors, json } from './cors.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Método no permitido' }, 405);

  let code = '';
  let answer = '';
  try {
    const body = await req.json();
    code = String(body.code ?? '').slice(0, 64);
    answer = String(body.answer ?? '').slice(0, 200);
  } catch {
    return json({ error: 'Solicitud no válida' }, 400);
  }
  if (!code || !answer) return json({ error: 'Faltan datos' }, 400);

  const pub = createClient(url, anon, { auth: { persistSession: false } });
  const { data, error } = await pub.rpc('unlock_entry', { p_code: code, p_answer: answer });
  if (error) return json({ error: 'No se pudo comprobar el código' }, 500);
  if (!data) return json({ error: 'Código incorrecto' }, 403);

  const assets = ((data as { assets?: { id: string; bucket: string | null; storage_path: string | null }[] }).assets ?? [])
    .filter((a) => a.bucket === 'media-private' && a.storage_path);
  const admin = createClient(url, service, { auth: { persistSession: false } });
  const urls: Record<string, string> = {};
  for (const a of assets) {
    const { data: s } = await admin.storage.from('media-private').createSignedUrl(a.storage_path!, 600);
    if (s?.signedUrl) urls[a.id] = s.signedUrl;
  }
  return json({ urls });
});
