-- Company profiles and key business metrics (for job research and comparison).

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  website text not null default '',
  industry text not null default '',
  location text not null default '',
  headquarters text not null default '',
  founded_year smallint,
  employee_count integer,
  employee_count_range text not null default '',
  annual_revenue numeric(16, 2),
  revenue_currency text not null default 'INR',
  funding_stage text not null default '',
  total_funding numeric(16, 2),
  valuation numeric(16, 2),
  is_public boolean not null default false,
  remote_policy text not null default '',
  links jsonb not null default '[]'::jsonb,
  metrics_as_of date,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint companies_name_not_blank check (char_length(trim(name)) > 0),
  constraint companies_founded_year_valid check (
    founded_year is null or (founded_year >= 1800 and founded_year <= 2100)
  ),
  constraint companies_employee_count_non_negative check (
    employee_count is null or employee_count >= 0
  ),
  constraint companies_links_is_array check (jsonb_typeof(links) = 'array')
);

create or replace function public.set_companies_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger companies_set_updated_at
  before update on public.companies
  for each row
  execute function public.set_companies_updated_at();

alter table public.companies enable row level security;

grant select, insert, update, delete on table public.companies to anon, authenticated;

create policy "Anyone can read companies"
  on public.companies
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert companies"
  on public.companies
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update companies"
  on public.companies
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete companies"
  on public.companies
  for delete
  to anon, authenticated
  using (true);
