-- ============================================================
-- Feed Items Table
-- Drop into: supabase/migrations/
-- ============================================================

-- Feed item type enum
create type public.feed_item_type as enum (
  'streak',
  'activity',
  'challenge',
  'tournament'
);

-- Main feed_items table
create table if not exists public.feed_items (
  id           uuid primary key default gen_random_uuid(),
  type         public.feed_item_type not null,
  user_id      uuid references public.profile(user_id) on delete set null,
  created_at   timestamptz not null default now(),
  payload      jsonb not null default '{}'
);

-- Index for fast feed queries (newest first)
create index feed_items_created_at_idx on public.feed_items (created_at desc);
create index feed_items_type_idx       on public.feed_items (type);

-- RLS
alter table public.feed_items enable row level security;

-- Everyone authenticated can read the feed
create policy "Authenticated users can read feed"
  on public.feed_items
  for select
  to authenticated
  using (true);

-- Users can insert their own feed items
create policy "Users can insert own feed items"
  on public.feed_items
  for insert
  to authenticated
  with check (auth.uid() = user_id or user_id is null);

-- ============================================================
-- Dummy Data  (matches the hardcoded UI exactly)
-- user_id is NULL here — safe for demo; swap with real UUIDs later
-- ============================================================

insert into public.feed_items (type, created_at, payload) values

-- ── STREAK items ─────────────────────────────────────────────
(
  'streak',
  now() - interval '2 hours',
  '{
    "name": "David and Alana",
    "avatars": ["D", "A"],
    "achievement": "Reached a 475 day Friend Streak!",
    "days": 475,
    "reactions": ["🎉", "💪", "😊"],
    "reaction_count": 12742,
    "show_badge": false
  }'::jsonb
),
(
  'streak',
  now() - interval '4 hours',
  '{
    "name": "HB",
    "avatars": ["H"],
    "achievement": "Reached a DuoLingo Streak of 29!",
    "days": 29,
    "reactions": ["🎉", "💪", "😊"],
    "reaction_count": 892,
    "show_badge": true
  }'::jsonb
),
(
  'streak',
  now() - interval '6 hours',
  '{
    "name": "Emma & Jake",
    "avatars": ["E", "J"],
    "achievement": "Completed 100 workouts together this year!",
    "days": 100,
    "reactions": ["🎉", "🔥", "💪"],
    "reaction_count": 234,
    "show_badge": false
  }'::jsonb
),

-- ── TOURNAMENT items ──────────────────────────────────────────
(
  'tournament',
  now() - interval '3 hours',
  '{
    "name": "Paula",
    "avatars": ["P"],
    "achievement": "Won the Diamond Tournament Finale 9 times!",
    "icon": "💎",
    "reactions": ["🎉", "💪", "😊"],
    "reaction_count": 3412,
    "show_badge": false
  }'::jsonb
),

-- ── ACTIVITY items ────────────────────────────────────────────
(
  'activity',
  now() - interval '2 hours',
  '{
    "user_name": "Sarah Mitchell",
    "user_avatar": "S",
    "caption": "Morning grind! 💪 Hit a new PR on deadlifts today - 315lbs! Feeling stronger every day.",
    "stats": {
      "Duration": "1h 15m",
      "Calories": "420 kcal",
      "PR": "Deadlift 315lbs"
    },
    "likes": 87,
    "comments": 12
  }'::jsonb
),
(
  'activity',
  now() - interval '5 hours',
  '{
    "user_name": "Mike Johnson",
    "user_avatar": "M",
    "caption": "Leg day complete! 🦵 Nothing beats that post-workout feeling.",
    "stats": {
      "Duration": "50m",
      "Exercises": "8 sets",
      "Calories": "380 kcal"
    },
    "likes": 54,
    "comments": 8
  }'::jsonb
),
(
  'activity',
  now() - interval '1 hour',
  '{
    "user_name": "Alex Torres",
    "user_avatar": "A",
    "caption": "Early morning run before the gym! 🏃‍♂️ The sunrise was incredible.",
    "stats": {
      "Distance": "5.2 km",
      "Pace": "5:30 /km",
      "Time": "28m 36s"
    },
    "likes": 42,
    "comments": 5
  }'::jsonb
),
(
  'activity',
  now() - interval '3 hours',
  '{
    "user_name": "Jessica Park",
    "user_avatar": "J",
    "caption": "New yoga routine unlocked! Feeling zen and flexible 🧘‍♀️",
    "stats": {
      "Duration": "45m",
      "Type": "Vinyasa Flow",
      "Calories": "180 kcal"
    },
    "likes": 67,
    "comments": 9
  }'::jsonb
),

-- ── CHALLENGE items ───────────────────────────────────────────
(
  'challenge',
  now() - interval '1 day',
  '{
    "title": "30-Day Push-Up Challenge",
    "participants": 1247,
    "days_left": 12,
    "progress": 0.6
  }'::jsonb
);