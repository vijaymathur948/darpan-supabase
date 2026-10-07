alter table public.financial_deadlines
  add column status text not null default 'upcoming';

update public.financial_deadlines
set status = 'completed'
where completed_date is not null;

alter table public.financial_deadlines
  add constraint financial_deadlines_status_valid
    check (status in ('open', 'upcoming', 'completed')),
  add constraint financial_deadlines_status_completed_date_consistent
    check ((status = 'completed') = (completed_date is not null));
