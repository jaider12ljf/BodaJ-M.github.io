-- Álbum de la boda J&M — configuración de Supabase (pegar completo en SQL Editor y ejecutar una vez).
-- Los invitados (sin cuenta) pueden VER y SUBIR. Nadie puede borrar ni editar desde la app:
-- la moderación se hace desde el panel de Supabase (Table editor / Storage).

-- 1) Tabla de recuerdos
create table if not exists public.recuerdos (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  invitado    text not null check (char_length(invitado) between 1 and 60),
  momento     text not null check (momento in ('preboda','ceremonia','recepcion','fiesta')),
  tipo        text not null check (tipo in ('foto','video')),
  ruta        text not null check (ruta ~ '^r/[0-9a-z-]{8,40}\.(jpg|jpeg|png|webp|heic|heif|mp4|mov|webm)$'),
  miniatura   text not null check (miniatura ~ '^t/[0-9a-z-]{8,40}\.jpg$'),
  ancho       int  check (ancho between 1 and 10000),
  alto        int  check (alto between 1 and 10000),
  oculto      boolean not null default false
);
create index if not exists recuerdos_fecha on public.recuerdos (created_at desc);

-- El servidor fija id, fecha y visibilidad: un invitado no puede inventarlos
create or replace function public.recuerdos_sanear() returns trigger
language plpgsql as $$
begin
  new.id := gen_random_uuid();
  new.created_at := now();
  new.oculto := false;
  return new;
end $$;
drop trigger if exists recuerdos_sanear on public.recuerdos;
create trigger recuerdos_sanear before insert on public.recuerdos
  for each row execute function public.recuerdos_sanear();

alter table public.recuerdos enable row level security;

drop policy if exists "ver recuerdos" on public.recuerdos;
create policy "ver recuerdos" on public.recuerdos
  for select to anon, authenticated using (oculto = false);

drop policy if exists "subir recuerdos" on public.recuerdos;
create policy "subir recuerdos" on public.recuerdos
  for insert to anon, authenticated with check (oculto = false);

-- Permisos de la API (por si el proyecto no expone tablas nuevas automáticamente)
grant usage on schema public to anon, authenticated;
grant select, insert on public.recuerdos to anon, authenticated;

-- Avisos en vivo cuando alguien sube algo
do $$ begin
  alter publication supabase_realtime add table public.recuerdos;
exception when duplicate_object then null; end $$;

-- 2) Almacenamiento: bucket público de solo lectura + subida (máx. 50 MB, solo fotos y videos)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('album', 'album', true, 52428800,
        array['image/jpeg','image/png','image/webp','image/heic','image/heif',
              'video/mp4','video/quicktime','video/webm'])
on conflict (id) do update
  set public = true, file_size_limit = 52428800,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "album subir" on storage.objects;
create policy "album subir" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'album' and (storage.foldername(name))[1] in ('r','t'));

-- Sin permiso de listar: las fotos se ven solo por su enlace público (bucket público).
-- Para moderar: marcar "oculto" en la tabla y borrar el archivo en Storage.
drop policy if exists "album ver" on storage.objects;
