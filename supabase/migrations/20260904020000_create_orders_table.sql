-- Book orders: one record per purchase or planned purchase.

create type public.order_status as enum (
  'planned',
  'ordered',
  'delivered',
  'cancelled'
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  status public.order_status not null default 'planned',
  seller text not null default '',
  amount numeric(12, 2),
  ordered_at date,
  delivered_at date,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_amount_non_negative check (amount is null or amount >= 0),
  constraint orders_delivery_after_order check (delivered_at is null or ordered_at is null or delivered_at >= ordered_at)
);

create index orders_created_at_idx on public.orders (created_at desc);

create or replace function public.set_orders_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger orders_set_updated_at
  before update on public.orders
  for each row
  execute function public.set_orders_updated_at();

alter table public.orders enable row level security;

grant select, insert, update, delete on table public.orders to anon, authenticated;

create policy "Anyone can read orders" on public.orders for select to anon, authenticated using (true);
create policy "Anyone can insert orders" on public.orders for insert to anon, authenticated with check (true);
create policy "Anyone can update orders" on public.orders for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete orders" on public.orders for delete to anon, authenticated using (true);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  book_id uuid references public.books(id) on delete set null,
  quantity integer not null default 1,
  unit_amount numeric(12, 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_items_quantity_positive check (quantity > 0),
  constraint order_items_unit_amount_non_negative check (unit_amount is null or unit_amount >= 0),
  constraint order_items_order_book_unique unique (order_id, book_id)
);

create index order_items_order_id_idx on public.order_items (order_id);

create or replace function public.set_order_items_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger order_items_set_updated_at
  before update on public.order_items
  for each row
  execute function public.set_order_items_updated_at();

alter table public.order_items enable row level security;

grant select, insert, update, delete on table public.order_items to anon, authenticated;

create policy "Anyone can read order_items" on public.order_items for select to anon, authenticated using (true);
create policy "Anyone can insert order_items" on public.order_items for insert to anon, authenticated with check (true);
create policy "Anyone can update order_items" on public.order_items for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete order_items" on public.order_items for delete to anon, authenticated using (true);