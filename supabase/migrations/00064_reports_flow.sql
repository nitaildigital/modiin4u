-- ============================================================
-- Modiin4u — Migration 00064
-- A report counts, reaches the team, and can hide what it reports
--
-- Since 7 Oct the app files reports (report_sheet.dart) and the panel lists
-- them, but the flow stopped there: the same person could report the same
-- thing again and again; `report_count` on reviews and comments, which the
-- panel's Comments screen shows, never moved; nobody was told a report had
-- come in; and with replies live at once (00063), a reply many people found
-- abusive stayed up until someone happened to open the queue.
--
--   1. One report per person per item (a unique index). The app says "you
--      already reported this" instead of filing it twice.
--   2. `report_count` on a review or a comment is the number of reports
--      still open on it, kept by a trigger, so the panel's counts are real.
--   3. The first open report on an item queues a notification to the
--      administrators who moderate (super admins, and roles with the
--      'moderation' module) — one per item, not one per report.
--   4. `app_settings.reports_auto_hide_at`: when a review or a reply reaches
--      that many open reports it is hidden until someone looks. Unset or 0 —
--      the default — nothing hides itself; the panel decides.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. One report per person per item ───
-- Duplicates already filed keep the earliest.
delete from public.reports r
 using public.reports older
 where r.reporter_id = older.reporter_id
   and r.entity_type = older.entity_type
   and r.entity_id = older.entity_id
   and (older.created_at, older.id) < (r.created_at, r.id);

create unique index if not exists reports_one_per_person
  on public.reports (reporter_id, entity_type, entity_id);

-- ─── 2–4. Counts, the team's notification, hiding ───
create or replace function public.reports_after_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  r          reports;
  v_open     int;
  v_hide_at  int;
  v_admins   jsonb;
  v_what     text;
  v_what_en  text;
begin
  if tg_op = 'DELETE' then r := old; else r := new; end if;

  select count(*) into v_open
    from reports
   where entity_type = r.entity_type
     and entity_id = r.entity_id
     and status in ('open', 'reviewed');

  -- Runs as its owner, so the column guards (00032), which stop residents
  -- changing a count or a status, do not stop it.
  if r.entity_type = 'review' then
    update reviews set report_count = v_open
     where id = r.entity_id and report_count is distinct from v_open;
  elsif r.entity_type = 'comment' then
    update comments set report_count = v_open
     where id = r.entity_id and report_count is distinct from v_open;
  end if;

  if tg_op <> 'INSERT' then
    return null;
  end if;

  -- Hidden, not deleted: the panel's Reviews and Comments can show it again.
  select case when jsonb_typeof(value) = 'number' then value::text::int end
    into v_hide_at
    from app_settings where key = 'reports_auto_hide_at';
  if coalesce(v_hide_at, 0) > 0 and v_open >= v_hide_at then
    if r.entity_type = 'review' then
      update reviews set status = 'hidden'
       where id = r.entity_id and status = 'approved';
    elsif r.entity_type = 'comment' then
      update comments set status = 'hidden'
       where id = r.entity_id and status = 'approved';
    end if;
  end if;

  -- The team hears of an item once, when its first open report arrives.
  if v_open = 1 then
    select jsonb_agg(distinct au.profile_id) into v_admins
      from admin_users au
      join admin_roles ro on ro.id = au.role_id
     where au.is_active
       and (ro.name = 'super_admin'
            or exists (
              select 1 from admin_role_permissions p
               where p.role_id = au.role_id
                 and p.module = 'moderation'
                 and p.action = 'view'
                 and p.allowed));

    v_what := case r.entity_type
      when 'review' then 'ביקורת' when 'comment' then 'תגובה'
      when 'business' then 'עסק' when 'listing' then 'מודעת נדל״ן'
      else 'תוכן' end;
    v_what_en := case r.entity_type
      when 'review' then 'a review' when 'comment' then 'a reply'
      when 'business' then 'a business' when 'listing' then 'a listing'
      else 'content' end;

    if v_admins is not null then
      -- No link: the panel is the website's (/admin), not the app's.
      insert into push_campaigns (
        title, body, title_en, body_en,
        status, scheduled_at, audience_type, audience_filter, source_type, source_id
      ) values (
        'דיווח חדש', 'תושב דיווח על ' || v_what || '. פרטים בניהול ← דיווחים.',
        'New report', 'A resident reported ' || v_what_en || '. See the panel → Reports.',
        'scheduled', now(), 'profiles',
        jsonb_build_object('profile_ids', v_admins),
        'report', r.id
      );
    end if;
  end if;

  return null;
end;
$$;

drop trigger if exists reports_after_change on public.reports;
create trigger reports_after_change
  after insert or delete or update of status on public.reports
  for each row execute function public.reports_after_change();

-- Counts for what was reported before this ran.
update reviews rv set report_count = sub.n
  from (select entity_id, count(*) n from reports
         where entity_type = 'review' and status in ('open', 'reviewed')
         group by entity_id) sub
 where rv.id = sub.entity_id and rv.report_count is distinct from sub.n;
update comments c set report_count = sub.n
  from (select entity_id, count(*) n from reports
         where entity_type = 'comment' and status in ('open', 'reviewed')
         group by entity_id) sub
 where c.id = sub.entity_id and c.report_count is distinct from sub.n;
