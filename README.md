# agent-poke

Runs Codex and Claude Code at fixed times so their usage windows are opened by a tiny non-interactive check-in message.

The container does not automate account login. The user logs in once through each official CLI flow, and credentials stay in the persistent Docker home volume.

## Schedule

The schedule is static and shared by Codex and Claude.

Default times:

- 06:30
- 11:32
- 16:34
- 21:36

These times are chosen for Claude's critical `09:00-19:00` usage window:

- `06:30` opens the first window before work starts.
- `11:32` is 5 hours + 2 minutes later.
- `16:34` is another 5 hours + 2 minutes later and carries usage past 19:00.
- `21:36` opens an evening window.

Codex uses the same static schedule. Change times in `config/schedule.cron` if needed.

## Build

```sh
docker compose build
```

## Server Deployment

Copy the repository to a server with Docker installed, then run:

```sh
docker compose up -d --build
```

Before starting the service, make sure the runtime directories exist and are writable by the container user:

```sh
mkdir -p logs workspace
chown -R 1001:1001 logs workspace
```

## Login

Login must be done by the user. API keys are not used.

Codex uses the device auth flow:

```sh
docker compose run --rm agent-poke login-codex
```

This runs:

```sh
codex login --device-auth
```

Open the URL shown by Codex, enter the device code, finish login, then return to the terminal.

Claude Code uses its official auth command with the Claude.ai subscription flow:

```sh
docker compose run --rm agent-poke login-claude
```

This runs:

```sh
claude auth login --claudeai
```

Finish the browser login flow when Claude prompts for it.

Both logins are stored in the `agent_home` Docker volume mounted at `/home/agent`.

Do not run `docker compose down -v` unless you want to delete the saved login state.

## Manual Check

Run both agents:

```sh
docker compose run --rm agent-poke checkin
```

Run one agent:

```sh
docker compose run --rm agent-poke checkin codex
docker compose run --rm agent-poke checkin claude
```

Check-ins are non-interactive:

- Codex: `codex exec --skip-git-repo-check "Hey!"`
- Claude: `claude -p "Hey!"`

Override the message with `CHECKIN_PROMPT` in `docker-compose.yml`.

## Run Scheduler

Start the scheduler:

```sh
docker compose up -d
```

Check status:

```sh
docker compose ps
```

Stop the service without deleting login state:

```sh
docker compose down
```

## Logs

Check-in logs are written to:

```sh
logs/run-*.log
```

View recent logs:

```sh
ls -lt logs
tail -n 120 logs/run-*.log
```

The runner keeps the 20 most recent `run-*.log` files.

Scheduler logs are visible with:

```sh
docker compose logs -f agent-poke
```

## Server Permission Fix

If you see `Permission denied` for `/app/logs/run-*.log`, fix host directory ownership:

```sh
mkdir -p logs workspace
chown -R 1001:1001 logs workspace
```

The container user is `agent` with UID/GID `1001:1001`.

## Server Notes

- Keep the `agent_home` volume. Removing it removes CLI login state.
- Keep `/workspace` stable. If Codex or Claude asks to trust the working directory, approve it once during manual login or manual check.
- Do not bake credentials into the image.
- After changing scripts or Dockerfile, run `docker compose up -d --build`.
