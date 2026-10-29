alter table public.orders
  add column receipt_checked_at timestamptz;

alter table public.order_items
  add column received_quantity integer,
  add constraint order_items_received_quantity_non_negative
    check (received_quantity is null or received_quantity >= 0);

create or replace function public.save_order_receipt(p_order_id uuid, p_items jsonb)
returns timestamptz
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  current_status public.order_status;
  order_item_count integer;
  updated_item_count integer;
  checked_at timestamptz;
begin
  select status into current_status
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found.';
  end if;

  if current_status = 'cancelled' then
    raise exception 'A cancelled order cannot be checked for receipt.';
  end if;

  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' then
    raise exception 'Add a received quantity for each order item.';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception 'Add a received quantity for each order item.';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as receipt(item_id uuid, received_quantity numeric)
    where receipt.item_id is null
      or receipt.received_quantity is null
      or receipt.received_quantity < 0
      or receipt.received_quantity <> trunc(receipt.received_quantity)
  ) then
    raise exception 'Received quantities must be whole numbers greater than or equal to zero.';
  end if;

  if (
    select count(*) <> count(distinct receipt.item_id)
    from jsonb_to_recordset(p_items) as receipt(item_id uuid, received_quantity numeric)
  ) then
    raise exception 'Each order item can only appear once in the receipt check.';
  end if;

  select count(*) into order_item_count
  from public.order_items
  where order_id = p_order_id;

  if order_item_count <> jsonb_array_length(p_items) then
    raise exception 'The receipt check must include every item in the order.';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as receipt(item_id uuid, received_quantity numeric)
    where not exists (
      select 1
      from public.order_items item
      where item.id = receipt.item_id and item.order_id = p_order_id
    )
  ) then
    raise exception 'A receipt item does not belong to this order.';
  end if;

  update public.order_items item
  set received_quantity = receipt.received_quantity::integer
  from jsonb_to_recordset(p_items) as receipt(item_id uuid, received_quantity numeric)
  where item.id = receipt.item_id and item.order_id = p_order_id;

  get diagnostics updated_item_count = row_count;

  if updated_item_count <> order_item_count then
    raise exception 'Unable to save all received quantities for this order.';
  end if;

  update public.orders
  set receipt_checked_at = now()
  where id = p_order_id
  returning receipt_checked_at into checked_at;

  return checked_at;
end;
$$;

grant execute on function public.save_order_receipt(uuid, jsonb) to anon, authenticated;
