-- Information pages the client writes himself: About Us, Accessibility Statement
--
-- The website's footer has "About Us" and "Accessibility Statement" links,
-- and both opened the help page, because there was no text to show. The
-- accessibility statement is required by law in Israel, and neither page may
-- be written for him: the words are his (handover, "Waiting on the client").
-- So this is a table of fixed pages he fills from the panel, one row per
-- page, found by its slug.
--
-- The two rows are seeded with their titles only — the page names the footer
-- already prints — and no body. A page stays hidden until he switches it to
-- published, and until then the site says the content will be published
-- soon rather than showing anything in its place.
--
-- The body is plain text with three conventions the pages render: a line
-- starting "# " or "## " is a heading, a line starting "- " is a list item,
-- and a blank line starts a new paragraph. Enough for a statement with
-- sections and a contact list, without a formatting editor.
--
-- The pages are fixed: the panel edits and publishes them but never adds or
-- deletes one, so administrators get select and update only. Unpublishing
-- is how a page is taken down, and it can be undone.

create table if not exists site_pages (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique,
  title_he     text not null default '',
  title_en     text not null default '',
  body_he      text not null default '',
  body_en      text not null default '',
  is_published boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  updated_by   uuid references auth.users(id) on delete set null
);

-- Who saved the page last is taken from the session, not from what the
-- panel sends, and the time from the database's clock.
create or replace function site_pages_stamp()
returns trigger as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$ language plpgsql;

drop trigger if exists site_pages_stamp on site_pages;
create trigger site_pages_stamp
  before update on site_pages
  for each row execute function site_pages_stamp();

alter table site_pages enable row level security;

-- Anyone may read a published page; an administrator reads drafts too.
drop policy if exists site_pages_read on site_pages;
create policy site_pages_read on site_pages
  for select using (is_published or is_admin());

drop policy if exists site_pages_admin_update on site_pages;
create policy site_pages_admin_update on site_pages
  for update using (is_admin()) with check (is_admin());

insert into site_pages (slug, title_he, title_en)
values
  ('about', 'אודות', 'About Us'),
  ('accessibility', 'הצהרת נגישות', 'Accessibility Statement')
on conflict (slug) do nothing;
