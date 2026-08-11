-- Allow admin CRUD on form submission values (edit/delete responses).
grant update, delete on table public.form_submission_values to anon, authenticated;

create policy "Anyone can update submission values"
  on public.form_submission_values for update to anon, authenticated
  using (true) with check (true);

create policy "Anyone can delete submission values"
  on public.form_submission_values for delete to anon, authenticated
  using (true);
