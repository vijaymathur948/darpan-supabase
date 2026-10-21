-- Bookstall: name and image.

create table public.bookstall (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookstall_name_not_blank check (length(trim(name)) > 0)
);

create or replace function public.set_bookstall_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger bookstall_set_updated_at
  before update on public.bookstall
  for each row
  execute function public.set_bookstall_updated_at();

alter table public.bookstall enable row level security;

grant select, insert, update, delete on table public.bookstall to anon, authenticated;

create policy "Anyone can read bookstall" on public.bookstall for select to anon, authenticated using (true);
create policy "Anyone can insert bookstall" on public.bookstall for insert to anon, authenticated with check (true);
create policy "Anyone can update bookstall" on public.bookstall for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete bookstall" on public.bookstall for delete to anon, authenticated using (true);
