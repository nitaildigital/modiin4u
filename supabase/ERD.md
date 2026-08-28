# Modiin4u Control Center — ERD

## Core Entities & Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTH & USERS                                 │
│                                                                     │
│  auth.users ──1:1──► profiles ◄──── favorites                      │
│                         │            (business/article/event)       │
│                         │                                           │
│                    admin_users ──► admin_roles                      │
│                                      │                              │
│                              admin_role_permissions                 │
│                              (module + action)                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        BUSINESSES                                   │
│                                                                     │
│  businesses ──► neighborhoods                                       │
│      │  │                                                           │
│      │  ├── business_hours (7 days)                                 │
│      │  ├── business_attribute_defs ──► business_attribute_values   │
│      │  ├── reviews                                                 │
│      │  ├── offers ──► offer_claims                                 │
│      │  ├── commercial_agreements                                   │
│      │  ├── subscriptions                                           │
│      │  ├── revenue_transactions                                    │
│      │  ├── campaigns                                               │
│      │  └── push_campaigns                                          │
│      │                                                              │
│      └── entity_categories / entity_tags / entity_media             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        CONTENT                                      │
│                                                                     │
│  articles ──► article_versions                                      │
│      │   └── article_businesses (M:M with businesses)               │
│      └── entity_categories / entity_tags / entity_media             │
│                                                                     │
│  events ──► event_attendees                                         │
│      │  └── business (optional link)                                │
│      └── entity_categories / entity_tags / entity_media             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     SHARED / TAXONOMY                               │
│                                                                     │
│  categories (hierarchical, scoped: business/article/event)          │
│      └── parent_id (self-ref)                                       │
│                                                                     │
│  tags ◄──── entity_tags (polymorphic)                               │
│  media ◄──── entity_media (polymorphic: cover/logo/gallery/og)      │
│  neighborhoods (used by: profiles, businesses, offers, challenges)  │
│                                                                     │
│  comments (polymorphic: article/event/business, threaded)           │
│  reports (polymorphic: review/comment/business/user)                │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      ADVERTISING                                    │
│                                                                     │
│  ad_placements ◄── campaigns                                        │
│                       ├── business (advertiser)                     │
│                       └── salesperson (admin_user)                  │
│                                                                     │
│  push_campaigns ──► business (optional sponsor)                     │
│  push_automations (rule-based triggers)                             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       COMMERCE                                      │
│                                                                     │
│  commercial_agreements ──► business                                 │
│        │                                                            │
│        ├── subscriptions                                            │
│        └── revenue_transactions ──► payments                        │
│                                                                     │
│  Flow: Agreement → Transaction → Payment                            │
│  Types: subscription, banner, push, featured, sponsored, custom     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     GAMIFICATION                                    │
│                                                                     │
│  point_rules (admin-managed values)                                 │
│  point_transactions ──► profiles                                    │
│                                                                     │
│  games ──► game_sessions ──► profiles                               │
│  challenges ──► challenge_participants ──► profiles                  │
│  daily_steps ──► profiles                                           │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     APP CONFIG                                      │
│                                                                     │
│  home_blocks (ordered, targetable, publishable)                     │
│  feature_flags (per-platform rollout)                               │
│  remote_config (text overrides without app update)                  │
│  app_settings (global key-value)                                    │
│  redirects (SEO 301/302)                                            │
│  search_synonyms                                                    │
│  deep_links                                                         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      SYSTEM                                         │
│                                                                     │
│  audit_logs (who, what, when, before/after)                         │
│  trash (soft-delete with 30-day expiry)                             │
│  entity_versions (restore previous versions)                        │
│  admin_notifications (internal team alerts)                         │
└─────────────────────────────────────────────────────────────────────┘
```

## Table Count: 42 tables

### V1 Priority (must have for launch):
1. profiles, admin_users, admin_roles, admin_role_permissions
2. neighborhoods, categories, tags, entity_tags, entity_categories
3. businesses, business_hours, business_attribute_defs/values
4. articles, article_versions
5. events, event_attendees
6. reviews, comments, reports
7. offers, offer_claims
8. media, entity_media
9. ad_placements, campaigns
10. push_campaigns
11. commercial_agreements, subscriptions, revenue_transactions, payments
12. home_blocks
13. feature_flags, remote_config, app_settings
14. audit_logs, trash

### V2 (with features):
- games, game_sessions
- challenges, challenge_participants, daily_steps
- point_rules, point_transactions
- push_automations
- entity_versions (full)
- redirects, search_synonyms, deep_links
- admin_notifications

## Key Design Decisions

1. **Polymorphic junctions** (entity_tags, entity_media, entity_categories, comments, reports, favorites) — one table serves all entity types via `entity_type` + `entity_id`
2. **Unified categories** — scoped by `scope` field, hierarchical via `parent_id`
3. **Shared media library** — media table + entity_media junction
4. **Dynamic business attributes** — admin defines attributes per category, businesses fill values
5. **Commercial = per-product** — one business can have multiple agreements (subscription + banner + push)
6. **Revenue ledger** — every shekel is a row in revenue_transactions, linked to its source
7. **Audit everything** — before/after JSON snapshots
8. **Soft delete** — trash table with 30-day auto-expiry
9. **Home Builder** — ordered blocks with targeting, versioning, publish workflow
10. **RLS strategy** — is_admin() helper, has_permission(module, action) for granular access
