-- Personal job application tracking (single-user foundation CRUD).

-- Expected flow: wishlist → applied → interview → offer → joined
-- Did not join: rejected | declined | ghosted | bad_contact
create type public.job_application_status as enum (
  'wishlist',
  'applied',
  'interview',
  'offer',
  'joined',
  'rejected',
  'declined',
  'ghosted',
  'bad_contact'
);

create table public.job_applications (
  id uuid primary key default gen_random_uuid(),
  company text not null,
  role text not null,
  status public.job_application_status not null default 'wishlist',
  job_url text not null default '',
  job_location text not null default '',
  main_office text not null default '',
  source text not null default '',
  salary_range text not null default '',
  experience_required text not null default '',
  company_links jsonb not null default '[]'::jsonb,
  applied_at date,
  follow_up_at date,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint job_applications_company_not_blank check (char_length(trim(company)) > 0),
  constraint job_applications_role_not_blank check (char_length(trim(role)) > 0),
  constraint job_applications_company_links_is_array check (jsonb_typeof(company_links) = 'array')
);

create or replace function public.set_job_applications_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger job_applications_set_updated_at
  before update on public.job_applications
  for each row
  execute function public.set_job_applications_updated_at();

alter table public.job_applications enable row level security;

grant select, insert, update, delete on table public.job_applications to anon, authenticated;

create policy "Anyone can read job_applications"
  on public.job_applications
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert job_applications"
  on public.job_applications
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can update job_applications"
  on public.job_applications
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Anyone can delete job_applications"
  on public.job_applications
  for delete
  to anon, authenticated
  using (true);
