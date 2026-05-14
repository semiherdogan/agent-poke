#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
Claude Code login is interactive.

Run /login inside Claude, choose the Claude.ai subscription option, finish the browser/device flow, then exit Claude.
Credentials are stored in the persistent Docker home volume.
MSG

cd /workspace
exec claude "$@"
