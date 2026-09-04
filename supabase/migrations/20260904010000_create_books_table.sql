-- Books: one record per book, with an optional cover image.

create table public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text,
  image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint books_title_not_empty check (char_length(trim(title)) > 0)
);

create index books_created_at_idx on public.books (created_at desc);

create or replace function public.set_books_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger books_set_updated_at
  before update on public.books
  for each row
  execute function public.set_books_updated_at();

alter table public.books enable row level security;

grant select, insert, update, delete on table public.books to anon, authenticated;

create policy "Anyone can read books" on public.books for select to anon, authenticated using (true);
create policy "Anyone can insert books" on public.books for insert to anon, authenticated with check (true);
create policy "Anyone can update books" on public.books for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete books" on public.books for delete to anon, authenticated using (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('book-images', 'book-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "Anyone can read book images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'book-images');

create policy "Anyone can upload book images"
  on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'book-images');

create policy "Anyone can update book images"
  on storage.objects for update to anon, authenticated
  using (bucket_id = 'book-images') with check (bucket_id = 'book-images');

create policy "Anyone can delete book images"
  on storage.objects for delete to anon, authenticated
  using (bucket_id = 'book-images');