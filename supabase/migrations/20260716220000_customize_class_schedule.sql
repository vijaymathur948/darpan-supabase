-- Custom scheduling: classes no longer always run daily.

alter table public.classes
  add column days_of_week integer[] not null default '{1,2,3,4,5,6,7}';

alter table public.classes
  add column extra_dates date[] not null default '{}';

alter table public.classes
  add column excluded_dates date[] not null default '{}';

alter table public.classes
  add constraint classes_days_of_week_valid check (
    array_length(days_of_week, 1) > 0
    and not exists (
      select 1
      from unnest(days_of_week) as day_value
      where day_value < 1 or day_value > 7
    )
  );
