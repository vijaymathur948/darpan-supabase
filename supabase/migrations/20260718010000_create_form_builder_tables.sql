-- Basic form builder: forms, fields, public submissions.

create table public.forms (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  status text not null default 'draft'
    check (status in ('draft', 'published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint forms_title_not_blank check (char_length(trim(title)) > 0)
);

create table public.form_fields (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references public.forms (id) on delete cascade,
  field_type text not null
    check (field_type in ('text', 'textarea', 'select')),
  label text not null,
  placeholder text not null default '',
  required boolean not null default false,
  sort_order integer not null default 0,
  options jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  constraint form_fields_label_not_blank check (char_length(trim(label)) > 0)
);

create table public.form_submissions (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references public.forms (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.form_submission_values (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.form_submissions (id) on delete cascade,
  field_id uuid not null references public.form_fields (id) on delete cascade,
  value text not null,
  constraint form_submission_values_unique_field unique (submission_id, field_id)
);

create index forms_status_idx on public.forms (status);
create index forms_created_at_idx on public.forms (created_at desc);
create index form_fields_form_id_sort_idx on public.form_fields (form_id, sort_order);
create index form_submissions_form_id_idx on public.form_submissions (form_id, created_at desc);
create index form_submission_values_submission_id_idx on public.form_submission_values (submission_id);

alter table public.forms enable row level security;
alter table public.form_fields enable row level security;
alter table public.form_submissions enable row level security;
alter table public.form_submission_values enable row level security;

grant select, insert, update, delete on table public.forms to anon, authenticated;
grant select, insert, update, delete on table public.form_fields to anon, authenticated;
grant select, insert, delete on table public.form_submissions to anon, authenticated;
grant select, insert on table public.form_submission_values to anon, authenticated;

-- Builder + public fill (auth deferred — open policies like other tables).

create policy "Anyone can read forms"
  on public.forms for select to anon, authenticated using (true);

create policy "Anyone can insert forms"
  on public.forms for insert to anon, authenticated with check (true);

create policy "Anyone can update forms"
  on public.forms for update to anon, authenticated using (true) with check (true);

create policy "Anyone can delete forms"
  on public.forms for delete to anon, authenticated using (true);

create policy "Anyone can read form fields"
  on public.form_fields for select to anon, authenticated using (true);

create policy "Anyone can insert form fields"
  on public.form_fields for insert to anon, authenticated with check (true);

create policy "Anyone can update form fields"
  on public.form_fields for update to anon, authenticated using (true) with check (true);

create policy "Anyone can delete form fields"
  on public.form_fields for delete to anon, authenticated using (true);

create policy "Anyone can read form submissions"
  on public.form_submissions for select to anon, authenticated using (true);

create policy "Anyone can submit forms"
  on public.form_submissions for insert to anon, authenticated with check (true);

create policy "Anyone can delete form submissions"
  on public.form_submissions for delete to anon, authenticated using (true);

create policy "Anyone can read submission values"
  on public.form_submission_values for select to anon, authenticated using (true);

create policy "Anyone can insert submission values"
  on public.form_submission_values for insert to anon, authenticated with check (true);
