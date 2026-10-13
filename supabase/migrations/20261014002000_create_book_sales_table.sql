create table public.book_sales (
  id uuid primary key default gen_random_uuid(),
  book_id uuid references public.books(id) on delete set null,
  book_title text not null,
  quantity integer not null,
  unit_price numeric(12, 2) not null,
  sold_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint book_sales_quantity_positive check (quantity > 0),
  constraint book_sales_unit_price_non_negative check (unit_price >= 0)
);

create index book_sales_sold_at_idx on public.book_sales (sold_at desc);
create index book_sales_book_id_idx on public.book_sales (book_id);

alter table public.book_sales enable row level security;

grant select, insert, update, delete on table public.book_sales to anon, authenticated;

create policy "Anyone can read book_sales" on public.book_sales for select to anon, authenticated using (true);
create policy "Anyone can insert book_sales" on public.book_sales for insert to anon, authenticated with check (true);
create policy "Anyone can update book_sales" on public.book_sales for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete book_sales" on public.book_sales for delete to anon, authenticated using (true);
