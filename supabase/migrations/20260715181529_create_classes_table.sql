-- Standalone schema start (pgcrypto needed for gen_random_uuid).
create extension if not exists "pgcrypto";

-- Classes table: name, schedule (daily for now), status (active|inactive).
-- Auth is still deferred, so RLS is open to anon/authenticated for now.

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  schedule text not null default 'daily',
  start_time time not null,
  end_time time not null,
  status text not null default 'active'
    check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  constraint classes_end_after_start check (end_time > start_time)
);

alter table public.classes enable row level security;

grant select, insert, update, delete on table public.classes to anon, authenticated;

create policy "Anyone can read classes"
  on public.classes
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert classes"
  on public.classes
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update classes"
  on public.classes
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete classes"
  on public.classes
  for delete
  to anon, authenticated
  using (true);
