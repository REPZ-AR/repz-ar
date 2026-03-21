create table public.trainer_client (
  id          uuid primary key default gen_random_uuid(),
  trainer_id  uuid not null references auth.users(id) on delete cascade,
  client_id   uuid not null references auth.users(id) on delete cascade,
  client_type text not null default 'online' check (client_type in ('online', 'gym')),
  status      text not null default 'active' check (status in ('active', 'pending', 'inactive')),
  created_at  timestamptz not null default now(),
  constraint no_self_client check (trainer_id <> client_id),
  constraint unique_trainer_client unique (trainer_id, client_id)
);

alter table public.trainer_client enable row level security;

create policy "Trainers can view their clients"
  on public.trainer_client for select to authenticated
  using (auth.uid() = trainer_id);

create policy "Trainers can insert clients"
  on public.trainer_client for insert to authenticated
  with check (auth.uid() = trainer_id);

create policy "Trainers can update their client records"
  on public.trainer_client for update to authenticated
  using (auth.uid() = trainer_id);

create policy "Trainers can delete their client records"
  on public.trainer_client for delete to authenticated
  using (auth.uid() = trainer_id);

create policy "Clients can view their trainers"
  on public.trainer_client for select to authenticated
  using (auth.uid() = client_id);

create policy "Anyone can view trainer profiles"
  on public.profile for select to authenticated
  using (mode = 'TRAINER');

create policy "Clients can insert their own trainer relationships"
  on public.trainer_client for insert to authenticated
  with check (auth.uid() = client_id);