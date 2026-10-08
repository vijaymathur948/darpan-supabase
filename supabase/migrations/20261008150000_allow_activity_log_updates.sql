grant update on table public.activity_log to anon, authenticated;

create policy "Anyone can update activity log entries"
  on public.activity_log
  for update
  to anon, authenticated
  using (true)
  with check (true);
