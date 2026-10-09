-- ============================================================
-- Modiin4u — Migration 00078
-- The panel reads the conversations between businesses and residents
--
-- Harshit, for the client (9 Oct): "the admin can see all the chats which
-- are done by businesses and the job seekers". 00069 kept them private to
-- the two sides ("the panel does not read them"). Now an administrator with
-- the moderation module reads them — through two functions, not through the
-- tables, so the app's own rules stay as they were, and every conversation
-- opened is written to the activity log: who read which conversation, when.
--
-- The privacy policy published 8 Oct does not say the team reads messages;
-- a line for it waits for the client's lawyer (PLAN.md, 9 Oct).
--
-- Needs 00012, 00050, 00069. Safe to run more than once.
-- ============================================================

alter type public.audit_action add value if not exists 'view';

-- The list: every conversation, newest first, with both sides named. Search
-- by business, resident or job title, or by the last line.
create or replace function public.admin_conversations(
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
  created_at      timestamptz
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
         c.created_at
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

-- One conversation's messages, oldest first, each marked as the business's
-- or the resident's. Reading it does not mark it read for either side.
create or replace function public.admin_conversation_messages(p_conversation uuid)
returns table (
  id            uuid,
  sender_id     uuid,
  from_business boolean,
  body          text,
  created_at    timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile uuid;
begin
  if not is_admin() or not admin_may('moderation', 'view') then
    raise exception 'not-allowed' using errcode = '42501';
  end if;

  select c.profile_id into v_profile from conversations c where c.id = p_conversation;
  if not found then
    return;
  end if;

  -- Logged at most once an hour per administrator and conversation, so a
  -- refresh does not fill the log. The log keeps the administrator's team
  -- row, not their account (audit_logs_stamp_actor). Its own failure must
  -- not stop the reading.
  begin
    if not exists (
      select 1 from audit_logs a
       where a.admin_id in (select au.id from admin_users au where au.profile_id = auth.uid())
         and a.action = 'view'
         and a.entity_type = 'conversations' and a.entity_id = p_conversation
         and a.created_at > now() - interval '1 hour'
    ) then
      insert into audit_logs (admin_id, action, entity_type, entity_id)
      values (auth.uid(), 'view', 'conversations', p_conversation);
    end if;
  exception when others then
    null;
  end;

  return query
  select m.id, m.sender_id, m.sender_id is distinct from v_profile, m.body, m.created_at
    from messages m
   where m.conversation_id = p_conversation
   order by m.created_at;
end;
$$;

revoke all on function public.admin_conversation_messages(uuid) from public, anon;
grant execute on function public.admin_conversation_messages(uuid) to authenticated;
