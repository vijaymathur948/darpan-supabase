-- Problems people are trying to solve (generic catalog, not app bug reports).

create table public.problems (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  solution text not null default '',
  website text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint problems_title_not_blank check (char_length(trim(title)) > 0)
);

create index problems_created_at_idx on public.problems (created_at desc);
create index problems_title_idx on public.problems (title);

create or replace function public.set_problems_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger problems_set_updated_at
  before update on public.problems
  for each row
  execute function public.set_problems_updated_at();

alter table public.problems enable row level security;

grant select, insert, update, delete on table public.problems to anon, authenticated;

create policy "Anyone can read problems"
  on public.problems
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert problems"
  on public.problems
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update problems"
  on public.problems
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete problems"
  on public.problems
  for delete
  to anon, authenticated
  using (true);
