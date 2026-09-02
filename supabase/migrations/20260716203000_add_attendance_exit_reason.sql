-- Track a reason when a student exits class early or otherwise notes an exit.

alter table public.attendance
  add column exit_reason text;
