-- Attendance: one enrollment per class (single student for now).
-- started_at = when Attend is tapped; withdrawn_at = null until withdraw (once).

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes (id) on delete cascade,
  started_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  created_at timestamptz not null default now(),
  constraint attendance_one_per_class unique (class_id),
  constraint attendance_withdraw_after_start check (
    withdrawn_at is null or withdrawn_at >= started_at
  )
);

create index attendance_class_id_idx on public.attendance (class_id);

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
