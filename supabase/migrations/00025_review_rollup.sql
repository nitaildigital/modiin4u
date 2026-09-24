-- ============================================================
-- Modiin4u — Migration 00025
-- Keep a business's rating honest
--
-- The business page has a review form. Submitting it added a row to a list
-- held in memory and showed "Review submitted! Thank you 🎉" — nothing was
-- written, and it was gone on the next rebuild. Wiring the form up is the
-- app's job; this file is about the two numbers beside it.
--
-- `businesses.rating` and `businesses.review_count` are plain columns with
-- nothing keeping them in step, so a real review would have left the stars
-- above it unchanged.
--
-- Only approved reviews count. A review arrives as `pending` and an
-- administrator moves it to `approved`, so a business cannot have its score
-- moved by something nobody has looked at yet.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.sync_business_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target uuid := coalesce(new.business_id, old.business_id);
begin
  update public.businesses b
     set rating = coalesce(
           (select round(avg(r.rating)::numeric, 1)
              from public.reviews r
             where r.business_id = target
               and r.status = 'approved'),
           0
         ),
         review_count = (
           select count(*)
             from public.reviews r
            where r.business_id = target
              and r.status = 'approved'
         )
   where b.id = target;

  return coalesce(new, old);
end;
$$;

drop trigger if exists on_review_change on public.reviews;

-- Fires on approval too, not only on insert: a review sitting at `pending`
-- must not move the score, and must move it the moment it is approved.
create trigger on_review_change
  after insert or update or delete on public.reviews
  for each row execute function public.sync_business_rating();

-- ─── Bring the existing rows into line ───
--
-- `reviews` is empty today, so this sets every business that carries a
-- non-zero score back to zero. That is the correction: those numbers were
-- seeded with the import and no review stands behind any of them.

update public.businesses b
   set rating = coalesce(c.avg_rating, 0),
       review_count = coalesce(c.n, 0)
  from (
    select biz.id,
           round(avg(r.rating) filter (where r.status = 'approved')::numeric, 1)
             as avg_rating,
           count(r.*) filter (where r.status = 'approved') as n
      from public.businesses biz
      left join public.reviews r on r.business_id = biz.id
     group by biz.id
  ) c
 where c.id = b.id
   and (b.rating is distinct from coalesce(c.avg_rating, 0)
        or b.review_count is distinct from coalesce(c.n, 0));
