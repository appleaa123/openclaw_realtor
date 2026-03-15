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
  # Always overwrite SOUL from templates on every redeploy (picks up template changes)
  cp "/app/workspace-templates/SOUL-${AGENT}.md" "${WORKSPACE}/SOUL.md"
  # Copy HEARTBEAT on first run only (same for all agents — health check is global)
  [ -f "${WORKSPACE}/HEARTBEAT.md" ] || cp /app/workspace-templates/HEARTBEAT.md "${WORKSPACE}/HEARTBEAT.md"
  # Symlink shared skills directory (agents share the same skill set)
  [ -L "${WORKSPACE}/skills" ] || ln -s /app/skills "${WORKSPACE}/skills"
done

# Keep legacy single-workspace for backwards compat (used by direct openclaw session without --agent flag)
mkdir -p /data/workspace/forms
cp /app/workspace-templates/SOUL.md /data/workspace/SOUL.md
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
# Routing bindings: peer-specific so each team member routes to their agent.
# Tier-1 (peer match) — highest priority in resolveAgentRoute().
# Manager gets a Tier-7 channel fallback for unknown/unauthenticated senders.
# ---------------------------------------------------------------------------
if [ -n "$MANAGER_WHATSAPP" ] && [ -n "$RENT_WHATSAPP" ] && [ -n "$MAINTENANCE_WHATSAPP" ] && [ -n "$LEGAL_WHATSAPP" ] && [ -n "$ESCALATION_WHATSAPP" ]; then
  openclaw config set bindings "[
    {\"agentId\":\"manager\",     \"match\":{\"channel\":\"whatsapp\",\"peer\":\"${MANAGER_WHATSAPP}\"}},
    {\"agentId\":\"rent\",        \"match\":{\"channel\":\"whatsapp\",\"peer\":\"${RENT_WHATSAPP}\"}},
    {\"agentId\":\"maintenance\", \"match\":{\"channel\":\"whatsapp\",\"peer\":\"${MAINTENANCE_WHATSAPP}\"}},
    {\"agentId\":\"legal\",       \"match\":{\"channel\":\"whatsapp\",\"peer\":\"${LEGAL_WHATSAPP}\"}},
    {\"agentId\":\"escalation\",  \"match\":{\"channel\":\"whatsapp\",\"peer\":\"${ESCALATION_WHATSAPP}\"}},
    {\"agentId\":\"manager\",     \"match\":{\"channel\":\"whatsapp\"}}
  ]"
else
  echo "WARNING: Phone env vars not set — all WhatsApp messages route to manager."
  openclaw config set bindings '[{"agentId":"manager","match":{"channel":"whatsapp"}}]'
fi

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

# ---------------------------------------------------------------------------
# Session bootstrap: write a minimal sessions.json for each non-manager agent
# so they appear in the Chat agent selector.
# Direct file write — no openclaw CLI flag dependencies, no gateway startup delay.
# State dir = OPENCLAW_STATE_DIR=/data/.openclaw (render.yaml line 14).
# Guard: skip if sessions.json already exists (real or prior bootstrap sessions).
# ---------------------------------------------------------------------------
STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
for AGENT in rent maintenance legal escalation; do
  SESSIONS_FILE="${STATE_DIR}/agents/${AGENT}/sessions/sessions.json"
  if [ ! -f "$SESSIONS_FILE" ]; then
    mkdir -p "$(dirname "$SESSIONS_FILE")"
    EPOCH_MS="$(date +%s)000"
    printf '{"agent:%s:main":{"sessionId":"%s-main","updatedAt":%s,"displayName":"main"}}\n' \
      "$AGENT" "$AGENT" "$EPOCH_MS" > "$SESSIONS_FILE"
    echo "Created initial session for agent: ${AGENT}"
  fi
done

exec openclaw gateway --allow-unconfigured
