create table badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  month text not null,
  label text not null,
  description text not null,
  earned boolean not null default false,
  icon_code_point integer not null,
  bg_color bigint not null,
  border_color bigint not null,
  icon_color bigint not null,
  created_at timestamp with time zone default now()
);

alter table badges enable row level security;

create policy "Users can view own badges"
  on badges for select
  using (auth.uid() = user_id);

create policy "Service role can insert badges"
  on badges for insert
  with check (true);

create policy "Service role can update badges"
  on badges for update
  using (true);

create index badges_user_id_idx on badges(user_id);