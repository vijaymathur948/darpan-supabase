-- Maximum unit price (MRP / ceiling) per book in an order.

alter table public.order_items
  add column max_unit_amount numeric(12, 2);

alter table public.order_items
  add constraint order_items_max_unit_amount_non_negative
  check (max_unit_amount is null or max_unit_amount >= 0);
