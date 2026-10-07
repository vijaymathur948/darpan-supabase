alter table public.reminder
  add column reminder_type text not null default 'one_time',
  alter column remind_at drop not null;

alter table public.reminder
  add constraint reminder_type_valid
    check (reminder_type in ('one_time', 'no_deadline')),
  add constraint reminder_type_remind_at_consistent
    check (
      (reminder_type = 'one_time' and remind_at is not null)
      or (reminder_type = 'no_deadline' and remind_at is null)
    );
