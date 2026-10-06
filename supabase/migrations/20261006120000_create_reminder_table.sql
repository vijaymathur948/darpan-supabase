create table public.reminder (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  remind_at timestamptz not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index reminder_remind_at_idx
  on public.reminder (remind_at);

create or replace function public.set_reminder_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger reminder_set_updated_at
  before update on public.reminder
  for each row
  execute function public.set_reminder_updated_at();

alter table public.reminder enable row level security;

grant select, insert, update, delete on table public.reminder to anon, authenticated;

create policy "Anyone can read reminders"
  on public.reminder
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert reminders"
  on public.reminder
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update reminders"
  on public.reminder
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete reminders"
  on public.reminder
  for delete
  to anon, authenticated
  using (true);
