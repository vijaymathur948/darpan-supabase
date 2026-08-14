-- Today's time: activities (soft-deletable) and manual day sessions.

create table public.time_activities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon text not null default 'circle',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint time_activities_name_not_blank check (char_length(trim(name)) > 0),
  constraint time_activities_icon_not_blank check (char_length(trim(icon)) > 0)
);

create index time_activities_active_name_idx
  on public.time_activities (name)
  where deleted_at is null;

create index time_activities_deleted_at_idx
  on public.time_activities (deleted_at);

create or replace function public.set_time_activities_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger time_activities_set_updated_at
  before update on public.time_activities
  for each row
  execute function public.set_time_activities_updated_at();

create table public.time_sessions (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.time_activities (id),
  session_date date not null,
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint time_sessions_end_after_start check (end_time > start_time)
);

create index time_sessions_date_idx
  on public.time_sessions (session_date desc, start_time);

create index time_sessions_activity_id_idx
  on public.time_sessions (activity_id);

create or replace function public.set_time_sessions_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger time_sessions_set_updated_at
  before update on public.time_sessions
  for each row
  execute function public.set_time_sessions_updated_at();

alter table public.time_activities enable row level security;
alter table public.time_sessions enable row level security;

grant select, insert, update, delete on table public.time_activities to anon, authenticated;
grant select, insert, update, delete on table public.time_sessions to anon, authenticated;

create policy "Anyone can read time_activities"
  on public.time_activities
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert time_activities"
  on public.time_activities
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update time_activities"
  on public.time_activities
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete time_activities"
  on public.time_activities
  for delete
  to anon, authenticated
  using (true);

create policy "Anyone can read time_sessions"
  on public.time_sessions
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert time_sessions"
  on public.time_sessions
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update time_sessions"
  on public.time_sessions
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete time_sessions"
  on public.time_sessions
  for delete
  to anon, authenticated
  using (true);
