#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="/app/logs"
mkdir -p "$LOG_DIR"

export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"
export HOME="${HOME:-/home/agent}"

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/run-$STAMP.log"

find "$LOG_DIR" -name 'run-*.log' -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn \
    | awk 'NR > 20 {print $2}' \
    | xargs -r rm -f 2>/dev/null || true

if [ "$#" -gt 0 ]; then
    AGENTS=("$@")
else
    read -r -a AGENTS <<< "${AGENTS:-codex claude}"
fi

run_agent() {
    local name="$1"

    echo "=== $(date '+%Y-%m-%d %H:%M:%S') :: $name ==="
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "[skip] '$name' not on PATH"
        return
    fi

    case "$name" in
        codex)
            codex exec --skip-git-repo-check "${CHECKIN_PROMPT:-Hey!}" || echo "[warn] codex check-in exited non-zero"
            ;;
        claude)
            claude -p "${CHECKIN_PROMPT:-Hey!}" || echo "[warn] claude check-in exited non-zero"
            ;;
        *)
            echo "[skip] unsupported agent '$name'"
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
    for agent in "${AGENTS[@]}"; do
        run_agent "$agent"
    done

    echo "=== done @ $(date '+%Y-%m-%d %H:%M:%S') ==="
} >>"$LOG" 2>&1
