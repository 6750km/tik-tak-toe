-- Tic Tac Toe Easy Go: profiles, registration bonus, and minimal usage counters.
-- Run this migration in Supabase SQL Editor after creating the project.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  bonus_games_remaining integer not null default 10 check (bonus_games_remaining between 0 and 10),
  games_completed bigint not null default 0 check (games_completed >= 0),
  app_opens bigint not null default 0 check (app_opens >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

revoke all on public.profiles from anon;
revoke insert, update, delete on public.profiles from authenticated;
grant select on public.profiles to authenticated;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.consume_bonus_game()
returns integer
language plpgsql
security definer set search_path = ''
as $$
declare
  remaining integer;
begin
  update public.profiles
  set bonus_games_remaining = bonus_games_remaining - 1,
      games_completed = games_completed + 1,
      updated_at = now()
  where id = (select auth.uid())
    and bonus_games_remaining > 0
  returning bonus_games_remaining into remaining;

  if remaining is null then
    select bonus_games_remaining into remaining
    from public.profiles
    where id = (select auth.uid());
  end if;

  return coalesce(remaining, 0);
end;
$$;

create or replace function public.record_app_open()
returns void
language sql
security definer set search_path = ''
as $$
  update public.profiles
  set app_opens = app_opens + 1,
      updated_at = now()
  where id = (select auth.uid());
$$;

revoke all on function public.consume_bonus_game() from public;
revoke all on function public.record_app_open() from public;
grant execute on function public.consume_bonus_game() to authenticated;
grant execute on function public.record_app_open() to authenticated;
