alter table public.bookstall_events
  add column is_canceled boolean not null default false;
