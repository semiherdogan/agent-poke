# agent-poke

Runs Codex and Claude Code at fixed times with a tiny scheduled check-in message.

The container does not automate account login. The user logs in once through each official CLI flow, and credentials stay in the persistent Docker home volume.

## Schedule

The schedule is static and shared by Codex and Claude.

The timezone is configured with `TZ` in `docker-compose.yml`. The default is:

```yaml
TZ: Europe/Istanbul
```

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

## Quick Start

```sh
git clone https://github.com/semiherdogan/agent-poke.git
cd agent-poke
docker compose build
```

Log in once:

```sh
docker compose run --rm agent-poke login-codex
docker compose run --rm agent-poke login-claude
```

Run a manual check:

```sh
docker compose run --rm agent-poke checkin
```

This verifies that saved login state works inside the container. It also lets you answer any first-run workspace trust prompt before the scheduled runs start.

Start the scheduler:

```sh
docker compose up -d
```

## Server Deployment

On a server with Docker installed, clone the repository and prepare writable runtime directories:

```sh
git clone https://github.com/semiherdogan/agent-poke.git
cd agent-poke
mkdir -p logs workspace
chown -R 1001:1001 logs workspace
```

Then follow the login and scheduler steps above.

If you already cloned the repository, update and rebuild with:

```sh
git pull
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

Check-ins use the same flow for both agents:

- start the interactive CLI with `CHECKIN_PROMPT` as the initial prompt
- wait for output to settle
- exit the CLI

Agents are started in parallel during the same scheduled run, so a slow response from one CLI does not delay the other.

Override the message with `CHECKIN_PROMPT` in `docker-compose.yml`.

## Trust and Usage Notes

After login, run one manual check so Codex and Claude can ask and remember any workspace trust prompt:

```sh
docker compose run --rm agent-poke checkin
```

Scheduled runs use the same interactive path. That keeps Codex and Claude behavior aligned with normal CLI usage instead of using programmatic modes like `codex exec` or `claude -p`.

These check-ins make real model requests and count as usage for their respective CLIs.

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

The runner keeps the most recent `run-*.log` files based on `LOG_KEEP` in `docker-compose.yml`. The default is:

```yaml
LOG_KEEP: 20
```

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
Depending on your server setup, the `chown` command may need `sudo`.

## Server Notes

- Keep the `agent_home` volume. Removing it removes CLI login state.
- Keep `/workspace` stable. If Codex or Claude asks to trust the working directory, approve it once during manual login or manual check.
- Do not bake credentials into the image.
- After changing scripts or Dockerfile, run `docker compose up -d --build`.
