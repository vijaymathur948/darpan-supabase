-- Attendance is tracked per class-session day.

alter table public.attendance
  add column attendance_date date not null default current_date;

create index attendance_class_date_idx
  on public.attendance (class_id, attendance_date);
