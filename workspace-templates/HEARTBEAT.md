# HEARTBEAT

No email polling needed — inbound tenant emails are handled by OpenClaw's native email channel automatically.

Cron jobs handle all scheduled tasks:
- 7am daily: client-care-route (query visit candidates, send confirmation emails)
- 9am Mondays: rent-adjustment (check lease anniversaries within 4 months)

This file is intentionally minimal.
