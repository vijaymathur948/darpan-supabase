alter table public.expense
  add column name text not null default 'Expense';

alter table public.expense
  add constraint expense_name_not_empty check (length(trim(name)) > 0);
