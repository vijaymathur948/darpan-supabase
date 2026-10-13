-- Remove bookstalls tables, trigger function, and image storage.

do $$
begin
  if exists (
    select 1
    from storage.buckets
    where id = 'bookstall-images'
  ) then
    raise exception 'Delete the bookstall-images bucket through the Supabase Storage API or Dashboard before applying this migration.';
  end if;
end;
$$;

drop policy if exists "Anyone can read bookstall storage images" on storage.objects;
drop policy if exists "Anyone can upload bookstall storage images" on storage.objects;
drop policy if exists "Anyone can update bookstall storage images" on storage.objects;
drop policy if exists "Anyone can delete bookstall storage images" on storage.objects;

drop table if exists public.bookstall_images;
drop table if exists public.bookstalls;
drop function if exists public.set_bookstalls_updated_at();
