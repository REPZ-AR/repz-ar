alter table public.workout_plans
  add column if not exists plan_scope text not null default 'personal',
  add column if not exists trainer_id uuid references auth.users(id) on delete set null,
  add column if not exists assigned_client_id uuid references auth.users(id) on delete set null,
  add column if not exists source_workout_plan_id uuid references public.workout_plans(id) on delete set null,
  add column if not exists is_read_only boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_plans_plan_scope_check'
  ) then
    alter table public.workout_plans
      add constraint workout_plans_plan_scope_check
      check (plan_scope in ('personal', 'trainer_template', 'assigned_copy'));
  end if;
end;
$$;

create table if not exists public.workout_plan_assignments (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid not null references auth.users(id) on delete cascade,
  trainer_workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  client_workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workout_schedule_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trainer_id uuid references auth.users(id) on delete cascade,
  assignment_id uuid references public.workout_plan_assignments(id) on delete cascade,
  name text not null,
  source_type text not null default 'self',
  is_active boolean not null default false,
  is_read_only boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workout_schedule_profile_days (
  id uuid primary key default gen_random_uuid(),
  schedule_profile_id uuid not null references public.workout_schedule_profiles(id) on delete cascade,
  day_of_week smallint not null,
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_plan_assignments_status_check'
  ) then
    alter table public.workout_plan_assignments
      add constraint workout_plan_assignments_status_check
      check (status in ('active', 'archived'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_schedule_profiles_source_type_check'
  ) then
    alter table public.workout_schedule_profiles
      add constraint workout_schedule_profiles_source_type_check
      check (source_type in ('self', 'trainer_proposed'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_schedule_profile_days_day_of_week_check'
  ) then
    alter table public.workout_schedule_profile_days
      add constraint workout_schedule_profile_days_day_of_week_check
      check (day_of_week between 1 and 7);
  end if;
end;
$$;

create unique index if not exists workout_plan_assignments_unique_active
  on public.workout_plan_assignments (trainer_id, client_id, trainer_workout_plan_id)
  where status = 'active';

create unique index if not exists workout_schedule_profiles_one_active_per_user
  on public.workout_schedule_profiles (user_id)
  where is_active = true;

create unique index if not exists workout_schedule_profile_days_unique_day
  on public.workout_schedule_profile_days (schedule_profile_id, day_of_week);

create index if not exists workout_plans_scope_user_idx
  on public.workout_plans (user_id, plan_scope, updated_at desc);

create index if not exists workout_plans_trainer_client_idx
  on public.workout_plans (trainer_id, assigned_client_id, plan_scope);

create index if not exists workout_plan_assignments_client_idx
  on public.workout_plan_assignments (client_id, trainer_id, updated_at desc);

create index if not exists workout_schedule_profiles_user_idx
  on public.workout_schedule_profiles (user_id, is_active, updated_at desc);

create index if not exists workout_schedule_profile_days_profile_idx
  on public.workout_schedule_profile_days (schedule_profile_id, day_of_week);

alter table public.workout_plan_assignments enable row level security;
alter table public.workout_schedule_profiles enable row level security;
alter table public.workout_schedule_profile_days enable row level security;

drop policy if exists "Users can read own workout plans" on public.workout_plans;
drop policy if exists "Users can insert own workout plans" on public.workout_plans;
drop policy if exists "Users can update own workout plans" on public.workout_plans;
drop policy if exists "Users can delete own workout plans" on public.workout_plans;
drop policy if exists "Users can read role-aware workout plans" on public.workout_plans;
create policy "Users can read role-aware workout plans"
  on public.workout_plans for select to authenticated
  using (
    auth.uid() = user_id
    or auth.uid() = trainer_id
    or (
      assigned_client_id is not null and exists (
        select 1
        from public.trainer_client tc
        where tc.trainer_id = auth.uid()
          and tc.client_id = assigned_client_id
      )
    )
  );

drop policy if exists "Users can insert role-aware workout plans" on public.workout_plans;
create policy "Users can insert role-aware workout plans"
  on public.workout_plans for insert to authenticated
  with check (
    (
      auth.uid() = user_id
      and plan_scope = 'personal'
      and trainer_id is null
      and assigned_client_id is null
    ) or (
      auth.uid() = user_id
      and plan_scope = 'trainer_template'
      and trainer_id = auth.uid()
      and assigned_client_id is null
    ) or (
      auth.uid() = trainer_id
      and plan_scope = 'assigned_copy'
      and assigned_client_id is not null
      and is_read_only = true
      and exists (
        select 1
        from public.trainer_client tc
        where tc.trainer_id = auth.uid()
          and tc.client_id = assigned_client_id
      )
    )
  );

drop policy if exists "Users can update role-aware workout plans" on public.workout_plans;
create policy "Users can update role-aware workout plans"
  on public.workout_plans for update to authenticated
  using (
    (
      auth.uid() = user_id
      and plan_scope = 'personal'
    ) or (
      auth.uid() = user_id
      and plan_scope = 'trainer_template'
      and trainer_id = auth.uid()
    )
  )
  with check (
    (
      auth.uid() = user_id
      and plan_scope = 'personal'
    ) or (
      auth.uid() = user_id
      and plan_scope = 'trainer_template'
      and trainer_id = auth.uid()
    )
  );

drop policy if exists "Users can delete role-aware workout plans" on public.workout_plans;
create policy "Users can delete role-aware workout plans"
  on public.workout_plans for delete to authenticated
  using (
    (
      auth.uid() = user_id
      and plan_scope = 'personal'
    ) or (
      auth.uid() = user_id
      and plan_scope = 'trainer_template'
      and trainer_id = auth.uid()
    )
  );

drop policy if exists "Users can read own workout plan exercises" on public.workout_plan_exercises;
drop policy if exists "Users can insert own workout plan exercises" on public.workout_plan_exercises;
drop policy if exists "Users can update own workout plan exercises" on public.workout_plan_exercises;
drop policy if exists "Users can delete own workout plan exercises" on public.workout_plan_exercises;
drop policy if exists "Users can read role-aware workout plan exercises" on public.workout_plan_exercises;
create policy "Users can read role-aware workout plan exercises"
  on public.workout_plan_exercises for select to authenticated
  using (exists (
    select 1
    from public.workout_plans wp
    where wp.id = workout_plan_id
      and (
        auth.uid() = wp.user_id
        or auth.uid() = wp.trainer_id
        or (
          wp.assigned_client_id is not null and exists (
            select 1
            from public.trainer_client tc
            where tc.trainer_id = auth.uid()
              and tc.client_id = wp.assigned_client_id
          )
        )
      )
  ));

drop policy if exists "Users can insert role-aware workout plan exercises" on public.workout_plan_exercises;
create policy "Users can insert role-aware workout plan exercises"
  on public.workout_plan_exercises for insert to authenticated
  with check (exists (
    select 1
    from public.workout_plans wp
    where wp.id = workout_plan_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
        or (auth.uid() = wp.trainer_id and wp.plan_scope = 'assigned_copy' and wp.is_read_only = true)
      )
  ));

drop policy if exists "Users can update role-aware workout plan exercises" on public.workout_plan_exercises;
create policy "Users can update role-aware workout plan exercises"
  on public.workout_plan_exercises for update to authenticated
  using (exists (
    select 1
    from public.workout_plans wp
    where wp.id = workout_plan_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
      )
  ))
  with check (exists (
    select 1
    from public.workout_plans wp
    where wp.id = workout_plan_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
      )
  ));

drop policy if exists "Users can delete role-aware workout plan exercises" on public.workout_plan_exercises;
create policy "Users can delete role-aware workout plan exercises"
  on public.workout_plan_exercises for delete to authenticated
  using (exists (
    select 1
    from public.workout_plans wp
    where wp.id = workout_plan_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
      )
  ));

drop policy if exists "Users can read own workout plan sets" on public.workout_plan_sets;
drop policy if exists "Users can insert own workout plan sets" on public.workout_plan_sets;
drop policy if exists "Users can update own workout plan sets" on public.workout_plan_sets;
drop policy if exists "Users can delete own workout plan sets" on public.workout_plan_sets;
drop policy if exists "Users can read role-aware workout plan sets" on public.workout_plan_sets;
create policy "Users can read role-aware workout plan sets"
  on public.workout_plan_sets for select to authenticated
  using (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id
      and (
        auth.uid() = wp.user_id
        or auth.uid() = wp.trainer_id
        or (
          wp.assigned_client_id is not null and exists (
            select 1
            from public.trainer_client tc
            where tc.trainer_id = auth.uid()
              and tc.client_id = wp.assigned_client_id
          )
        )
      )
  ));

drop policy if exists "Users can insert role-aware workout plan sets" on public.workout_plan_sets;
create policy "Users can insert role-aware workout plan sets"
  on public.workout_plan_sets for insert to authenticated
  with check (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
        or (auth.uid() = wp.trainer_id and wp.plan_scope = 'assigned_copy' and wp.is_read_only = true)
      )
  ));

drop policy if exists "Users can update role-aware workout plan sets" on public.workout_plan_sets;
create policy "Users can update role-aware workout plan sets"
  on public.workout_plan_sets for update to authenticated
  using (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
      )
  ))
  with check (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
      )
  ));

drop policy if exists "Users can delete role-aware workout plan sets" on public.workout_plan_sets;
create policy "Users can delete role-aware workout plan sets"
  on public.workout_plan_sets for delete to authenticated
  using (exists (
    select 1
    from public.workout_plan_exercises wpe
    join public.workout_plans wp on wp.id = wpe.workout_plan_id
    where wpe.id = workout_plan_exercise_id
      and (
        (auth.uid() = wp.user_id and wp.plan_scope = 'personal')
        or (auth.uid() = wp.user_id and wp.plan_scope = 'trainer_template' and wp.trainer_id = auth.uid())
      )
  ));

drop policy if exists "Users can read plan assignments" on public.workout_plan_assignments;
create policy "Users can read plan assignments"
  on public.workout_plan_assignments for select to authenticated
  using (
    auth.uid() = trainer_id
    or auth.uid() = client_id
  );

drop policy if exists "Trainers can manage plan assignments" on public.workout_plan_assignments;
create policy "Trainers can manage plan assignments"
  on public.workout_plan_assignments for all to authenticated
  using (
    auth.uid() = trainer_id
    and exists (
      select 1
      from public.trainer_client tc
      where tc.trainer_id = auth.uid()
        and tc.client_id = workout_plan_assignments.client_id
    )
  )
  with check (
    auth.uid() = trainer_id
    and exists (
      select 1
      from public.trainer_client tc
      where tc.trainer_id = auth.uid()
        and tc.client_id = workout_plan_assignments.client_id
    )
  );

drop policy if exists "Users can read schedule profiles" on public.workout_schedule_profiles;
create policy "Users can read schedule profiles"
  on public.workout_schedule_profiles for select to authenticated
  using (
    auth.uid() = user_id
    or auth.uid() = trainer_id
    or exists (
      select 1
      from public.trainer_client tc
      where tc.trainer_id = auth.uid()
        and tc.client_id = workout_schedule_profiles.user_id
    )
  );

drop policy if exists "Clients can manage their own self schedule profiles" on public.workout_schedule_profiles;
create policy "Clients can manage their own self schedule profiles"
  on public.workout_schedule_profiles for all to authenticated
  using (
    auth.uid() = user_id
    and source_type = 'self'
  )
  with check (
    auth.uid() = user_id
    and source_type = 'self'
  );

drop policy if exists "Clients can activate any of their schedule profiles" on public.workout_schedule_profiles;
create policy "Clients can activate any of their schedule profiles"
  on public.workout_schedule_profiles for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Trainers can manage proposed schedule profiles" on public.workout_schedule_profiles;
create policy "Trainers can manage proposed schedule profiles"
  on public.workout_schedule_profiles for all to authenticated
  using (
    auth.uid() = trainer_id
    and source_type = 'trainer_proposed'
    and exists (
      select 1
      from public.trainer_client tc
      where tc.trainer_id = auth.uid()
        and tc.client_id = workout_schedule_profiles.user_id
    )
  )
  with check (
    auth.uid() = trainer_id
    and source_type = 'trainer_proposed'
    and exists (
      select 1
      from public.trainer_client tc
      where tc.trainer_id = auth.uid()
        and tc.client_id = workout_schedule_profiles.user_id
    )
  );

drop policy if exists "Users can read schedule profile days" on public.workout_schedule_profile_days;
create policy "Users can read schedule profile days"
  on public.workout_schedule_profile_days for select to authenticated
  using (exists (
    select 1
    from public.workout_schedule_profiles wsp
    where wsp.id = schedule_profile_id
      and (
        auth.uid() = wsp.user_id
        or auth.uid() = wsp.trainer_id
        or exists (
          select 1
          from public.trainer_client tc
          where tc.trainer_id = auth.uid()
            and tc.client_id = wsp.user_id
        )
      )
  ));

drop policy if exists "Users can manage schedule profile days" on public.workout_schedule_profile_days;
create policy "Users can manage schedule profile days"
  on public.workout_schedule_profile_days for all to authenticated
  using (exists (
    select 1
    from public.workout_schedule_profiles wsp
    where wsp.id = schedule_profile_id
      and (
        (auth.uid() = wsp.user_id and wsp.source_type = 'self')
        or (auth.uid() = wsp.trainer_id and wsp.source_type = 'trainer_proposed')
      )
  ))
  with check (exists (
    select 1
    from public.workout_schedule_profiles wsp
    where wsp.id = schedule_profile_id
      and (
        (auth.uid() = wsp.user_id and wsp.source_type = 'self')
        or (auth.uid() = wsp.trainer_id and wsp.source_type = 'trainer_proposed')
      )
  ));

drop trigger if exists workout_plan_assignments_set_updated_at on public.workout_plan_assignments;
create trigger workout_plan_assignments_set_updated_at
before update on public.workout_plan_assignments
for each row execute function public.set_workout_entity_updated_at();

drop trigger if exists workout_schedule_profiles_set_updated_at on public.workout_schedule_profiles;
create trigger workout_schedule_profiles_set_updated_at
before update on public.workout_schedule_profiles
for each row execute function public.set_workout_entity_updated_at();

create or replace function public.set_schedule_profile_day_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists workout_schedule_profile_days_set_updated_at on public.workout_schedule_profile_days;
create trigger workout_schedule_profile_days_set_updated_at
before update on public.workout_schedule_profile_days
for each row execute function public.set_schedule_profile_day_updated_at();

do $$
declare
  profile_row record;
  profile_id uuid;
begin
  for profile_row in
    select distinct user_id
    from public.workout_plan_schedule
  loop
    insert into public.workout_schedule_profiles (
      user_id,
      name,
      source_type,
      is_active,
      is_read_only
    )
    values (
      profile_row.user_id,
      'My Schedule',
      'self',
      true,
      false
    )
    on conflict do nothing
    returning id into profile_id;

    if profile_id is null then
      select id into profile_id
      from public.workout_schedule_profiles
      where user_id = profile_row.user_id
        and source_type = 'self'
      order by created_at
      limit 1;
    end if;

    insert into public.workout_schedule_profile_days (
      schedule_profile_id,
      day_of_week,
      workout_plan_id
    )
    select
      profile_id,
      wps.day_of_week,
      wps.workout_plan_id
    from public.workout_plan_schedule wps
    where wps.user_id = profile_row.user_id
    on conflict (schedule_profile_id, day_of_week) do nothing;
  end loop;
end;
$$;
