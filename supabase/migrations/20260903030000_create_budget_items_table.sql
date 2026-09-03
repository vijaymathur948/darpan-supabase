-- Budget items break a category budget into smaller planned amounts.

create table public.budget_item (
  id uuid primary key default gen_random_uuid(),
  budget_id uuid not null references public.budget(id) on delete cascade,
  name text not null,
  amount numeric(12, 2) not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint budget_item_name_not_empty check (char_length(trim(name)) > 0),
  constraint budget_item_amount_positive check (amount > 0)
);

create index budget_item_budget_id_idx on public.budget_item (budget_id);

create or replace function public.set_budget_item_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger budget_item_set_updated_at
  before update on public.budget_item
  for each row
  execute function public.set_budget_item_updated_at();

alter table public.budget_item enable row level security;

grant select, insert, update, delete on table public.budget_item to anon, authenticated;

create policy "Anyone can read budget items" on public.budget_item for select to anon, authenticated using (true);
create policy "Anyone can insert budget items" on public.budget_item for insert to anon, authenticated with check (true);
create policy "Anyone can update budget items" on public.budget_item for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete budget items" on public.budget_item for delete to anon, authenticated using (true);