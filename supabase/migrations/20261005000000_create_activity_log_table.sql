-- Activity log: records what happened and when it happened.

create table public.activity_log (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz not null default now(),
  constraint activity_log_title_not_empty check (char_length(trim(title)) > 0),
  constraint activity_log_description_not_empty check (char_length(trim(description)) > 0),
  constraint activity_log_time_order check (end_time >= start_time)
);

create index activity_log_start_time_idx on public.activity_log (start_time desc);

alter table public.activity_log enable row level security;

grant select, insert, delete on table public.activity_log to anon, authenticated;

create policy "Anyone can read activity log entries" on public.activity_log for select to anon, authenticated using (true);
create policy "Anyone can insert activity log entries" on public.activity_log for insert to anon, authenticated with check (true);
create policy "Anyone can delete activity log entries" on public.activity_log for delete to anon, authenticated using (true);
