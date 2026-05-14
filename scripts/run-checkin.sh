#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="/app/logs"
LOG_KEEP="${LOG_KEEP:-20}"
DRIVER="/app/lib/drive-agent.expect"
mkdir -p "$LOG_DIR"

export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"
export HOME="${HOME:-/home/agent}"

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/run-$STAMP.log"
TMP_DIR="$LOG_DIR/.run-$STAMP"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

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

    case "$name" in
        codex)
            if ! command -v codex >/dev/null 2>&1; then
                echo "[skip] codex not on PATH"
                return 127
            fi
            expect "$DRIVER" codex "${CHECKIN_PROMPT:-Hey!}"
            ;;
        claude)
            if ! command -v claude >/dev/null 2>&1; then
                echo "[skip] claude not on PATH"
                return 127
            fi
            expect "$DRIVER" claude "${CHECKIN_PROMPT:-Hey!}"
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
    pids=()
    names=()

    for agent in "${AGENTS[@]}"; do
        (
            run_agent "$agent"
        ) >"$TMP_DIR/$agent.log" 2>&1 &

        pid="$!"
        pids+=("$pid")
        names+=("$agent")
        echo "[start] $agent pid=$pid"
    done

    for index in "${!pids[@]}"; do
        agent="${names[$index]}"
        pid="${pids[$index]}"

        if wait "$pid"; then
            echo "[ok] $agent"
        else
            echo "[warn] $agent check-in exited non-zero"
            status=1
        fi

        if grep -q '[^[:space:]]' "$TMP_DIR/$agent.log"; then
            echo
            echo "=== $(date '+%Y-%m-%d %H:%M:%S') :: $agent ==="
            cat "$TMP_DIR/$agent.log"
        fi
    done

    echo "=== done @ $(date '+%Y-%m-%d %H:%M:%S') ==="
    exit "$status"
} >>"$LOG" 2>&1
