alter table public.orders
  add column buyer_name text not null default '';
