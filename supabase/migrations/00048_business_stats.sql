-- ============================================================
-- Modiin4u — Migration 00048
-- Statistics for each business page: views and button clicks
--
-- The client (2 Oct): "can we also collect data for each business page? To
-- know how many total views it had, broken down by month, week and day?
-- Plus how many people clicked on its website button, phone number, etc."
-- Nothing counted them: businesses had no view counter at all. So counting
-- has to start before launch — there is no history to fill it from.
--
-- One row per thing done on a business page, in the app or on the website:
-- the page opened, or one of its buttons pressed. Nothing about the person:
-- the business, what was done, app or web, the time, and a random id the
-- browser or phone makes for itself, so "unique visitors" can be counted
-- without knowing who anyone is.
--
-- Visitors add rows only through record_business_event and read nothing.
-- The panel reads them through business_stats, business_stats_totals and
-- business_stats_top, which only an administrator may call. Later, a
-- business owner reading their own business's numbers is one more check in
-- each.
--
-- Additive. Safe to run more than once.
-- ============================================================

create table if not exists public.business_events (
  id          bigint generated always as identity primary key,
  business_id uuid not null references public.businesses(id) on delete cascade,
  kind        text not null check (kind in (
                'view', 'call', 'website', 'whatsapp', 'directions',
                'share', 'instagram', 'facebook', 'email', 'menu')),
  platform    text not null check (platform in ('app', 'web')),
  visitor     text not null check (length(visitor) between 8 and 64),
  created_at  timestamptz not null default now()
);

create index if not exists idx_business_events_business_time
  on public.business_events (business_id, created_at);
create index if not exists idx_business_events_time
  on public.business_events (created_at);

alter table public.business_events enable row level security;
-- No policies: nobody reads or writes the table directly. The functions
-- below are the only way in.

-- ─── Recording ───
--
-- A view counts once per visitor per business per 30 minutes, so a refresh,
-- Back and forth, or a page drawn twice does not inflate it. Clicks count
-- each time: pressing Call twice is two calls.
create or replace function public.record_business_event(
  p_business uuid,
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
  if p_kind = 'view' and exists (
    select 1 from business_events
     where business_id = p_business
       and visitor = p_visitor
       and kind = 'view'
       and created_at > now() - interval '30 minutes'
  ) then
    return;
  end if;

  insert into business_events (business_id, kind, platform, visitor)
  select p_business, p_kind, p_platform, p_visitor
   where exists (select 1 from businesses where id = p_business);
end;
$$;

revoke all on function public.record_business_event(uuid, text, text, text) from public;
grant execute on function public.record_business_event(uuid, text, text, text) to anon, authenticated;

-- ─── Reading: one business, by day, week or month ───
--
-- Days, weeks and months are Israel's, not UTC's: a view at 01:00 in
-- Modi'in belongs to that day. Weeks start on Sunday, as the Israeli week
-- does. Each row is one period and one kind; `visitors` counts distinct
-- visitors, `total` every event.
create or replace function public.business_stats(
  p_business uuid,
  p_from     date,
  p_to       date,
  p_bucket   text default 'day'
)
returns table (period date, kind text, total bigint, visitors bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'not allowed';
  end if;
  if p_bucket not in ('day', 'week', 'month') then
    raise exception 'bucket must be day, week or month';
  end if;

  return query
    with local as (
      select e.kind, e.visitor, (e.created_at at time zone 'Asia/Jerusalem')::date as d
        from business_events e
       where e.business_id = p_business
         and e.created_at >= (p_from::timestamp at time zone 'Asia/Jerusalem')
         and e.created_at <  ((p_to + 1)::timestamp at time zone 'Asia/Jerusalem')
    )
    select case p_bucket
             when 'day' then l.d
             when 'week' then l.d - extract(dow from l.d)::int
             else date_trunc('month', l.d)::date
           end as period,
           l.kind,
           count(*) as total,
           count(distinct l.visitor) as visitors
      from local l
     group by 1, 2
     order by 1, 2;
end;
$$;

revoke all on function public.business_stats(uuid, date, date, text) from public;
grant execute on function public.business_stats(uuid, date, date, text) to authenticated;

-- ─── Reading: one business, the whole range at once ───
--
-- Visitors cannot be added up period by period — someone who came on Monday
-- and Tuesday is one visitor in the week, two in its days — so the range's
-- totals are counted here directly.
create or replace function public.business_stats_totals(
  p_business uuid,
  p_from     date,
  p_to       date
)
returns table (kind text, total bigint, visitors bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'not allowed';
  end if;

  return query
    select e.kind, count(*), count(distinct e.visitor)
      from business_events e
     where e.business_id = p_business
       and e.created_at >= (p_from::timestamp at time zone 'Asia/Jerusalem')
       and e.created_at <  ((p_to + 1)::timestamp at time zone 'Asia/Jerusalem')
     group by e.kind;
end;
$$;

revoke all on function public.business_stats_totals(uuid, date, date) from public;
grant execute on function public.business_stats_totals(uuid, date, date) to authenticated;

-- ─── Reading: every business, most viewed first ───
create or replace function public.business_stats_top(
  p_from  date,
  p_to    date,
  p_limit int default 20
)
returns table (business_id uuid, name text, views bigint, visitors bigint, clicks bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'not allowed';
  end if;

  return query
    select b.id, b.name,
           count(*) filter (where e.kind = 'view'),
           count(distinct e.visitor) filter (where e.kind = 'view'),
           count(*) filter (where e.kind <> 'view')
      from business_events e
      join businesses b on b.id = e.business_id
     where e.created_at >= (p_from::timestamp at time zone 'Asia/Jerusalem')
       and e.created_at <  ((p_to + 1)::timestamp at time zone 'Asia/Jerusalem')
     group by b.id, b.name
     order by 3 desc, 5 desc
     limit greatest(1, least(p_limit, 200));
end;
$$;

revoke all on function public.business_stats_top(date, date, int) from public;
grant execute on function public.business_stats_top(date, date, int) to authenticated;
