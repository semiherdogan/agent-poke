#!/usr/bin/env bash
set -euo pipefail

cd /workspace
exec codex login --device-auth "$@"
