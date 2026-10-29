create table public.order_installments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  amount numeric(12, 2) not null,
  due_at date not null,
  position integer not null,
  created_at timestamptz not null default now(),
  constraint order_installments_amount_positive check (amount > 0),
  constraint order_installments_position_positive check (position > 0),
  constraint order_installments_order_position_unique unique (order_id, position)
);

create index order_installments_order_id_idx
  on public.order_installments (order_id, position);

grant select on table public.order_installments to anon, authenticated;

alter table public.order_installments enable row level security;

create policy "Anyone can read order_installments"
  on public.order_installments for select to anon, authenticated using (true);

create table public.order_payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  installment_id uuid not null references public.order_installments(id) on delete cascade,
  amount numeric(12, 2) not null,
  paid_at date not null default current_date,
  created_at timestamptz not null default now(),
  constraint order_payments_amount_positive check (amount > 0)
);

create index order_payments_order_id_paid_at_idx
  on public.order_payments (order_id, paid_at);

create index order_payments_installment_id_idx
  on public.order_payments (installment_id);

grant select, insert on table public.order_payments to anon, authenticated;

alter table public.order_payments enable row level security;

create policy "Anyone can read order_payments"
  on public.order_payments for select to anon, authenticated using (true);

create policy "Anyone can insert order_payments"
  on public.order_payments for insert to anon, authenticated with check (true);

create or replace function public.save_order_installment_plan(p_order_id uuid, p_installments jsonb)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  order_total numeric(12, 2);
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

  if scheduled_total > order_total then
    raise exception 'Scheduled installments cannot exceed the order total.';
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

grant execute on function public.save_order_installment_plan(uuid, jsonb) to anon, authenticated;

create or replace function public.validate_order_payment()
returns trigger
language plpgsql
as $$
declare
  order_total numeric(12, 2);
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

  if paid_total + new.amount > order_total then
    raise exception 'The payment cannot be greater than the remaining order balance.';
  end if;

  if installment_paid + new.amount > installment_total then
    raise exception 'The payment cannot be greater than the remaining installment balance.';
  end if;

  return new;
end;
$$;

create trigger order_payments_validate_insert
  before insert on public.order_payments
  for each row
  execute function public.validate_order_payment();

create or replace function public.validate_order_total_after_payments()
returns trigger
language plpgsql
as $$
declare
  paid_total numeric(12, 2);
  scheduled_total numeric(12, 2);
begin
  if new.amount is distinct from old.amount then
    select coalesce(sum(amount), 0) into paid_total
    from public.order_payments
    where order_id = new.id;

    select coalesce(sum(amount), 0) into scheduled_total
    from public.order_installments
    where order_id = new.id;

    if (new.amount is null and paid_total > 0) or new.amount < paid_total then
      raise exception 'The order total cannot be less than the payments already recorded.';
    end if;

    if (new.amount is null and scheduled_total > 0) or new.amount < scheduled_total then
      raise exception 'Adjust the installment plan before lowering the order total below its scheduled amount.';
    end if;
  end if;

  return new;
end;
$$;

create trigger orders_validate_total_after_payments
  before update of amount on public.orders
  for each row
  execute function public.validate_order_total_after_payments();
