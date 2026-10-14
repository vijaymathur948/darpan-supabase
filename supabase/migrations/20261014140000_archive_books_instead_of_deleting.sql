alter table public.books
  add column deleted_at timestamptz;

create index books_active_created_at_idx
  on public.books (created_at desc)
  where deleted_at is null;
