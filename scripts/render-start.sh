#!/bin/sh
set -e
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
openclaw config set gateway.bind lan
exec openclaw gateway --allow-unconfigured
