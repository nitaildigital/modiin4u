-- ============================================================
-- Modiin4u — Migration 00056
-- A deal claimed can be used: a voucher per claim, and "Use now"
--
-- Claiming a deal ended at "Offer claimed": the deal's one code (which none
-- of the live deals has) shown to everyone the same, and nothing after it.
-- `offer_claims.redeemed` and `offers.redeem_count` existed, but nothing
-- could set them — the resident is barred from it (00033), the business has
-- no screen, and the panel had no button — so every claim stayed "claimed"
-- and every deal showed 0 used.
--
-- Now each claim carries a short code of its own, which the app shows on the
-- resident's voucher. At the till the resident slides "Use now" in front of
-- the staff; `redeem_my_claim` marks that claim used, once, while the deal is
-- still running, and the count follows (00049). The client chose this over
-- business accounts or scanning (6 Oct). The panel reads the claims, and can
-- still mark or unmark one itself (offer_claims_admin_update, 00033).
--
-- Safe to run more than once.
-- ============================================================

alter table public.offer_claims add column if not exists code text;

-- Security definer so the uniqueness check sees every claim, not only the
-- caller's own (the read policy); the claim trigger runs as the resident.
create or replace function public.new_claim_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  -- No 0/O, 1/I/L: read out loud at a till, they get confused.
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  c text;
begin
  loop
    c := '';
    for i in 1..6 loop
      c := c || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from offer_claims where code = c);
  end loop;
  return c;
end;
$$;

update public.offer_claims set code = public.new_claim_code() where code is null;

create unique index if not exists offer_claims_code_key on public.offer_claims (code);

-- The code is the database's: set on the way in, never changed after.
create or replace function public.offer_claims_code()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.code := public.new_claim_code();
  else
    new.code := old.code;
  end if;
  return new;
end;
$$;

drop trigger if exists offer_claims_code on public.offer_claims;
create trigger offer_claims_code
  before insert or update on public.offer_claims
  for each row execute function public.offer_claims_code();

-- The resident's own "Use now". Runs as its owner, past the column guard,
-- and checks for itself what the guard would: the caller's own claim, not
-- used yet, the deal live and in its dates, the caller not blocked.
create or replace function public.redeem_my_claim(p_claim uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  c record;
  o record;
  at timestamptz := now();
begin
  select * into c from offer_claims where id = p_claim for update;
  if c is null or c.profile_id is distinct from auth.uid() then
    raise exception 'claim-not-found' using errcode = 'P0002';
  end if;
  if c.redeemed then
    raise exception 'claim-used' using errcode = 'P0001';
  end if;
  if exists (select 1 from profiles where id = auth.uid() and is_banned) then
    raise exception 'account-blocked' using errcode = '42501';
  end if;

  select status, start_at, end_at into o from offers where id = c.offer_id;
  if o.status <> 'active'
     or (o.start_at is not null and o.start_at > at)
     or (o.end_at is not null and o.end_at <= at) then
    raise exception 'offer-ended' using errcode = 'P0001';
  end if;

  update offer_claims set redeemed = true, redeemed_at = at where id = p_claim;
  return at;
end;
$$;

revoke all on function public.redeem_my_claim(uuid) from public, anon;
grant execute on function public.redeem_my_claim(uuid) to authenticated;
revoke all on function public.new_claim_code() from public, anon;
grant execute on function public.new_claim_code() to authenticated;
