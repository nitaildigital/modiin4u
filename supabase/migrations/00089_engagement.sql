-- ============================================================
-- Modiin4u — Migration 00089
-- Likes, "helpful" on reviews, owner replies, a review taken back
--
-- The client (24 Nov) wants residents drawn into commenting and reviewing
-- "like Facebook or Instagram" and approved: likes on articles, businesses,
-- comments and reviews; "helpful" on reviews; official replies from the
-- business's owner with a badge; editing or withdrawing one's own review.
-- The ♥ stays what it is — saving to Favourites — and a like is a 👍 beside
-- it (Harshit, 25 Nov).
--
--   * `reactions` — one row per person per thing they liked, or per review
--     they found helpful. Only something the public can see can be liked:
--     a published article, an active business, an approved comment or
--     review. A blocked account cannot. Residents write and remove their
--     own rows; everybody reads the counts through `reaction_counts`, never
--     who reacted.
--   * `reaction_counts` — the counts for a list of ids in one call, so a
--     page asks once for all its reviews rather than once per review.
--   * `reply_to_review` — the business's owner (or an admin) answers a
--     review in `admin_response`, the column the panel's reply has always
--     written; empty text takes the answer away.
--   * `withdraw_my_review` — its author takes a review back. It is hidden,
--     not deleted (removal is reversible — the client's rule), so it sits in
--     the panel's trash; `withdrawn_at` says the author did it, and frees
--     them to write a new one.
--
-- Editing one's own review needs nothing new: row security already lets an
-- author update it, and the guard (00075/00076) sends it back to the queue.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Reactions ───

create table if not exists public.reactions (
  entity_type text not null check (entity_type in ('article', 'business', 'comment', 'review')),
  entity_id   uuid not null,
  kind        text not null check (kind in ('like', 'helpful')),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (entity_type, entity_id, kind, profile_id),
  -- "Helpful" is a review's alone.
  constraint reactions_helpful_on_reviews check (kind = 'like' or entity_type = 'review')
);

comment on table public.reactions is
  'Likes (articles, businesses, comments, reviews) and "helpful" (reviews), one per person per item (00089).';

-- The thing reacted to must be one the public can see.
create or replace function public.reactions_check_target()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  ok boolean;
begin
  ok := case new.entity_type
    when 'article'  then exists (select 1 from articles   where id = new.entity_id and status = 'published')
    when 'business' then exists (select 1 from businesses where id = new.entity_id and status = 'active')
    when 'comment'  then exists (select 1 from comments   where id = new.entity_id and status = 'approved')
    when 'review'   then exists (select 1 from reviews    where id = new.entity_id and status = 'approved')
    else false
  end;
  if not ok then
    raise exception 'only something published can be liked' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function public.reactions_check_target() from public, anon, authenticated;

drop trigger if exists reactions_check_target on public.reactions;
create trigger reactions_check_target
  before insert on public.reactions
  for each row execute function public.reactions_check_target();

alter table public.reactions enable row level security;

drop policy if exists reactions_read_own on public.reactions;
create policy reactions_read_own on public.reactions
  for select using (profile_id = (select auth.uid()));

drop policy if exists reactions_insert_own on public.reactions;
create policy reactions_insert_own on public.reactions
  for insert with check (profile_id = (select auth.uid()) and not (select is_banned_user()));

drop policy if exists reactions_delete_own on public.reactions;
create policy reactions_delete_own on public.reactions
  for delete using (profile_id = (select auth.uid()));

-- Since 30 Oct a new table has no API access until it is granted.
grant select, insert, delete on public.reactions to authenticated;
grant all on public.reactions to service_role;

-- The counts, for a page's worth of ids at once. Who reacted is not given.
create or replace function public.reaction_counts(p_entity_type text, p_ids uuid[])
returns table (entity_id uuid, likes bigint, helpful bigint)
language sql
security definer
set search_path = public
stable
as $$
  select r.entity_id,
         count(*) filter (where r.kind = 'like'),
         count(*) filter (where r.kind = 'helpful')
    from reactions r
   where r.entity_type = p_entity_type
     and r.entity_id = any (p_ids[1:500])
   group by r.entity_id;
$$;

revoke all on function public.reaction_counts(text, uuid[]) from public;
grant execute on function public.reaction_counts(text, uuid[]) to anon, authenticated;

-- ─── 2. The owner's reply ───

create or replace function public.reply_to_review(p_review uuid, p_text text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  r record;
  answer text := nullif(btrim(coalesce(p_text, '')), '');
begin
  if uid is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  select rv.id, rv.status, b.owner_id into r
    from reviews rv join businesses b on b.id = rv.business_id
   where rv.id = p_review;
  if r.id is null then
    raise exception 'no such review' using errcode = 'P0002';
  end if;
  if not (r.owner_id = uid or is_admin()) or is_banned_user() then
    raise exception 'only the business''s owner can answer its reviews' using errcode = '42501';
  end if;
  if r.status <> 'approved' then
    raise exception 'only a published review can be answered' using errcode = '42501';
  end if;
  if answer is not null and char_length(answer) > 2000 then
    raise exception 'an answer is at most 2000 characters' using errcode = '22001';
  end if;

  update reviews
     set admin_response = answer,
         responded_by = case when answer is null then null else uid end,
         responded_at = case when answer is null then null else now() end
   where id = p_review;
end;
$$;

revoke all on function public.reply_to_review(uuid, text) from public, anon;
grant execute on function public.reply_to_review(uuid, text) to authenticated;

-- ─── 3. Taking one's own review back ───

alter table public.reviews
  add column if not exists withdrawn_at timestamptz;

comment on column public.reviews.withdrawn_at is
  'Set when the author took the review back (00089): hidden, in the panel''s trash, and no longer counted as their review of the business.';

create or replace function public.withdraw_my_review(p_review uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  update reviews
     set status = 'hidden', withdrawn_at = now()
   where id = p_review and author_id = uid and withdrawn_at is null;
  if not found then
    raise exception 'not your review' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.withdraw_my_review(uuid) from public, anon;
grant execute on function public.withdraw_my_review(uuid) to authenticated;

-- Only the function above sets `withdrawn_at`: a resident writing it
-- directly could free themselves to review the same business twice. And a
-- review the panel restores from the trash is no longer withdrawn.
create or replace function public.reviews_guard_withdrawn()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if is_resident_write() then new.withdrawn_at := null; end if;
    return new;
  end if;
  if is_resident_write() and new.withdrawn_at is distinct from old.withdrawn_at then
    raise exception 'a review is taken back with withdraw_my_review' using errcode = '42501';
  end if;
  if new.status <> 'hidden' then
    new.withdrawn_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists reviews_guard_withdrawn on public.reviews;
create trigger reviews_guard_withdrawn
  before insert or update on public.reviews
  for each row execute function public.reviews_guard_withdrawn();
