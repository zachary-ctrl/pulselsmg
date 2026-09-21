-- SWARM graph + ML extension layer.
-- Safe follow-on migration for a dedicated SWARM Supabase/Postgres project.

create extension if not exists vector;

alter table profiles add column if not exists feature_vector jsonb not null default '{}';
alter table profiles add column if not exists embedding vector(1536);
alter table projects add column if not exists feature_vector jsonb not null default '{}';
alter table projects add column if not exists embedding vector(1536);

create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  slug text unique,
  description text not null default '',
  visibility text not null default 'private' check(visibility in ('private','public')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists organization_members (
  organization_id uuid not null references organizations(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key(organization_id,profile_id)
);

create table if not exists graph_edges (
  id uuid primary key default gen_random_uuid(),
  from_type text not null check(from_type in ('person','skill','role','project','swarm','organization','resource','location','outcome')),
  from_id uuid not null,
  edge_type text not null check(edge_type in ('has_skill','worked_with','completed_project','needs_role','matched_with','invited_to','member_of','trusts','endorsed_by','located_in','used_resource','achieved_outcome')),
  to_type text not null check(to_type in ('person','skill','role','project','swarm','organization','resource','location','outcome')),
  to_id uuid not null,
  weight numeric,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists idx_graph_from on graph_edges(from_type,from_id,edge_type);
create index if not exists idx_graph_to on graph_edges(to_type,to_id,edge_type);
create index if not exists idx_profiles_embedding on profiles using ivfflat (embedding vector_cosine_ops) with (lists=50);
create index if not exists idx_projects_embedding on projects using ivfflat (embedding vector_cosine_ops) with (lists=50);

alter table organizations enable row level security;
alter table organization_members enable row level security;
alter table graph_edges enable row level security;

drop policy if exists "organization owner full access" on organizations;
create policy "organization owner full access" on organizations for all
using (owner_id=auth.uid()) with check (owner_id=auth.uid());

drop policy if exists "public organizations readable" on organizations;
create policy "public organizations readable" on organizations for select
using (visibility='public' or owner_id=auth.uid());

drop policy if exists "organization member visibility" on organization_members;
create policy "organization member visibility" on organization_members for select
using (
  profile_id=auth.uid()
  or exists(select 1 from organizations o where o.id=organization_id and o.owner_id=auth.uid())
);

drop policy if exists "organization owner manages members" on organization_members;
create policy "organization owner manages members" on organization_members for all
using (exists(select 1 from organizations o where o.id=organization_id and o.owner_id=auth.uid()))
with check (exists(select 1 from organizations o where o.id=organization_id and o.owner_id=auth.uid()));

-- Graph edges remain private until a server-side graph service establishes
-- permission-aware read/write rules. No permissive public policy is created here.
