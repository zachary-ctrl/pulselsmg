# SWARM — An LSMG System

SWARM is a goal-to-organization engine.

A user describes an outcome. SWARM creates a Project Blueprint, identifies the required roles and skills, applies hard constraints, ranks people for roles using deterministic score components, optimizes complete team configurations, creates invitations, and opens a Swarm Room for execution.

## Architecture

- `src/goal-engine.mjs` — deterministic fallback goal parser + blueprint normalization.
- `src/match-engine.mjs` — hard constraints, person↔role scoring, pairwise compatibility and beam-search team optimization.
- `src/services.mjs` — Goal, Blueprint, Profile, Matching, Team Optimizer, Invitation, Swarm, Trust, Outcome, Notification and AI services.
- `src/store.mjs` — device-local repository + event analytics for the current MVP.
- `src/demo-data.mjs` — development seed network, clearly marked as demo.
- `netlify/functions/swarm-ai.mjs` — server-side SWARM Goal Intelligence / AI Coordinator using Netlify AI Gateway.
- `database/001_swarm_core.sql` — production database/RLS schema, intentionally not applied to an unrelated database.
- `tests/match-engine.test.mjs` — deterministic engine tests.

## Local testing

```bash
npm test
```

The app is intentionally dependency-light and deploys as a static PWA plus one AI serverless route.

## Important MVP boundary

Accounts and workspace data are currently device-local. The UI states this honestly. No ratings, real invitations, social activity or success statistics are fabricated. Demo people are marked DEMO / DEVELOPMENT NETWORK everywhere they appear.

## Brand

SWARM is branded as **AN LSMG SYSTEM**. The current visual identity uses graphite, electric chartreuse, ice cyan and restrained violet accents to distinguish SWARM from the former PULSE product.
