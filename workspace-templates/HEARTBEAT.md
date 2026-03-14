# HEARTBEAT

No email polling needed — inbound tenant emails are handled by OpenClaw's native email channel automatically.

Cron jobs handle all scheduled tasks:

- **7am daily**: Run `client-care-route` (query visit candidates, send confirmation emails) + compile all overnight team inbox emails into a digest → send formatted WhatsApp summary to `TEAM_WHATSAPP_GROUP` including: email count by classification, list of each email (sender, subject, suggested action), and any items needing approval
- **9am Mondays**: `rent-adjustment` (check lease anniversaries within 4 months)

**Daily system health (runs at midnight as part of `summary-12am` cron):** Verify Supabase connectivity by executing a lightweight query (`SELECT 1`). Verify all 5 agents (manager, rent, maintenance, legal, escalation) are reachable by checking their workspace SOUL.md exists and the agent config is registered. If any agent fails or Supabase is unreachable, send an alert to `MANAGER_WHATSAPP` immediately — do not wait for the next scheduled summary.

This file is intentionally minimal.
