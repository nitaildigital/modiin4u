-- ============================================================
-- Modiin4u — Migration 00060
-- More of what the panel adds goes out as a notification, and so does a
-- competition's winner
--
-- 00045 announced articles, events and businesses when they went live. The
-- client asked (6 Oct) for a notification whenever the panel adds something,
-- and when a step competition is won. Added here:
--
--   * a deal       — when it goes live, to devices with "Deals" on;
--   * a property   — when the panel approves it (status active), to devices
--                    with "Real estate" on;
--   * a competition — when it is switched on, to everyone, at its start time
--                    if that is later;
--   * the winner   — "You won!" with the prize, to the winner's own devices;
--   * the result   — "The competition has a winner", to everyone else.
--
-- The same "send a notification" box as 00045 (`notify_on_publish`, on for new
-- rows, off for rows already there), the same five-minute wait in which
-- clearing it or taking the row down cancels it, and a row is announced once.
-- A deal a business owner adds is not announced: city-wide notifications are
-- the panel's.
--
-- Two audiences join `push_matches` (00045): `person` — one person's devices,
-- whatever their topic switches, for news that is theirs alone; `all_but` —
-- everyone except those people.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. The audiences ───

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

-- The bell of a browser with no device shows what went to everyone too.
create or replace function public.push_feed(p_token text default null, p_limit int default 50)
returns table (
  id uuid, title text, body text, title_en text, body_en text,
  image_url text, deep_link text, sent_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.title, c.body, c.title_en, c.body_en, c.image_url, c.deep_link, c.sent_at
    from push_campaigns c
   where c.status = 'sent'
     and c.sent_at > now() - interval '60 days'
     and case
           when exists (select 1 from push_devices where token = p_token) then
             exists (select 1 from push_devices d where d.token = p_token and push_matches(c, d))
           else c.audience_type in ('all', 'topic', 'all_but')
         end
   order by c.sent_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

grant execute on function public.push_feed(text, int) to anon, authenticated;

-- ─── 2. The box on deals, listings and competitions ───

do $$
declare
  t text;
begin
  foreach t in array array['offers', 'listings', 'challenges'] loop
    if not exists (
      select 1 from information_schema.columns
       where table_schema = 'public' and table_name = t
         and column_name = 'notify_on_publish'
    ) then
      -- Off for what is there already: nothing old is announced as new.
      execute format(
        'alter table public.%I add column notify_on_publish boolean not null default false', t);
    end if;
    execute format(
      'alter table public.%I alter column notify_on_publish set default true', t);
    execute format(
      'alter table public.%I add column if not exists push_campaign_id uuid references public.push_campaigns(id) on delete set null', t);
  end loop;
end $$;

-- ─── 3. Queueing them ───

create or replace function public.queue_more_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  kind      text := tg_argv[0];            -- 'offer' | 'listing' | 'challenge'
  -- A resident's or owner's write, asked of the request rather than of
  -- `current_user` (is_resident_write), which in a security definer
  -- function is always this function's owner.
  resident  boolean := auth.uid() is not null and not is_admin();
  r         jsonb := to_jsonb(new);
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
begin
  -- The link to a campaign is the database's: a resident writing it could
  -- point their row at someone else's scheduled notification and cancel it.
  if resident then
    new.push_campaign_id := case when tg_op = 'INSERT' then null else old.push_campaign_id end;
  end if;

  -- A business owner's deal is not the panel's to announce.
  if kind = 'offer' and resident then
    if tg_op = 'INSERT' then new.notify_on_publish := false; end if;
    new.push_campaign_id := case when tg_op = 'INSERT' then null else old.push_campaign_id end;
    return new;
  end if;

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
      v_title := 'מבצע חדש';  v_title_en := 'New deal';
      v_body := r ->> 'name';  v_body_en := v_body;
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
      -- Announced when it begins, not when it is typed in.
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

drop trigger if exists offers_queue_push on public.offers;
create trigger offers_queue_push
  before insert or update on public.offers
  for each row execute function public.queue_more_push('offer');

drop trigger if exists listings_queue_push on public.listings;
create trigger listings_queue_push
  before insert or update on public.listings
  for each row execute function public.queue_more_push('listing');

drop trigger if exists challenges_queue_push on public.challenges;
create trigger challenges_queue_push
  before insert or update on public.challenges
  for each row execute function public.queue_more_push('challenge');

-- ─── 4. The winner, and everyone else ───
--
-- Same rule as 00058; on a win, two notifications go out at once: "You won"
-- with the prize to the winner, "The competition has a winner" to the rest.

create or replace function public.award_challenge_winner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  p record;
  c record;
  total int;
  first_day date;
  last_day date;
  won int;
  v_name text;
  v_prize text;
  v_prize_en text;
begin
  select id, full_name, health_enabled, is_banned into p
    from profiles where id = new.profile_id;
  if p.id is null or not p.health_enabled or p.is_banned then
    return new;
  end if;

  for c in
    select * from challenges
     where is_active
       and winner_id is null
       and challenge_type = 'steps'
       and start_at <= now() and end_at >= now()
  loop
    first_day := (c.start_at at time zone 'Asia/Jerusalem')::date;
    last_day  := (c.end_at   at time zone 'Asia/Jerusalem')::date;
    continue when new.date < first_day or new.date > last_day;

    if c.goal_per_day then
      total := new.steps;
    else
      select coalesce(sum(steps), 0) into total
        from daily_steps
       where profile_id = new.profile_id
         and date between first_day and last_day;
    end if;

    continue when total < c.goal;

    v_name := coalesce(nullif(trim(p.full_name), ''), 'תושב/ת');
    update challenges
       set winner_id = p.id, winner_name = v_name, won_at = now(), won_steps = total
     where id = c.id and winner_id is null;
    get diagnostics won = row_count;
    continue when won = 0;

    v_prize := nullif(trim(c.prize), '');
    v_prize_en := coalesce(nullif(trim(c.prize_en), ''), v_prize);

    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      '🏆 זכית בתחרות!',
      c.name || coalesce(' · הפרס שלך: ' || v_prize, ''),
      '🏆 You won the competition!',
      c.name || coalesce(' · Your prize: ' || v_prize_en, ''),
      '/steps', 'scheduled', now(), 'person',
      jsonb_build_object('profile_ids', jsonb_build_array(p.id)),
      'challenge_win', c.id
    ), (
      'יש זוכה בתחרות',
      v_name || ' זכה/תה ב' || c.name || coalesce(' · ' || v_prize, ''),
      'The competition has a winner',
      v_name || ' won ' || c.name || coalesce(' · ' || v_prize_en, ''),
      '/steps', 'scheduled', now(), 'all_but',
      jsonb_build_object('profile_ids', jsonb_build_array(p.id)),
      'challenge_result', c.id
    );
  end loop;

  return new;
end;
$$;

revoke all on function public.award_challenge_winner() from public, anon, authenticated;
