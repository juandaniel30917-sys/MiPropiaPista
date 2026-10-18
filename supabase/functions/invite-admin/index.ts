// Invita a una persona al panel. Solo un propietario (admin_users.role = 'owner') puede hacerlo.
// El rol se comprueba aquí con la sesión de quien llama; la clave service_role solo vive en el servidor.
import { createClient } from 'npm:@supabase/supabase-js@2.45.4';
import { cors, json } from './cors.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Método no permitido' }, 405);

  const auth = req.headers.get('Authorization') ?? '';
  const caller = createClient(url, anon, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });
  const { data: who } = await caller.auth.getUser();
  if (!who?.user) return json({ error: 'Tu sesión no es válida. Vuelve a iniciar sesión.' }, 401);
  const { data: owner } = await caller.rpc('is_owner');
  if (owner !== true) return json({ error: 'Solo un propietario puede invitar administradores.' }, 403);

  let email = '';
  let role = 'editor';
  let wanted = '';
  try {
    const body = await req.json();
    email = String(body.email ?? '').trim().toLowerCase();
    role = body.role === 'owner' ? 'owner' : 'editor';
    wanted = String(body.redirect_to ?? '');
  } catch {
    return json({ error: 'Solicitud no válida' }, 400);
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return json({ error: 'El correo no es válido.' }, 400);

  const admin = createClient(url, service, { auth: { persistSession: false } });
  const origin = req.headers.get('Origin');
  // La web indica adónde debe volver el enlace (cambia según el modo de rutas); solo se
  // acepta si es del mismo sitio desde el que se envió la invitación.
  let redirectTo: string | undefined;
  if (origin && /^https?:\/\//.test(origin)) {
    redirectTo = `${origin}/admin/restablecer`;
    try {
      if (wanted && new URL(wanted).origin === origin) redirectTo = wanted;
    } catch {
      // dirección no válida: se usa la predeterminada
    }
  }

  let userId: string | null = null;
  let invited = false;
  const inv = await admin.auth.admin.inviteUserByEmail(email, { redirectTo });
  if (inv.data?.user) {
    userId = inv.data.user.id;
    invited = true;
  } else {
    // Ya existe una cuenta con ese correo: se busca y solo se le da acceso.
    for (let page = 1; page <= 20 && !userId; page++) {
      const { data } = await admin.auth.admin.listUsers({ page, perPage: 200 });
      const found = data?.users.find((u) => u.email?.toLowerCase() === email);
      if (found) userId = found.id;
      if (!data || data.users.length < 200) break;
    }
    if (!userId) return json({ error: inv.error?.message ?? 'No se pudo crear la invitación.' }, 400);
  }

  const { error } = await admin.from('admin_users').upsert({ user_id: userId, role }, { onConflict: 'user_id' });
  if (error) return json({ error: 'La cuenta se creó, pero no se pudo dar acceso al panel.' }, 500);
  return json({ ok: true, invited });
});
