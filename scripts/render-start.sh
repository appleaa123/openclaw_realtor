#!/bin/sh
set -e
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
openclaw config set gateway.controlUi.dangerouslyDisableDeviceAuth true
openclaw config set gateway.bind lan
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

exec openclaw gateway --allow-unconfigured
