-- Initial schema for Darpan (no auth yet).
-- `samples` is a throwaway table for verifying the remote API / migrations.

create extension if not exists "pgcrypto";

create table public.samples (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  created_at timestamptz not null default now()
);

alter table public.samples enable row level security;

grant select, insert, delete on table public.samples to anon, authenticated;

-- Open policies so the anon key can smoke-test without auth.
create policy "Anyone can read samples"
  on public.samples
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can insert samples"
  on public.samples
  for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can delete samples"
  on public.samples
  for delete
  to anon, authenticated
  using (true);
