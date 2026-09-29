-- Where a stored file is used, for the panel
--
-- The panel removes files from the `media` bucket in two places: the media
-- library, and an image field whose picture was replaced. Neither may take a
-- file something still shows. A file's address is copied into whatever row
-- uses it — a business logo, an article cover, the middle of an article's
-- HTML, a listing's photo array, a gallery's `media` row — fifteen columns
-- today, and more as tables are added. A list of them written into the app
-- would miss the next one, and row security hides some rows (drafts, other
-- people's listings) from a client-side search.
--
-- So the database answers: every text, JSON or array column of every public
-- table is searched for the file's path, with row security bypassed, and the
-- rows found are returned with a name to show. It is read-only and open to
-- administrators only.
--
-- `p_media_id` names the library row being asked about: that row itself is
-- not counted as a use, and the galleries (`entity_media`) that point at it
-- by id are.

create or replace function public.media_usage(
  p_path text,
  p_media_id uuid default null
)
returns table (source text, column_name text, row_id text, label text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  c record;
  pattern text;
  own_row text;
begin
  if not public.is_admin() then
    raise exception 'media_usage is for administrators' using errcode = '42501';
  end if;
  if coalesce(trim(p_path), '') = '' then
    return;
  end if;

  -- The path as it appears inside a public address. LIKE's wildcards are
  -- escaped: file names are full of underscores.
  pattern := '%/media/'
    || replace(replace(replace(p_path, '\', '\\'), '%', '\%'), '_', '\_')
    || '%';

  for c in
    select col.table_name as tbl, col.column_name as col
    from information_schema.columns col
    join information_schema.tables t
      on t.table_schema = col.table_schema
     and t.table_name = col.table_name
     and t.table_type = 'BASE TABLE'
    where col.table_schema = 'public'
      and col.data_type in ('text', 'character varying', 'jsonb', 'json', 'ARRAY')
      and col.table_name <> 'spatial_ref_sys'
  loop
    own_row := case
      when c.tbl = 'media' and p_media_id is not null
        then format(' and t.id <> %L::uuid', p_media_id)
      else ''
    end;
    return query execute format(
      'select %L::text, %L::text, to_jsonb(t)->>''id'',
              coalesce(to_jsonb(t)->>''name'', to_jsonb(t)->>''title'',
                       to_jsonb(t)->>''title_he'', to_jsonb(t)->>''name_he'',
                       to_jsonb(t)->>''file_name'')
       from public.%I t
       where t.%I::text like $1 escape ''\''%s
       limit 50',
      c.tbl, c.col, c.tbl, c.col, own_row
    ) using pattern;
  end loop;

  if p_media_id is not null then
    return query
      select 'entity_media'::text,
             em.entity_type || ':' || em.role,
             em.entity_id::text,
             case em.entity_type
               when 'business' then (select b.name from businesses b where b.id = em.entity_id)
               when 'neighborhood' then (select n.name from neighborhoods n where n.id = em.entity_id)
             end
      from entity_media em
      where em.media_id = p_media_id;
  end if;
end;
$$;

revoke all on function public.media_usage(text, uuid) from public, anon;
grant execute on function public.media_usage(text, uuid) to authenticated;
