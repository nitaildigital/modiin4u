-- ============================================================
-- Modiin4u — Migration 00071
-- The client's QA round of 8 Oct: business hours, article comments,
-- neighbourhood ratings, residents' photographs
--
--   1. Business hours as the old site wrote them. No business had hours:
--      the old site kept them as free text ("א-ה 8:00-23:00 …", holiday
--      notes and all) and they were never imported. Read into day-by-day
--      rows they would be guesses, so the text itself is kept and shown, and
--      the panel edits it. Structured hours (business_hours) still win where
--      a business has them.
--   2. Comments on articles. `comments` already carries any entity; an
--      article's comment goes live at once like a review reply, unless the
--      panel's "replies need approval" is on. The team hears of one that
--      waits; a comment's writer hears of a reply to it.
--   3. A resident's star rating of a neighbourhood: one per person, changed
--      at will; the page shows the average and the count.
--   4. Photographs residents add to a business page. They wait for the
--      panel: approved, the photo joins the business's gallery and its
--      sender is told; declined, the sender is told why. Nothing is deleted
--      — a declined photo stays on record and can still be approved.
--
-- Needs 00069 (notify_people). Safe to run more than once.
-- ============================================================

-- ─── 1. Hours as text ───

alter table public.businesses add column if not exists hours_text text;

comment on column public.businesses.hours_text is
  'Opening hours as written (from the old site, or the panel). Shown when '
  'the business has no rows in business_hours.';

-- ─── 2. Comments on articles ───

-- 00063's guard, with articles beside review replies.
create or replace function public.comments_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    -- An administrator's comment from the app comes in at the column's
    -- default, 'pending', which left the team's own replies waiting for the
    -- team. The panel sets a status itself when it means another.
    if tg_op = 'INSERT' and is_admin() and new.status = 'pending'
       and new.entity_type in ('review', 'article') then
      new.status := 'approved';
    end if;
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.entity_type in ('review', 'article') and not coalesce(
      (select value = 'true'::jsonb from app_settings
        where key = 'replies_need_approval'),
      false) then
      new.status := 'approved';
    else
      new.status := 'pending';
    end if;
    new.report_count := 0;
    return new;
  end if;

  if new.status is distinct from old.status
     or new.report_count is distinct from old.report_count then
    raise exception 'a comment''s status and report count are set by moderation'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- A comment can only be on an article that is published.
create or replace function public.comments_article_check()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.entity_type = 'article' and tg_op = 'INSERT' and not exists (
    select 1 from articles where id = new.entity_id and status = 'published'
  ) and not is_admin() then
    raise exception 'article-not-found';
  end if;
  return new;
end;
$$;

revoke all on function public.comments_article_check() from public, anon, authenticated;

drop trigger if exists comments_article_check on public.comments;
create trigger comments_article_check
  before insert on public.comments
  for each row execute function public.comments_article_check();

-- Who hears of an article comment: the team when it waits, the writer of
-- the comment it answers when it is live (or approved later).
create or replace function public.on_article_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_title  text;
  v_parent comments;
  v_text   text;
begin
  if new.entity_type <> 'article' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = new.status then
    return new;
  end if;

  select title into v_title from articles where id = new.entity_id;
  v_text := coalesce(nullif(trim(new.author_name), ''), 'תושב/ת') || ': ' || snippet(new.body, 120);

  if new.status = 'pending' then
    perform notify_people(
      moderator_profile_ids('moderation', new.author_id),
      'תגובה חדשה לכתבה ממתינה לאישור', coalesce(v_title || ' · ', '') || v_text || ' — בניהול ← תגובות.',
      'New article comment awaiting approval', coalesce(v_title || ' · ', '') || v_text || ' — Panel → Comments.',
      null, 'moderation', new.id
    );
    return new;
  end if;

  if new.status = 'approved' and new.parent_id is not null then
    select * into v_parent from comments where id = new.parent_id;
    if v_parent.author_id is not null and v_parent.author_id <> new.author_id then
      perform notify_people(
        jsonb_build_array(v_parent.author_id),
        'תגובה חדשה לתגובה שלך', v_text,
        'New reply to your comment', v_text,
        '/article/' || new.entity_id || '?comment=' || new.id, 'article_reply', new.id
      );
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.on_article_comment() from public, anon, authenticated;

drop trigger if exists comments_after_article on public.comments;
create trigger comments_after_article
  after insert or update of status on public.comments
  for each row execute function public.on_article_comment();

-- ─── 3. Neighbourhood ratings ───

create table if not exists public.neighborhood_ratings (
  neighborhood_id uuid not null references public.neighborhoods(id) on delete cascade,
  profile_id      uuid not null references public.profiles(id) on delete cascade,
  rating          smallint not null check (rating between 1 and 5),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  primary key (neighborhood_id, profile_id)
);

alter table public.neighborhood_ratings enable row level security;

-- Each person's own rating; the average comes through the function below,
-- so who rated what is not public.
drop policy if exists neighborhood_ratings_own on public.neighborhood_ratings;
create policy neighborhood_ratings_own on public.neighborhood_ratings
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid() and not is_banned_user());

drop policy if exists neighborhood_ratings_admin_read on public.neighborhood_ratings;
create policy neighborhood_ratings_admin_read on public.neighborhood_ratings
  for select using (is_admin());

create or replace function public.neighborhood_ratings_stamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists neighborhood_ratings_stamp on public.neighborhood_ratings;
create trigger neighborhood_ratings_stamp
  before insert or update on public.neighborhood_ratings
  for each row execute function public.neighborhood_ratings_stamp();

-- Average and count for one neighbourhood — or every one, for lists.
create or replace function public.neighborhood_rating_summary(p_neighborhood uuid default null)
returns table (neighborhood_id uuid, average numeric, ratings bigint)
language sql
stable
security definer
set search_path = public
as $$
  select r.neighborhood_id, round(avg(r.rating)::numeric, 1), count(*)
    from neighborhood_ratings r
   where p_neighborhood is null or r.neighborhood_id = p_neighborhood
   group by r.neighborhood_id;
$$;

revoke all on function public.neighborhood_rating_summary(uuid) from public;
grant execute on function public.neighborhood_rating_summary(uuid) to anon, authenticated;

-- ─── 4. Residents' photographs of a business ───

create table if not exists public.photo_submissions (
  id           uuid primary key default gen_random_uuid(),
  entity_type  text not null default 'business' check (entity_type in ('business')),
  entity_id    uuid not null,
  profile_id   uuid references public.profiles(id) on delete cascade,
  file_path    text not null,
  url          text not null,
  caption      text check (caption is null or length(caption) <= 300),
  status       text not null default 'pending'
               check (status in ('pending', 'approved', 'declined')),
  reason       text,
  media_id     uuid references public.media(id) on delete set null,
  decided_by   uuid references public.profiles(id) on delete set null,
  decided_at   timestamptz,
  created_at   timestamptz not null default now(),
  check (split_part(file_path, '/', 1) = 'submissions'
         and split_part(file_path, '/', 2) = profile_id::text)
);

create index if not exists idx_photo_submissions_status on public.photo_submissions (status, created_at desc);
create index if not exists idx_photo_submissions_entity on public.photo_submissions (entity_type, entity_id);

alter table public.photo_submissions enable row level security;

drop policy if exists photo_submissions_read on public.photo_submissions;
create policy photo_submissions_read on public.photo_submissions
  for select to authenticated
  using (profile_id = auth.uid() or is_admin());

-- A resident sends their own, as pending, to a business that is shown.
drop policy if exists photo_submissions_send on public.photo_submissions;
create policy photo_submissions_send on public.photo_submissions
  for insert to authenticated
  with check (
    profile_id = auth.uid()
    and status = 'pending' and media_id is null and decided_by is null
    and not is_banned_user()
    and exists (select 1 from businesses b where b.id = entity_id and b.status = 'active')
  );

-- Uploads go to `submissions/<your id>/` in the public media bucket.
drop policy if exists "media_submission_insert" on storage.objects;
create policy "media_submission_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'submissions'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

-- The panel's decision. Approved: a media row and a place at the end of the
-- business's gallery, where the site and the app already read it.
create or replace function public.admin_decide_photo(
  p_submission uuid,
  p_approve    boolean,
  p_reason     text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  s photo_submissions;
  v_media uuid;
  v_order int;
begin
  if not is_admin() or not admin_may('businesses', 'edit') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  select * into s from photo_submissions where id = p_submission for update;
  if s.id is null then
    raise exception 'not found';
  end if;

  if p_approve then
    if s.media_id is null then
      insert into media (file_name, file_path, url, mime_type, folder, uploaded_by)
      values (split_part(s.file_path, '/', 3), s.file_path, s.url,
              case when s.file_path ilike '%.png' then 'image/png'
                   when s.file_path ilike '%.webp' then 'image/webp'
                   else 'image/jpeg' end,
              'submissions', s.profile_id)
      returning id into v_media;
    else
      v_media := s.media_id;
    end if;
    if not exists (select 1 from entity_media
                    where entity_type = 'business' and entity_id = s.entity_id
                      and role = 'gallery' and media_id = v_media) then
      select coalesce(max(sort_order) + 1, 0) into v_order
        from entity_media
       where entity_type = 'business' and entity_id = s.entity_id and role = 'gallery';
      insert into entity_media (media_id, entity_type, entity_id, role, sort_order)
      values (v_media, 'business', s.entity_id, 'gallery', v_order);
    end if;
    update photo_submissions
       set status = 'approved', reason = null, media_id = v_media,
           decided_by = auth.uid(), decided_at = now()
     where id = s.id;
  else
    -- Declined after approval: out of the gallery, the file kept.
    if s.media_id is not null then
      delete from entity_media
       where entity_type = 'business' and entity_id = s.entity_id
         and role = 'gallery' and media_id = s.media_id;
    end if;
    update photo_submissions
       set status = 'declined', reason = nullif(trim(p_reason), ''),
           decided_by = auth.uid(), decided_at = now()
     where id = s.id;
  end if;

  insert into audit_logs (admin_id, action, entity_type, entity_id, after_data)
  values (auth.uid(), 'update', 'photo_submissions', s.id,
          jsonb_build_object('approved', p_approve));
end;
$$;

revoke all on function public.admin_decide_photo(uuid, boolean, text) from public, anon;
grant execute on function public.admin_decide_photo(uuid, boolean, text) to authenticated;

-- The team hears of a photo waiting; its sender of the decision.
create or replace function public.on_photo_submission()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business text;
begin
  select name into v_business from businesses where id = new.entity_id;
  if tg_op = 'INSERT' then
    perform notify_people(
      moderator_profile_ids('businesses', new.profile_id),
      'תמונה חדשה ממתינה לאישור', coalesce(v_business, '') || ' — בניהול ← תמונות תושבים.',
      'New photo awaiting approval', coalesce(v_business, '') || ' — Panel → Resident photos.',
      null, 'photo_submission', new.id, new.url
    );
  elsif new.status is distinct from old.status and new.status = 'approved' then
    perform notify_people(
      jsonb_build_array(new.profile_id),
      'התמונה שלך פורסמה', coalesce(v_business, ''),
      'Your photo is published', coalesce(v_business, ''),
      '/business/' || new.entity_id, 'photo_decision', new.id, new.url
    );
  elsif new.status is distinct from old.status and new.status = 'declined' then
    perform notify_people(
      jsonb_build_array(new.profile_id),
      'התמונה שלך לא אושרה', coalesce(v_business, '') || coalesce(' — ' || new.reason, ''),
      'Your photo was not approved', coalesce(v_business, '') || coalesce(' — ' || new.reason, ''),
      '/business/' || new.entity_id, 'photo_decision', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_photo_submission() from public, anon, authenticated;

drop trigger if exists photo_submissions_notify on public.photo_submissions;
create trigger photo_submissions_notify
  after insert or update of status on public.photo_submissions
  for each row execute function public.on_photo_submission();
