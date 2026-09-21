-- SWARM core schema for a dedicated Supabase/Postgres project.
-- Prepared but intentionally NOT applied to any unrelated database.

create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  bio text not null default '',
  location_city text,
  location_region text,
  location_country text default 'US',
  location_precision text not null default 'city' check (location_precision in ('hidden','city','exact')),
  remote_allowed boolean not null default true,
  travel_radius integer not null default 0,
  timezone text not null default 'UTC',
  hourly_rate numeric,
  project_rate numeric,
  minimum_budget numeric,
  preferred_project_types text[] not null default '{}',
  languages text[] not null default '{}',
  working_style text[] not null default '{}',
  communication_preferences text[] not null default '{}',
  portfolio jsonb not null default '[]',
  social_links jsonb not null default '[]',
  visibility text not null default 'private' check (visibility in ('private','public')),
  rate_visibility text not null default 'private' check (rate_visibility in ('private','project','public')),
  availability_visibility text not null default 'project' check (availability_visibility in ('private','project','public')),
  verification_status jsonb not null default '{}',
  reliability_score numeric,
  completion_rate numeric,
  response_rate numeric,
  average_response_time numeric,
  projects_completed integer not null default 0,
  peer_ratings numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists skills (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text,
  created_at timestamptz not null default now()
);

create table if not exists profile_skills (
  profile_id uuid not null references profiles(id) on delete cascade,
  skill_id uuid not null references skills(id) on delete cascade,
  proficiency numeric not null default .5 check (proficiency between 0 and 1),
  verified boolean not null default false,
  evidence jsonb not null default '[]',
  primary key(profile_id,skill_id)
);

create table if not exists profile_experience (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  organization text,
  industry text,
  years numeric,
  verified boolean not null default false,
  evidence jsonb not null default '[]',
  started_on date,
  ended_on date
);

create table if not exists profile_goals (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  goal text not null,
  created_at timestamptz not null default now()
);

create table if not exists profile_roles (
  profile_id uuid not null references profiles(id) on delete cascade,
  role_name text not null,
  primary key(profile_id,role_name)
);

create table if not exists availability (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  hours_per_week numeric,
  status text not null default 'available' check(status in ('available','limited','unavailable')),
  created_at timestamptz not null default now()
);

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references profiles(id) on delete cascade,
  raw_goal text not null,
  title text not null,
  objective text not null,
  category text,
  location_text text,
  remote_allowed boolean not null default true,
  budget_min numeric,
  budget_max numeric,
  start_date date,
  deadline date,
  preferred_experience jsonb not null default '[]',
  preferred_working_style text[] not null default '{}',
  constraints jsonb not null default '[]',
  team_size_min integer,
  team_size_max integer,
  visibility text not null default 'private' check (visibility in ('private','public')),
  status text not null default 'blueprint' check(status in ('blueprint','matching','forming','active','completed','abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists project_roles (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  title text not null,
  required boolean not null default true,
  budget_cap numeric,
  estimated_hours numeric,
  required_languages text[] not null default '{}',
  certifications text[] not null default '{}',
  notes text not null default '',
  sort_order integer not null default 0
);

create table if not exists project_skills (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  role_id uuid references project_roles(id) on delete cascade,
  skill_id uuid references skills(id) on delete set null,
  skill_name text not null,
  required boolean not null default true,
  weight numeric not null default 1
);

create table if not exists project_resources (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  name text not null,
  status text not null default 'needed' check(status in ('needed','secured','removed')),
  details jsonb not null default '{}'
);

create table if not exists project_milestones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  title text not null,
  status text not null default 'todo' check(status in ('todo','in_progress','done','blocked')),
  due_date date,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  role_id uuid not null references project_roles(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  eligible boolean not null,
  score numeric not null check(score between 0 and 1),
  estimated_cost numeric,
  hard_constraints jsonb not null default '[]',
  reasons jsonb not null default '[]',
  concerns jsonb not null default '[]',
  scoring_version text not null default 'v1',
  created_at timestamptz not null default now(),
  unique(project_id,role_id,profile_id,scoring_version)
);

create table if not exists match_score_components (
  match_id uuid not null references matches(id) on delete cascade,
  component text not null,
  normalized_value numeric not null check(normalized_value between 0 and 1),
  weight numeric not null,
  contribution numeric not null,
  primary key(match_id,component)
);

create table if not exists team_candidates (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  label text not null,
  score numeric not null check(score between 0 and 1),
  projected_cost numeric,
  member_count integer not null,
  metrics jsonb not null default '{}',
  assignments jsonb not null default '[]',
  optimizer_version text not null default 'v1',
  created_at timestamptz not null default now()
);

create table if not exists swarms (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null unique references projects(id) on delete cascade,
  team_candidate_id uuid references team_candidates(id) on delete set null,
  status text not null default 'forming' check(status in ('forming','active','completed','cancelled')),
  projected_cost numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists swarm_members (
  swarm_id uuid not null references swarms(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role_id uuid references project_roles(id) on delete set null,
  member_status text not null default 'invited' check(member_status in ('invited','accepted','declined','active','removed')),
  joined_at timestamptz,
  left_at timestamptz,
  primary key(swarm_id,profile_id,role_id)
);

create table if not exists invitations (
  id uuid primary key default gen_random_uuid(),
  swarm_id uuid not null references swarms(id) on delete cascade,
  project_id uuid not null references projects(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role_id uuid not null references project_roles(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending','accepted','declined','expired','withdrawn')),
  estimated_compensation numeric,
  why_matched jsonb not null default '[]',
  replacement_for uuid references invitations(id) on delete set null,
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  swarm_id uuid not null references swarms(id) on delete cascade,
  title text not null,
  description text not null default '',
  status text not null default 'todo' check(status in ('todo','in_progress','done','blocked')),
  owner_profile_id uuid references profiles(id) on delete set null,
  due_at timestamptz,
  created_by uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  swarm_id uuid not null references swarms(id) on delete cascade,
  sender_id uuid not null references profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  reviewer_id uuid not null references profiles(id) on delete cascade,
  subject_id uuid not null references profiles(id) on delete cascade,
  would_work_again boolean,
  rating numeric check(rating between 1 and 5),
  text text,
  created_at timestamptz not null default now(),
  unique(project_id,reviewer_id,subject_id)
);

create table if not exists trust_signals (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  signal_type text not null,
  value jsonb not null,
  source text not null,
  evidence jsonb not null default '{}',
  visible boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists relationships (
  id uuid primary key default gen_random_uuid(),
  from_profile_id uuid not null references profiles(id) on delete cascade,
  to_profile_id uuid not null references profiles(id) on delete cascade,
  relationship_type text not null check(relationship_type in ('worked_with','trusts','endorsed_by','blocked')),
  project_id uuid references projects(id) on delete set null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique(from_profile_id,to_profile_id,relationship_type,project_id)
);

create table if not exists outcomes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null unique references projects(id) on delete cascade,
  swarm_id uuid references swarms(id) on delete set null,
  finished boolean,
  on_time boolean,
  on_budget boolean,
  creator_satisfied numeric check(creator_satisfied between 1 and 5),
  milestones_completed integer,
  members_replaced integer not null default 0,
  dropouts integer not null default 0,
  produced text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  kind text not null,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists activity_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id) on delete set null,
  project_id uuid references projects(id) on delete cascade,
  swarm_id uuid references swarms(id) on delete cascade,
  event_name text not null,
  properties jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists idx_profile_skills_skill on profile_skills(skill_id,profile_id);
create index if not exists idx_projects_creator on projects(creator_id,created_at desc);
create index if not exists idx_project_roles_project on project_roles(project_id,sort_order);
create index if not exists idx_matches_project_role_score on matches(project_id,role_id,score desc);
create index if not exists idx_invitations_profile_status on invitations(profile_id,status);
create index if not exists idx_tasks_swarm_status on tasks(swarm_id,status);
create index if not exists idx_messages_swarm_created on messages(swarm_id,created_at);
create index if not exists idx_activity_project_created on activity_events(project_id,created_at desc);

alter table profiles enable row level security;
alter table projects enable row level security;
alter table project_roles enable row level security;
alter table project_skills enable row level security;
alter table project_resources enable row level security;
alter table project_milestones enable row level security;
alter table swarms enable row level security;
alter table swarm_members enable row level security;
alter table invitations enable row level security;
alter table tasks enable row level security;
alter table messages enable row level security;
alter table notifications enable row level security;
alter table outcomes enable row level security;

drop policy if exists "profiles self write" on profiles;
create policy "profiles self write" on profiles for all using (auth.uid()=id) with check (auth.uid()=id);

drop policy if exists "profiles public or self read" on profiles;
create policy "profiles public or self read" on profiles for select using (visibility='public' or auth.uid()=id);

drop policy if exists "projects creator full access" on projects;
create policy "projects creator full access" on projects for all using (auth.uid()=creator_id) with check (auth.uid()=creator_id);

drop policy if exists "projects public read" on projects;
create policy "projects public read" on projects for select using (visibility='public');

drop policy if exists "project roles via creator" on project_roles;
create policy "project roles via creator" on project_roles for all using (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())) with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "project skills via creator" on project_skills;
create policy "project skills via creator" on project_skills for all using (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())) with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "resources via creator" on project_resources;
create policy "resources via creator" on project_resources for all using (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())) with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "milestones via creator" on project_milestones;
create policy "milestones via creator" on project_milestones for all using (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())) with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "swarm project creator or member" on swarms;
create policy "swarm project creator or member" on swarms for select using (
  exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())
  or exists(select 1 from swarm_members sm where sm.swarm_id=id and sm.profile_id=auth.uid() and sm.member_status in ('accepted','active'))
);

drop policy if exists "swarm creator write" on swarms;
create policy "swarm creator write" on swarms for all using (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())) with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "members swarm access" on swarm_members;
create policy "members swarm access" on swarm_members for select using (
  profile_id=auth.uid()
  or exists(select 1 from swarms s join projects p on p.id=s.project_id where s.id=swarm_id and p.creator_id=auth.uid())
);

drop policy if exists "creator manages members" on swarm_members;
create policy "creator manages members" on swarm_members for all using (
  exists(select 1 from swarms s join projects p on p.id=s.project_id where s.id=swarm_id and p.creator_id=auth.uid())
) with check (
  exists(select 1 from swarms s join projects p on p.id=s.project_id where s.id=swarm_id and p.creator_id=auth.uid())
);

drop policy if exists "invitation recipient or creator" on invitations;
create policy "invitation recipient or creator" on invitations for select using (
  profile_id=auth.uid() or exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())
);

drop policy if exists "invitation creator write" on invitations;
create policy "invitation creator write" on invitations for insert with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "invitation recipient update" on invitations;
create policy "invitation recipient update" on invitations for update using (profile_id=auth.uid() or exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));

drop policy if exists "tasks room read" on tasks;
create policy "tasks room read" on tasks for select using (exists(select 1 from swarm_members sm where sm.swarm_id=tasks.swarm_id and sm.profile_id=auth.uid() and sm.member_status in ('accepted','active')) or exists(select 1 from swarms s join projects p on p.id=s.project_id where s.id=tasks.swarm_id and p.creator_id=auth.uid()));

drop policy if exists "tasks room write" on tasks;
create policy "tasks room write" on tasks for all using (exists(select 1 from swarm_members sm where sm.swarm_id=tasks.swarm_id and sm.profile_id=auth.uid() and sm.member_status in ('accepted','active')) or exists(select 1 from swarms s join projects p on p.id=s.project_id where s.id=tasks.swarm_id and p.creator_id=auth.uid())) with check (created_by=auth.uid());

drop policy if exists "messages room access" on messages;
create policy "messages room access" on messages for all using (sender_id=auth.uid() or exists(select 1 from swarm_members sm where sm.swarm_id=messages.swarm_id and sm.profile_id=auth.uid() and sm.member_status in ('accepted','active'))) with check (sender_id=auth.uid());

drop policy if exists "notifications self" on notifications;
create policy "notifications self" on notifications for all using (profile_id=auth.uid()) with check (profile_id=auth.uid());

drop policy if exists "outcomes creator access" on outcomes;
create policy "outcomes creator access" on outcomes for all using (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid())) with check (exists(select 1 from projects p where p.id=project_id and p.creator_id=auth.uid()));
