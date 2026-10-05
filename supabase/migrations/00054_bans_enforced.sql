-- ============================================================
-- Modiin4u — Migration 00054
-- A blocked resident can no longer write
--
-- The panel's Users → Block sets `profiles.is_banned`, and until now only the
-- step leaderboards read it (00022, 00043): a blocked resident could still
-- review, reply, post an apartment, claim a deal, RSVP, save favourites,
-- report, ask for a business and apply for jobs. The panel said "blocked".
--
-- One restrictive rule per write on each table a resident writes: added to
-- the existing rules, so it only takes away. They can still read, sign in,
-- edit their own profile and delete their account. The functions residents
-- call instead of writing (applying for a job) check it themselves, since
-- they run past these rules.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.is_banned_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1 from profiles where id = auth.uid() and is_banned
  );
$$;

revoke all on function public.is_banned_user() from public;
grant execute on function public.is_banned_user() to anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array[
    'reviews', 'comments', 'listings', 'offer_claims', 'event_attendees',
    'favorites', 'reports', 'challenge_participants',
    'business_owner_requests', 'job_alerts'
  ] loop
    if to_regclass('public.' || t) is null then continue; end if;

    execute format('drop policy if exists %I on public.%I', t || '_not_banned_insert', t);
    execute format(
      'create policy %I on public.%I as restrictive for insert to authenticated
         with check (not public.is_banned_user())',
      t || '_not_banned_insert', t);

    execute format('drop policy if exists %I on public.%I', t || '_not_banned_update', t);
    execute format(
      'create policy %I on public.%I as restrictive for update to authenticated
         using (not public.is_banned_user())',
      t || '_not_banned_update', t);
  end loop;
end $$;

-- Applying for a job runs as its owner, past the rules above.
do $$
begin
  if to_regprocedure('public.apply_for_job(uuid, text, text, text, text, text, text)') is not null then
    execute $f$
      create or replace function public.job_apply_not_banned()
      returns trigger
      language plpgsql
      security definer
      set search_path = public
      as $b$
      begin
        if new.profile_id is not null and exists (
          select 1 from profiles where id = new.profile_id and is_banned
        ) then
          raise exception 'account-blocked' using errcode = '42501';
        end if;
        return new;
      end;
      $b$;
    $f$;
    execute 'drop trigger if exists job_apply_not_banned on public.job_applications';
    execute 'create trigger job_apply_not_banned before insert on public.job_applications
               for each row execute function public.job_apply_not_banned()';
  end if;
end $$;

-- Step groups are made and joined through functions that run past the rules
-- too; a trigger stops a blocked caller there. `auth.uid()` is still the
-- caller inside them.
create or replace function public.caller_not_banned()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_banned_user() then
    raise exception 'account-blocked' using errcode = '42501';
  end if;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['step_groups', 'step_group_members'] loop
    if to_regclass('public.' || t) is null then continue; end if;
    execute format('drop trigger if exists %I on public.%I', t || '_not_banned', t);
    execute format(
      'create trigger %I before insert on public.%I
         for each row execute function public.caller_not_banned()',
      t || '_not_banned', t);
  end loop;
end $$;
