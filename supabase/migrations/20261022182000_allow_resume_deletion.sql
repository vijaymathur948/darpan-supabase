grant delete on table public.resumes to anon, authenticated;

create policy "Anyone can delete resumes"
  on public.resumes
  for delete
  to anon, authenticated
  using (true);
