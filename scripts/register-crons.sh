#!/bin/sh
# register-crons.sh — Register all 9 scheduled cron jobs for the property management multi-agent system.
#
# Run this script once post-deploy from the Render shell:
#   sh /app/scripts/register-crons.sh
#
# Prerequisites:
#   - 5 agents registered (manager, rent, maintenance, legal, escalation)
#   - Phone number env vars set (see below)
#   - openclaw CLI available in PATH
#
# Required env vars (set in Render environment):
#   MANAGER_WHATSAPP        — Manager E.164 number (e.g. +16474588574)
#   RENT_WHATSAPP           — Rent team member E.164 number
#   MAINTENANCE_WHATSAPP    — Maintenance team member E.164 number
#   LEGAL_WHATSAPP          — Legal/admin team member E.164 number
#   ESCALATION_WHATSAPP     — Escalation team member E.164 number (may equal manager)

set -e

# ---------------------------------------------------------------------------
# Validate required env vars
# ---------------------------------------------------------------------------
for VAR in MANAGER_WHATSAPP RENT_WHATSAPP MAINTENANCE_WHATSAPP LEGAL_WHATSAPP ESCALATION_WHATSAPP; do
  eval "VAL=\$$VAR"
  if [ -z "$VAL" ]; then
    echo "ERROR: $VAR is not set. Aborting." >&2
    exit 1
  fi
done

TIMEZONE="America/Toronto"
MODEL="google/gemini-2.5-flash"

echo "Registering cron jobs (timezone: $TIMEZONE, model: $MODEL)..."

# ---------------------------------------------------------------------------
# UC0 — Summary crons (4x per day): manager agent aggregates all 4 UC domains
# ---------------------------------------------------------------------------

SUMMARY_MSG="Run scheduled multi-domain summary. Query Supabase for the past 6 hours of activity across all domains: (1) RENT — tenant table for payment changes and anniversary flags; (2) MAINTENANCE — maintenance table for new, updated, and stale tickets; (3) LEGAL — interactions and maintenance tables for LTB triggers and expense items; (4) ESCALATIONS — all tables for unresolved escalations and owner update items. Format one combined WhatsApp message with four labeled sections (RENT, MAINTENANCE, LEGAL, ESCALATIONS) and a count of items needing approval. Send to MANAGER_WHATSAPP via wacli. Also run health check: verify Supabase connectivity with SELECT 1 and confirm all 5 agent workspaces exist; alert MANAGER_WHATSAPP if any check fails."

openclaw cron add \
  --id "summary-6am" \
  --schedule "0 6 * * *" \
  --timezone "$TIMEZONE" \
  --agent manager \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MANAGER_WHATSAPP" \
  --message "$SUMMARY_MSG"
echo "  ✓ summary-6am"

openclaw cron add \
  --id "summary-12pm" \
  --schedule "0 12 * * *" \
  --timezone "$TIMEZONE" \
  --agent manager \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MANAGER_WHATSAPP" \
  --message "$SUMMARY_MSG"
echo "  ✓ summary-12pm"

openclaw cron add \
  --id "summary-6pm" \
  --schedule "0 18 * * *" \
  --timezone "$TIMEZONE" \
  --agent manager \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MANAGER_WHATSAPP" \
  --message "$SUMMARY_MSG"
echo "  ✓ summary-6pm"

MIDNIGHT_MSG="Run scheduled multi-domain summary. Query Supabase for the past 6 hours of activity across all domains: (1) RENT — tenant table for payment changes and anniversary flags; (2) MAINTENANCE — maintenance table for new, updated, and stale tickets; (3) LEGAL — interactions and maintenance tables for LTB triggers and expense items; (4) ESCALATIONS — all tables for unresolved escalations and owner update items. Format one combined WhatsApp message with four labeled sections (RENT, MAINTENANCE, LEGAL, ESCALATIONS) and a count of items needing approval. Send to MANAGER_WHATSAPP via wacli. Additionally, run daily health check: verify Supabase connectivity with SELECT 1, confirm all 5 agent workspaces exist (/data/workspace-manager/SOUL.md, /data/workspace-rent/SOUL.md, /data/workspace-maintenance/SOUL.md, /data/workspace-legal/SOUL.md, /data/workspace-escalation/SOUL.md). If any check fails, send alert to MANAGER_WHATSAPP immediately and include which component failed."

openclaw cron add \
  --id "summary-12am" \
  --schedule "0 0 * * *" \
  --timezone "$TIMEZONE" \
  --agent manager \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MANAGER_WHATSAPP" \
  --message "$MIDNIGHT_MSG"
echo "  ✓ summary-12am (includes health check)"

# ---------------------------------------------------------------------------
# UC1 — Rent: weekly lease anniversary check (Monday 9am)
# ---------------------------------------------------------------------------

openclaw cron add \
  --id "rent-check" \
  --schedule "0 9 * * 1" \
  --timezone "$TIMEZONE" \
  --agent rent \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$RENT_WHATSAPP" \
  --message "Scan the tenant table in Supabase for all tenants whose last_time_rent_adjustment_date is within 4 months of their 12-month lease anniversary. For each eligible tenant, calculate the maximum legal rent increase under the Ontario Rent Increase Guideline and draft a rent increase notice. Present a formatted brief to RENT_WHATSAPP listing: tenant name, unit address, current rent, proposed new rent, legal maximum, and months until anniversary. Label each entry 'DRAFT — not sent until APPROVED'. Wait for APPROVE before taking any further action."
echo "  ✓ rent-check (Monday 9am)"

# ---------------------------------------------------------------------------
# UC2 — Maintenance: morning route + evening route + stale ticket monitor
# ---------------------------------------------------------------------------

openclaw cron add \
  --id "route-morning" \
  --schedule "0 7 * * *" \
  --timezone "$TIMEZONE" \
  --agent maintenance \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MAINTENANCE_WHATSAPP" \
  --message "Query the maintenance table in Supabase for all scheduled property visits today (inspections, follow-up checks, work order sign-offs). For each visit, draft a tenant confirmation email including: property address, visit date/time window, reason for visit, and team member name. Present the full list to MAINTENANCE_WHATSAPP with all draft emails labeled 'DRAFT — not sent until APPROVED'. Wait for APPROVE before sending any confirmation email via himalaya. After approval and send, report how many confirmations were sent."
echo "  ✓ route-morning"

openclaw cron add \
  --id "route-evening" \
  --schedule "0 18 * * *" \
  --timezone "$TIMEZONE" \
  --agent maintenance \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MAINTENANCE_WHATSAPP" \
  --message "Query the maintenance table in Supabase for tomorrow's scheduled visits. Compile all confirmed tenant responses received since this morning. Using client-care-route skill, build an optimized visit route for tomorrow ordered by geography. Send the finalized route to MAINTENANCE_WHATSAPP as a plain list: time window, address, unit, visit reason, tenant name. This is a read-only planning output — no HITL required."
echo "  ✓ route-evening"

openclaw cron add \
  --id "maintenance-stale" \
  --schedule "0 8 * * *" \
  --timezone "$TIMEZONE" \
  --agent maintenance \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MAINTENANCE_WHATSAPP" \
  --message "Query the maintenance table in Supabase for all open tickets where updated_at is more than 24 hours ago. For each stale ticket report: property address, unit, tenant name, issue description, severity, assigned vendor (if any), and hours since last update. Send formatted list to MAINTENANCE_WHATSAPP. Additionally, for any tickets stale more than 72 hours, flag as critical escalation and also send to MANAGER_WHATSAPP. This is a read-only status report — no HITL required."
echo "  ✓ maintenance-stale"

# ---------------------------------------------------------------------------
# UC3 — Legal: monthly expense report (1st of month, 9am)
# ---------------------------------------------------------------------------

openclaw cron add \
  --id "expense-monthly" \
  --schedule "0 9 1 * *" \
  --timezone "$TIMEZONE" \
  --agent legal \
  --session isolated \
  --model "$MODEL" \
  --deliver announce \
  --channel whatsapp \
  --to "$MANAGER_WHATSAPP" \
  --message "Generate the monthly expense report for all properties. Query the maintenance table in Supabase for all work orders closed in the previous calendar month. Query the interactions table for any expense-related entries in the same period. Group results by property address. Using ltb-forms expense report function, produce: total spend per property, itemized list (date, vendor, description, amount), grand total across all properties, and any anomalies (single items over \$500, repeat vendors). Send the formatted report to MANAGER_WHATSAPP via wacli. Include a separate section for any expenses still pending approval. This is a read-only summary report — no HITL required for the summary itself, but flagged pending items require manager APPROVE."
echo "  ✓ expense-monthly (1st of month)"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "All 9 cron jobs registered."
echo ""
echo "Verify with: openclaw cron list"
echo ""
echo "Test a job manually with: openclaw cron run <job-id>"
echo "Example: openclaw cron run summary-6am"
