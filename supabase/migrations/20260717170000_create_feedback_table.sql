-- User feedback: bug reports, feature ideas, and general suggestions.

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  type text not null
    check (type in ('bug', 'feature', 'improvement', 'question', 'other')),
  title text not null,
  message text not null,
  created_at timestamptz not null default now(),
  constraint feedback_title_not_blank check (char_length(trim(title)) > 0),
  constraint feedback_message_not_blank check (char_length(trim(message)) > 0)
);

create index feedback_created_at_idx on public.feedback (created_at desc);
create index feedback_type_idx on public.feedback (type);

alter table public.feedback enable row level security;

grant select, insert on table public.feedback to anon, authenticated;

create policy "Anyone can read feedback"
  on public.feedback
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can submit feedback"
  on public.feedback
  for insert
  to anon, authenticated
  with check (true);
