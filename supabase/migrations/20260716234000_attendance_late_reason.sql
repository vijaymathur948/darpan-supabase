-- Optional reason when a student joins after the join window has closed.

alter table public.attendance
  add column late_reason text;

alter table public.attendance
  add constraint attendance_late_reason_not_blank check (
    late_reason is null or length(trim(late_reason)) > 0
  );
