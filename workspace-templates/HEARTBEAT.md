# HEARTBEAT

No email polling needed — inbound tenant emails are handled by OpenClaw's native email channel automatically.

Cron jobs handle all scheduled tasks:
- **7am daily**: Run `client-care-route` (query visit candidates, send confirmation emails) + compile all overnight team inbox emails into a digest → send formatted WhatsApp summary to `TEAM_WHATSAPP_GROUP` including: email count by classification, list of each email (sender, subject, suggested action), and any items needing approval
- **9am Mondays**: `rent-adjustment` (check lease anniversaries within 4 months)

This file is intentionally minimal.
