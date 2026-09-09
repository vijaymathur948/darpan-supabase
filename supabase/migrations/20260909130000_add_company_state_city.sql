alter table public.companies
  add column state text not null default '',
  add column city text not null default '',
  add column country text not null default '';