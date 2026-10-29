grant update (paid_at) on table public.order_payments to anon, authenticated;

create policy "Anyone can update order payment dates"
  on public.order_payments for update to anon, authenticated
  using (true)
  with check (true);
