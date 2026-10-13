alter table public.book_sales
  add column payment_mode text not null default 'cash',
  add constraint book_sales_payment_mode_valid check (payment_mode in ('cash', 'online'));
