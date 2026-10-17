-- One saved home per user. Deleting the auth user deletes the row.
create table if not exists public.homes (
  user_id uuid primary key references auth.users on delete cascade,
  parcel_id text not null,
  address text not null,
  features jsonb not null default '{}'::jsonb,
  completed_steps text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.homes enable row level security;

-- Row-level security: each user can only see and change their own row.
create policy "own row select" on public.homes for select using (auth.uid() = user_id);
create policy "own row insert" on public.homes for insert with check (auth.uid() = user_id);
create policy "own row update" on public.homes for update using (auth.uid() = user_id);
create policy "own row delete" on public.homes for delete using (auth.uid() = user_id);
