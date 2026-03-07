#!/bin/sh
set -e
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
exec openclaw gateway --bind lan --allow-unconfigured
