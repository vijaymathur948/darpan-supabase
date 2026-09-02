-- Allow multiple attendance entries for the same class/day.

alter table public.attendance
  drop constraint if exists attendance_exit_after_join;

create index attendance_class_date_joined_idx
  on public.attendance (class_id, attendance_date, joined_at desc);
