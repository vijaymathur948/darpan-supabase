create extension if not exists pgcrypto with schema extensions;

create table public.app_access_settings (
  singleton boolean primary key default true check (singleton),
  password_hash text not null,
  updated_at timestamptz not null default now()
);

alter table public.app_access_settings enable row level security;
revoke all on table public.app_access_settings from anon, authenticated;

create or replace function public.verify_app_access_password(p_password text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select p_password is not null and exists (
    select 1
    from public.app_access_settings as settings
    where settings.singleton
      and settings.password_hash = extensions.crypt(p_password, settings.password_hash)
  );
$$;

revoke all on function public.verify_app_access_password(text) from public, anon, authenticated;
grant execute on function public.verify_app_access_password(text) to anon, authenticated;
