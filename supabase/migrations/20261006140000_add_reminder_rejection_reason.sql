alter table public.reminder
  add column rejection_reason text;

alter table public.reminder
  add constraint reminder_status_valid
    check (status in ('pending', 'completed', 'rejected')),
  add constraint reminder_rejected_reason_required
    check (
      status <> 'rejected'
      or char_length(trim(coalesce(rejection_reason, ''))) > 0
    );
