-- Job posting URL is covered by company_links (e.g. Website).

alter table public.job_applications
  drop column if exists job_url;
