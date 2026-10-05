-- ============================================================
-- Modiin4u — Migration 00049
-- What sign-up collects is kept; a deal's claims are counted
--
-- Found in the 5 Oct audit of what is never saved.
--
-- 1. The phone typed at sign-up was lost. The form sends it with the account
--    (`raw_user_meta_data.phone`), but the profile trigger (00019) copied
--    `new.phone` — the account's own phone column, empty for an e-mail
--    sign-up. Every new profile had no phone.
--
-- 2. The neighbourhood, family status, pet and date of birth were written
--    after sign-up, which needs a session. A project that asks for the
--    address to be confirmed returns none, so they were dropped. The form now
--    sends them with the account too, and the trigger keeps them: the
--    neighbourhood by its name, the others only when they are values the
--    columns accept, so a bad value is left out rather than failing the
--    sign-up.
--
--    The phones already lost are put back from what those people typed
--    (still in their account's data), where the profile has none.
--
-- 3. `offers.claim_count` never moved: claims were saved, nothing counted
--    them. So `max_claims` was never enforced and the panel showed 0 claims
--    for every deal. Now each claim added or removed changes the count, a
--    claim on a deal that is full is refused, and the counts are set from
--    the claims there are. The offer row is locked while a claim is checked,
--    so two people claiming the last one at once cannot both get it.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1 and 2: the profile a new account starts with ───

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
    case when v_birth ~ '^\d{4}-\d{2}-\d{2}$' then v_birth::date end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- The phones lost so far, from what each person typed.
update public.profiles p
   set phone = nullif(trim(u.raw_user_meta_data->>'phone'), '')
  from auth.users u
 where u.id = p.id
   and coalesce(p.phone, '') = ''
   and nullif(trim(u.raw_user_meta_data->>'phone'), '') is not null;

-- ─── 3: a deal's claims, counted ───

create or replace function public.offer_claims_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max int;
  v_count int;
begin
  if tg_op = 'INSERT' then
    select max_claims, claim_count into v_max, v_count
      from offers where id = new.offer_id
       for update;
    if v_max is not null and v_count >= v_max then
      raise exception 'offer-full' using errcode = 'P0001';
    end if;
    update offers set claim_count = claim_count + 1 where id = new.offer_id;
    return new;
  end if;

  if tg_op = 'DELETE' then
    update offers set claim_count = greatest(claim_count - 1, 0) where id = old.offer_id;
    if old.redeemed then
      update offers set redeem_count = greatest(redeem_count - 1, 0) where id = old.offer_id;
    end if;
    return old;
  end if;

  -- UPDATE: a claim marked used, or unmarked, by the business.
  if new.redeemed is distinct from old.redeemed then
    update offers
       set redeem_count = greatest(redeem_count + case when new.redeemed then 1 else -1 end, 0)
     where id = new.offer_id;
  end if;
  return new;
end;
$$;

drop trigger if exists offer_claims_count_insert on public.offer_claims;
create trigger offer_claims_count_insert
  before insert on public.offer_claims
  for each row execute function public.offer_claims_count();

drop trigger if exists offer_claims_count_change on public.offer_claims;
create trigger offer_claims_count_change
  after update or delete on public.offer_claims
  for each row execute function public.offer_claims_count();

-- The counts as the claims stand today.
update public.offers o
   set claim_count  = coalesce(c.claims, 0),
       redeem_count = coalesce(c.redeemed, 0)
  from (
    select offer_id,
           count(*) as claims,
           count(*) filter (where redeemed) as redeemed
      from public.offer_claims
     group by offer_id
  ) c
 where c.offer_id = o.id;

update public.offers
   set claim_count = 0, redeem_count = 0
 where id not in (select distinct offer_id from public.offer_claims)
   and (claim_count <> 0 or redeem_count <> 0);
