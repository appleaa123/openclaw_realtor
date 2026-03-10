#!/bin/sh
set -e
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
openclaw config set gateway.bind lan
# Provision workspace templates on first run
mkdir -p /data/workspace/forms
[ -f /data/workspace/SOUL.md ]      || cp /app/workspace-templates/SOUL.md      /data/workspace/SOUL.md
[ -f /data/workspace/HEARTBEAT.md ] || cp /app/workspace-templates/HEARTBEAT.md /data/workspace/HEARTBEAT.md

# Configure Supabase MCP server (values come from Render secret env vars, never from repo)
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_KEY" ]; then
  openclaw config set mcp.servers.supabase.command npx
  openclaw config set mcp.servers.supabase.args '["-y","@supabase/mcp-server-supabase"]'
  openclaw config set mcp.servers.supabase.env.SUPABASE_URL "$SUPABASE_URL"
  openclaw config set mcp.servers.supabase.env.SUPABASE_SERVICE_KEY "$SUPABASE_SERVICE_KEY"
fi

exec openclaw gateway --allow-unconfigured
