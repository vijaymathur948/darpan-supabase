create or replace function public.prevent_paid_installment_changes()
returns trigger
language plpgsql
set search_path = pg_catalog, public, pg_temp
as $$
declare
  paid_total numeric(12, 2);
begin
  select coalesce(sum(payment.amount), 0)
  into paid_total
  from public.order_payments payment
  where payment.installment_id = old.id;

  if paid_total >= old.amount
    and (new.amount is distinct from old.amount or new.due_at is distinct from old.due_at) then
    raise exception 'A fully paid installment cannot be changed.';
  end if;

  return new;
end;
$$;

create trigger order_installments_protect_paid_fields
  before update of amount, due_at on public.order_installments
  for each row
  execute function public.prevent_paid_installment_changes();
