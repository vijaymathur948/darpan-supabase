-- Optional logo image URL for problems catalog cards.

alter table public.problems
  add column if not exists logo text not null default '';
