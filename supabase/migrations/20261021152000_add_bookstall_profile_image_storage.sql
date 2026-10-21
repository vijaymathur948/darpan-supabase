alter table public.bookstall
  add column if not exists image_path text not null default '';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'bookstall-profile-images',
  'bookstall-profile-images',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "Anyone can read bookstall profile images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'bookstall-profile-images');

create policy "Anyone can upload bookstall profile images"
  on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'bookstall-profile-images');

create policy "Anyone can update bookstall profile images"
  on storage.objects for update to anon, authenticated
  using (bucket_id = 'bookstall-profile-images')
  with check (bucket_id = 'bookstall-profile-images');

create policy "Anyone can delete bookstall profile images"
  on storage.objects for delete to anon, authenticated
  using (bucket_id = 'bookstall-profile-images');
