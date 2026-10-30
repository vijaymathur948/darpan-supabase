alter table public.order_items
  rename column unit_amount to cost_price,
  rename column max_unit_amount to max_retail_price,
  rename constraint order_items_unit_amount_non_negative to order_items_cost_price_non_negative,
  rename constraint order_items_max_unit_amount_non_negative to order_items_max_retail_price_non_negative;

create or replace function public.calculate_order_payable_amount(p_order_id uuid, p_order_amount numeric)
returns numeric(12, 2)
language sql
stable
security definer
set search_path = pg_catalog, public, pg_temp
as $$
  with order_state as (
    select receipt_checked_at
    from public.orders
    where id = p_order_id
  ),
  receipt_totals as (
    select
      coalesce(bool_or(item.received_quantity is null), false) as has_incomplete_receipt,
      coalesce(bool_or(item.received_quantity is distinct from item.quantity and item.cost_price is null), false) as has_unpriced_adjustment,
      coalesce(sum(greatest(item.quantity - item.received_quantity, 0) * item.cost_price), 0) as missing_amount,
      coalesce(sum(greatest(item.received_quantity - item.quantity, 0) * item.cost_price), 0) as extra_amount
    from public.order_items item
    where item.order_id = p_order_id
  )
  select case
    when p_order_amount is null then null
    when order_state.receipt_checked_at is null then p_order_amount
    when receipt_totals.has_incomplete_receipt or receipt_totals.has_unpriced_adjustment then null
    else greatest(0, p_order_amount - receipt_totals.missing_amount + receipt_totals.extra_amount)
  end
  from order_state
  cross join receipt_totals;
$$;
