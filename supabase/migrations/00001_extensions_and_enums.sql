-- ============================================================
-- Modiin4u Control Center — Migration 00001
-- Extensions & Enum Types
-- ============================================================

-- gen_random_uuid() is built into Postgres 13+, no extension needed
-- PostGIS can be enabled later if needed for geo queries

-- ─── User & Auth ───
create type user_role as enum ('resident', 'business_owner', 'editor', 'moderator', 'sales', 'finance', 'support', 'analyst', 'super_admin');

-- ─── Business ───
create type business_status as enum ('draft', 'pending', 'active', 'suspended', 'closed');
create type price_level as enum ('₪', '₪₪', '₪₪₪', '₪₪₪₪');
create type kosher_level as enum ('none', 'rabbanut', 'mehadrin', 'badatz', 'other');

-- ─── Content ───
create type article_status as enum ('draft', 'published', 'archived', 'trash');
create type event_status as enum ('draft', 'pending', 'published', 'cancelled', 'past');
create type offer_status as enum ('draft', 'active', 'expired', 'redeemed_out');

-- ─── Advertising ───
create type campaign_status as enum ('draft', 'scheduled', 'active', 'paused', 'ended');
create type push_status as enum ('draft', 'scheduled', 'sending', 'sent', 'failed');

-- ─── Commerce ───
create type payment_status as enum ('pending', 'paid', 'partial', 'overdue', 'cancelled', 'refunded');
create type subscription_status as enum ('trial', 'active', 'paused', 'past_due', 'cancelled');
create type agreement_type as enum ('subscription', 'banner', 'push', 'featured', 'sponsored', 'custom');
create type billing_cycle as enum ('monthly', 'quarterly', 'semi_annual', 'annual', 'one_time');

-- ─── Moderation ───
create type moderation_status as enum ('pending', 'approved', 'rejected', 'hidden');
create type report_reason as enum ('spam', 'offensive', 'fake', 'personal_info', 'harassment', 'other');

-- ─── Home Builder ───
create type block_type as enum (
  'hero', 'alert', 'news_grid', 'event_carousel', 'business_carousel',
  'restaurant_carousel', 'banner', 'offers', 'game', 'ai_search',
  'map_preview', 'real_estate', 'steps_challenge', 'custom_promo', 'weather'
);

-- ─── Audit ───
create type audit_action as enum (
  'create', 'update', 'delete', 'restore',
  'approve', 'reject', 'suspend', 'ban', 'unban',
  'publish', 'unpublish', 'archive',
  'login', 'logout', 'change_role', 'change_password',
  'send_push', 'activate_campaign', 'change_price'
);
