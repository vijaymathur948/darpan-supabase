-- Track why a class join was late.

alter table public.attendance
  add column late_reason text;
