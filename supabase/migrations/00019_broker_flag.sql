-- ============================================================
-- Modiin4u — Migration 00019
-- Carry the account type from signup into the profile
--
-- The sign-up screen asks which of the two account types someone is —
-- resident or real-estate broker — and sends the answer as `is_broker` in the
-- account's metadata. Nothing read it: `profiles` had no such column, so the
-- profile screen showed a hardcoded "Real Estate Broker" badge to every
-- resident, and there was no way to ask who the brokers are.
--
-- This adds the column, has the signup trigger fill it, and backfills from
-- the metadata already stored on existing accounts.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. The column ───

alter table public.profiles
  add column if not exists is_broker boolean not null default false;

comment on column public.profiles.is_broker is
  'Chosen at sign-up. A broker may post apartment listings under their own name.';

-- ─── 2. Fill it on sign-up ───
--
-- Same function as 00015, with the flag added. `->>'` yields text, so the
-- cast is explicit and a missing key falls back to false rather than null.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone, is_broker)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'תושב'
    ),
    new.email,
    new.phone,
    coalesce((new.raw_user_meta_data->>'is_broker')::boolean, false)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- ─── 3. Backfill ───
--
-- Accounts created before the column existed kept the answer in their
-- metadata; this reads it back. Only rows that disagree are written.

update public.profiles p
   set is_broker = coalesce((u.raw_user_meta_data->>'is_broker')::boolean, false),
       updated_at = now()
  from auth.users u
 where u.id = p.id
   and p.is_broker is distinct from
       coalesce((u.raw_user_meta_data->>'is_broker')::boolean, false);
