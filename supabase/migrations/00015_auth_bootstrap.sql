-- ============================================================
-- Modiin4u — Migration 00015
-- Sign-in bootstrap and account deletion
--
-- `profiles` extends `auth.users` but nothing ever created the row, and
-- `full_name` is NOT NULL, so the first thing a new account did was fail.
-- There is also no INSERT policy on `profiles`, so a signed-in person cannot
-- create their own row either.
--
-- This adds a trigger that creates the profile as the account is created, and
-- a function that lets someone delete their own account — required by both
-- app stores and asked for by the client.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Create the profile alongside the account ───
--
-- SECURITY DEFINER so it runs as the owner rather than as the new account,
-- which has no rights over `profiles` yet. `full_name` falls back to the part
-- of the address before the @, so the column is never null and the person has
-- a name on screen before they have filled anything in.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'תושב'
    ),
    new.email,
    new.phone
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill anyone who signed in before this migration ran.
insert into public.profiles (id, full_name, email, phone)
select
  u.id,
  coalesce(
    nullif(u.raw_user_meta_data->>'full_name', ''),
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'תושב'
  ),
  u.email,
  u.phone
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- ─── 2. Let a signed-in person create their own row ───
--
-- The trigger covers new accounts; this is the fallback for a profile that
-- went missing, and it cannot be used to write anyone else's row.

drop policy if exists "profiles_insert_own" on public.profiles;

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (id = auth.uid());

-- ─── 3. Delete my account ───
--
-- Removing the `auth.users` row cascades to `profiles`, and the foreign keys
-- already say what should happen from there: a business listing and an
-- article are detached (`on delete set null`) so published content survives
-- the account, while the person's own reviews, comments, favourites, claims,
-- steps and attendance go with them (`on delete cascade`).
--
-- SECURITY DEFINER because `auth.users` is not writable by the anon or
-- authenticated roles. It only ever deletes the caller: there is no argument
-- to point it at somebody else.

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not signed in';
  end if;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
