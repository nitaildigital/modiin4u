-- ============================================================
-- Modiin4u — Migration 00052
-- Job openings: jobs, applications and candidates, alerts, statistics
--
-- The client's specification (5 Oct): a local marketplace between hiring
-- businesses and job seekers — posting, search, applying, and basic
-- candidate management. A job belongs to a business; its owner (00051) and
-- the panel manage it. The screens come with Kamal's design; this is what
-- they stand on.
--
--   * jobs — title, category (categories with scope 'job', kept in the
--     panel), place, type, scope, description, requirements, experience,
--     salary (optional), hours, contact person, picture; flags for the
--     dedicated lists (youth, students, no experience, shifts); how to apply
--     — call, WhatsApp, e-mail and/or a short form, as the owner chooses;
--     statuses draft, active, expired, closed (closed covers filled); an
--     expiry date. Featuring and boosting are the panel's, as with deals.
--   * job_applications — the short form's answers and an optional CV, made
--     only through `apply_for_job`; the job's owner moves them through new,
--     viewed, contacted, interview, suitable, unsuitable, accepted, archived,
--     with private notes and a reminder date. The applicant sees their own
--     ("my applications") and nothing of the notes.
--   * CVs — a private bucket, `cvs/<applicant id>/<file>`: the applicant,
--     the owner of a job they applied to with it, and the panel may read it;
--     nobody else, not even by its address.
--   * saved jobs — `favorites` with entity_type 'job' (no new table).
--   * job_alerts — a resident's saved search, for notifications later.
--   * job_events — views and clicks, as business_events (00048), with
--     `job_stats` for the owner and the panel.
--
-- The client's answers (5 Oct): a job goes live as the owner sets it, with
-- no approval, like deals. Applications are deleted two days after their job
-- closes or expires; the number of days is his to change in the panel
-- (`app_settings`, key `job_applications_keep_days`). A CV file is the
-- applicant's own, in their folder, reused for the next application; when
-- the application goes, the business loses access to it (`can_read_cv`
-- reads through the application), and the file itself goes when the
-- applicant removes it or deletes their account.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Jobs ───

create table if not exists public.jobs (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid not null references public.businesses(id) on delete cascade,
  category_id      uuid references public.categories(id) on delete set null,

  title            text not null,
  description      text,
  requirements     text,
  job_type         text check (job_type in ('full_time', 'part_time', 'shifts', 'temporary', 'freelance', 'internship')),
  scope            text,             -- "3 days a week", "evenings" — the owner's words
  experience       text check (experience in ('none', 'junior', 'mid', 'senior')),
  location         text,
  neighborhood_id  uuid references public.neighborhoods(id) on delete set null,
  salary_min       numeric(10, 2),
  salary_max       numeric(10, 2),
  salary_period    text check (salary_period in ('hour', 'month', 'year', 'project')),
  hours            text,
  image_url        text,

  -- The dedicated lists the specification names.
  for_youth        boolean not null default false,
  for_students     boolean not null default false,
  no_experience    boolean not null default false,
  shift_work       boolean not null default false,

  -- Who to contact, and the ways the job page offers to apply.
  contact_name     text,
  contact_phone    text,
  contact_whatsapp text,
  contact_email    text,
  apply_by_call     boolean not null default false,
  apply_by_whatsapp boolean not null default false,
  apply_by_email    boolean not null default false,
  apply_by_form     boolean not null default true,
  form_accepts_cv   boolean not null default true,

  status           text not null default 'draft'
                   check (status in ('draft', 'active', 'expired', 'closed')),
  published_at     timestamptz,
  expires_at       timestamptz,
  closed_at        timestamptz,      -- when it stopped taking applications

  -- The panel's, not the owner's.
  is_featured      boolean not null default false,
  boosted_until    timestamptz,

  created_by       uuid references public.profiles(id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  check (salary_min is null or salary_max is null or salary_min <= salary_max)
);

create index if not exists idx_jobs_live on public.jobs (status, published_at desc);
create index if not exists idx_jobs_business on public.jobs (business_id);
create index if not exists idx_jobs_category on public.jobs (category_id);

-- A job is live while active and not past its expiry; nothing has to run at
-- midnight to take it down.
create or replace function public.job_is_live(j public.jobs)
returns boolean
language sql
stable
as $$
  select j.status = 'active' and (j.expires_at is null or j.expires_at > now());
$$;

create or replace function public.jobs_stamp()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  if new.status = 'active' and (tg_op = 'INSERT' or old.status is distinct from 'active') then
    new.published_at := coalesce(new.published_at, now());
  end if;
  -- Open again (active or back to draft): the retention clock stops.
  if new.status in ('active', 'draft') then
    new.closed_at := null;
  end if;
  -- The retention clock (section 6) starts when it closes.
  if new.status in ('closed', 'expired')
     and (tg_op = 'INSERT' or old.status not in ('closed', 'expired')) then
    new.closed_at := now();
  end if;
  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
  end if;

  -- An owner may not feature or boost (the panel's, as for deals) or move a
  -- job to another business.
  if not is_admin() and current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.is_featured := false;
      new.boosted_until := null;
    elsif new.is_featured is distinct from old.is_featured
       or new.boosted_until is distinct from old.boosted_until
       or new.business_id is distinct from old.business_id then
      raise exception 'featuring, boosting and the business of a job are set by the management panel'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists jobs_stamp on public.jobs;
create trigger jobs_stamp
  before insert or update on public.jobs
  for each row execute function public.jobs_stamp();

alter table public.jobs enable row level security;

drop policy if exists jobs_read on public.jobs;
create policy jobs_read on public.jobs
  for select using (
    (status = 'active' and (expires_at is null or expires_at > now()))
    or public.owns_business(business_id)
    or is_admin()
  );

-- Add and edit; not delete — a deleted job takes its applications with it.
-- An owner ends a job by closing it; the panel can delete.
drop policy if exists jobs_owner_write on public.jobs;
drop policy if exists jobs_owner_insert on public.jobs;
create policy jobs_owner_insert on public.jobs
  for insert to authenticated
  with check (public.owns_business(business_id));

drop policy if exists jobs_owner_update on public.jobs;
create policy jobs_owner_update on public.jobs
  for update to authenticated
  using (public.owns_business(business_id))
  with check (public.owns_business(business_id));

drop policy if exists jobs_admin_write on public.jobs;
create policy jobs_admin_write on public.jobs
  for all to authenticated
  using (is_admin() and public.admin_may('businesses', 'edit'))
  with check (is_admin() and public.admin_may('businesses', 'edit'));

-- ─── 2. Applications and candidates ───

create table if not exists public.job_applications (
  id          uuid primary key default gen_random_uuid(),
  job_id      uuid not null references public.jobs(id) on delete cascade,
  -- An applicant who deletes their account takes their applications with
  -- them, as the Delete Account page promises.
  profile_id  uuid references public.profiles(id) on delete cascade,
  full_name   text not null,
  phone       text,
  email       text,
  message     text,
  cv_path     text,                 -- in the private `cvs` bucket
  status      text not null default 'new'
              check (status in ('new', 'viewed', 'contacted', 'interview',
                                'suitable', 'unsuitable', 'accepted', 'archived')),
  notes       text,                 -- the owner's, never shown to the applicant
  remind_at   timestamptz,          -- the owner's reminder
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (phone is not null or email is not null)
);

create index if not exists idx_job_applications_job on public.job_applications (job_id, created_at desc);
create index if not exists idx_job_applications_profile on public.job_applications (profile_id);
-- One application per person per job.
create unique index if not exists job_applications_one_per_person
  on public.job_applications (job_id, profile_id) where profile_id is not null;

alter table public.job_applications enable row level security;

drop policy if exists job_applications_read on public.job_applications;
create policy job_applications_read on public.job_applications
  for select using (
    profile_id = auth.uid()
    or is_admin()
    or exists (select 1 from jobs j where j.id = job_id and public.owns_business(j.business_id))
  );

-- The job's owner (and the panel) move an application along; nobody inserts
-- directly — `apply_for_job` does.
drop policy if exists job_applications_manage on public.job_applications;
create policy job_applications_manage on public.job_applications
  for update to authenticated
  using (is_admin() or exists (select 1 from jobs j where j.id = job_id and public.owns_business(j.business_id)))
  with check (is_admin() or exists (select 1 from jobs j where j.id = job_id and public.owns_business(j.business_id)));

drop policy if exists job_applications_admin_delete on public.job_applications;
create policy job_applications_admin_delete on public.job_applications
  for delete to authenticated using (is_admin());

-- What the owner may change: the status, the notes, the reminder.
create or replace function public.job_applications_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  if not is_admin() and current_user in ('authenticated', 'anon') and (
       new.job_id is distinct from old.job_id
    or new.profile_id is distinct from old.profile_id
    or new.full_name is distinct from old.full_name
    or new.phone is distinct from old.phone
    or new.email is distinct from old.email
    or new.message is distinct from old.message
    or new.cv_path is distinct from old.cv_path
    or new.created_at is distinct from old.created_at) then
    raise exception 'only the status, notes and reminder of an application can be changed'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists job_applications_guard on public.job_applications;
create trigger job_applications_guard
  before update on public.job_applications
  for each row execute function public.job_applications_guard();

-- Applying: a live job that takes the form; the applicant signed in or not
-- (the website has no resident accounts). A CV only from the applicant's own
-- folder, and only where the job asks for one.
create or replace function public.apply_for_job(
  p_job       uuid,
  p_full_name text,
  p_phone     text default null,
  p_email     text default null,
  p_message   text default null,
  p_cv_path   text default null,
  p_platform  text default 'web'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  j jobs;
  v_id uuid;
  v_name text := nullif(trim(coalesce(p_full_name, '')), '');
  v_phone text := nullif(trim(coalesce(p_phone, '')), '');
  v_email text := nullif(lower(trim(coalesce(p_email, ''))), '');
begin
  select * into j from jobs where id = p_job;
  if j.id is null or not job_is_live(j) or not j.apply_by_form then
    raise exception 'job-not-open';
  end if;
  if v_name is null or length(v_name) > 120 then
    raise exception 'name-required';
  end if;
  if v_phone is null and v_email is null then
    raise exception 'contact-required';
  end if;
  if v_email is not null and v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'email-invalid';
  end if;
  if p_cv_path is not null and (
       not j.form_accepts_cv
    or auth.uid() is null
    or split_part(p_cv_path, '/', 1) <> auth.uid()::text) then
    raise exception 'cv-not-allowed';
  end if;
  -- The same address or phone once per job, account or not.
  if exists (
    select 1 from job_applications a
     where a.job_id = p_job
       and ((v_email is not null and a.email = v_email)
         or (v_phone is not null and a.phone = v_phone)
         or (auth.uid() is not null and a.profile_id = auth.uid()))
  ) then
    raise exception 'already-applied';
  end if;

  insert into job_applications (job_id, profile_id, full_name, phone, email, message, cv_path)
  values (p_job, auth.uid(), v_name, v_phone, v_email,
          nullif(left(trim(coalesce(p_message, '')), 2000), ''), p_cv_path)
  returning id into v_id;

  insert into job_events (job_id, kind, platform, visitor)
  values (p_job, 'apply',
          case when p_platform = 'app' then 'app' else 'web' end,
          coalesce(auth.uid()::text, 'anonymous-' || v_id::text));

  return v_id;
end;
$$;

-- ─── 3. CVs: a private bucket ───

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cvs', 'cvs', false, 5242880,
        array['application/pdf', 'application/msword',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do nothing;

create or replace function public.can_read_cv(p_path text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
       split_part(p_path, '/', 1) = auth.uid()::text
    or is_admin()
    or exists (
         select 1 from job_applications a
           join jobs j on j.id = a.job_id
          where a.cv_path = p_path and owns_business(j.business_id))
  );
$$;

drop policy if exists "cvs_read" on storage.objects;
create policy "cvs_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'cvs' and public.can_read_cv(name));

drop policy if exists "cvs_own_write" on storage.objects;
create policy "cvs_own_write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'cvs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "cvs_own_update" on storage.objects;
create policy "cvs_own_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'cvs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "cvs_own_delete" on storage.objects;
create policy "cvs_own_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'cvs' and (storage.foldername(name))[1] = auth.uid()::text);

-- A resident's CV, kept for applying in one tap.
alter table public.profiles
  add column if not exists cv_path text,
  add column if not exists cv_updated_at timestamptz;

-- ─── 4. Job alerts ───

create table if not exists public.job_alerts (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  filters     jsonb not null default '{}'::jsonb,   -- the search: category, type, area, flags…
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create index if not exists idx_job_alerts_profile on public.job_alerts (profile_id);

alter table public.job_alerts enable row level security;

drop policy if exists job_alerts_own on public.job_alerts;
create policy job_alerts_own on public.job_alerts
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

drop policy if exists job_alerts_admin_read on public.job_alerts;
create policy job_alerts_admin_read on public.job_alerts
  for select using (is_admin());

-- ─── 5. Statistics ───

create table if not exists public.job_events (
  id         bigint generated always as identity primary key,
  job_id     uuid not null references public.jobs(id) on delete cascade,
  kind       text not null check (kind in ('view', 'apply', 'call', 'whatsapp', 'email', 'share', 'save')),
  platform   text not null check (platform in ('app', 'web')),
  visitor    text not null check (length(visitor) between 8 and 80),
  created_at timestamptz not null default now()
);

create index if not exists idx_job_events_job_time on public.job_events (job_id, created_at);
alter table public.job_events enable row level security;  -- no policies: functions only

create or replace function public.record_job_event(
  p_job      uuid,
  p_kind     text,
  p_platform text,
  p_visitor  text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_kind = 'apply' then
    return;  -- counted by apply_for_job itself, not by the page
  end if;
  if p_kind = 'view' and exists (
    select 1 from job_events
     where job_id = p_job and visitor = p_visitor and kind = 'view'
       and created_at > now() - interval '30 minutes'
  ) then
    return;
  end if;
  insert into job_events (job_id, kind, platform, visitor)
  select p_job, p_kind, p_platform, p_visitor
   where exists (select 1 from jobs where id = p_job);
end;
$$;

-- Views, applications, conversion and the rest, for one job.
create or replace function public.job_stats(p_job uuid)
returns table (kind text, total bigint, visitors bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (is_admin() or exists (select 1 from jobs where id = p_job and owns_business(business_id))) then
    raise exception 'not allowed';
  end if;
  return query
    select e.kind, count(*), count(distinct e.visitor)
      from job_events e
     where e.job_id = p_job
     group by e.kind
    union all
    select 'saves', count(*), count(*)
      from favorites
     where entity_type = 'job' and entity_id = p_job;
end;
$$;

revoke all on function public.apply_for_job(uuid, text, text, text, text, text, text) from public;
revoke all on function public.record_job_event(uuid, text, text, text) from public;
revoke all on function public.job_stats(uuid) from public, anon;
revoke all on function public.can_read_cv(text) from public;
grant execute on function public.apply_for_job(uuid, text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.record_job_event(uuid, text, text, text) to anon, authenticated;
grant execute on function public.job_stats(uuid) to authenticated;
grant execute on function public.can_read_cv(text) to authenticated;

-- ─── 6. Applications are kept two days after their job closes ───
--
-- A job stops taking applications when it is closed or expired by status,
-- or when its expiry date passes. Every night its applications older than
-- that by `job_applications_keep_days` (2 unless the panel says otherwise)
-- are deleted: the applicant's name, phone, e-mail, message and the link to
-- their CV. Until then the business and the panel still see them.

insert into public.app_settings (key, value)
values ('job_applications_keep_days', '2'::jsonb)
on conflict (key) do nothing;

create or replace function public.purge_closed_job_applications()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_days int;
  v_count int;
begin
  -- A whole number of days; anything else in the setting means the default,
  -- never a purge that fails every night.
  select case when (value #>> '{}') ~ '^\d{1,3}$' then (value #>> '{}')::int end
    into v_days
    from app_settings where key = 'job_applications_keep_days';
  v_days := coalesce(v_days, 2);

  delete from job_applications a
   using jobs j
   where j.id = a.job_id
     and coalesce(
           j.closed_at,
           case when j.expires_at is not null and j.expires_at <= now() then j.expires_at end
         ) < now() - make_interval(days => v_days);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.purge_closed_job_applications() from public, anon, authenticated;

create extension if not exists pg_cron;

select cron.unschedule('purge-closed-job-applications')
 where exists (select 1 from cron.job where jobname = 'purge-closed-job-applications');

-- 00:30 UTC: 02:30–03:30 in Modi'in.
select cron.schedule(
  'purge-closed-job-applications',
  '30 0 * * *',
  $job$ select public.purge_closed_job_applications(); $job$
);

-- ─── 7. Job categories, kept in the panel ───
-- The specification's dedicated lists are flags on the job (youth, students,
-- no experience, shifts); the trades are categories the client adds.
