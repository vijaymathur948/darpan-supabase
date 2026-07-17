-- Track workflow status for each feedback item.

alter table public.feedback
  add column status text not null default 'open'
    check (status in ('open', 'in_progress', 'resolved', 'closed'));

create index feedback_status_idx on public.feedback (status);
