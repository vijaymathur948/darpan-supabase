alter table public.books
  add column language text
  check (language in ('Hindi', 'English'));

update public.books
set language = 'Hindi'
where language is null;

alter table public.books
  alter column language set default 'Hindi',
  alter column language set not null;

alter table public.books
  add constraint books_max_unit_amount_required
  check (max_unit_amount is not null or deleted_at is not null)
  not valid;
