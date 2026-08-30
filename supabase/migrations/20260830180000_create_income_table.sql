-- Income: one row per receipt. No sources catalog — a single stream of amounts by date.

create table public.income (
  id uuid primary key default gen_random_uuid(),
  entry_date timestamptz not null,
  amount numeric(12, 2) not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint income_amount_positive check (amount > 0)
);

create index income_entry_date_idx
  on public.income (entry_date desc);

create or replace function public.set_income_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger income_set_updated_at
  before update on public.income
  for each row
  execute function public.set_income_updated_at();

alter table public.income enable row level security;

grant select, insert, update, delete on table public.income to anon, authenticated;

create policy "Anyone can read income"
  on public.income
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert income"
  on public.income
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update income"
  on public.income
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete income"
  on public.income
  for delete
  to anon, authenticated
  using (true);