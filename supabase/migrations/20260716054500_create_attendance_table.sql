-- Class attendance log: when a user joined and when they left a class.

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes (id) on delete cascade,
  joined_at timestamptz not null default now(),
  exited_at timestamptz,
  created_at timestamptz not null default now(),
  constraint attendance_exit_after_join check (exited_at is null or exited_at >= joined_at)
);

alter table public.attendance enable row level security;

grant select, insert, update, delete on table public.attendance to anon, authenticated;

create policy "Anyone can read attendance"
  on public.attendance
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert attendance"
  on public.attendance
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update attendance"
  on public.attendance
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete attendance"
  on public.attendance
  for delete
  to anon, authenticated
  using (true);
