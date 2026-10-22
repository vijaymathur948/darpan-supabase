create table public.resumes (
  id uuid primary key default gen_random_uuid(),
  content jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint resumes_content_object check (jsonb_typeof(content) = 'object')
);

alter table public.resumes enable row level security;

grant select, insert on table public.resumes to anon, authenticated;

create policy "Anyone can read public resumes"
  on public.resumes
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can create resumes"
  on public.resumes
  for insert
  to anon, authenticated
  with check (true);
