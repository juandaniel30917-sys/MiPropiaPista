-- =====================================================================
-- Mi Propia Pista · Migración 003 · Contenido inicial
-- Todo el contenido canónico sale literal del guion literario V5_1 y de los
-- resúmenes del guion técnico. Lo que viene del sitio anterior y no está en el
-- guion entra como borrador «no_canonico» (no visible para el público).
-- =====================================================================

-- Ajustes globales -----------------------------------------------------
update public.site_settings set
  title = 'Mi Propia Pista',
  short_title = 'MPP',
  seo = jsonb_build_object(
    'description', 'El archivo de Mi Propia Pista, un cortometraje de Juan Daniel Bermúdez sobre dos hermanos, una moto y lo que queda guardado.',
    'keywords', 'Mi Propia Pista, cortometraje, motociclismo, Juan Daniel Bermúdez'),
  palette = jsonb_build_object(
    'bg', '#0A0B0D', 'surface', '#121418', 'line', '#24272D', 'text', '#ECE8E1', 'muted', '#9A968F',
    'taller', jsonb_build_object('accent', '#8FA6B8', 'glow', '#C9D6E0', 'base', '#0B0D10'),
    'casa', jsonb_build_object('accent', '#D9A05B', 'glow', '#F0C27A', 'base', '#120E0B'),
    'exterior', jsonb_build_object('accent', '#E8A65A', 'glow', '#9FB9C9', 'base', '#0A0F12'),
    'pista', jsonb_build_object('accent', '#E2772E', 'glow', '#D1313B', 'base', '#08080A')),
  intro = jsonb_build_object(
    'lines', jsonb_build_array('TARJETA SD · LEO', 'LEYENDO ARCHIVOS…', 'CUATRO AÑOS DESPUÉS'),
    'tagline', 'Lo que quedó guardado.',
    'enter_label', 'Entrar al archivo',
    'skip_label', 'Saltar'),
  system_texts = jsonb_build_object(
    'loading', 'Leyendo archivo…',
    'error', 'No se pudo leer el archivo. Revisa tu conexión e inténtalo otra vez.',
    'not_found', 'Archivo no encontrado.',
    'locked', 'Archivo bloqueado',
    'empty', 'Todavía no hay nada guardado aquí.'),
  final_screen = jsonb_build_object(
    'enabled', true,
    'title', 'Tu propia pista',
    'text', 'No corras para llegar a donde yo llegue, corre hasta encontrar, tu propia pista.'),
  footer_text = 'Mi Propia Pista · Un cortometraje de Juan Daniel Bermúdez.'
where id = true;

-- Pantallas ------------------------------------------------------------
insert into public.screens (key, nav_label, title, intro, icon, world, sort_order) values
  ('archivo',    'Archivo',     'Archivo central', 'Taller, casa, carretera y pista. Todo lo que quedó.', 'folder', null, 0),
  ('personajes', 'Personajes',  'Personajes', 'Quiénes son, con sus propias palabras.', 'helmet', 'casa', 1),
  ('cronologia', 'Cronología',  'Cronología', 'Antes, la noche y cuatro años después.', 'track', 'exterior', 2),
  ('archivos',   'Archivos',    'Archivos', 'Videos, mensajes y registros.', 'camera', 'taller', 3),
  ('vehiculos',  'Motos',       'Motos', 'Las dos motos de la historia.', 'wrench', 'taller', 4),
  ('podcast',    'Podcast',     'Podcast', null, 'audio', 'casa', 5),
  ('produccion', 'Producción',  'Detrás de cámaras', 'Cómo se hizo Mi Propia Pista.', 'film', 'exterior', 6);

insert into public.screen_modules (screen_key, module_type, title, config, sort_order) values
  ('archivo', 'mundos',     'Cuatro lugares', '{}'::jsonb, 0),
  ('archivo', 'frase',      null, '{"mode":"featured"}'::jsonb, 1),
  ('archivo', 'destacados', 'Archivos recuperados', '{"codes":["GP-001","IG-001","CEL-003"]}'::jsonb, 2),
  ('archivo', 'progreso',   'Tu recorrido', '{}'::jsonb, 3);

-- Personajes -----------------------------------------------------------
insert into public.characters (slug, name, role, ages, summary, bio, world, fields, status, canon, sort_order) values
('matias', 'Matías Herrera', 'Protagonista · hermano menor', '16 · 20 cuatro años después',
 'Limpia su pequeña moto mientras espera a su hermano. Quiere correr como él.',
 '<p>A los 16 años, Matías espera a Leonardo en el garaje y le confiesa que quiere ser como él. Leonardo le enseña a andar en moto y Matías recorre la misma ruta que su hermano hizo esa mañana.</p><p>Cuatro años después de la muerte de Leonardo, Matías mira la pista desde afuera. Bruno le entrega la GoPro de su hermano, y en ella encuentra un mensaje. Repara la moto de Leonardo, corre dos veces y descubre que no tiene que correr contra él.</p>',
 'taller',
 '[{"campo":"Edad","valor":"16 · 20 cuatro años después"},{"campo":"Familia","valor":"Hermano menor de Leonardo, hijo de Elena"}]'::jsonb,
 'published', 'canon', 0),
('leonardo', 'Leonardo Herrera', 'Hermano mayor · piloto', '19',
 'Conduce con seguridad, inclinado sobre la moto. Para él, la carretera también es una pista.',
 '<p>Leonardo tiene 19 años. Le enseña a Matías a andar en moto («Si te caì, te levantaì nomas») y le pide a su madre que lo deje ser.</p><p>Muere después de caer en una carrera nocturna. Cuatro años después, sus videos en la GoPro y en Instagram le hablan a su hermano.</p>',
 'exterior',
 '[{"campo":"Edad","valor":"19"},{"campo":"Familia","valor":"Hermano mayor de Matías, hijo de Elena"}]'::jsonb,
 'published', 'canon', 1),
('elena', 'Elena', 'Madre de Leonardo y Matías', null,
 'No quiere que sus hijos se maten en la calle.',
 '<p>Elena le reprocha a Leonardo que le preste la moto a su hermano. Se entera del accidente por el noticiero.</p><p>Cuatro años después, se niega a que Matías corra. Al final le pide una sola cosa: que no viva una vida elegida por el miedo.</p>',
 'casa',
 '[{"campo":"Familia","valor":"Madre de Leonardo y Matías"}]'::jsonb,
 'published', 'canon', 2),
('bruno', 'Bruno', 'Antiguo amigo de Leonardo', '22',
 'Le entrega a Matías la GoPro de su hermano y lo ayuda a reparar la moto.',
 '<p>La noche del accidente es quien le escribe a Matías que su hermano falleció.</p><p>Cuatro años después le devuelve la GoPro de Leonardo, repara la moto con él y le dice lo que nadie se atreve: que está corriendo contra el mismo trauma.</p>',
 'taller',
 '[{"campo":"Edad","valor":"22 (cuatro años después)"},{"campo":"Relación","valor":"Antiguo amigo de Leonardo"}]'::jsonb,
 'published', 'canon', 3),
('veronica', 'Verónica', 'Piloto', '21',
 'Toma la trazada con precisión. Le pregunta a Matías si se va a quedar mirando toda la tarde.',
 '<p>La noche del accidente le manda a Matías un audio para que vaya al hospital.</p><p>Cuatro años después corre en la pista donde Matías solo mira. Compite contra él dos veces.</p>',
 'pista',
 '[{"campo":"Edad","valor":"21 (cuatro años después)"},{"campo":"Actividad","valor":"Piloto"}]'::jsonb,
 'published', 'canon', 4);

insert into public.character_relations (from_id, to_id, label, sort_order)
select f.id, t.id, r.label, r.ord
from (values
  ('matias','leonardo','Hermano mayor',0), ('matias','elena','Madre',1), ('matias','bruno','Antiguo amigo de Leonardo',2), ('matias','veronica','Compite contra él',3),
  ('leonardo','matias','Hermano menor',0), ('leonardo','elena','Madre',1), ('leonardo','bruno','Antiguo amigo',2),
  ('elena','leonardo','Hijo mayor',0), ('elena','matias','Hijo menor',1),
  ('bruno','leonardo','Antiguo amigo',0), ('bruno','matias','Lo ayuda a reparar la moto',1),
  ('veronica','matias','Compite contra él',0)
) as r(f, t, label, ord)
join public.characters f on f.slug = r.f
join public.characters t on t.slug = r.t;

-- Escenas (en borrador: publicarlas revela la trama completa) ------------
insert into public.scenes (number, heading, era, world, summary, status) values
 (1,  'EXT. CARRETERA RURAL – DÍA', 'antes', 'exterior', 'Presentación de Leonardo: seguridad, concentración y libertad. La carretera es la «pista» del título.', 'draft'),
 (2,  'INT. GARAJE – DÍA', 'antes', 'taller', 'La admiración de Matías por su hermano.', 'draft'),
 (3,  'EXT. CALLE – DÍA', 'antes', 'exterior', 'La primera lección. Su frase vuelve en el flashback de la escena 20.', 'draft'),
 (4,  'EXT. CARRETERA – TARDE', 'antes', 'exterior', 'Matías recorre la misma ruta que Leonardo hizo esa mañana.', 'draft'),
 (5,  'INT. CASA – DÍA', 'antes', 'casa', 'La casa es el refugio, aunque haya conflicto.', 'draft'),
 (6,  'INT. HABITACIÓN DE MATÍAS – TARDE', 'antes', 'casa', 'Matías, feliz por haber manejado, intenta no oír la discusión.', 'draft'),
 (7,  'INT. CASA – TARDE', 'antes', 'casa', 'La última vez que vemos a Leonardo en casa.', 'draft'),
 (8,  'EXT. PISTA – NOCHE', 'la_noche', 'pista', 'La carrera y el accidente de Leonardo.', 'draft'),
 (9,  'INT. CASA – NOCHE', 'la_noche', 'casa', 'Elena se entera por el noticiero.', 'draft'),
 (10, 'INT. PIEZA DE MATÍAS – NOCHE (CONT.)', 'la_noche', 'casa', 'Matías se entera por el celular.', 'draft'),
 (11, 'EXT. PISTA – TARDE – CUATRO AÑOS DESPUÉS', 'cuatro_anios_despues', 'pista', 'Matías (20) mira, pero no corre. Bruno le entrega la GoPro de Leonardo.', 'draft'),
 (12, 'INT. CASA – NOCHE (LA CENA)', 'cuatro_anios_despues', 'casa', 'Matías le dice a Elena que quiere correr. Entre ambos, la silla vacía de Leonardo.', 'draft'),
 (13, 'INT. GARAJE – NOCHE', 'cuatro_anios_despues', 'taller', 'Los videos de Leonardo.', 'draft'),
 (14, 'INT. GARAJE – DÍA', 'cuatro_anios_despues', 'taller', 'Bruno ayuda a reparar la moto. Advertencia y trabajo.', 'draft'),
 (15, 'EXT. CARRETERA – DÍA', 'cuatro_anios_despues', 'exterior', 'Por primera vez Matías siente la libertad por sí mismo.', 'draft'),
 (16, 'INT. CASA – DÍA', 'cuatro_anios_despues', 'casa', 'Elena ve la moto: el pasado frente a ella.', 'draft'),
 (17, 'EXT. PISTA – TARDE (CARRERA 1)', 'cuatro_anios_despues', 'pista', 'Matías corre contra el trauma y pierde.', 'draft'),
 (18, 'INT. TALLER – NOCHE', 'cuatro_anios_despues', 'taller', 'La pelea con Bruno y la lección de Leonardo.', 'draft'),
 (19, 'INT. CASA (SALÓN) – NOCHE', 'cuatro_anios_despues', 'casa', 'Por primera vez dejan de pelear contra el mismo dolor.', 'draft'),
 (20, 'EXT. PISTA – TARDE (CARRERA 2)', 'cuatro_anios_despues', 'pista', 'Matías corre su propia línea.', 'draft'),
 (21, 'INT. CASA (COCINA) – NOCHE', 'cuatro_anios_despues', 'casa', 'Matías decide no competir y terminar de arreglar la moto, por el recuerdo.', 'draft'),
 (22, 'EXT. CARRETERA – ATARDECER', 'cuatro_anios_despues', 'exterior', 'Matías conduce solo hasta un mirador: ahora la libertad es suya.', 'draft');

-- Frases literales -----------------------------------------------------
insert into public.quotes (text, character_id, scene_id, featured, status, sort_order)
select q.txt, c.id, s.id, q.feat, 'published', q.ord
from (values
  ('No corras para llegar a donde yo llegue, corre hasta encontrar, tu propia pista.', 'leonardo', 13, true, 0),
  ('No es necesario que seas igual que yo', 'leonardo', 2, true, 1),
  ('Si te caì, te levantaì nomas', 'leonardo', 3, true, 2),
  ('Y si no podi, yo te levanto.', 'leonardo', 3, true, 3),
  ('La línea más rápida no siempre es la que más corta la pista. A veces tienes que abrirte para salir mejor de la curva. No tengas miedo de caerte.', 'leonardo', 18, false, 4),
  ('No soy Leo.', 'matias', 16, true, 5),
  ('No puedo pasar toda la vida evitando correr', 'matias', 12, false, 6),
  ('pero nadie me dijo hacia donde', 'matias', 19, false, 7),
  ('Espero que este orgulloso de quien soy ahora.', 'matias', 21, false, 8),
  ('Y yo no puedo pasar toda la vida enterrando hijos', 'elena', 12, true, 9),
  ('No estoy hablando de la moto.', 'elena', 16, false, 10),
  ('entonces no lo seas... pero no vivas una vida elegida por el miedo..', 'elena', 19, true, 11),
  ('tu hermano.... el era bueno, pero tu no eres el.', 'bruno', 14, false, 12),
  ('hermano no podi ganarle a un muerto', 'bruno', 18, true, 13),
  ('asi nunca vai a correr', 'veronica', 11, true, 14),
  ('Tomate esta wea enserio, ya no eri un cabro chico.', 'veronica', 17, false, 15)
) as q(txt, slug, num, feat, ord)
join public.characters c on c.slug = q.slug
join public.scenes s on s.number = q.num;

-- Cronología -----------------------------------------------------------
insert into public.timeline_events (title, era, description, world, scene_id, status, sort_order)
select e.title, e.era::public.era, e.descr, e.world::public.world, s.id, 'published', e.ord
from (values
  ('Leonardo en la carretera', 'antes', 'El rugido de una moto deportiva rompe el silencio del campo. Leonardo conduce con seguridad.', 'exterior', 1, 0),
  ('Ya quiero correr como tú', 'antes', 'Matías limpia su pequeña moto y espera a su hermano en el garaje.', 'taller', 2, 1),
  ('La primera lección', 'antes', 'Leonardo le enseña a Matías a andar en moto por una calle tranquila.', 'exterior', 3, 2),
  ('La misma ruta', 'antes', 'Matías conduce la moto de Leonardo por la ruta que su hermano recorrió esa mañana.', 'exterior', 4, 3),
  ('La discusión', 'antes', 'Elena le reprocha a Leonardo que le preste la moto a su hermano. Matías la escucha desde su pieza.', 'casa', 5, 4),
  ('Este finde', 'antes', 'Leonardo le dice a Elena que compite este fin de semana y se va.', 'casa', 7, 5),
  ('La carrera', 'la_noche', 'Una pista improvisada iluminada por focos y faros. La rueda trasera pierde adherencia y Leonardo cae.', 'pista', 8, 6),
  ('Último minuto', 'la_noche', 'Elena escucha en el noticiero la palabra «accidente».', 'casa', 9, 7),
  ('Los mensajes', 'la_noche', 'Un audio de Verónica, un mensaje de Bruno y después muchos más.', 'casa', 10, 8),
  ('La GoPro', 'cuatro_anios_despues', 'Matías mira la pista desde afuera. Bruno le entrega la GoPro de Leonardo.', 'pista', 11, 9),
  ('La silla vacía', 'cuatro_anios_despues', 'En la cena, Matías le dice a Elena que quiere correr.', 'casa', 12, 10),
  ('Los videos', 'cuatro_anios_despues', 'En el garaje, Matías enciende la cámara de su hermano y se queda toda la noche viendo sus videos.', 'taller', 13, 11),
  ('Frenos, aceite, cadena', 'cuatro_anios_despues', 'Bruno y Matías reparan la moto de Leonardo hasta que el motor arranca.', 'taller', 14, 12),
  ('Solo conduce', 'cuatro_anios_despues', 'Durante unos segundos Matías no piensa en Leonardo. Solo conduce.', 'exterior', 15, 13),
  ('Primera carrera', 'cuatro_anios_despues', 'Matías frena en una curva y cruza la meta en segundo lugar.', 'pista', 17, 14),
  ('Contra el mismo trauma', 'cuatro_anios_despues', 'Matías empuja a Bruno en el taller. Después ve un video de Leonardo hablando sobre conducción.', 'taller', 18, 15),
  ('En el piso del salón', 'cuatro_anios_despues', 'Elena se sienta junto a Matías. Por primera vez dejan de pelear contra el mismo dolor.', 'casa', 19, 16),
  ('Su propia línea', 'cuatro_anios_despues', 'Matías no persigue a Verónica: busca su propia trayectoria y cruza primero por centímetros.', 'pista', 20, 17),
  ('Por el recuerdo', 'cuatro_anios_despues', 'Matías decide no competir y terminar de arreglar la moto.', 'casa', 21, 18),
  ('El mirador', 'cuatro_anios_despues', 'Matías conduce solo hasta un mirador. El silencio ya no se siente como una ausencia.', 'exterior', 22, 19)
) as e(title, era, descr, world, num, ord)
join public.scenes s on s.number = e.num;

-- Motos ----------------------------------------------------------------
insert into public.vehicles (slug, name, owner_id, summary, specs, state, status, sort_order)
select v.slug, v.name, c.id, v.summary, v.specs::jsonb, v.state, 'published', v.ord
from (values
  ('moto-leonardo', 'La moto de Leonardo', 'leonardo',
   'Leonardo la modificó él mismo y lo grabó con su GoPro. Matías la conduce por primera vez por la carretera. Cuatro años después está cubierta en el garaje; Bruno y Matías la reparan.',
   '[{"campo":"Marca","valor":""},{"campo":"Modelo","valor":""},{"campo":"Cilindrada","valor":""},{"campo":"Modificaciones","valor":"Hechas por Leonardo (registradas en su GoPro)"}]',
   'Reparada por Bruno y Matías. Matías decide no venderla.', 0),
  ('moto-matias', 'La moto de Matías', 'matias',
   'Su pequeña motocicleta, la que limpia con cuidado mientras espera a su hermano. Con ella aprende a usar los dos frenos.',
   '[{"campo":"Marca","valor":""},{"campo":"Modelo","valor":""},{"campo":"Cilindrada","valor":""}]',
   null, 1)
) as v(slug, name, owner, summary, specs, state, ord)
join public.characters c on c.slug = v.owner;

-- Colecciones ----------------------------------------------------------
insert into public.collections (slug, title, description, template, owner_id, world, status, sort_order)
select k.slug, k.title, k.descr, k.tpl::public.collection_template, c.id, k.world::public.world, k.st::public.content_status, k.ord
from (values
  ('gopro-leonardo', 'GoPro de Leonardo', 'Una GoPro vieja. Bruno la encontró gracias a su mamá. La batería está casi agotada.', 'camara', 'leonardo', 'taller', 'published', 0),
  ('la-noche', 'La noche', 'Lo que llegó a los celulares la noche de la carrera.', 'celular', 'matias', 'casa', 'published', 1),
  ('instagram-leonardo', 'Instagram de Leonardo', 'Publicaciones guardadas en la cuenta de Leonardo.', 'feed', 'leonardo', 'taller', 'published', 2),
  ('registros', 'Registros', 'Carreras y noticias.', 'carpeta', null, 'pista', 'published', 3),
  ('produccion', 'Detrás de cámaras', 'Material del rodaje.', 'carpeta', null, 'exterior', 'published', 4),
  ('archivo-anterior', 'Sitio anterior (no canónico)', 'Textos del sitio anterior que no están en el guion. Solo visibles en el admin hasta que decidas qué hacer con ellos.', 'carpeta', null, null, 'draft', 9)
) as k(slug, title, descr, tpl, owner, world, st, ord)
left join public.characters c on c.slug = k.owner;

-- Archivos canónicos ---------------------------------------------------
insert into public.entries (code, type, collection_id, title, summary, body, date_label, world, meta, status, canon, sort_order)
select x.code, x.type::public.entry_type, k.id, x.title, x.summary, x.body, x.date_label, x.world::public.world, x.meta::jsonb, 'published', 'canon', x.ord
from (values
  ('GP-001', 'video', 'gopro-leonardo', 'Las modificaciones',
   'Leonardo, sentado sobre la moto, termina unas modificaciones. Está cansado, pero emocionado.',
   '<p>Leonardo ajusta una pieza, prueba el encendido y el motor falla.</p><blockquote>A Matias le va a encantar</blockquote><blockquote>si no funciona no se que hacer</blockquote><p>Hace un último intento. El motor finalmente arranca. Leonardo sonríe, sorprendido.</p><blockquote>Vamos mierda</blockquote>',
   'Antes del accidente', 'taller', '{"dispositivo":"GoPro","autor":"Leonardo"}', 0),
  ('GP-002', 'video', 'gopro-leonardo', 'Mati, si algún día ves esto',
   'El final del mismo video. Leonardo salta de alegría y mira directamente a la cámara.',
   '<blockquote>Mati, si algun dia vez esto....</blockquote><blockquote>No corras para llegar a donde yo llegue, corre hasta encontrar, tu propia pista.</blockquote><blockquote>Si encuentras este video mañana voy a quedar como weon</blockquote>',
   'Antes del accidente', 'taller', '{"dispositivo":"GoPro","autor":"Leonardo","nota":"Fragmento final del video GP-001"}', 1),
  ('CEL-001', 'mensaje', 'la-noche', 'Buena suerte',
   'En el celular de Leonardo, antes de la carrera: un mensaje de Matías con un sticker de buena suerte. Leonardo sonríe al verlo.',
   null, 'La noche de la carrera', 'pista', '{"de":"Matías","para":"Leonardo"}', 0),
  ('CEL-002', 'audio', 'la-noche', 'Audio de Verónica',
   'Matías ve la notificación y se lo toma con humor: «Que wea quiere esta ahora».',
   '<blockquote>¡Matias tu hermano choco wn, en la K-40, se lo llevo la ambulancia, anda pal hospital altiro!</blockquote>',
   'La noche de la carrera', 'casa', '{"de":"Verónica","para":"Matías"}', 1),
  ('CEL-003', 'mensaje', 'la-noche', 'Mensaje de Bruno',
   'Después le empiezan a llegar un montón de mensajes.',
   '<blockquote>Mati, tu hermano acaba de fallecer...</blockquote>',
   'La noche de la carrera', 'casa', '{"de":"Bruno","para":"Matías"}', 2),
  ('REG-001', 'noticia', 'registros', 'Noticiero · Último minuto',
   'Una noticia de última hora interrumpe la programación mientras Elena espera a sus hijos.',
   '<blockquote>Ultimo minuto. En estos momentos estamos evidenciando un accidente de motocicleta en san Rafael, en la ruta K-40. Un joven de aproximadamente 19 años se encontró sin vida producto de la gravedad de sus lesiones luego de un par de minutos pasado el accidente. vamos a seguir reportando para dar mas información al respecto...</blockquote>',
   'La noche de la carrera', 'casa', '{"medio":"Noticiero"}', 0),
  ('REG-002', 'registro', 'registros', 'La carrera de Leonardo',
   'Una pista improvisada, iluminada por focos y faros. Pocos espectadores y varias motos alineadas.',
   '<p>La carrera comienza. Leonardo acelera, toma una curva, vuelve a abrir el acelerador y busca ganar posiciones. La rueda trasera pierde adherencia. La motocicleta se cruza. Leonardo intenta corregirla, pero cae.</p>',
   'La noche de la carrera', 'pista', '{"piloto":"Leonardo"}', 1),
  ('REG-003', 'registro', 'registros', 'Carrera 1 · Segundo lugar',
   'Matías entra rápido a la primera curva, se abre demasiado y Verónica lo adelanta.',
   '<p>En otra curva vuelve el recuerdo de la noche del accidente. Matías frena, pierde posiciones y cruza la meta en segundo lugar.</p>',
   'Cuatro años después', 'pista', '{"piloto":"Matías","resultado":"2.º"}', 2),
  ('REG-004', 'registro', 'registros', 'Carrera 2 · Primero por centímetros',
   'Esta vez Matías no busca demostrar nada. Estudia las curvas y respira con calma.',
   '<p>No persigue a Verónica: busca su propia trayectoria. En la última curva abre ligeramente la línea y prepara la aceleración. Cruza primero por centímetros. No grita ni celebra. Solo sonríe.</p>',
   'Cuatro años después', 'pista', '{"piloto":"Matías","resultado":"1.º"}', 3),
  ('IG-001', 'video', 'instagram-leonardo', 'La línea más rápida',
   'Un antiguo video de Leonardo hablando sobre conducción.',
   '<blockquote>La línea más rápida no siempre es la que más corta la pista. A veces tienes que abrirte para salir mejor de la curva. No tengas miedo de caerte.</blockquote>',
   'Antes del accidente', 'exterior', '{"plataforma":"Instagram","formato":"vertical 9:16"}', 0)
) as x(code, type, coll, title, summary, body, date_label, world, meta, ord)
join public.collections k on k.slug = x.coll;

-- El mensaje final se abre después de ver el primer fragmento (secreto narrativo).
update public.entries set unlock = 'after_entries',
  unlock_after = array[(select id from public.entries where code = 'GP-001')],
  unlock_hint = 'Mira primero el video de las modificaciones.'
where code = 'GP-002';

insert into public.entry_links (entry_id, character_id)
select e.id, c.id from (values
  ('GP-001','leonardo'), ('GP-002','leonardo'), ('GP-002','matias'), ('CEL-001','matias'), ('CEL-001','leonardo'),
  ('CEL-002','veronica'), ('CEL-002','matias'), ('CEL-003','bruno'), ('CEL-003','matias'), ('REG-001','elena'),
  ('REG-002','leonardo'), ('REG-003','matias'), ('REG-003','veronica'), ('REG-004','matias'), ('REG-004','veronica'),
  ('IG-001','leonardo')
) as l(code, slug)
join public.entries e on e.code = l.code
join public.characters c on c.slug = l.slug;

insert into public.entry_links (entry_id, scene_id)
select e.id, s.id from (values
  ('GP-001',13), ('GP-002',13), ('CEL-001',8), ('CEL-002',10), ('CEL-003',10), ('REG-001',9),
  ('REG-002',8), ('REG-003',17), ('REG-004',20), ('IG-001',18)
) as l(code, num)
join public.entries e on e.code = l.code
join public.scenes s on s.number = l.num;

insert into public.entry_links (entry_id, vehicle_id)
select e.id, v.id from (values ('GP-001','moto-leonardo'), ('GP-002','moto-leonardo')) as l(code, slug)
join public.entries e on e.code = l.code
join public.vehicles v on v.slug = l.slug;

-- Textos del sitio anterior (borrador, no canónicos) ----------------------
insert into public.entries (code, type, collection_id, title, summary, status, canon, sort_order)
select x.code, 'nota', k.id, x.title, x.summary, 'draft', 'no_canonico', x.ord
from (values
  ('OLD-P001', 'Una fecha oculta', 'Una fotografía aparentemente normal contiene una fecha escrita al reverso.', 0),
  ('OLD-P002', 'Segundos adicionales', 'Un video de Leonardo contiene unos segundos adicionales al final que nadie había notado.', 1),
  ('OLD-P003', 'Publicación antigua', 'Una publicación antigua de Instagram contiene información sobre una carrera.', 2),
  ('OLD-P004', 'Una nota sin explicación', 'Una nota de Matías hace referencia a algo que no se explica en el cortometraje.', 3),
  ('OLD-P005', 'Una modificación importante', 'Una fotografía de la motocicleta muestra una modificación que podría ser importante.', 4),
  ('OLD-P006', 'Testigo sin identificar', 'El reporte del accidente menciona a un testigo cuyo nombre fue tachado.', 5),
  ('OLD-IG01', 'Post: una curva mal tomada', 'Una curva mal tomada puede cambiarlo todo.', 6),
  ('OLD-IG02', 'Post: toda la tarde bajo la moto', 'Toda la tarde bajo la moto. Mañana se sabrá si valió la pena.', 7),
  ('OLD-IG04', 'Post: Matías ya casi llega a mi cintura', 'Matías ya casi llega a mi cintura. En un rato me pasa.', 8),
  ('OLD-D01', 'Diario de Matías: día 01', 'Hoy volví a tocar la moto de Leo.', 9),
  ('OLD-D14', 'Diario de Matías: día 14', 'Todos dicen que debería dejarlo atrás.', 10),
  ('OLD-D28', 'Diario de Matías: día 28', 'Quizás no quiero ser como él.', 11),
  ('OLD-D41', 'Diario de Matías: día 41', 'Quizás solo quiero entenderlo.', 12)
) as x(code, title, summary, ord)
join public.collections k on k.slug = 'archivo-anterior';

-- Créditos -------------------------------------------------------------
insert into public.credits (person, role, department, status, sort_order) values
  ('Juan Daniel Bermúdez', 'Guion', 'Guion', 'published', 0);
