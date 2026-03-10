#!/bin/sh
set -e
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
openclaw config set gateway.bind lan
# Provision workspace templates on first run
mkdir -p /data/workspace/forms
[ -f /data/workspace/SOUL.md ]      || cp /app/workspace-templates/SOUL.md      /data/workspace/SOUL.md
[ -f /data/workspace/HEARTBEAT.md ] || cp /app/workspace-templates/HEARTBEAT.md /data/workspace/HEARTBEAT.md

# Configure stable gateway auth token from Render secret env var
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  openclaw config set gateway.auth.mode token
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN"
fi

exec openclaw gateway --allow-unconfigured
