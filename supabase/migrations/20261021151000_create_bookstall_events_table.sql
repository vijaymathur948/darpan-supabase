-- Events belong to a bookstall and have a location and scheduled time.

create table public.bookstall_events (
  id uuid primary key default gen_random_uuid(),
  bookstall_id uuid not null references public.bookstall (id) on delete cascade,
  location text not null,
  google_maps_url text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookstall_events_location_not_blank check (length(trim(location)) > 0),
  constraint bookstall_events_time_range check (ends_at > starts_at)
);

create index bookstall_events_bookstall_starts_at_idx
  on public.bookstall_events (bookstall_id, starts_at);

create or replace function public.set_bookstall_events_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger bookstall_events_set_updated_at
  before update on public.bookstall_events
  for each row
  execute function public.set_bookstall_events_updated_at();

alter table public.bookstall_events enable row level security;

grant select, insert, update, delete on table public.bookstall_events to anon, authenticated;

create policy "Anyone can read bookstall_events" on public.bookstall_events for select to anon, authenticated using (true);
create policy "Anyone can insert bookstall_events" on public.bookstall_events for insert to anon, authenticated with check (true);
create policy "Anyone can update bookstall_events" on public.bookstall_events for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete bookstall_events" on public.bookstall_events for delete to anon, authenticated using (true);
