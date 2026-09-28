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

Control phrases work inside the prompt too — no model call, toggles locally:

```bash
./muse-effort.sh "라우터 꺼줘"  # router off (default)
./muse-effort.sh "라우터 켜줘"  # router on (default)
./muse-effort.sh "라우터 상태"  # show effective state
```

Only exact phrases toggle (`라우터 꺼줘`, `router off`, `effort 고정`, …).
Anything longer ("라우터 꺼줘가 뭐야? 설명해줘") routes normally.

## Chat control (interactive sessions)

`skills/effort-router/SKILL.md` teaches an interactive Muse Code session the
same on/off/status commands. Install it with
`muse skills install ./skills/effort-router --scope user` so "라우터 꺼줘"
works in plain chat too.

## Tune

Edit `effort-map.json`. Point elsewhere with `MUSE_EFFORT_MAP=/path/to/map.json`.
Reset the sticky session with `rm ~/.cache/muse-effort-router/session-id`.

## Test

```bash
./tests/test-map.sh
```

## License

MIT
