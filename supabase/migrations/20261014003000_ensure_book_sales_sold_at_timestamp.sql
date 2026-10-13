alter table public.book_sales
  alter column sold_at type timestamptz
  using sold_at::timestamptz;
