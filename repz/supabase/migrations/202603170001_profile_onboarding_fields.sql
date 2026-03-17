-- Add onboarding fields to profile. Only `mode` is currently used by the app gate.

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'profile_mode'
      and n.nspname = 'public'
  ) then
    create type public.profile_mode as enum ('USER', 'TRAINER');
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'profile_experience_level'
      and n.nspname = 'public'
  ) then
    create type public.profile_experience_level as enum (
      'BEGINNER',
      'INTERMEDIATE',
      'EXPERT'
    );
  end if;
end;
$$;

alter table public.profile
  add column if not exists mode public.profile_mode,
  add column if not exists birthday date,
  add column if not exists gender text,
  add column if not exists height_cm numeric(5,2),
  add column if not exists weight_kg numeric(5,2),
  add column if not exists experience public.profile_experience_level,
  add column if not exists frequency smallint;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profile_height_cm_non_negative'
  ) then
    alter table public.profile
      add constraint profile_height_cm_non_negative
      check (height_cm is null or height_cm >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profile_weight_kg_non_negative'
  ) then
    alter table public.profile
      add constraint profile_weight_kg_non_negative
      check (weight_kg is null or weight_kg >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profile_frequency_non_negative'
  ) then
    alter table public.profile
      add constraint profile_frequency_non_negative
      check (frequency is null or frequency >= 0);
  end if;
end;
$$;

