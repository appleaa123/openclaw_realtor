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
# Provision workspace templates on first run
mkdir -p /data/workspace/forms
[ -f /data/workspace/SOUL.md ]      || cp /app/workspace-templates/SOUL.md      /data/workspace/SOUL.md
[ -f /data/workspace/HEARTBEAT.md ] || cp /app/workspace-templates/HEARTBEAT.md /data/workspace/HEARTBEAT.md

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
