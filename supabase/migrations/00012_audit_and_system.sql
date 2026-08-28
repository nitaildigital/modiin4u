-- ============================================================
-- Modiin4u Control Center — Migration 00012
-- Audit Log, Trash (Soft Delete), System Health
-- ============================================================

-- ─── Audit Log ───
create table audit_logs (
  id            uuid primary key default gen_random_uuid(),
  admin_id      uuid references admin_users(id) on delete set null,
  action        audit_action not null,
  entity_type   text not null,           -- 'business', 'article', 'user', etc.
  entity_id     uuid,
  before_data   jsonb,
  after_data    jsonb,
  ip_address    inet,
  user_agent    text,
  created_at    timestamptz not null default now()
);

create index idx_audit_entity on audit_logs(entity_type, entity_id);
create index idx_audit_admin on audit_logs(admin_id);
create index idx_audit_date on audit_logs(created_at desc);

-- ─── Soft Delete Trash ───
create table trash (
  id            uuid primary key default gen_random_uuid(),
  entity_type   text not null,
  entity_id     uuid not null,
  entity_data   jsonb not null,          -- full snapshot for restore
  deleted_by    uuid references admin_users(id),
  deleted_at    timestamptz not null default now(),
  expires_at    timestamptz not null default (now() + interval '30 days')
);

create index idx_trash_entity on trash(entity_type, entity_id);

-- ─── Version History (for important entities) ───
create table entity_versions (
  id            uuid primary key default gen_random_uuid(),
  entity_type   text not null,
  entity_id     uuid not null,
  version       int not null,
  data          jsonb not null,
  changed_by    uuid references profiles(id),
  created_at    timestamptz not null default now()
);

create index idx_versions_entity on entity_versions(entity_type, entity_id);

-- ─── System Notifications (internal, for admin team) ───
create table admin_notifications (
  id            uuid primary key default gen_random_uuid(),
  admin_id      uuid references admin_users(id) on delete cascade,
  title         text not null,
  body          text,
  type          text not null default 'info',  -- 'info', 'warning', 'error', 'action'
  link          text,                           -- deep link to relevant screen
  is_read       boolean not null default false,
  created_at    timestamptz not null default now()
);

create index idx_admin_notifs_user on admin_notifications(admin_id, is_read);
