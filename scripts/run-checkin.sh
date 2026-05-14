#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="/app/logs"
LOG_KEEP="${LOG_KEEP:-20}"
mkdir -p "$LOG_DIR"

export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"
export HOME="${HOME:-/home/agent}"

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/run-$STAMP.log"

find "$LOG_DIR" -name 'run-*.log' -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn \
    | awk -v keep="$LOG_KEEP" 'NR > keep {print $2}' \
    | xargs -r rm -f 2>/dev/null || true

if [ "$#" -gt 0 ]; then
    AGENTS=("$@")
else
    read -r -a AGENTS <<< "${AGENTS:-codex claude}"
fi

run_agent() {
    local name="$1"

    echo "=== $(date '+%Y-%m-%d %H:%M:%S') :: $name ==="

    case "$name" in
        codex)
            if ! command -v codex >/dev/null 2>&1; then
                echo "[skip] codex not on PATH"
                return 127
            fi
            codex exec --skip-git-repo-check "${CHECKIN_PROMPT:-Hey!}"
            ;;
        claude)
            if ! command -v claude >/dev/null 2>&1; then
                echo "[skip] claude not on PATH"
                return 127
            fi
            claude -p "${CHECKIN_PROMPT:-Hey!}"
            ;;
        *)
            echo "[skip] unsupported agent '$name'"
            return 2
            ;;
    esac
    echo
}

{
    echo "agent-poke run @ $(date)"
    echo "cwd: $(pwd)"
    echo "home: $HOME"
    echo "agents: ${AGENTS[*]}"
    echo

    cd /workspace
    status=0
    for agent in "${AGENTS[@]}"; do
        if ! run_agent "$agent"; then
            echo "[warn] $agent check-in exited non-zero"
            status=1
        fi
    done

    echo "=== done @ $(date '+%Y-%m-%d %H:%M:%S') ==="
    exit "$status"
} >>"$LOG" 2>&1
