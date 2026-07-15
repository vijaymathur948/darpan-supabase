-- Exit reason: manual (student tapped Exit) or auto_timeout (system after exit window).
alter table public.attendance
  add column exit_reason text
    check (exit_reason is null or exit_reason in ('manual', 'auto_timeout'));
