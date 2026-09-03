-- Expense: one row per expense entry. Keeps the same basic structure as income.

create table public.expense (
  id uuid primary key default gen_random_uuid(),
  entry_date timestamptz not null,
  amount numeric(12, 2) not null,
  category text not null default 'general',
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint expense_amount_positive check (amount > 0)
);

create index expense_entry_date_idx
  on public.expense (entry_date desc);

create or replace function public.set_expense_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger expense_set_updated_at
  before update on public.expense
  for each row
  execute function public.set_expense_updated_at();

alter table public.expense enable row level security;

grant select, insert, update, delete on table public.expense to anon, authenticated;

create policy "Anyone can read expense"
  on public.expense
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert expense"
  on public.expense
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update expense"
  on public.expense
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete expense"
  on public.expense
  for delete
  to anon, authenticated
  using (true);
