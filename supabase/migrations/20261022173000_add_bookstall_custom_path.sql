alter table public.bookstall
  add column custom_path text;

alter table public.bookstall
  add constraint bookstall_custom_path_format
  check (
    custom_path is null
    or (
      length(custom_path) <= 80
      and custom_path ~ '^[a-z0-9]+(-[a-z0-9]+)*$'
      and custom_path !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    )
  );

create unique index bookstall_custom_path_unique
  on public.bookstall (custom_path)
  where custom_path is not null;
