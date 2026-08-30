-- Threats catalog: named entries with a type and description.

create table public.threats (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  type text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint threats_name_not_blank check (char_length(trim(name)) > 0),
  constraint threats_type_not_blank check (char_length(trim(type)) > 0)
);

create index threats_created_at_idx on public.threats (created_at desc);
create index threats_name_idx on public.threats (name);
create index threats_type_idx on public.threats (type);

create or replace function public.set_threats_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger threats_set_updated_at
  before update on public.threats
  for each row
  execute function public.set_threats_updated_at();

alter table public.threats enable row level security;

grant select, insert, update, delete on table public.threats to anon, authenticated;

create policy "Anyone can read threats"
  on public.threats
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert threats"
  on public.threats
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update threats"
  on public.threats
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete threats"
  on public.threats
  for delete
  to anon, authenticated
  using (true);
