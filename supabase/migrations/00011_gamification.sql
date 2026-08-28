-- ============================================================
-- Modiin4u Control Center — Migration 00011
-- Points, Games, Steps, Challenges, Leaderboards
-- ============================================================

-- ─── Points Rules (admin-managed, not hard-coded) ───
create table point_rules (
  id           uuid primary key default gen_random_uuid(),
  action       text not null unique,     -- 'signup', 'review', 'invite', 'daily_steps', 'game_win'
  label        text not null,            -- 'הרשמה', 'כתיבת ביקורת'
  points       int not null,
  max_per_day  int,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger point_rules_updated_at before update on point_rules
  for each row execute function update_updated_at();

-- ─── Points Ledger (every point transaction) ───
create table point_transactions (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references profiles(id) on delete cascade,
  amount       int not null,             -- positive = earned, negative = spent
  reason       text not null,
  source       text not null,            -- 'system', 'admin', 'game', 'steps'
  rule_id      uuid references point_rules(id),
  admin_id     uuid references admin_users(id),  -- if manually given by admin
  created_at   timestamptz not null default now()
);

create index idx_points_profile on point_transactions(profile_id);

-- ─── Games ───
create table games (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  slug         text not null unique,
  description  text,
  thumbnail    text,
  game_url     text not null,           -- WebView URL
  is_active    boolean not null default true,
  is_featured  boolean not null default false,
  points_reward int not null default 0,
  start_at     timestamptz,
  end_at       timestamptz,
  sort_order   int not null default 0,

  -- Stats
  player_count   int not null default 0,
  session_count  int not null default 0,
  avg_session_sec int not null default 0,

  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger games_updated_at before update on games
  for each row execute function update_updated_at();

-- ─── Game Sessions ───
create table game_sessions (
  id           uuid primary key default gen_random_uuid(),
  game_id      uuid not null references games(id) on delete cascade,
  profile_id   uuid not null references profiles(id) on delete cascade,
  score        int,
  duration_sec int,
  created_at   timestamptz not null default now()
);

-- ─── Step Challenges ───
create table challenges (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  description     text,
  image_url       text,
  challenge_type  text not null default 'steps',  -- 'steps', 'neighborhood', 'custom'
  goal            int not null,                    -- e.g., 50000 steps
  reward_points   int not null default 0,

  -- Targeting
  neighborhoods   uuid[],
  start_at        timestamptz not null,
  end_at          timestamptz not null,

  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger challenges_updated_at before update on challenges
  for each row execute function update_updated_at();

-- ─── Challenge Participants ───
create table challenge_participants (
  id            uuid primary key default gen_random_uuid(),
  challenge_id  uuid not null references challenges(id) on delete cascade,
  profile_id    uuid not null references profiles(id) on delete cascade,
  progress      int not null default 0,
  completed     boolean not null default false,
  completed_at  timestamptz,
  joined_at     timestamptz not null default now(),
  unique (challenge_id, profile_id)
);

-- ─── Daily Steps ───
create table daily_steps (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references profiles(id) on delete cascade,
  date         date not null,
  steps        int not null default 0,
  unique (profile_id, date)
);
