# muse-effort-router

Per-prompt reasoning-effort router for Muse Code. One sticky session, effort picked at input time.

## Why

Muse Code pins `--reasoning-effort` at session start. This wrapper classifies each
prompt and calls `muse exec --session-id <fixed> --reasoning-effort <picked>`,
so cheap prompts run cheap and hard prompts run deep — without losing context.

Verified 2026-09-28: same `--session-id` with different efforts remembers prior
turns; a fresh id does not.

## Files

- `muse-effort.sh` — router + sticky session + `muse exec` passthrough
- `effort-map.json` — tunable keyword/length rules (first match wins)
- `tests/test-map.sh` — dry-run mapping check, no API calls

## Use

```bash
chmod +x muse-effort.sh
./muse-effort.sh "list open PRs" --dry-run   # effort=low session=... router=on
./muse-effort.sh "list open PRs"             # runs it
./muse-effort.sh "debug this stack trace..." # runs with higher effort
./muse-effort.sh "hi" --reasoning-effort low # manual override
./muse-effort.sh "hi" -- --workspace /path   # extra args to muse exec
```

## Router on/off

On by default. When off, every prompt runs at `default_effort` with no
classification (session stickiness still applies).

```bash
./muse-effort.sh --router off     # persist off
./muse-effort.sh --router on      # persist on
./muse-effort.sh --router status  # show effective state
MUSE_EFFORT_ROUTER=off ./muse-effort.sh "hi"  # one-shot override
```

## Tune

Edit `effort-map.json`. Point elsewhere with `MUSE_EFFORT_MAP=/path/to/map.json`.
Reset the sticky session with `rm ~/.cache/muse-effort-router/session-id`.

## Test

```bash
./tests/test-map.sh
```

## License

MIT
