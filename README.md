# agent-poke

Runs Codex and Claude Code at fixed times so their usage windows are opened by a tiny interactive check-in message.

Default schedule:

- 06:30
- 11:30
- 16:30

The container does not automate account login. The user logs in once through each official CLI flow, and credentials stay in the persistent Docker home volume.

## Build

```sh
docker compose build
```

## Login

Codex uses the device auth flow:

```sh
docker compose run --rm agent-poke login-codex
```

Claude Code uses its official auth command with the Claude.ai subscription flow:

```sh
docker compose run --rm agent-poke login-claude
```

Both logins are stored under the `agent_home` Docker volume mounted at `/home/agent`.

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

Logs are written to `logs/run-*.log`.

Check-ins are non-interactive:

- Codex: `codex exec --skip-git-repo-check "Hey!"`
- Claude: `claude -p "Hey!"`

Override the message with `CHECKIN_PROMPT` in `docker-compose.yml`.

## Run Scheduler

```sh
docker compose up -d
```

The schedule is defined in `config/schedule.cron` and uses the `TZ` value from `docker-compose.yml`.

## Server Notes

- Keep the `agent_home` volume. Removing it removes CLI login state.
- Keep `/workspace` stable. If Codex or Claude asks to trust the working directory, approve it once during manual login or manual check.
- Do not bake credentials into the image.
