-- Attendance was unique per class *forever*; fix it to be unique per class per day
-- so custom (non-daily) schedules and multi-day history both work correctly.

alter table public.attendance
  add column session_date date;

update public.attendance
  set session_date = started_at::date
  where session_date is null;

alter table public.attendance
  alter column session_date set not null,
  alter column session_date set default current_date;

alter table public.attendance
  drop constraint attendance_one_per_class;

alter table public.attendance
  add constraint attendance_one_per_class_per_day unique (class_id, session_date);

create index attendance_class_id_session_date_idx
  on public.attendance (class_id, session_date);
