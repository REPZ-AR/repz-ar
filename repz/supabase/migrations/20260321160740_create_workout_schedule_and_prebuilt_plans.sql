create table if not exists public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  notes text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workout_plan_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  sort_order integer not null default 0,
  exercise_key text not null,
  display_name text not null,
  workout_type text,
  asset_path text,
  target_joints text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.workout_plan_sets (
  id uuid primary key default gen_random_uuid(),
  workout_plan_exercise_id uuid not null references public.workout_plan_exercises(id) on delete cascade,
  sort_order integer not null default 0,
  reps integer not null default 0,
  variation text not null default 'Standard',
  created_at timestamptz not null default now()
);

create table if not exists public.workout_plan_schedule (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day_of_week smallint not null,
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prebuilt_workout_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  difficulty text,
  goal_tag text,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prebuilt_workout_plan_exercises (
  id uuid primary key default gen_random_uuid(),
  prebuilt_workout_plan_id uuid not null references public.prebuilt_workout_plans(id) on delete cascade,
  sort_order integer not null default 0,
  exercise_key text not null,
  display_name text not null,
  workout_type text,
  asset_path text,
  target_joints text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.prebuilt_workout_plan_sets (
  id uuid primary key default gen_random_uuid(),
  prebuilt_workout_plan_exercise_id uuid not null references public.prebuilt_workout_plan_exercises(id) on delete cascade,
  sort_order integer not null default 0,
  reps integer not null default 0,
  variation text not null default 'Standard',
  created_at timestamptz not null default now()
);

alter table public.workout_progress
  add column if not exists current_workout_plan_id uuid references public.workout_plans(id) on delete set null;

create unique index if not exists workout_plans_one_active_per_user
  on public.workout_plans (user_id)
  where is_active = true;

create unique index if not exists workout_plan_schedule_one_per_day
  on public.workout_plan_schedule (user_id, day_of_week);

create index if not exists workout_plans_user_id_idx
  on public.workout_plans (user_id, updated_at desc);

create index if not exists workout_plan_exercises_plan_id_idx
  on public.workout_plan_exercises (workout_plan_id, sort_order);

create index if not exists workout_plan_sets_exercise_id_idx
  on public.workout_plan_sets (workout_plan_exercise_id, sort_order);

create index if not exists workout_plan_schedule_user_day_idx
  on public.workout_plan_schedule (user_id, day_of_week);

create index if not exists prebuilt_workout_plans_featured_idx
  on public.prebuilt_workout_plans (is_featured, created_at);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'workout_plans_name_non_empty'
  ) then
    alter table public.workout_plans
      add constraint workout_plans_name_non_empty
      check (char_length(trim(name)) > 0);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'workout_plan_schedule_day_of_week_check'
  ) then
    alter table public.workout_plan_schedule
      add constraint workout_plan_schedule_day_of_week_check
      check (day_of_week between 1 and 7);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'workout_plan_sets_reps_non_negative'
  ) then
    alter table public.workout_plan_sets
      add constraint workout_plan_sets_reps_non_negative
      check (reps >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'prebuilt_workout_plan_sets_reps_non_negative'
  ) then
    alter table public.prebuilt_workout_plan_sets
      add constraint prebuilt_workout_plan_sets_reps_non_negative
      check (reps >= 0);
  end if;
end;
$$;

alter table public.workout_plans enable row level security;
alter table public.workout_plan_exercises enable row level security;
alter table public.workout_plan_sets enable row level security;
alter table public.workout_plan_schedule enable row level security;
alter table public.prebuilt_workout_plans enable row level security;
alter table public.prebuilt_workout_plan_exercises enable row level security;
alter table public.prebuilt_workout_plan_sets enable row level security;

drop policy if exists "Users can read own workout plans" on public.workout_plans;
create policy "Users can read own workout plans"
  on public.workout_plans for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own workout plans" on public.workout_plans;
create policy "Users can insert own workout plans"
  on public.workout_plans for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own workout plans" on public.workout_plans;
create policy "Users can update own workout plans"
  on public.workout_plans for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own workout plans" on public.workout_plans;
create policy "Users can delete own workout plans"
  on public.workout_plans for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read own workout plan exercises" on public.workout_plan_exercises;
create policy "Users can read own workout plan exercises"
  on public.workout_plan_exercises for select to authenticated
  using (exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can insert own workout plan exercises" on public.workout_plan_exercises;
create policy "Users can insert own workout plan exercises"
  on public.workout_plan_exercises for insert to authenticated
  with check (exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can update own workout plan exercises" on public.workout_plan_exercises;
create policy "Users can update own workout plan exercises"
  on public.workout_plan_exercises for update to authenticated
  using (exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can delete own workout plan exercises" on public.workout_plan_exercises;
create policy "Users can delete own workout plan exercises"
  on public.workout_plan_exercises for delete to authenticated
  using (exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can read own workout plan sets" on public.workout_plan_sets;
create policy "Users can read own workout plan sets"
  on public.workout_plan_sets for select to authenticated
  using (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can insert own workout plan sets" on public.workout_plan_sets;
create policy "Users can insert own workout plan sets"
  on public.workout_plan_sets for insert to authenticated
  with check (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can update own workout plan sets" on public.workout_plan_sets;
create policy "Users can update own workout plan sets"
  on public.workout_plan_sets for update to authenticated
  using (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id and wp.user_id = auth.uid()
  ))
  with check (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can delete own workout plan sets" on public.workout_plan_sets;
create policy "Users can delete own workout plan sets"
  on public.workout_plan_sets for delete to authenticated
  using (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id and wp.user_id = auth.uid()
  ));

drop policy if exists "Users can read own workout plan schedule" on public.workout_plan_schedule;
create policy "Users can read own workout plan schedule"
  on public.workout_plan_schedule for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own workout plan schedule" on public.workout_plan_schedule;
create policy "Users can insert own workout plan schedule"
  on public.workout_plan_schedule for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own workout plan schedule" on public.workout_plan_schedule;
create policy "Users can update own workout plan schedule"
  on public.workout_plan_schedule for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own workout plan schedule" on public.workout_plan_schedule;
create policy "Users can delete own workout plan schedule"
  on public.workout_plan_schedule for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Authenticated users can read prebuilt workout plans" on public.prebuilt_workout_plans;
create policy "Authenticated users can read prebuilt workout plans"
  on public.prebuilt_workout_plans for select to authenticated
  using (true);

drop policy if exists "Authenticated users can read prebuilt workout plan exercises" on public.prebuilt_workout_plan_exercises;
create policy "Authenticated users can read prebuilt workout plan exercises"
  on public.prebuilt_workout_plan_exercises for select to authenticated
  using (exists (
    select 1 from public.prebuilt_workout_plans pwp
    where pwp.id = prebuilt_workout_plan_id
  ));

drop policy if exists "Authenticated users can read prebuilt workout plan sets" on public.prebuilt_workout_plan_sets;
create policy "Authenticated users can read prebuilt workout plan sets"
  on public.prebuilt_workout_plan_sets for select to authenticated
  using (exists (
    select 1
    from public.prebuilt_workout_plan_exercises pwpe
    where pwpe.id = prebuilt_workout_plan_exercise_id
  ));

create or replace function public.set_workout_entity_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists workout_plans_set_updated_at on public.workout_plans;
create trigger workout_plans_set_updated_at
before update on public.workout_plans
for each row execute function public.set_workout_entity_updated_at();

drop trigger if exists workout_plan_schedule_set_updated_at on public.workout_plan_schedule;
create trigger workout_plan_schedule_set_updated_at
before update on public.workout_plan_schedule
for each row execute function public.set_workout_entity_updated_at();

drop trigger if exists prebuilt_workout_plans_set_updated_at on public.prebuilt_workout_plans;
create trigger prebuilt_workout_plans_set_updated_at
before update on public.prebuilt_workout_plans
for each row execute function public.set_workout_entity_updated_at();

do $$
declare
  beginner_id uuid;
  strength_id uuid;
  recovery_id uuid;
  ex_id uuid;
begin
  if not exists (select 1 from public.prebuilt_workout_plans) then
    insert into public.prebuilt_workout_plans (name, description, difficulty, goal_tag, is_featured)
    values
      ('Beginner Upper Body', 'A simple upper-body starter plan for lighter training days.', 'Beginner', 'Strength', true)
    returning id into beginner_id;

    insert into public.prebuilt_workout_plan_exercises (
      prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints
    ) values (
      beginner_id, 0, 'hammer_curl', 'Hammer Curl', 'CURLS', 'assets/data/baseline_curls.json', array['leftShoulder','leftElbow','leftWrist']
    ) returning id into ex_id;

    insert into public.prebuilt_workout_plan_sets (prebuilt_workout_plan_exercise_id, sort_order, reps, variation)
    values
      (ex_id, 0, 12, 'Standard'),
      (ex_id, 1, 12, 'Slow Eccentric'),
      (ex_id, 2, 10, 'Tempo');

    insert into public.prebuilt_workout_plan_exercises (
      prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints
    ) values (
      beginner_id, 1, 'lateral_raise', 'Lateral Raise', 'CURLS', 'assets/data/baseline_curls.json', array['leftShoulder','leftElbow']
    ) returning id into ex_id;

    insert into public.prebuilt_workout_plan_sets (prebuilt_workout_plan_exercise_id, sort_order, reps, variation)
    values
      (ex_id, 0, 12, 'Standard'),
      (ex_id, 1, 10, 'Tempo'),
      (ex_id, 2, 10, 'Pause Reps');

    insert into public.prebuilt_workout_plans (name, description, difficulty, goal_tag, is_featured)
    values
      ('Strength Foundation', 'A lower-body and core focused pre-built session.', 'Intermediate', 'Foundation', true)
    returning id into strength_id;

    insert into public.prebuilt_workout_plan_exercises (
      prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints
    ) values (
      strength_id, 0, 'bodyweight_squat', 'Bodyweight Squat', 'SQUATS', 'assets/data/baseline_squat.json', array['leftHip','leftKnee','leftAnkle']
    ) returning id into ex_id;

    insert into public.prebuilt_workout_plan_sets (prebuilt_workout_plan_exercise_id, sort_order, reps, variation)
    values
      (ex_id, 0, 15, 'Standard'),
      (ex_id, 1, 12, 'Pause Reps'),
      (ex_id, 2, 10, 'Tempo');

    insert into public.prebuilt_workout_plan_exercises (
      prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints
    ) values (
      strength_id, 1, 'plank_hold', 'Plank Hold', 'PLANKS', 'assets/data/baseline_plank.json', array['leftShoulder','leftHip','leftAnkle']
    ) returning id into ex_id;

    insert into public.prebuilt_workout_plan_sets (prebuilt_workout_plan_exercise_id, sort_order, reps, variation)
    values
      (ex_id, 0, 30, 'Standard'),
      (ex_id, 1, 30, 'Single Arm'),
      (ex_id, 2, 45, 'Tempo');

    insert into public.prebuilt_workout_plans (name, description, difficulty, goal_tag, is_featured)
    values
      ('Recovery Flow', 'A light session for movement quality and lower fatigue days.', 'Beginner', 'Recovery', false)
    returning id into recovery_id;

    insert into public.prebuilt_workout_plan_exercises (
      prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints
    ) values (
      recovery_id, 0, 'plank_hold', 'Plank Hold', 'PLANKS', 'assets/data/baseline_plank.json', array['leftShoulder','leftHip','leftAnkle']
    ) returning id into ex_id;

    insert into public.prebuilt_workout_plan_sets (prebuilt_workout_plan_exercise_id, sort_order, reps, variation)
    values
      (ex_id, 0, 20, 'Standard'),
      (ex_id, 1, 20, 'Tempo');

    insert into public.prebuilt_workout_plan_exercises (
      prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints
    ) values (
      recovery_id, 1, 'treadmill', 'Treadmill', null, null, '{}'
    ) returning id into ex_id;

    insert into public.prebuilt_workout_plan_sets (prebuilt_workout_plan_exercise_id, sort_order, reps, variation)
    values
      (ex_id, 0, 10, 'Standard'),
      (ex_id, 1, 10, 'Incline');
  end if;
end;
$$;
