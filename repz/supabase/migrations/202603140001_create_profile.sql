-- Create profile table for user onboarding flags.
create table if not exists public.profile (
  user_id uuid primary key references auth.users(id) on delete cascade,
  first_time boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profile enable row level security;

-- Users can read their own profile row.
create policy "Users can read own profile"
  on public.profile
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Users can update their own profile row.
create policy "Users can update own profile"
  on public.profile
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.set_profile_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profile_set_updated_at on public.profile;
create trigger profile_set_updated_at
before update on public.profile
for each row
execute function public.set_profile_updated_at();

-- Auto-create a profile row on every new auth user.
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profile (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row
execute function public.handle_new_user_profile();

-- Backfill existing users in case this migration is added after users exist.
insert into public.profile (user_id)
select u.id
from auth.users u
left join public.profile p on p.user_id = u.id
where p.user_id is null;

