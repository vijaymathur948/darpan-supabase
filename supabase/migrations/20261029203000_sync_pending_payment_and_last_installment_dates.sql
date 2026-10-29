update public.order_installments as installment
set due_at = order_row.pending_payment_date
from public.orders as order_row
where installment.order_id = order_row.id
  and order_row.pending_payment_date is not null
  and installment.id = (
    select candidate.id
    from public.order_installments as candidate
    where candidate.order_id = order_row.id
    order by candidate.position desc
    limit 1
  )
  and installment.due_at is distinct from order_row.pending_payment_date
  and (
    select coalesce(sum(payment.amount), 0)
    from public.order_payments as payment
    where payment.installment_id = installment.id
  ) < installment.amount;

update public.orders as order_row
set pending_payment_date = (
  select installment.due_at
  from public.order_installments as installment
  where installment.order_id = order_row.id
  order by installment.position desc
  limit 1
)
where order_row.pending_payment_date is distinct from (
  select installment.due_at
  from public.order_installments as installment
  where installment.order_id = order_row.id
  order by installment.position desc
  limit 1
)
and exists (
  select 1
  from public.order_installments as installment
  where installment.order_id = order_row.id
);

create or replace function public.save_order_installment_plan_and_sync_pending_payment_date(
  p_order_id uuid,
  p_installments jsonb
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
begin
  perform public.save_order_installment_plan(p_order_id, p_installments);

  update public.orders as order_row
  set pending_payment_date = (
    select installment.due_at
    from public.order_installments as installment
    where installment.order_id = p_order_id
    order by installment.position desc
    limit 1
  )
  where order_row.id = p_order_id;
end;
$$;

revoke all on function public.save_order_installment_plan_and_sync_pending_payment_date(uuid, jsonb) from public;
grant execute on function public.save_order_installment_plan_and_sync_pending_payment_date(uuid, jsonb) to anon, authenticated;

create or replace function public.update_order_pending_payment_date_and_last_installment(
  p_order_id uuid,
  p_pending_payment_date date
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  last_installment_id uuid;
  last_installment_due_date date;
  synchronized_date date;
  updated_order public.orders;
begin
  perform 1
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found.';
  end if;

  select installment.id, installment.due_at
  into last_installment_id, last_installment_due_date
  from public.order_installments as installment
  where installment.order_id = p_order_id
  order by installment.position desc
  limit 1
  for update;

  if last_installment_id is null then
    synchronized_date := p_pending_payment_date;
  else
    synchronized_date := coalesce(p_pending_payment_date, last_installment_due_date);

    if p_pending_payment_date is not null
      and last_installment_due_date is distinct from p_pending_payment_date then
      update public.order_installments
      set due_at = p_pending_payment_date
      where id = last_installment_id;
    end if;
  end if;

  update public.orders
  set pending_payment_date = synchronized_date
  where id = p_order_id
  returning * into updated_order;

  return to_jsonb(updated_order);
end;
$$;

revoke all on function public.update_order_pending_payment_date_and_last_installment(uuid, date) from public;
grant execute on function public.update_order_pending_payment_date_and_last_installment(uuid, date) to anon, authenticated;
