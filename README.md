# SWARM — An LSMG System

SWARM is a live goal-to-organization engine. A user describes an outcome, SWARM turns it into an editable Project Blueprint, searches the real opt-in capability network, applies hard constraints, scores person↔role fit with deterministic components, optimizes complete teams, sends real in-app invitations, and opens a shared realtime Swarm Room.

## Production architecture

- Netlify: static PWA frontend + SWARM Goal Intelligence / AI Coordinator.
- Supabase project: dedicated **SWARM** backend in the LSMG organization.
- Supabase Auth: cross-device email/password identity.
- Postgres + Row Level Security: profiles, projects, roles, matches, score components, teams, Swarms, invitations, tasks, messages, decisions, files, notifications, trust signals and outcomes.
- Supabase Realtime: projects, Swarms, invitations, member state, tasks, chat, decisions, notifications and project files.
- Supabase Storage: private `swarm-files` bucket with signed file access.
- Supabase Edge Function `swarm-match`: protected server-side matching, team optimization, invitation formation and replacement matching.
- Netlify function `swarm-ai`: goal parsing and project coordination only. AI does not calculate final match/team scores.

## Core source

- `src/app.mjs` — cloud-first application UI and orchestration.
- `src/cloud.mjs` — Supabase auth/data/realtime/storage client.
- `src/goal-engine.mjs` — deterministic goal-parser fallback and blueprint normalization.
- `src/match-engine.mjs` — reference deterministic match/optimizer implementation + automated tests.
- `supabase/functions/swarm-match/index.ts` — production server-side match engine.
- `database/` — versioned database architecture.
- `tests/match-engine.test.mjs` — deterministic engine tests.

## Product integrity

Production matching uses only real profiles whose owners explicitly set visibility to **public**. Development seed profiles remain in the repository for algorithm tests but are not used by the live app.

Match explanations come from stored score components. SWARM AI does not invent match percentages.

## Local testing

```bash
npm test
```

## Brand

**SWARM — An LSMG System**

Graphite / electric chartreuse / ice cyan / restrained violet. The product is designed around living networks, formation, coordination and collective intelligence.
