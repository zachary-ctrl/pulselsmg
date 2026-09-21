# SWARM Repository Audit

## Existing stack
- Static, framework-free PWA hosted on Netlify.
- Single-page client built with vanilla HTML/CSS/JavaScript.
- Netlify Functions for server-side AI and legacy PULSE content endpoints.
- Netlify AI Gateway is available to the AI function at runtime.
- No application database is currently connected to this repo.
- Existing authentication was device-local PBKDF2 + localStorage, not cloud identity.
- Existing PULSE service worker, manifest, responsive shell and deployment pipeline were working and worth preserving conceptually.

## KEEP
- Netlify + GitHub deployment pipeline.
- PWA/service-worker architecture.
- PBKDF2 device-account code as an explicitly labeled MVP fallback only.
- Netlify AI Gateway server boundary.
- Mobile-first responsive shell and safe-area handling.

## REFACTOR
- PULSE culture/news UI → SWARM goal-to-organization workflow.
- One large app.js → modular services + engines in /src.
- Generic AI chat → Goal Intelligence + AI Coordinator with structured responsibilities.
- Local storage → repository layer with a prepared Postgres/Supabase migration for future cloud persistence.

## REMOVE
- PULSE branding and red design language.
- Prediction markets, magazine reader, podcast/news feed, wallet, PULSE Bucks, and culture-streaming UI from the SWARM product.
- Creator matching/swiping.
- LLM-driven ranking. SWARM matching is deterministic structured scoring.
- Dead Connect-era bindings and legacy content dependencies from the active UI.

## BUILD
- Goal composer.
- Structured Project Blueprint editor.
- Role Map.
- Standalone SWARM Match Engine.
- Whole-team optimizer with configurable weights.
- Match explanations from score components.
- Team assembly variants only when compositions differ.
- Invitation + replacement workflow.
- Basic Swarm Room with tasks, milestones, chat, resources, decisions and AI coordinator.
- Outcome tracking + analytics events.
- Capability profile + transparent trust signals.
- Development-network seed data clearly labeled DEMO.
- SQL schema + RLS migration ready for a dedicated SWARM backend.
- Automated deterministic matching tests.

## Known infrastructure boundary
The only connected Supabase project discovered during the audit is unrelated to SWARM. It was not modified. The SWARM app therefore uses device persistence for this MVP while the production schema is checked into the repo and ready to apply once a dedicated SWARM database/auth project is connected.
