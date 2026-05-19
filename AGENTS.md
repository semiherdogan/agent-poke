# agent-poke project notes

## Purpose

`agent-poke` runs small scheduled check-ins against supported AI CLIs/services so their usage window is opened by a real user-style message.

Current supported agents:

- `codex`
- `claude`
- `ollama` via Ollama Cloud

## How it works

The scheduler is a Docker service. `supercronic` reads `config/schedule.cron` and runs `/app/scripts/run-checkin.sh`.

`run-checkin.sh`:

- reads enabled agents from the `AGENTS` environment variable, defaulting to `codex claude`
- starts enabled agents in parallel
- writes logs to `logs/run-*.log`
- keeps only the newest `LOG_KEEP` run logs

For Codex and Claude, `lib/drive-agent.expect` launches the interactive CLI with `CHECKIN_PROMPT`, waits for output to settle, then exits the process.

For Ollama Cloud, `run-checkin.sh` uses `curl` to send `CHECKIN_PROMPT` to `https://ollama.com/api/chat` with `stream: false`.

This is intentional. The check-in should be a real model request, not just a dry command or health check. If a provider's 5-hour usage window starts when a real prompt/message is sent, this path is meant to trigger that window.

## Important limit assumption

The code can only guarantee that it sends a real prompt through the provider path. It cannot independently prove provider-side window accounting.

When adding a new provider, verify that:

- the configured command/API call sends an actual model request
- the request consumes normal usage for that provider
- the provider starts or refreshes the intended usage window on that request

For Ollama Cloud specifically, using `OLLAMA_API_KEY` is acceptable as long as it stays in `.env`, Compose environment, or another local secret source and is never committed.

## Main files

- `Dockerfile`: installs runtime dependencies and AI CLIs.
- `docker-compose.yml`: service config, environment, volumes, enabled agents.
- `config/schedule.cron`: scheduled check-in times.
- `scripts/entrypoint.sh`: dispatches `schedule`, `checkin`, and login commands.
- `scripts/run-checkin.sh`: agent selection, parallel execution, log retention.
- `lib/drive-agent.expect`: interactive CLI driver for Codex/Claude-style agents.
- `scripts/login-codex.sh`: Codex login wrapper.
- `scripts/login-claude.sh`: Claude login wrapper.
- `logs/`: runtime logs, ignored except `.gitkeep`.
- `workspace/`: mounted working directory used by the agents.

## Enable or disable agents

Use `AGENTS` in `docker-compose.yml`.

Examples:

```yaml
AGENTS: codex claude
AGENTS: codex
AGENTS: claude
AGENTS: codex claude ollama
AGENTS: ollama
```

Manual runs can target one or more agents:

```sh
rtk docker compose run --rm agent-poke checkin codex
rtk docker compose run --rm agent-poke checkin claude
rtk docker compose run --rm agent-poke checkin codex claude
rtk docker compose run --rm agent-poke checkin ollama
```

## Ollama Cloud

Ollama Cloud uses direct API access. Put secrets in `.env`, not in git:

```sh
OLLAMA_API_KEY=your_api_key
OLLAMA_MODEL=gpt-oss:120b
```

`docker-compose.yml` passes those values into the container. `OLLAMA_MODEL` defaults to `gpt-oss:120b`.

If `ollama` is enabled but `OLLAMA_API_KEY` is missing, the runner logs:

```text
[skip] ollama missing OLLAMA_API_KEY
```

The first verification should be a manual check-in with logs confirming a real response from Ollama:

```sh
rtk docker compose run --rm agent-poke checkin ollama
```

## Local workflow rules

- Keep changes narrow.
- Prefer project-provided commands.
- For behavior changes, run the narrowest relevant check first.
