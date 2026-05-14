#!/usr/bin/env bash
set -euo pipefail

case "${1:-schedule}" in
    schedule)
        exec supercronic /app/config/schedule.cron
        ;;
    checkin)
        shift
        exec /app/scripts/run-checkin.sh "$@"
        ;;
    login-codex)
        shift
        exec /app/scripts/login-codex.sh "$@"
        ;;
    login-claude)
        shift
        exec /app/scripts/login-claude.sh "$@"
        ;;
    *)
        exec "$@"
        ;;
esac
