#!/bin/sh
set -e
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
openclaw config set gateway.controlUi.dangerouslyDisableDeviceAuth true
openclaw config set gateway.bind lan
# Ensure WhatsApp plugin is loaded into the active registry so QR login works
openclaw config set channels.whatsapp.enabled true
# allowFrom must be set before dmPolicy open — the config validator requires "*" in allowFrom when dmPolicy=open
openclaw config set channels.whatsapp.allowFrom '["*"]'
# Allow DMs from any sender (default "pairing" sends challenges, blocks agent responses)
openclaw config set channels.whatsapp.dmPolicy open
# Allow group messages (default "allowlist" with empty list silently drops all group messages)
openclaw config set channels.whatsapp.groupPolicy open

# ---------------------------------------------------------------------------
# Multi-agent workspace provisioning
# Each agent gets an isolated workspace with its own SOUL.md and shared skills
# ---------------------------------------------------------------------------

for AGENT in manager rent maintenance legal escalation; do
  WORKSPACE="/data/workspace-${AGENT}"
  mkdir -p "${WORKSPACE}/forms"
  # Copy agent-specific SOUL on first run only (preserve any runtime edits)
  [ -f "${WORKSPACE}/SOUL.md" ] || cp "/app/workspace-templates/SOUL-${AGENT}.md" "${WORKSPACE}/SOUL.md"
  # Copy HEARTBEAT on first run only (same for all agents — health check is global)
  [ -f "${WORKSPACE}/HEARTBEAT.md" ] || cp /app/workspace-templates/HEARTBEAT.md "${WORKSPACE}/HEARTBEAT.md"
  # Symlink shared skills directory (agents share the same skill set)
  [ -L "${WORKSPACE}/skills" ] || ln -s /app/skills "${WORKSPACE}/skills"
done

# Keep legacy single-workspace for backwards compat (used by direct openclaw session without --agent flag)
mkdir -p /data/workspace/forms
[ -f /data/workspace/SOUL.md ]      || cp /app/workspace-templates/SOUL.md      /data/workspace/SOUL.md
[ -f /data/workspace/HEARTBEAT.md ] || cp /app/workspace-templates/HEARTBEAT.md /data/workspace/HEARTBEAT.md

# ---------------------------------------------------------------------------
# Register named agents with their workspace directories
# ---------------------------------------------------------------------------

openclaw config set agents.list '[
  {"id":"manager",     "workspace":"/data/workspace-manager"},
  {"id":"rent",        "workspace":"/data/workspace-rent"},
  {"id":"maintenance", "workspace":"/data/workspace-maintenance"},
  {"id":"legal",       "workspace":"/data/workspace-legal"},
  {"id":"escalation",  "workspace":"/data/workspace-escalation"}
]'

# ---------------------------------------------------------------------------
# WhatsApp per-DM agent routing
# Map each team member's phone number to their agent session.
# Phone numbers are provided via Render environment variables.
# Set dmPolicy to allowlist so only known numbers are accepted.
# ---------------------------------------------------------------------------

# Build allowFrom list from phone env vars (only set if all 5 are provided)
if [ -n "$MANAGER_WHATSAPP" ] && [ -n "$RENT_WHATSAPP" ] && [ -n "$MAINTENANCE_WHATSAPP" ] && [ -n "$LEGAL_WHATSAPP" ] && [ -n "$ESCALATION_WHATSAPP" ]; then
  openclaw config set channels.whatsapp.allowFrom \
    "[\"${MANAGER_WHATSAPP}\",\"${RENT_WHATSAPP}\",\"${MAINTENANCE_WHATSAPP}\",\"${LEGAL_WHATSAPP}\",\"${ESCALATION_WHATSAPP}\"]"
  openclaw config set channels.whatsapp.dmPolicy allowlist
  openclaw config set channels.whatsapp.dms \
    "{\"${MANAGER_WHATSAPP}\":{\"agentId\":\"manager\"},\"${RENT_WHATSAPP}\":{\"agentId\":\"rent\"},\"${MAINTENANCE_WHATSAPP}\":{\"agentId\":\"maintenance\"},\"${LEGAL_WHATSAPP}\":{\"agentId\":\"legal\"},\"${ESCALATION_WHATSAPP}\":{\"agentId\":\"escalation\"}}"
else
  echo "WARNING: One or more WhatsApp phone number env vars not set. Keeping dmPolicy=open for initial setup."
  echo "  Required: MANAGER_WHATSAPP, RENT_WHATSAPP, MAINTENANCE_WHATSAPP, LEGAL_WHATSAPP, ESCALATION_WHATSAPP"
fi

# ---------------------------------------------------------------------------
# Routing bindings: associate each agent with the WhatsApp channel.
# These channel-level bindings (no peer/account qualifier) make all agents
# visible in the Chat agent selector and populate each agent's Channels tab.
# Actual per-DM routing to the right agent is still handled by
# channels.whatsapp.dms above (WhatsApp-extension-level, peer-specific).
# ---------------------------------------------------------------------------
openclaw config set bindings '[
  {"agentId":"manager",     "match":{"channel":"whatsapp"}},
  {"agentId":"rent",        "match":{"channel":"whatsapp"}},
  {"agentId":"maintenance", "match":{"channel":"whatsapp"}},
  {"agentId":"legal",       "match":{"channel":"whatsapp"}},
  {"agentId":"escalation",  "match":{"channel":"whatsapp"}}
]'

# ---------------------------------------------------------------------------
# Gateway auth
# ---------------------------------------------------------------------------

# Configure gateway auth token if provided (enables token-based auth as an alternative to password)
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN"
fi

# Configure gateway auth using SETUP_PASSWORD so the Control UI WebSocket handshake succeeds
if [ -n "$SETUP_PASSWORD" ]; then
  openclaw config set gateway.auth.mode password
  openclaw config set gateway.auth.password "$SETUP_PASSWORD"
fi

# Set default agent model to Gemini (picked up via GEMINI_API_KEY env var)
openclaw config set agents.defaults.model.primary "google/gemini-2.5-flash"

exec openclaw gateway --allow-unconfigured
