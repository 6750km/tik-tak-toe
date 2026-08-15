-- Preserve remaining guest games after registration and add profile avatars.

alter table public.profiles
  add column if not exists guest_games_claimed boolean not null default false,
  add column if not exists avatar_path text;

alter table public.profiles
  drop constraint if exists profiles_bonus_games_remaining_check;

alter table public.profiles
  add constraint profiles_bonus_games_remaining_check
  check (bonus_games_remaining between 0 and 20);

create or replace function public.claim_guest_games(p_remaining integer)
returns integer
language plpgsql
security definer set search_path = ''
as $$
declare
  remaining integer;
begin
  update public.profiles
  set bonus_games_remaining = bonus_games_remaining + greatest(0, least(p_remaining, 10)),
      guest_games_claimed = true,
      updated_at = now()
  where id = (select auth.uid())
    and guest_games_claimed = false
  returning bonus_games_remaining into remaining;

  if remaining is null then
    select bonus_games_remaining into remaining
    from public.profiles
    where id = (select auth.uid());
  end if;

  return coalesce(remaining, 0);
end;
$$;

create or replace function public.set_avatar_path(p_path text)
returns text
language plpgsql
security definer set search_path = ''
as $$
begin
  if p_path is null
     or split_part(p_path, '/', 1) <> (select auth.uid())::text then
    raise exception 'Invalid avatar path';
  end if;

  update public.profiles
  set avatar_path = p_path,
      updated_at = now()
  where id = (select auth.uid());

  return p_path;
end;
$$;

revoke all on function public.claim_guest_games(integer) from public;
revoke all on function public.set_avatar_path(text) from public;
grant execute on function public.claim_guest_games(integer) to authenticated;
grant execute on function public.set_avatar_path(text) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their own avatar objects" on storage.objects;
create policy "Users can read their own avatar objects"
on storage.objects for select
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can upload their own avatars" on storage.objects;
create policy "Users can upload their own avatars"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can update their own avatars" on storage.objects;
create policy "Users can update their own avatars"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can delete their own avatars" on storage.objects;
create policy "Users can delete their own avatars"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid()::text)
);
