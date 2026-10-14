alter table public.books
  add column min_unit_amount numeric(12, 2),
  add column max_unit_amount numeric(12, 2);

alter table public.books
  add constraint books_min_unit_amount_non_negative
    check (min_unit_amount is null or min_unit_amount >= 0),
  add constraint books_max_unit_amount_non_negative
    check (max_unit_amount is null or max_unit_amount >= 0);
