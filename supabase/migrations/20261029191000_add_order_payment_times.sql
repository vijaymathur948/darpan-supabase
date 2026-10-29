alter table public.order_payments
  add column paid_time time;

grant update (paid_time) on table public.order_payments to anon, authenticated;
