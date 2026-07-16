-- Custom scheduling: classes no longer always run daily.
-- days_of_week: 0=Sunday .. 6=Saturday (matches JS Date#getDay()).
-- extra_dates: one-off dates the class runs on top of days_of_week.
-- excluded_dates: one-off dates to skip even if days_of_week matches.

alter table public.classes
  add column days_of_week smallint[] not null default '{0,1,2,3,4,5,6}',
  add column extra_dates date[] not null default '{}',
  add column excluded_dates date[] not null default '{}';

alter table public.classes
  add constraint classes_days_of_week_valid check (
    days_of_week <@ array[0,1,2,3,4,5,6]::smallint[]
  );

alter table public.classes
  drop column schedule;
