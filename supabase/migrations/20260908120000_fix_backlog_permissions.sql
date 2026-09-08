-- Fix backlog permissions: app uses anon key without auth, like other tables.

grant select, insert, update, delete on table public.backlog to anon, authenticated;

drop policy if exists "Allow authenticated users to read backlog" on public.backlog;
drop policy if exists "Allow authenticated users to create backlog" on public.backlog;
drop policy if exists "Allow authenticated users to update backlog" on public.backlog;
drop policy if exists "Allow authenticated users to delete backlog" on public.backlog;

create policy "Anyone can read backlog"
  on public.backlog
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert backlog"
  on public.backlog
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update backlog"
  on public.backlog
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete backlog"
  on public.backlog
  for delete
  to anon, authenticated
  using (true);
