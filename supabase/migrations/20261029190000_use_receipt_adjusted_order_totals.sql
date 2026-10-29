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
      coalesce(bool_or(item.received_quantity is distinct from item.quantity and item.unit_amount is null), false) as has_unpriced_adjustment,
      coalesce(sum(greatest(item.quantity - item.received_quantity, 0) * item.unit_amount), 0) as missing_amount,
      coalesce(sum(greatest(item.received_quantity - item.quantity, 0) * item.unit_amount), 0) as extra_amount
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

create or replace function public.get_order_payable_amount(p_order_id uuid)
returns numeric(12, 2)
language sql
stable
security definer
set search_path = pg_catalog, public, pg_temp
as $$
  select public.calculate_order_payable_amount(order_row.id, order_row.amount)
  from public.orders order_row
  where order_row.id = p_order_id;
$$;

revoke all on function public.calculate_order_payable_amount(uuid, numeric) from public;
revoke all on function public.get_order_payable_amount(uuid) from public;
grant execute on function public.calculate_order_payable_amount(uuid, numeric) to anon, authenticated;
grant execute on function public.get_order_payable_amount(uuid) to anon, authenticated;

create or replace function public.save_order_installment_plan(p_order_id uuid, p_installments jsonb)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  order_total numeric(12, 2);
  payable_total numeric(12, 2);
  scheduled_total numeric(12, 2);
begin
  select amount into order_total
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found.';
  end if;

  if order_total is null then
    raise exception 'Set an order total before creating an installment plan.';
  end if;

  payable_total := public.get_order_payable_amount(p_order_id);
  if payable_total is null then
    raise exception 'The payable total is unavailable. Add prices for missing or extra books first.';
  end if;

  if p_installments is null or jsonb_typeof(p_installments) <> 'array' then
    raise exception 'Add at least one installment.';
  end if;

  if jsonb_array_length(p_installments) = 0 then
    raise exception 'Add at least one installment.';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date)
    where installment.amount is null or installment.amount <= 0 or installment.due_at is null
  ) then
    raise exception 'Each installment needs a positive amount and due date.';
  end if;

  if (
    select count(*) <> count(distinct installment.id)
    from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date)
    where installment.id is not null
  ) then
    raise exception 'An installment can only appear once in the plan.';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date)
    where installment.id is not null
      and not exists (
        select 1 from public.order_installments existing
        where existing.id = installment.id and existing.order_id = p_order_id
      )
  ) then
    raise exception 'An installment does not belong to this order.';
  end if;

  select coalesce(sum(installment.amount), 0) into scheduled_total
  from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date);

  if scheduled_total > payable_total then
    raise exception 'Scheduled installments cannot exceed the payable total.';
  end if;

  if exists (
    select 1
    from public.order_installments existing
    where existing.order_id = p_order_id
      and exists (select 1 from public.order_payments payment where payment.installment_id = existing.id)
      and not exists (
        select 1
        from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date)
        where installment.id = existing.id
      )
  ) then
    raise exception 'An installment with recorded payments cannot be removed.';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date)
    where installment.id is not null
      and (
        select coalesce(sum(payment.amount), 0)
        from public.order_payments payment
        where payment.installment_id = installment.id
      ) > installment.amount
  ) then
    raise exception 'An installment amount cannot be less than the payments already recorded for it.';
  end if;

  update public.order_installments
  set position = position + 1000000
  where order_id = p_order_id;

  delete from public.order_installments existing
  where existing.order_id = p_order_id
    and not exists (
      select 1
      from jsonb_to_recordset(p_installments) as installment(id uuid, amount numeric, due_at date)
      where installment.id = existing.id
    );

  update public.order_installments existing
  set amount = installment.amount,
      due_at = installment.due_at,
      position = installment.position
  from (
    select input.id, input.amount, input.due_at, payload.ordinality::integer as position
    from jsonb_array_elements(p_installments) with ordinality as payload(value, ordinality)
    cross join lateral jsonb_to_record(payload.value) as input(id uuid, amount numeric, due_at date)
    where input.id is not null
  ) as installment
  where existing.id = installment.id and existing.order_id = p_order_id;

  insert into public.order_installments (order_id, amount, due_at, position)
  select p_order_id, input.amount, input.due_at, payload.ordinality::integer
  from jsonb_array_elements(p_installments) with ordinality as payload(value, ordinality)
  cross join lateral jsonb_to_record(payload.value) as input(id uuid, amount numeric, due_at date)
  where input.id is null;
end;
$$;

create or replace function public.validate_order_payment()
returns trigger
language plpgsql
as $$
declare
  order_total numeric(12, 2);
  payable_total numeric(12, 2);
  paid_total numeric(12, 2);
  installment_total numeric(12, 2);
  installment_paid numeric(12, 2);
begin
  select amount into order_total
  from public.orders
  where id = new.order_id
  for update;

  if not found then
    raise exception 'Order not found.';
  end if;

  if order_total is null then
    raise exception 'Set an order total before recording a payment.';
  end if;

  select public.get_order_payable_amount(new.order_id) into payable_total;

  if payable_total is null then
    raise exception 'The payable total is unavailable. Add prices for missing or extra books first.';
  end if;

  select amount into installment_total
  from public.order_installments
  where id = new.installment_id and order_id = new.order_id;

  if not found then
    raise exception 'Choose an installment from this order.';
  end if;

  select coalesce(sum(amount), 0) into paid_total
  from public.order_payments
  where order_id = new.order_id;

  select coalesce(sum(amount), 0) into installment_paid
  from public.order_payments
  where installment_id = new.installment_id;

  if paid_total + new.amount > payable_total then
    raise exception 'The payment cannot be greater than the remaining payable balance.';
  end if;

  if installment_paid + new.amount > installment_total then
    raise exception 'The payment cannot be greater than the remaining installment balance.';
  end if;

  return new;
end;
$$;

create or replace function public.validate_order_total_after_payments()
returns trigger
language plpgsql
as $$
declare
  paid_total numeric(12, 2);
  scheduled_total numeric(12, 2);
  payable_total numeric(12, 2);
begin
  if new.amount is distinct from old.amount then
    select coalesce(sum(amount), 0) into paid_total
    from public.order_payments
    where order_id = new.id;

    select coalesce(sum(amount), 0) into scheduled_total
    from public.order_installments
    where order_id = new.id;

    payable_total := public.calculate_order_payable_amount(new.id, new.amount);

    if (new.amount is null and paid_total > 0) or new.amount < paid_total then
      raise exception 'The order total cannot be less than the payments already recorded.';
    end if;

    if (new.amount is null and scheduled_total > 0) or new.amount < scheduled_total then
      raise exception 'Adjust the installment plan before lowering the order total below its scheduled amount.';
    end if;

    if payable_total is not null and payable_total < paid_total then
      raise exception 'The payable total cannot be less than the payments already recorded.';
    end if;

    if payable_total is not null and payable_total < scheduled_total then
      raise exception 'Adjust the installment plan before lowering the payable total below its scheduled amount.';
    end if;
  end if;

  return new;
end;
$$;
