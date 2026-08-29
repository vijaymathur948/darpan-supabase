-- Reply tracking as proper columns (not free-form notes).

alter table public.job_applications
  add column if not exists replied boolean not null default false,
  add column if not exists reply_at date;
