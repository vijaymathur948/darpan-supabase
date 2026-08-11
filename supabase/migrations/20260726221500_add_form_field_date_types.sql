-- Allow date / time / datetime field types on form fields.
alter table public.form_fields
  drop constraint if exists form_fields_field_type_check;

alter table public.form_fields
  add constraint form_fields_field_type_check
  check (field_type in ('text', 'textarea', 'select', 'date', 'time', 'datetime'));
