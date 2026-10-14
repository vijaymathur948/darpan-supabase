alter table public.book_sales
  drop constraint book_sales_payment_mode_valid,
  add constraint book_sales_payment_mode_valid check (payment_mode in ('cash', 'online', 'gift'));
