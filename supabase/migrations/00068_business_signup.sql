-- ============================================================
-- Modiin4u — Migration 00068
-- A business account: the business is created with the sign-up
--
-- Kamal's design adds a third account type to sign-up, beside resident and
-- broker: a business. The person fills the business's details on the
-- sign-up form itself — name, phone, e-mail, address, website, opening hours,
-- about — and the client approves the business in the panel before it is
-- shown (his choice, 7 Oct, as for apartments).
--
-- Sign-up needs the address confirmed, so there is no session to write the
-- business with. The form sends the details with the account
-- (`raw_user_meta_data.account_type = 'business'`, `.business = {...}`), and
-- this trigger creates the business from them, `pending`, owned by the new
-- account. The logo and photos need a session to upload; the app sends them
-- after the first sign-in.
--
-- A separate trigger rather than a change to `handle_new_user`, which has
-- been redefined several times (00019, 00049, 00053). It is named to fire
-- after `on_auth_user_created` (triggers fire in name order), so the profile
-- the business's `owner_id` points at already exists.
--
-- Nothing here may stop an account being created: a business that cannot be
-- saved is logged and the sign-up goes on; the person can still be given a
-- business from the panel (00051).
--
-- Needs 00051 for the owner's rights on their business (photos, hours).
-- Safe to run more than once.
-- ============================================================

create or replace function public.handle_new_business_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta   jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  b      jsonb := meta->'business';
  v_name text;
  v_slug text;
  v_id   uuid;
  h      jsonb;
  v_day  int;
  v_open text;
  v_close text;
begin
  if meta->>'account_type' is distinct from 'business'
     or b is null or jsonb_typeof(b) <> 'object' then
    return new;
  end if;

  v_name := left(nullif(trim(b->>'name'), ''), 200);
  if v_name is null then
    return new;
  end if;

  begin
    -- The panel's slugs are the name with dashes, Hebrew kept. One already
    -- taken gets the start of the account's id.
    v_slug := lower(regexp_replace(
      regexp_replace(v_name, '[^[:alnum:][:space:]א-ת-]', '', 'g'),
      '[[:space:]]+', '-', 'g'));
    v_slug := nullif(trim(both '-' from v_slug), '');
    if v_slug is null then
      v_slug := 'business-' || left(new.id::text, 8);
    elsif exists (select 1 from businesses where slug = v_slug) then
      v_slug := v_slug || '-' || left(new.id::text, 6);
    end if;

    insert into businesses (
      owner_id, name, slug, phone, email, website, address,
      full_description, status, notify_on_publish
    )
    values (
      new.id,
      v_name,
      v_slug,
      left(nullif(trim(b->>'phone'), ''), 40),
      left(nullif(trim(b->>'email'), ''), 200),
      left(nullif(trim(b->>'website'), ''), 500),
      -- The column is required; the form requires it too.
      coalesce(left(nullif(trim(b->>'address'), ''), 300), ''),
      left(nullif(trim(b->>'about'), ''), 5000),
      -- Shown once the client approves it. Whether its publishing is
      -- announced is his to switch on then; an owner never can (00051).
      'pending',
      false
    )
    returning id into v_id;

    -- Opening hours: one row per day the form has, 0 = Sunday as the table
    -- stores it. A day without both times is closed.
    if jsonb_typeof(b->'hours') = 'array' then
      for h in select * from jsonb_array_elements(b->'hours') loop
        v_day := case when (h->>'day') ~ '^[0-6]$' then (h->>'day')::int end;
        continue when v_day is null;
        v_open := h->>'open';
        v_close := h->>'close';
        if coalesce((h->>'closed')::boolean, false)
           or v_open !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
           or v_close !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
          insert into business_hours (business_id, day_of_week, is_closed)
          values (v_id, v_day, true)
          on conflict (business_id, day_of_week) do nothing;
        else
          insert into business_hours (business_id, day_of_week, open_time, close_time)
          values (v_id, v_day, v_open::time, v_close::time)
          on conflict (business_id, day_of_week) do nothing;
        end if;
      end loop;
    end if;
  exception when others then
    raise warning 'business sign-up for % not saved: %', new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function public.handle_new_business_signup() from public, anon, authenticated;

drop trigger if exists on_auth_user_created_business on auth.users;
create trigger on_auth_user_created_business
  after insert on auth.users
  for each row execute function public.handle_new_business_signup();
