create table friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid references auth.users(id) on delete cascade,
  receiver_id uuid references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamp with time zone default now(),
  unique(requester_id, receiver_id)
);

alter table friendships enable row level security;

create policy "Users can view own friendships"
  on friendships for select
  using (auth.uid() = requester_id or auth.uid() = receiver_id);

create policy "Users can insert friendships"
  on friendships for insert
  with check (auth.uid() = requester_id);

create policy "Users can update own friendships"
  on friendships for update
  using (auth.uid() = receiver_id or auth.uid() = requester_id);

create index friendships_requester_idx on friendships(requester_id);
create index friendships_receiver_idx on friendships(receiver_id);