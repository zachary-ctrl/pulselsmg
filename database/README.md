# SWARM database

The production SWARM database is the dedicated Supabase project `ziqqpnstclqfnxsbxddf`.

Base schema files:
- `001_swarm_core.sql`
- `002_swarm_graph_ml.sql`

The live project also has the following applied Supabase migrations:
- swarm_production_hardening
- swarm_security_cleanup
- swarm_cloud_mvp_columns
- swarm_matching_invitation_policies
- swarm_invitee_project_read
- swarm_invitation_match_score
- swarm_invitation_questions
- swarm_teammate_profiles_and_response_notifications
- swarm_realtime_projects_files
- swarm_member_milestone_updates

These migrations harden RLS, create the private file bucket, add auth-profile creation, realtime tables, invitation notifications, cloud JSON state columns, and production matching permissions.

Do not apply these files to the unrelated Centrist News Site project.
