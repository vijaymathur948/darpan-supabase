drop function public.save_order_installment_plan_with_final_marker(uuid, jsonb);

create function public.save_order_installment_plan_with_final_marker(
  p_order_id uuid,
  p_installments jsonb,
  p_paid_installment_ids_to_remove uuid[]
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  final_installment_count integer;
begin
  perform 1
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found.';
  end if;

  if p_paid_installment_ids_to_remove is null then
    raise exception 'Paid installments to remove must be provided as a list.';
  end if;

  if exists (
    select 1
    from unnest(p_paid_installment_ids_to_remove) as requested(installment_id)
    where requested.installment_id is null
  ) then
    raise exception 'Paid installment IDs cannot be null.';
  end if;

  if (
    select count(*) <> count(distinct requested.installment_id)
    from unnest(p_paid_installment_ids_to_remove) as requested(installment_id)
  ) then
    raise exception 'A paid installment can only be removed once.';
  end if;

  if exists (
    select 1
    from unnest(p_paid_installment_ids_to_remove) as requested(installment_id)
    left join public.order_installments as installment
      on installment.id = requested.installment_id
      and installment.order_id = p_order_id
    where installment.id is null
      or (
        select coalesce(sum(payment.amount), 0)
        from public.order_payments as payment
        where payment.installment_id = installment.id
      ) < installment.amount
  ) then
    raise exception 'Only fully paid installments belonging to this order can be removed.';
  end if;

  delete from public.order_installments as installment
  using unnest(p_paid_installment_ids_to_remove) as requested(installment_id)
  where installment.id = requested.installment_id
    and installment.order_id = p_order_id;

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
end;
$$;

revoke all on function public.save_order_installment_plan_with_final_marker(uuid, jsonb, uuid[]) from public;
grant execute on function public.save_order_installment_plan_with_final_marker(uuid, jsonb, uuid[]) to anon, authenticated;
