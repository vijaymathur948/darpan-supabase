create type public.expense_type as enum (
  'mandatory',
  'optional'
);

alter table public.expense
  add column type public.expense_type not null default 'optional';

create index expense_type_idx
  on public.expense (type);