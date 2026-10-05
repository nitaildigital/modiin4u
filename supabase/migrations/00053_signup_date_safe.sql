-- ============================================================
-- Modiin4u — Migration 00053
-- A date of birth that is not a real date no longer stops a sign-up
--
-- 00049 kept the sign-up's date of birth when it looked like YYYY-MM-DD,
-- then cast it — and a shape that is right but a day that is not
-- ("2026-02-30", "0000-01-01") made the cast fail, and with it the new
-- account. The form's date picker sends only real dates, but the sign-up
-- data is whatever the caller sends. Now a date that does not parse is left
-- out, as 00049 meant.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.safe_date(p text)
returns date
language plpgsql
immutable
as $$
begin
  if p is null or p !~ '^\d{4}-\d{2}-\d{2}$' then
    return null;
  end if;
  return p::date;
exception when others then
  return null;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_phone text := nullif(trim(coalesce(meta->>'phone', new.phone, '')), '');
  v_family text := meta->>'family_status';
  v_pet text := lower(coalesce(meta->>'has_pet', ''));
  v_birth text := meta->>'date_of_birth';
  v_neighborhood uuid;
begin
  if nullif(trim(coalesce(meta->>'neighborhood', '')), '') is not null then
    select id into v_neighborhood
      from public.neighborhoods
     where name = trim(meta->>'neighborhood')
     limit 1;
  end if;

  insert into public.profiles (
    id, full_name, email, phone, is_broker,
    neighborhood_id, family_status, has_pet, date_of_birth
  )
  values (
    new.id,
    coalesce(
      nullif(meta->>'full_name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'תושב'
    ),
    new.email,
    v_phone,
    coalesce((meta->>'is_broker')::boolean, false),
    v_neighborhood,
    case when v_family in ('single', 'married', 'divorced', 'widowed') then v_family end,
    case v_pet when 'true' then true when 'false' then false end,
    public.safe_date(v_birth)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
