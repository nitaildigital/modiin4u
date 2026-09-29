-- The reviewer's name, on the review
--
-- A review is public; the name of whoever wrote it is part of it — the
-- design prints it above every review. But profiles are private since 00027
-- (a row carries email, phone and date of birth, and a policy is per row, not
-- per column), so the app's join from reviews to profiles comes back null for
-- anybody who is not the author or an admin, and every review on the website
-- was signed by nobody.
--
-- So the review carries the two things it shows: the author's name and
-- avatar, copied when the review is written and kept in step if the author
-- changes them. Nothing else about the author leaves the profiles table.

alter table public.reviews
  add column if not exists author_name text,
  add column if not exists author_avatar_url text;

update public.reviews r
set author_name = p.full_name,
    author_avatar_url = p.avatar_url
from public.profiles p
where p.id = r.author_id
  and r.author_name is null;

create or replace function public.reviews_fill_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select p.full_name, p.avatar_url
    into new.author_name, new.author_avatar_url
  from public.profiles p
  where p.id = new.author_id;
  return new;
end;
$$;

drop trigger if exists reviews_fill_author on public.reviews;
create trigger reviews_fill_author
  before insert on public.reviews
  for each row execute function public.reviews_fill_author();

create or replace function public.profiles_sync_review_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.full_name is distinct from old.full_name
     or new.avatar_url is distinct from old.avatar_url then
    update public.reviews
    set author_name = new.full_name,
        author_avatar_url = new.avatar_url
    where author_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_sync_review_author on public.profiles;
create trigger profiles_sync_review_author
  after update of full_name, avatar_url on public.profiles
  for each row execute function public.profiles_sync_review_author();
