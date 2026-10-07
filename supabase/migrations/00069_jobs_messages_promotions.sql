-- ============================================================
-- Modiin4u — Migration 00069
-- Kamal's business and job-seeker screens: what they save
--
-- Built on 00051 (owners) and 00052 (jobs, applications, CVs), with the
-- frames in `business_side/` and `user_side/` (7 Oct). Harshit, for the
-- client, 7 Oct: everything is saved in the database; a business may ask to
-- promote its page, a deal or a job for a number of days, the panel approves
-- or declines, and an approved one stands at the top of its list for those
-- days; and every event that concerns someone reaches them as a notification.
--
--   1. Jobs: what the Post a Job form adds — key responsibilities, the work
--      schedule, several images — and promotion.
--   2. The job seeker's profile (My Profile): about, skills, experience in
--      years, location, more information; work experience; education;
--      resumes. Private, read by its owner, by a business the person applied
--      to, and by the panel.
--   3. Applicants for a business: `job_applicants` gives each applicant's
--      photo, place and latest role, which the private profile row hides;
--      a heart (`shortlisted`) on each.
--   4. Messages between a business and a person: one conversation per pair,
--      started by the business with someone who applied to it, or by a
--      resident; read marks; live on the screen (realtime).
--   5. Promotion requests: a business asks, the panel approves or declines;
--      approved, the business, deal or job gets `promoted_until`, and the
--      lists put it first. Payment is not in the system (the client collects
--      it, as with the setup fee).
--   6. Deals: a type and value (Create Deal); an owner deletes a deal nobody
--      has claimed, and closes one that has claims.
--   7. Notifications — a `jobs` topic on devices, and:
--        a new job → everyone with Jobs on;
--        a job closed → its applicants and those who saved it;
--        an application → the business; its status (interview, accepted,
--          not selected) → the applicant;
--        a message → the other side;
--        a promotion request → the team; its decision → the business;
--        a business waiting for approval → the team; approved → its owner;
--        a business owner's new deal → everyone with Deals on (until now an
--          owner's deal was not announced — Harshit, 7 Oct);
--        a claim on a deal, an approved review → the business's owner.
--
-- Needs 00051 and 00052. Safe to run more than once.
-- ============================================================

-- ─── 0. Sending to particular people ───

-- One notification to the devices these people are signed in on, whatever
-- their topic switches — it is theirs alone. Nobody, or an empty list,
-- sends nothing.
create or replace function public.notify_people(
  p_ids       jsonb,
  p_title     text,
  p_body      text,
  p_title_en  text,
  p_body_en   text,
  p_link      text,
  p_source    text,
  p_source_id uuid,
  p_image     text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_ids is null or jsonb_typeof(p_ids) <> 'array' or jsonb_array_length(p_ids) = 0 then
    return;
  end if;
  insert into push_campaigns (
    title, body, title_en, body_en, image_url, deep_link,
    status, scheduled_at, audience_type, audience_filter, source_type, source_id
  ) values (
    p_title, coalesce(p_body, ''), p_title_en, p_body_en, p_image, p_link,
    'scheduled', now(), 'person', jsonb_build_object('profile_ids', p_ids),
    p_source, p_source_id
  );
end;
$$;

revoke all on function public.notify_people(jsonb, text, text, text, text, text, text, uuid, text)
  from public, anon, authenticated;

-- The people a business answers through: its owner.
create or replace function public.business_owner_ids(p_business uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when owner_id is null then null else jsonb_build_array(owner_id) end
    from businesses where id = p_business;
$$;

revoke all on function public.business_owner_ids(uuid) from public, anon, authenticated;

-- ─── 1. Jobs ───

alter table public.jobs
  add column if not exists responsibilities text,
  add column if not exists schedule text,
  add column if not exists images text[] not null default '{}',
  add column if not exists promoted_until timestamptz;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'jobs_schedule_check') then
    alter table public.jobs add constraint jobs_schedule_check
      check (schedule is null or schedule in ('fixed', 'shifts', 'flexible'));
  end if;
end $$;

create index if not exists idx_jobs_promoted on public.jobs (promoted_until desc nulls last);

-- 00052's stamp, with promotion added to what only the panel sets.
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
  if new.status in ('active', 'draft') then
    new.closed_at := null;
  end if;
  if new.status in ('closed', 'expired')
     and (tg_op = 'INSERT' or old.status not in ('closed', 'expired')) then
    new.closed_at := now();
  end if;
  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
  end if;

  if not is_admin() and current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.is_featured := false;
      new.boosted_until := null;
      new.promoted_until := null;
    elsif new.is_featured is distinct from old.is_featured
       or new.boosted_until is distinct from old.boosted_until
       or new.promoted_until is distinct from old.promoted_until
       or new.business_id is distinct from old.business_id then
      raise exception 'featuring, promotion and the business of a job are set by the management panel'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

-- Images uploaded by an owner go under `jobs/<business id>/` in the media
-- bucket.
drop policy if exists "media_job_owner_insert" on storage.objects;
create policy "media_job_owner_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'jobs'
    and public.owns_business_path((storage.foldername(name))[2])
  );

drop policy if exists "media_job_owner_delete" on storage.objects;
create policy "media_job_owner_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'jobs'
    and public.owns_business_path((storage.foldername(name))[2])
  );

-- Deals' images likewise, under `offers/<business id>/`.
drop policy if exists "media_offer_owner_insert" on storage.objects;
create policy "media_offer_owner_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'offers'
    and public.owns_business_path((storage.foldername(name))[2])
  );

-- Someone who applied keeps seeing the job after it closes, so it stays on
-- their Applied Jobs with its outcome.
create or replace function public.applied_to_job(p_job uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1 from job_applications where job_id = p_job and profile_id = auth.uid());
$$;

revoke all on function public.applied_to_job(uuid) from public, anon;
grant execute on function public.applied_to_job(uuid) to authenticated;

drop policy if exists jobs_applicant_read on public.jobs;
create policy jobs_applicant_read on public.jobs
  for select to authenticated using (public.applied_to_job(id));

-- A heart on an applicant: the business's shortlist.
alter table public.job_applications
  add column if not exists shortlisted boolean not null default false;

-- ─── 2. The job seeker's profile ───

create table if not exists public.job_profiles (
  profile_id       uuid primary key references public.profiles(id) on delete cascade,
  about            text check (about is null or length(about) <= 1000),
  skills           text[] not null default '{}',
  experience_years int check (experience_years is null or experience_years between 0 and 60),
  location         text,
  additional_info  text check (additional_info is null or length(additional_info) <= 1000),
  updated_at       timestamptz not null default now()
);

create table if not exists public.job_experiences (
  id              uuid primary key default gen_random_uuid(),
  profile_id      uuid not null references public.profiles(id) on delete cascade,
  title           text not null,
  company         text not null,
  location        text,
  employment_type text check (employment_type is null or employment_type in
                    ('full_time', 'part_time', 'shifts', 'temporary', 'freelance', 'internship')),
  start_date      date,
  end_date        date,
  is_current      boolean not null default false,
  description     text check (description is null or length(description) <= 1000),
  created_at      timestamptz not null default now()
);

create table if not exists public.job_educations (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles(id) on delete cascade,
  qualification text not null,
  institution   text not null,
  location      text,
  start_date    date,
  end_date      date,
  is_current    boolean not null default false,
  created_at    timestamptz not null default now()
);

-- The files are in the private `cvs` bucket (00052), `<profile id>/<file>`.
create table if not exists public.resumes (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  file_path   text not null unique,
  file_name   text not null,
  size_bytes  bigint,
  created_at  timestamptz not null default now(),
  check (split_part(file_path, '/', 1) = profile_id::text)
);

create index if not exists idx_job_experiences_profile on public.job_experiences (profile_id);
create index if not exists idx_job_educations_profile on public.job_educations (profile_id);
create index if not exists idx_resumes_profile on public.resumes (profile_id);

-- Whether the caller may see this person's job profile: themselves, the
-- panel, or a business they applied to.
create or replace function public.can_view_job_seeker(p_profile uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
       auth.uid() = p_profile
    or is_admin()
    or exists (
         select 1 from job_applications a
           join jobs j on j.id = a.job_id
          where a.profile_id = p_profile and owns_business(j.business_id))
  );
$$;

revoke all on function public.can_view_job_seeker(uuid) from public, anon;
grant execute on function public.can_view_job_seeker(uuid) to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['job_profiles', 'job_experiences', 'job_educations', 'resumes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_read', t);
    execute format(
      'create policy %I on public.%I for select using (public.can_view_job_seeker(profile_id))',
      t || '_read', t);
    execute format('drop policy if exists %I on public.%I', t || '_own', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (profile_id = auth.uid()) with check (profile_id = auth.uid())',
      t || '_own', t);
  end loop;
end $$;

create or replace function public.job_profiles_stamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists job_profiles_stamp on public.job_profiles;
create trigger job_profiles_stamp
  before insert or update on public.job_profiles
  for each row execute function public.job_profiles_stamp();

-- ─── 3. Applicants, for the business ───

create or replace function public.job_applicants(p_job uuid)
returns table (
  id               uuid,
  profile_id       uuid,
  full_name        text,
  email            text,
  phone            text,
  message          text,
  cv_path          text,
  status           text,
  shortlisted      boolean,
  created_at       timestamptz,
  avatar_url       text,
  location         text,
  headline         text,
  experience_years int
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  if not (is_admin() or exists (select 1 from jobs where jobs.id = p_job and owns_business(business_id))) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  return query
    select a.id, a.profile_id, a.full_name, a.email, a.phone, a.message, a.cv_path,
           a.status, a.shortlisted, a.created_at,
           p.avatar_url,
           coalesce(nullif(trim(jp.location), ''), n.name),
           (select e.title from job_experiences e
             where e.profile_id = a.profile_id
             order by e.is_current desc, e.start_date desc nulls last
             limit 1),
           jp.experience_years
      from job_applications a
      left join profiles p on p.id = a.profile_id
      left join neighborhoods n on n.id = p.neighborhood_id
      left join job_profiles jp on jp.profile_id = a.profile_id
     where a.job_id = p_job
     order by a.created_at desc;
end;
$$;

revoke all on function public.job_applicants(uuid) from public, anon;
grant execute on function public.job_applicants(uuid) to authenticated;

-- The applicant's own view: their applications with the job and business.
-- (RLS already lets them read the rows; this saves the app a join through
-- jobs that a closed job would hide.)
create or replace function public.my_job_applications()
returns table (id uuid, job_id uuid, status text, created_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select a.id, a.job_id, a.status, a.created_at
    from job_applications a
   where a.profile_id = auth.uid()
   order by a.created_at desc;
$$;

revoke all on function public.my_job_applications() from public, anon;
grant execute on function public.my_job_applications() to authenticated;

-- ─── 4. Messages ───

create table if not exists public.conversations (
  id                    uuid primary key default gen_random_uuid(),
  business_id           uuid not null references public.businesses(id) on delete cascade,
  profile_id            uuid not null references public.profiles(id) on delete cascade,
  job_id                uuid references public.jobs(id) on delete set null,
  last_message          text,
  last_message_at       timestamptz,
  business_last_read_at timestamptz,
  resident_last_read_at timestamptz,
  created_at            timestamptz not null default now(),
  unique (business_id, profile_id)
);

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid references public.profiles(id) on delete set null,
  body            text not null check (length(trim(body)) between 1 and 4000),
  created_at      timestamptz not null default now()
);

create index if not exists idx_messages_conversation on public.messages (conversation_id, created_at);
create index if not exists idx_conversations_profile on public.conversations (profile_id, last_message_at desc);
create index if not exists idx_conversations_business on public.conversations (business_id, last_message_at desc);

create or replace function public.is_conversation_member(p_conversation uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from conversations c
     where c.id = p_conversation
       and (c.profile_id = auth.uid() or owns_business(c.business_id)));
$$;

revoke all on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- Private between the two sides; the panel does not read them.
drop policy if exists conversations_members on public.conversations;
create policy conversations_members on public.conversations
  for select to authenticated
  using (profile_id = auth.uid() or public.owns_business(business_id));

drop policy if exists messages_members_read on public.messages;
create policy messages_members_read on public.messages
  for select to authenticated
  using (public.is_conversation_member(conversation_id));

drop policy if exists messages_members_send on public.messages;
create policy messages_members_send on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.is_conversation_member(conversation_id));

-- Opening a conversation. A business with someone who applied to one of its
-- jobs — never a cold message to any resident, whose profile is private; a
-- resident with any business that is shown in the app.
create or replace function public.start_conversation(
  p_business uuid,
  p_profile  uuid default null,
  p_job      uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile uuid;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'sign-in-required' using errcode = '42501';
  end if;

  if owns_business(p_business) and p_profile is not null and p_profile <> auth.uid() then
    if not exists (
      select 1 from job_applications a join jobs j on j.id = a.job_id
       where a.profile_id = p_profile and j.business_id = p_business
    ) and not exists (
      select 1 from conversations where business_id = p_business and profile_id = p_profile
    ) then
      raise exception 'not-an-applicant' using errcode = '42501';
    end if;
    v_profile := p_profile;
  else
    if not exists (select 1 from businesses where id = p_business and status = 'active') then
      raise exception 'business-not-found';
    end if;
    v_profile := auth.uid();
  end if;

  insert into conversations (business_id, profile_id, job_id)
  values (p_business, v_profile, p_job)
  on conflict (business_id, profile_id) do update
    set job_id = coalesce(excluded.job_id, conversations.job_id)
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.start_conversation(uuid, uuid, uuid) from public, anon;
grant execute on function public.start_conversation(uuid, uuid, uuid) to authenticated;

create or replace function public.mark_conversation_read(p_conversation uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update conversations c
     set resident_last_read_at = case when c.profile_id = auth.uid() then now() else c.resident_last_read_at end,
         business_last_read_at = case when owns_business(c.business_id) then now() else c.business_last_read_at end
   where c.id = p_conversation
     and (c.profile_id = auth.uid() or owns_business(c.business_id));
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public, anon;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- The list: each conversation from the caller's side — as a resident, or as
-- the owner of the business — with who is on the other side. A resident's
-- name and photo come from their private profile, so through here.
create or replace function public.my_conversations()
returns table (
  id              uuid,
  business_id     uuid,
  profile_id      uuid,
  as_business     boolean,
  other_name      text,
  other_avatar    text,
  job_title       text,
  last_message    text,
  last_message_at timestamptz,
  unread          int
)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.business_id, c.profile_id,
         owns_business(c.business_id) as as_business,
         case when owns_business(c.business_id) then p.full_name else b.name end,
         case when owns_business(c.business_id) then p.avatar_url else b.logo_url end,
         j.title,
         c.last_message, coalesce(c.last_message_at, c.created_at),
         (select count(*)::int from messages m
           where m.conversation_id = c.id
             and m.sender_id is distinct from auth.uid()
             and m.created_at > coalesce(
                   case when owns_business(c.business_id) then c.business_last_read_at
                        else c.resident_last_read_at end,
                   '-infinity'::timestamptz))
    from conversations c
    join businesses b on b.id = c.business_id
    left join profiles p on p.id = c.profile_id
    left join jobs j on j.id = c.job_id
   where c.profile_id = auth.uid() or owns_business(c.business_id)
   order by coalesce(c.last_message_at, c.created_at) desc;
$$;

revoke all on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;

create or replace function public.my_unread_messages()
returns int
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(unread), 0)::int from my_conversations();
$$;

revoke all on function public.my_unread_messages() from public, anon;
grant execute on function public.my_unread_messages() to authenticated;

-- A new message: the conversation's last line, the sender's read mark, and
-- a notification to the other side — one a minute per conversation at most,
-- so a quick exchange does not ring for every line.
create or replace function public.on_message_sent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  c          conversations;
  v_business text;
  v_logo     text;
  v_sender   text;
  v_to       jsonb;
  v_from_biz boolean;
begin
  select * into c from conversations where id = new.conversation_id;
  select name, logo_url into v_business, v_logo from businesses where id = c.business_id;
  v_from_biz := new.sender_id is distinct from c.profile_id;

  update conversations
     set last_message = snippet(new.body, 120),
         last_message_at = new.created_at,
         business_last_read_at = case when v_from_biz then new.created_at else business_last_read_at end,
         resident_last_read_at = case when v_from_biz then resident_last_read_at else new.created_at end
   where id = c.id;

  if v_from_biz then
    v_to := jsonb_build_array(c.profile_id);
    v_sender := v_business;
  else
    v_to := business_owner_ids(c.business_id);
    select full_name into v_sender from profiles where id = c.profile_id;
  end if;

  if exists (
    select 1 from push_campaigns
     where source_type = 'message' and source_id = c.id
       and audience_filter = jsonb_build_object('profile_ids', v_to)
       and created_at > now() - interval '1 minute'
  ) then
    return new;
  end if;

  perform notify_people(
    v_to,
    coalesce(v_sender, 'הודעה חדשה'), snippet(new.body, 120),
    coalesce(v_sender, 'New message'), snippet(new.body, 120),
    '/messages/' || c.id, 'message', c.id,
    case when v_from_biz then v_logo end
  );
  return new;
end;
$$;

revoke all on function public.on_message_sent() from public, anon, authenticated;

drop trigger if exists messages_after_insert on public.messages;
create trigger messages_after_insert
  after insert on public.messages
  for each row execute function public.on_message_sent();

-- Live on the open conversation.
do $$
begin
  if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime' and tablename = 'messages') then
    alter publication supabase_realtime add table public.messages;
  end if;
  if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime' and tablename = 'conversations') then
    alter publication supabase_realtime add table public.conversations;
  end if;
end $$;

-- ─── 5. Promotions ───

alter table public.businesses add column if not exists promoted_until timestamptz;
alter table public.offers add column if not exists promoted_until timestamptz;
create index if not exists idx_businesses_promoted on public.businesses (promoted_until desc nulls last);
create index if not exists idx_offers_promoted on public.offers (promoted_until desc nulls last);

create table if not exists public.promotion_requests (
  id           uuid primary key default gen_random_uuid(),
  entity_type  text not null check (entity_type in ('business', 'offer', 'job')),
  entity_id    uuid not null,
  business_id  uuid not null references public.businesses(id) on delete cascade,
  requested_by uuid references public.profiles(id) on delete set null,
  days         int not null check (days between 1 and 90),
  message      text check (message is null or length(message) <= 1000),
  status       text not null default 'pending'
               check (status in ('pending', 'approved', 'declined', 'cancelled')),
  reason       text,              -- why it was declined, shown to the business
  decided_by   uuid references public.profiles(id) on delete set null,
  decided_at   timestamptz,
  starts_at    timestamptz,
  ends_at      timestamptz,
  created_at   timestamptz not null default now()
);

create index if not exists idx_promotion_requests_status on public.promotion_requests (status, created_at desc);
create unique index if not exists promotion_requests_one_pending
  on public.promotion_requests (entity_type, entity_id) where status = 'pending';

alter table public.promotion_requests enable row level security;

drop policy if exists promotion_requests_read on public.promotion_requests;
create policy promotion_requests_read on public.promotion_requests
  for select to authenticated
  using (public.owns_business(business_id) or is_admin());

-- What it is and whose: the business itself, or its deal or job.
create or replace function public.promotion_target(p_type text, p_id uuid)
returns table (business_id uuid, title text, image_url text, link text)
language sql
stable
security definer
set search_path = public
as $$
  select b.id, b.name, coalesce(b.cover_url, b.logo_url), '/business/' || b.id
    from businesses b where p_type = 'business' and b.id = p_id
  union all
  select o.business_id, o.name, o.image_url, '/deal/' || o.id
    from offers o where p_type = 'offer' and o.id = p_id
  union all
  select j.business_id, j.title, coalesce(j.image_url, j.images[1]), '/jobs/' || j.id
    from jobs j where p_type = 'job' and j.id = p_id;
$$;

revoke all on function public.promotion_target(text, uuid) from public, anon;
grant execute on function public.promotion_target(text, uuid) to authenticated;

create or replace function public.request_promotion(
  p_type    text,
  p_id      uuid,
  p_days    int,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business uuid;
  v_id uuid;
begin
  select business_id into v_business from promotion_target(p_type, p_id);
  if v_business is null or not owns_business(v_business) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  if p_days is null or p_days not between 1 and 90 then
    raise exception 'days-invalid';
  end if;
  if exists (select 1 from promotion_requests
              where entity_type = p_type and entity_id = p_id and status = 'pending') then
    raise exception 'already-requested';
  end if;
  insert into promotion_requests (entity_type, entity_id, business_id, requested_by, days, message)
  values (p_type, p_id, v_business, auth.uid(), p_days,
          nullif(left(trim(coalesce(p_message, '')), 1000), ''))
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.request_promotion(text, uuid, int, text) from public, anon;
grant execute on function public.request_promotion(text, uuid, int, text) to authenticated;

-- The panel's decision. Approved, the promotion runs from now (or from the
-- end of one still running) for the days asked.
create or replace function public.admin_decide_promotion(
  p_request uuid,
  p_approve boolean,
  p_reason  text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r promotion_requests;
  v_current timestamptz;
  v_start timestamptz;
  v_end timestamptz;
begin
  if not is_admin() or not admin_may('businesses', 'edit') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  select * into r from promotion_requests where id = p_request for update;
  if r.id is null or r.status <> 'pending' then
    raise exception 'request is not pending';
  end if;

  if p_approve then
    v_current := case r.entity_type
      when 'business' then (select promoted_until from businesses where id = r.entity_id)
      when 'offer' then (select promoted_until from offers where id = r.entity_id)
      else (select promoted_until from jobs where id = r.entity_id)
    end;
    v_start := greatest(now(), coalesce(v_current, now()));
    v_end := v_start + make_interval(days => r.days);
    case r.entity_type
      when 'business' then update businesses set promoted_until = v_end where id = r.entity_id;
      when 'offer' then update offers set promoted_until = v_end where id = r.entity_id;
      else update jobs set promoted_until = v_end where id = r.entity_id;
    end case;
  end if;

  update promotion_requests
     set status = case when p_approve then 'approved' else 'declined' end,
         reason = case when p_approve then null else nullif(trim(p_reason), '') end,
         decided_by = auth.uid(),
         decided_at = now(),
         starts_at = v_start,
         ends_at = v_end
   where id = p_request;

  insert into audit_logs (admin_id, action, entity_type, entity_id, after_data)
  values (auth.uid(), 'update', 'promotion_requests', p_request,
          jsonb_build_object('approved', p_approve, 'ends_at', v_end));
end;
$$;

revoke all on function public.admin_decide_promotion(uuid, boolean, text) from public, anon;
grant execute on function public.admin_decide_promotion(uuid, boolean, text) to authenticated;

-- The panel ends a promotion early (reversible: it can approve another).
create or replace function public.admin_end_promotion(p_type text, p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin() or not admin_may('businesses', 'edit') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  case p_type
    when 'business' then update businesses set promoted_until = null where id = p_id;
    when 'offer' then update offers set promoted_until = null where id = p_id;
    when 'job' then update jobs set promoted_until = null where id = p_id;
  end case;
  update promotion_requests set ends_at = now()
   where entity_type = p_type and entity_id = p_id and status = 'approved' and ends_at > now();
end;
$$;

revoke all on function public.admin_end_promotion(text, uuid) from public, anon;
grant execute on function public.admin_end_promotion(text, uuid) to authenticated;

-- A promotion that has run out is cleared, so the lists can put the
-- promoted first with a plain `order by promoted_until desc nulls last`.
create or replace function public.clear_ended_promotions()
returns void
language sql
security definer
set search_path = public
as $$
  update businesses set promoted_until = null where promoted_until <= now();
  update offers set promoted_until = null where promoted_until <= now();
  update jobs set promoted_until = null where promoted_until <= now();
$$;

revoke all on function public.clear_ended_promotions() from public, anon, authenticated;

select cron.unschedule('clear-ended-promotions')
 where exists (select 1 from cron.job where jobname = 'clear-ended-promotions');
select cron.schedule('clear-ended-promotions', '*/10 * * * *',
  $job$ select public.clear_ended_promotions(); $job$);

-- An owner may not set promotion on their business or deal (00033, 00051's
-- guards, with the new column).
create or replace function businesses_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.is_verified := false;
    new.is_featured := false;
    new.is_sponsored := false;
    new.is_recommended := false;
    new.featured_start := null;
    new.featured_end := null;
    new.rating := 0;
    new.review_count := 0;
    new.approved_at := null;
    new.closed_at := null;
    new.promoted_until := null;
    return new;
  end if;

  if new.status is distinct from old.status
     or new.is_verified is distinct from old.is_verified
     or new.is_featured is distinct from old.is_featured
     or new.is_sponsored is distinct from old.is_sponsored
     or new.is_recommended is distinct from old.is_recommended
     or new.featured_start is distinct from old.featured_start
     or new.featured_end is distinct from old.featured_end
     or new.rating is distinct from old.rating
     or new.review_count is distinct from old.review_count
     or new.approved_at is distinct from old.approved_at
     or new.closed_at is distinct from old.closed_at
     or new.owner_id is distinct from old.owner_id
     or new.promoted_until is distinct from old.promoted_until then
    raise exception 'a business''s status, verification, promotion, rating and owner are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- ─── 6. Deals ───

alter table public.offers
  add column if not exists deal_type text,
  add column if not exists deal_value numeric(10, 2);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'offers_deal_type_check') then
    alter table public.offers add constraint offers_deal_type_check
      check (deal_type is null or deal_type in ('percentage', 'fixed', 'bogo', 'other'));
  end if;
end $$;

create or replace function public.offers_owner_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if is_admin() or current_user not in ('authenticated', 'anon') then
    return coalesce(new, old);
  end if;
  if tg_op = 'INSERT' then
    new.is_featured := false;
    new.points_required := 0;
    new.view_count := 0;
    new.claim_count := 0;
    new.redeem_count := 0;
    new.promoted_until := null;
    return new;
  end if;
  if tg_op = 'UPDATE' and (
       new.is_featured is distinct from old.is_featured
    or new.points_required is distinct from old.points_required
    or new.business_id is distinct from old.business_id
    or new.view_count is distinct from old.view_count
    or new.claim_count is distinct from old.claim_count
    or new.redeem_count is distinct from old.redeem_count
    or new.promoted_until is distinct from old.promoted_until) then
    raise exception 'featuring, promotion, points, the business and the counts of a deal are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- An owner deletes a deal nobody has claimed; one with claims is closed
-- instead, so residents' vouchers are never taken away. Asked through a
-- function: the owner cannot read other people's claims, and a check they
-- could not see would let every deal through.
create or replace function public.offer_has_claims(p_offer uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from offer_claims where offer_id = p_offer);
$$;

revoke all on function public.offer_has_claims(uuid) from public, anon;
grant execute on function public.offer_has_claims(uuid) to authenticated;

drop policy if exists offers_owner_delete on public.offers;
create policy offers_owner_delete on public.offers
  for delete to authenticated
  using (public.owns_business(business_id) and not public.offer_has_claims(id));

-- ─── 7. Notifications ───

-- A Jobs switch on each device, on unless turned off.
alter table public.push_devices
  add column if not exists notify_jobs boolean not null default true;

create or replace function public.push_matches(c public.push_campaigns, d public.push_devices)
returns boolean
language sql
immutable
as $$
  select case c.audience_type
    when 'all' then true
    when 'topic' then case c.audience_filter ->> 'topic'
      when 'news'       then d.notify_news
      when 'events'     then d.notify_events
      when 'businesses' then d.notify_businesses
      when 'deals'      then d.notify_deals
      when 'realestate' then d.notify_realestate
      when 'jobs'       then d.notify_jobs
      else false
    end
    when 'neighborhood' then d.notify_neighborhood
      and d.neighborhood_id::text = c.audience_filter ->> 'neighborhood_id'
    when 'profiles' then d.notify_replies and d.profile_id is not null
      and c.audience_filter -> 'profile_ids' ? d.profile_id::text
    when 'person' then d.profile_id is not null
      and c.audience_filter -> 'profile_ids' ? d.profile_id::text
    when 'all_but' then d.profile_id is null
      or not (c.audience_filter -> 'profile_ids' ? d.profile_id::text)
    when 'device' then d.id::text = c.audience_filter ->> 'device_id'
    else false
  end;
$$;

-- The app registers with the Jobs switch too. A version without it keeps
-- calling the old signature, which stays (Jobs left as it was).
create or replace function public.register_push_device(
  p_token           text,
  p_platform        text,
  p_locale          text,
  p_enabled         boolean,
  p_news            boolean,
  p_events          boolean,
  p_businesses      boolean,
  p_deals           boolean,
  p_realestate      boolean,
  p_neighborhood    boolean,
  p_neighborhood_id uuid,
  p_app_version     text,
  p_replies         boolean,
  p_jobs            boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform register_push_device(
    p_token, p_platform, p_locale, p_enabled, p_news, p_events, p_businesses,
    p_deals, p_realestate, p_neighborhood, p_neighborhood_id, p_app_version, p_replies);
  update push_devices set notify_jobs = coalesce(p_jobs, true) where token = p_token;
end;
$$;

grant execute on function public.register_push_device(
  text, text, text, boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, uuid, text, boolean, boolean
) to anon, authenticated;

-- Jobs: a new opening to everyone with Jobs on, once; a closed one to its
-- applicants and to those who saved it.
create or replace function public.on_job_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business text;
  v_logo     text;
  v_people   jsonb;
begin
  select name, logo_url into v_business, v_logo from businesses where id = new.business_id;

  if new.status = 'active'
     and (tg_op = 'INSERT' or old.status is distinct from 'active')
     and not exists (select 1 from push_campaigns where source_type = 'job' and source_id = new.id) then
    insert into push_campaigns (
      title, body, title_en, body_en, image_url, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'משרה חדשה', new.title || coalesce(' · ' || v_business, ''),
      'New job opening', new.title || coalesce(' · ' || v_business, ''),
      coalesce(new.image_url, new.images[1], v_logo), '/jobs/' || new.id,
      -- A minute's grace, in case it is closed again straight away.
      'scheduled', now() + interval '1 minute', 'topic', jsonb_build_object('topic', 'jobs'),
      'job', new.id
    );
  end if;

  -- Taken down within the minute: the announcement does not go.
  if tg_op = 'UPDATE' and new.status <> 'active' and old.status = 'active' then
    update push_campaigns set status = 'cancelled'
     where source_type = 'job' and source_id = new.id and status = 'scheduled'
       and audience_type = 'topic';
  end if;

  if tg_op = 'UPDATE' and new.status in ('closed', 'expired') and old.status = 'active' then
    select jsonb_agg(distinct x) into v_people from (
      select a.profile_id as x from job_applications a
       where a.job_id = new.id and a.profile_id is not null
      union
      select f.profile_id from favorites f
       where f.entity_type = 'job' and f.entity_id = new.id
    ) s;
    perform notify_people(
      v_people,
      'המשרה נסגרה', new.title || coalesce(' · ' || v_business, '') || ' — המשרה כבר לא מקבלת מועמדויות.',
      'Job closed', new.title || coalesce(' · ' || v_business, '') || ' is no longer taking applications.',
      '/jobs/' || new.id, 'job_closed', new.id, v_logo
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_job_change() from public, anon, authenticated;

drop trigger if exists jobs_after_change on public.jobs;
create trigger jobs_after_change
  after insert or update of status on public.jobs
  for each row execute function public.on_job_change();

-- Applications: the business hears of a new one; the applicant of where it
-- stands.
create or replace function public.on_application_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  j          jobs;
  v_business text;
  v_logo     text;
begin
  select * into j from jobs where id = new.job_id;
  select name, logo_url into v_business, v_logo from businesses where id = j.business_id;

  if tg_op = 'INSERT' then
    perform notify_people(
      business_owner_ids(j.business_id),
      'מועמדות חדשה', new.full_name || ' הגיש/ה מועמדות ל' || j.title,
      'New application', new.full_name || ' applied for ' || j.title,
      '/business-jobs/' || j.id || '?tab=applicants', 'application', new.id
    );
    return new;
  end if;

  if new.status is distinct from old.status and new.profile_id is not null then
    case new.status
      when 'interview' then
        perform notify_people(jsonb_build_array(new.profile_id),
          'הוזמנת לראיון', j.title || coalesce(' · ' || v_business, ''),
          'Invited to an interview', j.title || coalesce(' · ' || v_business, ''),
          '/jobs/' || j.id, 'application_status', new.id, v_logo);
      when 'accepted' then
        perform notify_people(jsonb_build_array(new.profile_id),
          'התקבלת למשרה', j.title || coalesce(' · ' || v_business, ''),
          'You got the job', j.title || coalesce(' · ' || v_business, ''),
          '/jobs/' || j.id, 'application_status', new.id, v_logo);
      when 'unsuitable' then
        perform notify_people(jsonb_build_array(new.profile_id),
          'עדכון על המועמדות שלך', j.title || coalesce(' · ' || v_business, '') || ' — הפעם לא נבחרת. בהצלחה בהמשך!',
          'Your application', j.title || coalesce(' · ' || v_business, '') || ' — not selected this time. Good luck!',
          '/jobs/' || j.id, 'application_status', new.id, v_logo);
      else
        null;
    end case;
  end if;
  return new;
end;
$$;

revoke all on function public.on_application_change() from public, anon, authenticated;

drop trigger if exists job_applications_after_change on public.job_applications;
create trigger job_applications_after_change
  after insert or update of status on public.job_applications
  for each row execute function public.on_application_change();

-- Promotions: the team hears of a request; the business of the decision.
create or replace function public.on_promotion_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  t record;
  v_kind_he text := case new.entity_type when 'business' then 'העסק' when 'offer' then 'המבצע' else 'המשרה' end;
  v_kind_en text := case new.entity_type when 'business' then 'business' when 'offer' then 'deal' else 'job' end;
begin
  select * into t from promotion_target(new.entity_type, new.entity_id);

  if tg_op = 'INSERT' then
    perform notify_people(
      moderator_profile_ids('businesses'),
      'בקשת קידום חדשה', coalesce(t.title, '') || ' · ' || new.days || ' ימים — בניהול ← קידומים.',
      'New promotion request', coalesce(t.title, '') || ' · ' || new.days || ' days — Panel → Promotions.',
      null, 'promotion_request', new.id
    );
    return new;
  end if;

  if new.status is distinct from old.status and new.status in ('approved', 'declined') then
    if new.status = 'approved' then
      perform notify_people(
        business_owner_ids(new.business_id),
        'הקידום אושר', coalesce(t.title, '') || ' — ' || v_kind_he || ' יוצג בראש הרשימה למשך ' || new.days || ' ימים.',
        'Promotion approved', coalesce(t.title, '') || ' — your ' || v_kind_en || ' is at the top of the list for ' || new.days || ' days.',
        t.link, 'promotion_decision', new.id, t.image_url
      );
    else
      perform notify_people(
        business_owner_ids(new.business_id),
        'בקשת הקידום נדחתה', coalesce(t.title, '') || coalesce(' — ' || new.reason, ''),
        'Promotion declined', coalesce(t.title, '') || coalesce(' — ' || new.reason, ''),
        t.link, 'promotion_decision', new.id, t.image_url
      );
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.on_promotion_change() from public, anon, authenticated;

drop trigger if exists promotion_requests_after_change on public.promotion_requests;
create trigger promotion_requests_after_change
  after insert or update of status on public.promotion_requests
  for each row execute function public.on_promotion_change();

-- Businesses with an owner: the team when one waits for approval, the owner
-- when it is approved.
create or replace function public.on_owned_business_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.owner_id is null then
    return new;
  end if;
  if new.status = 'pending' and (tg_op = 'INSERT' or old.status is distinct from 'pending') then
    perform notify_people(
      moderator_profile_ids('businesses', new.owner_id),
      'עסק חדש ממתין לאישור', new.name || ' — בניהול ← עסקים ← ממתין.',
      'New business awaiting approval', new.name || ' — Panel → Businesses → Pending.',
      null, 'business_pending', new.id
    );
  elsif tg_op = 'UPDATE' and new.status = 'active' and old.status = 'pending' then
    perform notify_people(
      jsonb_build_array(new.owner_id),
      'העסק שלך אושר', new.name || ' מוצג עכשיו באפליקציה.',
      'Your business is approved', new.name || ' is now shown in the app.',
      '/business/' || new.id, 'business_approved', new.id, new.logo_url
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_owned_business_change() from public, anon, authenticated;

drop trigger if exists businesses_after_owned_change on public.businesses;
create trigger businesses_after_owned_change
  after insert or update of status on public.businesses
  for each row execute function public.on_owned_business_change();

-- A claim on a deal: its business's owner.
create or replace function public.on_offer_claimed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  o offers;
begin
  select * into o from offers where id = new.offer_id;
  perform notify_people(
    business_owner_ids(o.business_id),
    'מימוש חדש למבצע', o.name,
    'New deal claim', o.name,
    '/business-deals', 'offer_claim', new.id, o.image_url
  );
  return new;
end;
$$;

revoke all on function public.on_offer_claimed() from public, anon, authenticated;

drop trigger if exists offer_claims_notify_owner on public.offer_claims;
create trigger offer_claims_notify_owner
  after insert on public.offer_claims
  for each row execute function public.on_offer_claimed();

-- An approved review: its business's owner.
create or replace function public.on_review_for_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved'
     and (tg_op = 'INSERT' or old.status is distinct from 'approved') then
    perform notify_people(
      business_owner_ids(new.business_id),
      'ביקורת חדשה על העסק', repeat('★', greatest(least(new.rating, 5), 0)::int) || ' ' || snippet(coalesce(new.body, new.title, ''), 100),
      'New review of your business', repeat('★', greatest(least(new.rating, 5), 0)::int) || ' ' || snippet(coalesce(new.body, new.title, ''), 100),
      '/business/' || new.business_id || '?review=' || new.id, 'owner_review', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_review_for_owner() from public, anon, authenticated;

drop trigger if exists reviews_notify_owner on public.reviews;
create trigger reviews_notify_owner
  after insert or update of status on public.reviews
  for each row execute function public.on_review_for_owner();

-- A business owner's new deal is announced to everyone with Deals on, like
-- the panel's (00060 held it back; Harshit, 7 Oct). The owner cannot switch
-- the announcement off or point it elsewhere.
create or replace function public.queue_more_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  kind      text := tg_argv[0];
  resident  boolean := auth.uid() is not null and not is_admin();
  r         jsonb;
  live      boolean;
  pending   push_campaigns;
  v_title   text;
  v_title_en text;
  v_body    text;
  v_body_en text;
  v_image   text;
  v_link    text;
  v_type    text := 'topic';
  v_filter  jsonb;
  v_when    timestamptz := now() + interval '5 minutes';
  v_id      uuid;
  v_price   text;
  v_business text;
begin
  if resident then
    new.push_campaign_id := case when tg_op = 'INSERT' then null else old.push_campaign_id end;
    if kind = 'offer' then
      new.notify_on_publish := case when tg_op = 'INSERT' then true else old.notify_on_publish end;
    end if;
  end if;
  r := to_jsonb(new);

  live := case kind
    when 'offer' then r ->> 'status' = 'active'
      and (r ->> 'end_at' is null or (r ->> 'end_at')::timestamptz > now())
    when 'listing' then r ->> 'status' = 'active'
    else (r ->> 'is_active')::boolean
      and (r ->> 'end_at')::timestamptz > now()
      and r ->> 'winner_id' is null
  end;

  case kind
    when 'offer' then
      select name into v_business from businesses where id = (r ->> 'business_id')::uuid;
      v_title := 'מבצע חדש';  v_title_en := 'New deal';
      v_body := (r ->> 'name') || coalesce(' · ' || v_business, '');  v_body_en := v_body;
      v_image := r ->> 'image_url';
      v_link := '/deal/' || new.id;
      v_filter := jsonb_build_object('topic', 'deals');
    when 'listing' then
      v_price := coalesce(r ->> 'price', r ->> 'price_per_month');
      v_title := case when r ->> 'kind' = 'rent' then 'דירה חדשה להשכרה' else 'דירה חדשה למכירה' end;
      v_title_en := case when r ->> 'kind' = 'rent' then 'New for rent' else 'New for sale' end;
      v_body := (r ->> 'title') || case when v_price is null then '' else ' · ₪' || to_char(v_price::numeric, 'FM999,999,999') end;
      v_body_en := v_body;
      v_image := r ->> 'cover_url';
      v_link := '/listing/' || new.id;
      v_filter := jsonb_build_object('topic', 'realestate');
    else
      v_title := 'תחרות צעדים חדשה';  v_title_en := 'New step competition';
      v_body := (r ->> 'name') || coalesce(' · פרס: ' || nullif(trim(r ->> 'prize'), ''), '');
      v_body_en := (r ->> 'name') || coalesce(' · Prize: ' || nullif(trim(coalesce(r ->> 'prize_en', r ->> 'prize')), ''), '');
      v_image := r ->> 'image_url';
      v_link := '/steps';
      v_type := 'all';
      v_filter := '{}'::jsonb;
      v_when := greatest(v_when, (r ->> 'start_at')::timestamptz);
  end case;

  if new.push_campaign_id is not null then
    select * into pending from push_campaigns
     where id = new.push_campaign_id and status = 'scheduled';
  end if;

  if pending.id is not null then
    if not live or not new.notify_on_publish then
      update push_campaigns set status = 'cancelled' where id = pending.id;
      new.push_campaign_id := null;
    else
      update push_campaigns
         set title = v_title, body = v_body, title_en = v_title_en,
             body_en = v_body_en, image_url = v_image, scheduled_at = v_when
       where id = pending.id;
    end if;
    return new;
  end if;

  if new.push_campaign_id is not null or not live or not new.notify_on_publish then
    return new;
  end if;

  -- Announced once: a deal closed and opened again is not news twice.
  if exists (select 1 from push_campaigns
              where source_type = kind and source_id = new.id and status in ('sent', 'sending')) then
    return new;
  end if;

  insert into push_campaigns (
    title, body, title_en, body_en, image_url, deep_link,
    status, scheduled_at, audience_type, audience_filter,
    source_type, source_id
  ) values (
    v_title, v_body, v_title_en, v_body_en, v_image, v_link,
    'scheduled', v_when, v_type, v_filter, kind, new.id
  )
  returning id into v_id;

  new.push_campaign_id := v_id;
  return new;
end;
$$;

revoke all on function public.queue_more_push() from public, anon, authenticated;
