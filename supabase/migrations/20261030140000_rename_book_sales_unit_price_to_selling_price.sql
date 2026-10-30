alter table public.book_sales
  rename column unit_price to selling_price;

alter table public.book_sales
  rename constraint book_sales_unit_price_non_negative to book_sales_selling_price_non_negative;
