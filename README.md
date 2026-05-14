# agent-poke

Runs Codex and Claude Code at fixed times so their usage windows are opened by a tiny non-interactive check-in message.

The container does not automate account login. The user logs in once through each official CLI flow, and credentials stay in the persistent Docker home volume.

## Schedule

Default schedule, using the `TZ` value in `docker-compose.yml`:

- 06:30
- 11:30
- 16:30

The schedule is defined in `config/schedule.cron`.

## Build

```sh
docker compose build
```

## Deploy

From your local machine:

```sh
./deploy.sh
```

The deploy script syncs the project to `semih-server:/opt/apps/projects/agent-poke`, creates `logs` and `workspace`, fixes their ownership for the container user, and runs:

```sh
docker compose up -d --build
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

Start the scheduled service:

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

## Server Permission Fix

If you see `Permission denied` for `/app/logs/run-*.log`, fix host directory ownership:

```sh
cd /opt/apps/projects/agent-poke
mkdir -p logs workspace
chown -R 1001:1001 logs workspace
```

The container user is `agent` with UID/GID `1001:1001`.

## Server Notes

- Keep the `agent_home` volume. Removing it removes CLI login state.
- Keep `/workspace` stable. If Codex or Claude asks to trust the working directory, approve it once during manual login or manual check.
- Do not bake credentials into the image.
- After changing scripts or Dockerfile, redeploy or run `docker compose up -d --build`.
