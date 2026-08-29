-- Role options for job applications: React | Node | MERN Stack

create type public.job_application_role as enum (
  'react',
  'node',
  'mern_stack'
);

alter table public.job_applications
  alter column role drop default;

alter table public.job_applications
  alter column role type public.job_application_role
  using (
    case
      when lower(role) like '%mern%' then 'mern_stack'::public.job_application_role
      when lower(role) like '%react%' then 'react'::public.job_application_role
      when lower(role) like '%node%' then 'node'::public.job_application_role
      else 'mern_stack'::public.job_application_role
    end
  );

alter table public.job_applications
  alter column role set default 'mern_stack'::public.job_application_role;

alter table public.job_applications
  drop constraint if exists job_applications_role_not_blank;
