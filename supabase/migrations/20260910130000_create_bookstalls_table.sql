-- Bookstall: a stall/event entry with a location, duration, images, and flexible metadata.

create table public.bookstalls (
  id uuid primary key default gen_random_uuid(),
  location text not null default '',
  start_time timestamptz not null,
  end_time timestamptz,
  custom_fields jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookstalls_end_after_start check (end_time is null or end_time >= start_time),
  constraint bookstalls_custom_fields_object check (jsonb_typeof(custom_fields) = 'object')
);

create table public.bookstall_images (
  id uuid primary key default gen_random_uuid(),
  bookstall_id uuid not null references public.bookstalls(id) on delete cascade,
  image_url text not null,
  image_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create or replace function public.set_bookstalls_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger bookstalls_set_updated_at
  before update on public.bookstalls
  for each row
  execute function public.set_bookstalls_updated_at();

alter table public.bookstalls enable row level security;
alter table public.bookstall_images enable row level security;

grant select, insert, update, delete on table public.bookstalls to anon, authenticated;
grant select, insert, update, delete on table public.bookstall_images to anon, authenticated;

create policy "Anyone can read bookstalls" on public.bookstalls for select to anon, authenticated using (true);
create policy "Anyone can insert bookstalls" on public.bookstalls for insert to anon, authenticated with check (true);
create policy "Anyone can update bookstalls" on public.bookstalls for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete bookstalls" on public.bookstalls for delete to anon, authenticated using (true);

create policy "Anyone can read bookstall images" on public.bookstall_images for select to anon, authenticated using (true);
create policy "Anyone can insert bookstall images" on public.bookstall_images for insert to anon, authenticated with check (true);
create policy "Anyone can update bookstall images" on public.bookstall_images for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete bookstall images" on public.bookstall_images for delete to anon, authenticated using (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bookstall-images', 'bookstall-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "Anyone can read bookstall storage images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'bookstall-images');

create policy "Anyone can upload bookstall storage images"
  on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'bookstall-images');

create policy "Anyone can update bookstall storage images"
  on storage.objects for update to anon, authenticated
  using (bucket_id = 'bookstall-images') with check (bucket_id = 'bookstall-images');

create policy "Anyone can delete bookstall storage images"
  on storage.objects for delete to anon, authenticated
  using (bucket_id = 'bookstall-images');
