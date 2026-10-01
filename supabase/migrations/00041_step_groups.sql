-- ============================================================
-- Modiin4u — Migration 00041
-- Step groups: walk together, see each other's steps
--
-- The client (29 Sep): "there should be an option to create a group with
-- people who have the app and invite them to it — for example, by sending
-- them an invitation — and then view group stats/activity together. Quite
-- similar to StepsApp."
--
-- A resident creates a group and becomes its owner. Others join with the
-- group's invite code, which travels inside a link
-- (https://app.modiin4u.co.il/join/<code>) shared from the phone's share
-- sheet. There is no people search: profiles are private, and a search would
-- tell anyone who uses the app.
--
-- Joining is the consent: the join screen says that members see each
-- other's daily steps, and only members do. `daily_steps` stays
-- own-rows-only (00014); the figures reach other members through
-- `step_group_stats`, which checks membership first and returns names and
-- sums, never rows.
--
-- Residents never write these tables directly. Every change goes through a
-- function below that checks who is asking; the policies only let a member
-- read their own groups, and the panel read and hide any group. Hiding is
-- the panel's removal, and it is reversible.
--
-- Dates are Israel's: "today" is the day on a phone in Modi'in, which is
-- also the date the app writes into `daily_steps`.
--
-- Safe to run more than once.
-- ============================================================

create table if not exists public.step_groups (
  id           uuid primary key default gen_random_uuid(),
  name         text not null check (char_length(btrim(name)) between 1 and 40),
  invite_code  text not null unique,
  created_by   uuid references public.profiles(id) on delete set null,
  is_hidden    boolean not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists public.step_group_members (
  group_id    uuid not null references public.step_groups(id) on delete cascade,
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  role        text not null default 'member' check (role in ('owner', 'member')),
  joined_at   timestamptz not null default now(),
  primary key (group_id, profile_id)
);

create index if not exists step_group_members_profile_idx
  on public.step_group_members (profile_id);

alter table public.step_groups enable row level security;
alter table public.step_group_members enable row level security;

-- ─── 1. Helpers ───

create or replace function public.step_today()
returns date
language sql
stable
as $$
  select (now() at time zone 'Asia/Jerusalem')::date;
$$;

-- Security definer so the policy on step_groups can ask about
-- step_group_members without that table's own policy getting in the way.
create or replace function public.is_step_group_member(p_group uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from step_group_members
    where group_id = p_group and profile_id = auth.uid()
  );
$$;

create or replace function public.is_step_group_owner(p_group uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from step_group_members
    where group_id = p_group and profile_id = auth.uid() and role = 'owner'
  );
$$;

-- Eight characters from an alphabet without the look-alikes (0/O, 1/I/L),
-- so a code read aloud or typed from a screenshot survives. The randomness
-- is gen_random_uuid's; bytes 6 and 8 carry the uuid's fixed version bits
-- and are skipped.
create or replace function public.step_group_new_code()
returns text
language plpgsql
volatile
set search_path = public
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  picks constant int[] := array[0, 1, 2, 3, 4, 5, 10, 11];
  bytes bytea;
  code text;
  i int;
begin
  loop
    bytes := uuid_send(gen_random_uuid());
    code := '';
    foreach i in array picks loop
      code := code || substr(alphabet, (get_byte(bytes, i) % 31) + 1, 1);
    end loop;
    exit when not exists (select 1 from step_groups where invite_code = code);
  end loop;
  return code;
end;
$$;

-- ─── 2. Who may read ───

drop policy if exists step_groups_member_read on public.step_groups;
create policy step_groups_member_read on public.step_groups
  for select using (public.is_step_group_member(id) or public.is_admin());

drop policy if exists step_groups_admin_update on public.step_groups;
create policy step_groups_admin_update on public.step_groups
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists step_group_members_read on public.step_group_members;
create policy step_group_members_read on public.step_group_members
  for select using (profile_id = auth.uid() or public.is_admin());

-- ─── 3. Recording steps ───
--
-- The app reports the last month from the phone's health data, and today's
-- count every minute while the Step Counter is open. Each day keeps the
-- highest figure reported for it, so a count that restarts (a reboot, a
-- reinstall, a phone without health data) can never lower a day already
-- recorded. Only the last 31 days are accepted, and no day beyond tomorrow
-- (a phone ahead of Israel's clock); the 0–100,000 bound is 00032's.

create or replace function public.record_daily_steps(p_days jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  d jsonb;
  day date;
  n int;
begin
  if uid is null then
    raise exception 'not signed in';
  end if;
  for d in select * from jsonb_array_elements(coalesce(p_days, '[]'::jsonb)) loop
    day := (d->>'date')::date;
    n := least(greatest(coalesce((d->>'steps')::int, 0), 0), 100000);
    continue when day < step_today() - 31 or day > step_today() + 1 or n = 0;
    insert into daily_steps (profile_id, date, steps)
    values (uid, day, n)
    on conflict (profile_id, date)
      do update set steps = greatest(daily_steps.steps, excluded.steps);
  end loop;
end;
$$;

-- ─── 4. Groups ───

create or replace function public.create_step_group(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  gid uuid;
begin
  if uid is null then
    raise exception 'not signed in';
  end if;
  -- Enough for family, friends and a work team; a ceiling against a script.
  if (select count(*) from step_group_members
      where profile_id = uid and role = 'owner') >= 10 then
    raise exception 'too many groups';
  end if;
  insert into step_groups (name, invite_code, created_by)
  values (btrim(p_name), step_group_new_code(), uid)
  returning id into gid;
  insert into step_group_members (group_id, profile_id, role)
  values (gid, uid, 'owner');
  return gid;
end;
$$;

-- What the join screen shows before someone decides: the group's name and
-- how many are in it. Open to the anonymous key too, because the website's
-- /join page shows it to someone who does not have the app yet; the code is
-- the secret, and only its holder learns the name.
create or replace function public.step_group_preview(p_code text)
returns table (id uuid, name text, member_count int, is_member boolean)
language sql
security definer
set search_path = public
stable
as $$
  select g.id, g.name,
         (select count(*)::int from step_group_members m where m.group_id = g.id),
         exists (select 1 from step_group_members m
                 where m.group_id = g.id and m.profile_id = auth.uid())
  from step_groups g
  where g.invite_code = upper(btrim(p_code))
    and not g.is_hidden;
$$;

create or replace function public.join_step_group(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  gid uuid;
begin
  if uid is null then
    raise exception 'not signed in';
  end if;
  select g.id into gid from step_groups g
  where g.invite_code = upper(btrim(p_code)) and not g.is_hidden;
  if gid is null then
    raise exception 'no such group';
  end if;
  if not exists (select 1 from step_group_members
                 where group_id = gid and profile_id = uid)
     and (select count(*) from step_group_members where group_id = gid) >= 50 then
    raise exception 'group is full';
  end if;
  insert into step_group_members (group_id, profile_id)
  values (gid, uid)
  on conflict do nothing;
  return gid;
end;
$$;

-- Leaving is always allowed. An owner who leaves hands the group to the
-- member who has been in it longest; the last one out removes it, since
-- nobody is left to see it.
create or replace function public.leave_step_group(p_group uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  was_owner boolean;
  heir uuid;
begin
  delete from step_group_members
  where group_id = p_group and profile_id = uid
  returning role = 'owner' into was_owner;
  if was_owner is null then
    return;
  end if;
  select profile_id into heir from step_group_members
  where group_id = p_group
  order by joined_at
  limit 1;
  if heir is null then
    delete from step_groups where id = p_group;
  elsif was_owner then
    update step_group_members set role = 'owner'
    where group_id = p_group and profile_id = heir;
  end if;
end;
$$;

create or replace function public.remove_step_group_member(p_group uuid, p_profile uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_step_group_owner(p_group) then
    raise exception 'only the owner can remove members';
  end if;
  delete from step_group_members
  where group_id = p_group and profile_id = p_profile and role <> 'owner';
end;
$$;

create or replace function public.rename_step_group(p_group uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_step_group_owner(p_group) then
    raise exception 'only the owner can rename the group';
  end if;
  update step_groups set name = btrim(p_name) where id = p_group;
end;
$$;

-- A new code, so links already sent stop working — for a link that went
-- further than meant.
create or replace function public.reset_step_group_code(p_group uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  code text;
begin
  if not is_step_group_owner(p_group) then
    raise exception 'only the owner can change the invite';
  end if;
  code := step_group_new_code();
  update step_groups set invite_code = code where id = p_group;
  return code;
end;
$$;

create or replace function public.delete_step_group(p_group uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_step_group_owner(p_group) then
    raise exception 'only the owner can delete the group';
  end if;
  delete from step_groups where id = p_group;
end;
$$;

-- ─── 5. What the screens read ───

-- The caller's groups, with what the list shows: their role, the member
-- count, the group's steps today and the caller's place in it today.
create or replace function public.my_step_groups()
returns table (
  id uuid,
  name text,
  role text,
  member_count int,
  today_total bigint,
  my_rank int
)
language sql
security definer
set search_path = public
stable
as $$
  with mine as (
    select g.id, g.name, m.role
    from step_group_members m
    join step_groups g on g.id = m.group_id
    where m.profile_id = auth.uid() and not g.is_hidden
  ),
  today as (
    select m.group_id, m.profile_id, coalesce(d.steps, 0) as steps
    from step_group_members m
    left join daily_steps d
      on d.profile_id = m.profile_id and d.date = step_today()
    where m.group_id in (select id from mine)
  ),
  ranked as (
    select group_id, profile_id, steps,
           rank() over (partition by group_id order by steps desc)::int as r
    from today
  )
  select mine.id, mine.name, mine.role,
         (select count(*)::int from today t where t.group_id = mine.id),
         (select coalesce(sum(t.steps), 0)::bigint from today t where t.group_id = mine.id),
         (select r from ranked where ranked.group_id = mine.id
                                 and ranked.profile_id = auth.uid())
  from mine
  order by mine.name;
$$;

-- One group's members with their steps: today, this week (Israel's week,
-- from Sunday), this month, and each of the last seven days for the chart.
-- Members only; the panel too, for moderation.
create or replace function public.step_group_stats(p_group uuid)
returns table (
  profile_id uuid,
  full_name text,
  avatar_url text,
  role text,
  joined_at timestamptz,
  is_me boolean,
  today int,
  week int,
  month int,
  last7 jsonb
)
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  t date := step_today();
  week_start date := t - extract(dow from t)::int;
  month_start date := date_trunc('month', t)::date;
begin
  if not (is_step_group_member(p_group) or is_admin()) then
    raise exception 'not a member of this group';
  end if;
  return query
  select p.id, p.full_name, p.avatar_url, m.role, m.joined_at,
         p.id = auth.uid(),
         coalesce(sum(d.steps) filter (where d.date = t), 0)::int,
         coalesce(sum(d.steps) filter (where d.date >= week_start), 0)::int,
         coalesce(sum(d.steps) filter (where d.date >= month_start), 0)::int,
         coalesce(
           jsonb_object_agg(d.date::text, d.steps) filter (where d.date > t - 7),
           '{}'::jsonb)
  from step_group_members m
  join profiles p on p.id = m.profile_id
  left join daily_steps d
    on d.profile_id = m.profile_id
   and d.date >= least(month_start, week_start, t - 6)
   and d.date <= t
  where m.group_id = p_group
  group by p.id, p.full_name, p.avatar_url, m.role, m.joined_at;
end;
$$;

-- ─── 6. Who may call them ───

do $$
declare
  f text;
begin
  foreach f in array array[
    'record_daily_steps(jsonb)',
    'create_step_group(text)',
    'join_step_group(text)',
    'leave_step_group(uuid)',
    'remove_step_group_member(uuid, uuid)',
    'rename_step_group(uuid, text)',
    'reset_step_group_code(uuid)',
    'delete_step_group(uuid)',
    'my_step_groups()',
    'step_group_stats(uuid)',
    'step_group_new_code()'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

revoke all on function public.step_group_new_code() from authenticated;

revoke all on function public.step_group_preview(text) from public;
grant execute on function public.step_group_preview(text) to anon, authenticated;
