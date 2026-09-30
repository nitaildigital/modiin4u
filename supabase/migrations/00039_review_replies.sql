-- Residents reply to each other's reviews
--
-- The client: "Modiin4u and businesses will not be replying to reviews at
-- this stage — instead, users can reply to other users, like on Facebook."
--
-- A reply is a row in `comments` (00007) with entity_type 'review' and the
-- review's id — the table was made for threads and has sat empty, and the
-- panel's Comments section (fixed in 00031) already moderates it. Replies
-- start 'pending' as reviews do (the guard in 00032 sees to that for
-- residents), the client approves them there, and the business page shows
-- the approved ones — and each author their own, marked as waiting.
--
-- Profiles are private, so a reply cannot join its author's name. As with
-- reviews (00029), the name and photo are copied onto the row when it is
-- written, and kept in step when the author changes them.

alter table public.comments
  add column if not exists author_name text,
  add column if not exists author_avatar_url text;

update public.comments c
set author_name = p.full_name,
    author_avatar_url = p.avatar_url
from public.profiles p
where p.id = c.author_id
  and c.author_name is null;

create or replace function public.comments_fill_author()
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

drop trigger if exists comments_fill_author on public.comments;
create trigger comments_fill_author
  before insert on public.comments
  for each row execute function public.comments_fill_author();

create or replace function public.profiles_sync_comment_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.full_name is distinct from old.full_name
     or new.avatar_url is distinct from old.avatar_url then
    update public.comments
    set author_name = new.full_name,
        author_avatar_url = new.avatar_url
    where author_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_sync_comment_author on public.profiles;
create trigger profiles_sync_comment_author
  after update on public.profiles
  for each row execute function public.profiles_sync_comment_author();
