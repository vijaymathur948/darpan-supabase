-- Rename source → medium (how you reached them).

alter table public.job_applications
  rename column source to medium;
