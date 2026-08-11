-- Allow multiple join/exit segments for the same class on the same day.
-- Each join inserts a new attendance row; each exit closes that row.

alter table public.attendance
  drop constraint if exists attendance_one_per_class_per_day;

create index if not exists attendance_class_id_session_date_started_at_idx
  on public.attendance (class_id, session_date, started_at);
