-- Allow update and delete on feedback (matches other tables until auth is added).

grant update, delete on table public.feedback to anon, authenticated;

create policy "Anyone can update feedback"
  on public.feedback
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete feedback"
  on public.feedback
  for delete
  to anon, authenticated
  using (true);
