alter table public.orders
  add column planned_at date,
  add column cancelled_at date;
