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

create unique index if not exists workout_plans_one_active_per_user
  on public.workout_plans (user_id)
  where is_active = true;

create index if not exists workout_plans_user_id_idx
  on public.workout_plans (user_id, updated_at desc);

create index if not exists workout_plan_exercises_plan_id_idx
  on public.workout_plan_exercises (workout_plan_id, sort_order);

create index if not exists workout_plan_sets_exercise_id_idx
  on public.workout_plan_sets (workout_plan_exercise_id, sort_order);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_plans_name_non_empty'
  ) then
    alter table public.workout_plans
      add constraint workout_plans_name_non_empty
      check (char_length(trim(name)) > 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_plan_sets_reps_non_negative'
  ) then
    alter table public.workout_plan_sets
      add constraint workout_plan_sets_reps_non_negative
      check (reps >= 0);
  end if;
end;
$$;

alter table public.workout_plans enable row level security;
alter table public.workout_plan_exercises enable row level security;
alter table public.workout_plan_sets enable row level security;

create policy "Users can read own workout plans"
  on public.workout_plans
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own workout plans"
  on public.workout_plans
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own workout plans"
  on public.workout_plans
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own workout plans"
  on public.workout_plans
  for delete
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can read own workout plan exercises"
  on public.workout_plan_exercises
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.workout_plans wp
      where wp.id = workout_plan_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can insert own workout plan exercises"
  on public.workout_plan_exercises
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.workout_plans wp
      where wp.id = workout_plan_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can update own workout plan exercises"
  on public.workout_plan_exercises
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.workout_plans wp
      where wp.id = workout_plan_id
        and wp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.workout_plans wp
      where wp.id = workout_plan_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can delete own workout plan exercises"
  on public.workout_plan_exercises
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.workout_plans wp
      where wp.id = workout_plan_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can read own workout plan sets"
  on public.workout_plan_sets
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.workout_plan_exercises wpe
      join public.workout_plans wp on wp.id = wpe.workout_plan_id
      where wpe.id = workout_plan_exercise_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can insert own workout plan sets"
  on public.workout_plan_sets
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.workout_plan_exercises wpe
      join public.workout_plans wp on wp.id = wpe.workout_plan_id
      where wpe.id = workout_plan_exercise_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can update own workout plan sets"
  on public.workout_plan_sets
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.workout_plan_exercises wpe
      join public.workout_plans wp on wp.id = wpe.workout_plan_id
      where wpe.id = workout_plan_exercise_id
        and wp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.workout_plan_exercises wpe
      join public.workout_plans wp on wp.id = wpe.workout_plan_id
      where wpe.id = workout_plan_exercise_id
        and wp.user_id = auth.uid()
    )
  );

create policy "Users can delete own workout plan sets"
  on public.workout_plan_sets
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.workout_plan_exercises wpe
      join public.workout_plans wp on wp.id = wpe.workout_plan_id
      where wpe.id = workout_plan_exercise_id
        and wp.user_id = auth.uid()
    )
  );

create or replace function public.set_workout_plan_updated_at()
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
for each row
execute function public.set_workout_plan_updated_at();
