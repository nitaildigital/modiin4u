-- ============================================================
-- Modiin4u — Migration 00067
-- A notification's conversions: replies and reviews it led to
--
-- The client asked (2 Oct) for each notification's conversions beside
-- "opened", and defined them on 7 Oct (through Harshit): a conversion is the
-- resident replying to a comment or writing a review. Counted here: someone
-- who opened a notification and, within 24 hours, wrote a reply or a review
-- converts for that notification — the last one they opened, once per
-- device. The panel's Push list shows the count beside Opened.
--
-- Safe to run more than once.
-- ============================================================

alter table public.push_campaigns
  add column if not exists conversion_count int not null default 0;

-- push_events gains the kind 'reply' (a conversion).
alter table public.push_events drop constraint if exists push_events_kind_check;
alter table public.push_events add constraint push_events_kind_check
  check (kind in ('open', 'call', 'directions', 'website', 'reply'));

create or replace function public.count_push_conversion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author uuid;
  v_event  record;
  v_added  int;
begin
  if tg_table_name = 'comments' then
    if new.entity_type <> 'review' then
      return new;
    end if;
    v_author := new.author_id;
  else
    v_author := new.author_id;
  end if;
  if v_author is null then
    return new;
  end if;

  -- The last notification this person opened, on any of their phones, in
  -- the 24 hours before writing.
  select e.campaign_id, e.device_id into v_event
    from push_events e
    join push_devices d on d.id = e.device_id
   where d.profile_id = v_author
     and e.kind = 'open'
     and e.created_at > now() - interval '24 hours'
   order by e.created_at desc
   limit 1;
  if v_event.campaign_id is null then
    return new;
  end if;

  insert into push_events (campaign_id, device_id, kind)
  values (v_event.campaign_id, v_event.device_id, 'reply')
  on conflict (campaign_id, device_id, kind) do nothing;
  get diagnostics v_added = row_count;
  if v_added > 0 then
    update push_campaigns set conversion_count = conversion_count + 1
     where id = v_event.campaign_id;
  end if;
  return new;
end;
$$;

drop trigger if exists comments_push_conversion on public.comments;
create trigger comments_push_conversion
  after insert on public.comments
  for each row execute function public.count_push_conversion();

drop trigger if exists reviews_push_conversion on public.reviews;
create trigger reviews_push_conversion
  after insert on public.reviews
  for each row execute function public.count_push_conversion();
