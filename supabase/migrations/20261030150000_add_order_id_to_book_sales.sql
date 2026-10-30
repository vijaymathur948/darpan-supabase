alter table public.book_sales
  add column order_id uuid references public.orders(id) on delete set null;

create index book_sales_order_id_idx on public.book_sales (order_id);
