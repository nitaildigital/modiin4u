-- ============================================================
-- Modiin4u — Migration 00080
-- Report and block in a conversation
--
-- Apple's App Review (guideline 1.2) asks an app where people write to one
-- another for a way to report what they receive and to block whoever sends
-- it; Harshit, 12 Oct: "add that report in chats also and add block also".
--
--   * Report: a conversation is reported like a review or a business — a row
--     in `reports` (entity_type 'conversation'), one per person, which the
--     panel's Reports lists and its Messages section reads.
--   * Block: either side of a conversation may block it. While it is
--     blocked nobody can write in it — the other side cannot reach the one
--     who blocked, and the one who blocked does not write to someone they
--     shut out. Nothing is deleted; the one who blocked can unblock.
--
-- my_conversations() (00074) and admin_conversations() (00078) return the
-- block too, so their return types change: both are dropped and made again.
--
-- Needs 00069, 00074, 00078. Safe to run more than once.
-- ============================================================

alter table public.conversations
  add column if not exists blocked_by_business boolean not null default false,
  add column if not exists blocked_by_resident boolean not null default false;

create or replace function public.conversation_blocked(p_conversation uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select c.blocked_by_business or c.blocked_by_resident
                     from conversations c where c.id = p_conversation), false);
$$;

revoke all on function public.conversation_blocked(uuid) from public, anon;
grant execute on function public.conversation_blocked(uuid) to authenticated;

-- 00069's rule for sending, and not into a blocked conversation.
drop policy if exists messages_members_send on public.messages;
create policy messages_members_send on public.messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_member(conversation_id)
    and not public.conversation_blocked(conversation_id)
  );

-- Blocks or unblocks from the caller's side: the resident's, or the
-- business's for its owner.
create or replace function public.set_conversation_blocked(p_conversation uuid, p_blocked boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update conversations c
     set blocked_by_resident = case when c.profile_id = auth.uid() then p_blocked else c.blocked_by_resident end,
         blocked_by_business = case when c.profile_id is distinct from auth.uid() and owns_business(c.business_id)
                                    then p_blocked else c.blocked_by_business end
   where c.id = p_conversation
     and (c.profile_id = auth.uid() or owns_business(c.business_id));
  if not found then
    raise exception 'not-a-member' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.set_conversation_blocked(uuid, boolean) from public, anon;
grant execute on function public.set_conversation_blocked(uuid, boolean) to authenticated;

-- ─── The list, with the block from each side ───

drop function if exists public.my_conversations();
create function public.my_conversations()
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
  unread          int,
  blocked_by_me   boolean,
  blocked_by_them boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with mine as (
    -- As the resident.
    select c.*, false as as_business
      from conversations c
     where c.profile_id = auth.uid()
    union all
    -- As the owner of the business — a conversation with one's own
    -- business as the resident is already above.
    select c.*, true as as_business
      from conversations c
     where c.business_id in (select b.id from businesses b where b.owner_id = auth.uid())
       and c.profile_id is distinct from auth.uid()
  )
  select c.id, c.business_id, c.profile_id,
         c.as_business,
         case when c.as_business then p.full_name else b.name end,
         case when c.as_business then p.avatar_url else b.logo_url end,
         j.title,
         c.last_message, coalesce(c.last_message_at, c.created_at),
         (select count(*)::int from messages m
           where m.conversation_id = c.id
             and m.sender_id is distinct from auth.uid()
             and m.created_at > coalesce(
                   case when c.as_business then c.business_last_read_at
                        else c.resident_last_read_at end,
                   '-infinity'::timestamptz)),
         case when c.as_business then c.blocked_by_business else c.blocked_by_resident end,
         case when c.as_business then c.blocked_by_resident else c.blocked_by_business end
    from mine c
    join businesses b on b.id = c.business_id
    left join profiles p on p.id = c.profile_id
    left join jobs j on j.id = c.job_id
   where auth.uid() is not null
   order by coalesce(c.last_message_at, c.created_at) desc;
$$;

revoke all on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;

-- 00069's count, over the new list.
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

-- ─── The panel's list, with the block and the open reports ───

drop function if exists public.admin_conversations(text, int, int);
create function public.admin_conversations(
  p_search text default null,
  p_limit  int  default 50,
  p_offset int  default 0
)
returns table (
  id              uuid,
  business_id     uuid,
  business_name   text,
  business_logo   text,
  profile_id      uuid,
  resident_name   text,
  resident_avatar text,
  job_id          uuid,
  job_title       text,
  last_message    text,
  last_message_at timestamptz,
  message_count   int,
  created_at      timestamptz,
  blocked         boolean,
  open_reports    int
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  q text := nullif(trim(coalesce(p_search, '')), '');
begin
  if not is_admin() or not admin_may('moderation', 'view') then
    raise exception 'not-allowed' using errcode = '42501';
  end if;

  return query
  select c.id, c.business_id, b.name, b.logo_url,
         c.profile_id, p.full_name, p.avatar_url,
         c.job_id, j.title,
         c.last_message, coalesce(c.last_message_at, c.created_at),
         (select count(*)::int from messages m where m.conversation_id = c.id),
         c.created_at,
         c.blocked_by_business or c.blocked_by_resident,
         (select count(*)::int from reports r
           where r.entity_type = 'conversation' and r.entity_id = c.id
             and r.status in ('open', 'reviewed'))
    from conversations c
    join businesses b on b.id = c.business_id
    left join profiles p on p.id = c.profile_id
    left join jobs j on j.id = c.job_id
   where q is null
      or b.name ilike '%' || q || '%'
      or p.full_name ilike '%' || q || '%'
      or j.title ilike '%' || q || '%'
      or c.last_message ilike '%' || q || '%'
   order by coalesce(c.last_message_at, c.created_at) desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

revoke all on function public.admin_conversations(text, int, int) from public, anon;
grant execute on function public.admin_conversations(text, int, int) to authenticated;
