-- Catalog tables for gym equipment, target muscle groups, and tutorials.

create table if not exists public.gym_equipment (
  equipment_id uuid primary key default gen_random_uuid(),
  equipment_name text not null unique,
  created_date timestamptz not null default now(),
  updated_date timestamptz not null default now(),
  constraint gym_equipment_name_not_empty check (length(trim(equipment_name)) > 0)
);

create table if not exists public.muscle_group (
  id uuid primary key default gen_random_uuid(),
  muscle_group_name text not null unique,
  muscle_class text not null,
  description text,
  constraint muscle_group_name_not_empty check (length(trim(muscle_group_name)) > 0),
  constraint muscle_group_class_not_empty check (length(trim(muscle_class)) > 0)
);

create table if not exists public.gym_equipment_muscle_group (
  equipment_id uuid not null references public.gym_equipment(equipment_id) on delete cascade,
  muscle_group_id uuid not null references public.muscle_group(id) on delete cascade,
  primary key (equipment_id, muscle_group_id)
);

create index if not exists idx_gym_equipment_muscle_group_muscle_group_id
  on public.gym_equipment_muscle_group (muscle_group_id);

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'tutorial_source'
      and n.nspname = 'public'
  ) then
    create type public.tutorial_source as enum (
      'youtube',
      'instagram',
      'facebook',
      'tiktok'
    );
  end if;
end;
$$;

create table if not exists public.tutorials (
  id uuid primary key default gen_random_uuid(),
  equipment_id uuid not null references public.gym_equipment(equipment_id) on delete cascade,
  description text not null,
  tutorial_link text not null,
  source public.tutorial_source not null,
  constraint tutorials_description_not_empty check (length(trim(description)) > 0),
  constraint tutorials_link_not_empty check (length(trim(tutorial_link)) > 0)
);

create index if not exists idx_tutorials_equipment_id
  on public.tutorials (equipment_id);

create or replace function public.set_gym_equipment_updated_date()
returns trigger
language plpgsql
as $$
begin
  new.updated_date = now();
  return new;
end;
$$;

drop trigger if exists gym_equipment_set_updated_date on public.gym_equipment;
create trigger gym_equipment_set_updated_date
before update on public.gym_equipment
for each row
execute function public.set_gym_equipment_updated_date();

alter table public.gym_equipment enable row level security;
alter table public.muscle_group enable row level security;
alter table public.gym_equipment_muscle_group enable row level security;
alter table public.tutorials enable row level security;

-- Any signed-in user can read catalog records.
create policy "Authenticated users can read gym equipment"
  on public.gym_equipment
  for select
  to authenticated
  using (true);

create policy "Authenticated users can read muscle groups"
  on public.muscle_group
  for select
  to authenticated
  using (true);

create policy "Authenticated users can read equipment muscle groups"
  on public.gym_equipment_muscle_group
  for select
  to authenticated
  using (true);

create policy "Authenticated users can read tutorials"
  on public.tutorials
  for select
  to authenticated
  using (true);

-- Catalog data is read-only for signed-in users.


