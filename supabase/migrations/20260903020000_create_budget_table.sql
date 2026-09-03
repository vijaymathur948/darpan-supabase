-- Budget: one planned amount per category and month.

create table public.budget (
  id uuid primary key default gen_random_uuid(),
  month date not null,
  category text not null default 'general',
  amount numeric(12, 2) not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint budget_month_start check (month = date_trunc('month', month)::date),
  constraint budget_amount_positive check (amount > 0),
  constraint budget_month_category_unique unique (month, category)
);

create index budget_month_idx on public.budget (month desc);

create or replace function public.set_budget_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger budget_set_updated_at
  before update on public.budget
  for each row
  execute function public.set_budget_updated_at();

alter table public.budget enable row level security;

grant select, insert, update, delete on table public.budget to anon, authenticated;

create policy "Anyone can read budget" on public.budget for select to anon, authenticated using (true);
create policy "Anyone can insert budget" on public.budget for insert to anon, authenticated with check (true);
create policy "Anyone can update budget" on public.budget for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete budget" on public.budget for delete to anon, authenticated using (true);