-- Per-class join/exit windows, replacing the hardcoded 10-minute buffer.
-- join_window_minutes: how long before start_time joining opens.
-- exit_window_minutes: how long after end_time exiting stays open.

alter table public.classes
  add column join_window_minutes smallint not null default 10,
  add column exit_window_minutes smallint not null default 10;

alter table public.classes
  add constraint classes_join_window_valid check (join_window_minutes between 0 and 120),
  add constraint classes_exit_window_valid check (exit_window_minutes between 0 and 120);
