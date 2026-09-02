-- Add per-class join/exit windows for attendance tracking.

alter table public.classes
  add column join_window_minutes integer not null default 10,
  add column exit_window_minutes integer not null default 10;

alter table public.classes
  add constraint classes_join_window_valid check (join_window_minutes between 0 and 120),
  add constraint classes_exit_window_valid check (exit_window_minutes between 0 and 120);
