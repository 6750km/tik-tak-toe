-- Grant 10 account games once, and preserve unspent guest games once.

alter table public.profiles
  add column if not exists welcome_games_claimed boolean not null default false;

alter table public.profiles
  alter column bonus_games_remaining set default 0;

alter table public.profiles
  drop constraint if exists profiles_bonus_games_remaining_check;

alter table public.profiles
  add constraint profiles_bonus_games_remaining_check
  check (bonus_games_remaining >= 0);

create or replace function public.claim_welcome_games(p_guest_remaining integer)
returns integer
language plpgsql
security definer set search_path = ''
as $$
declare
  remaining integer;
begin
  update public.profiles
  set bonus_games_remaining = bonus_games_remaining
        + 10
        + case
            when guest_games_claimed = false
            then greatest(0, least(p_guest_remaining, 10))
            else 0
          end,
      welcome_games_claimed = true,
      guest_games_claimed = true,
      updated_at = now()
  where id = (select auth.uid())
    and welcome_games_claimed = false
  returning bonus_games_remaining into remaining;

  if remaining is null then
    select bonus_games_remaining into remaining
    from public.profiles
    where id = (select auth.uid());
  end if;

  return coalesce(remaining, 0);
end;
$$;

revoke all on function public.claim_welcome_games(integer) from public;
grant execute on function public.claim_welcome_games(integer) to authenticated;
