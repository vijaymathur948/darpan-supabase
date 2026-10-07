create table public.financial_deadlines (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  amount numeric(12, 2),
  start_date date not null,
  duration interval not null,
  completed_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_financial_deadlines_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger financial_deadlines_set_updated_at
  before update on public.financial_deadlines
  for each row
  execute function public.set_financial_deadlines_updated_at();

alter table public.financial_deadlines enable row level security;

grant select, insert, update, delete on table public.financial_deadlines to anon, authenticated;

create policy "Anyone can read financial_deadlines"
  on public.financial_deadlines
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert financial_deadlines"
  on public.financial_deadlines
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update financial_deadlines"
  on public.financial_deadlines
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete financial_deadlines"
  on public.financial_deadlines
  for delete
  to anon, authenticated
  using (true);
