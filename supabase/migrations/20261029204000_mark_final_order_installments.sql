alter table public.order_installments
  add column is_final boolean not null default false;

create or replace function public.save_order_installment_plan_and_sync_pending_payment_date(
  p_order_id uuid,
  p_installments jsonb
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  final_installment_count integer;
begin
  perform public.save_order_installment_plan(p_order_id, p_installments);

  select count(*) into final_installment_count
  from jsonb_array_elements(p_installments) as payload(value)
  where coalesce((payload.value ->> 'is_final')::boolean, false);

  if final_installment_count > 1 then
    raise exception 'Only one installment can be marked as the final installment.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_installments) with ordinality as payload(value, ordinality)
    where coalesce((payload.value ->> 'is_final')::boolean, false)
      and payload.ordinality < jsonb_array_length(p_installments)
  ) then
    raise exception 'The final installment must be last in the plan.';
  end if;

  update public.order_installments as existing
  set is_final = input.is_final
  from (
    select
      payload.ordinality::integer as position,
      coalesce((payload.value ->> 'is_final')::boolean, false) as is_final
    from jsonb_array_elements(p_installments) with ordinality as payload(value, ordinality)
  ) as input
  where existing.order_id = p_order_id
    and existing.position = input.position
    and existing.is_final is distinct from input.is_final;

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
