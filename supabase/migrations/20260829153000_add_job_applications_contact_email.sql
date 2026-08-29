-- HR / company email used when sending the application.

alter table public.job_applications
  add column contact_email text not null default '';
