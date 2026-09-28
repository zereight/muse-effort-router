---
name: effort-router
description: Toggle the per-prompt effort router from chat. Use when the user says "라우터 꺼줘", "라우터 켜줘", "라우터 상태", "effort 고정", "router on/off", or asks about automatic effort switching.
---

# Effort Router toggle

`muse-effort.sh` (this repo root) picks `--reasoning-effort` per prompt.
Default is on. When off, every prompt runs at `default_effort` with no
classification. Session stickiness applies either way.

## Locate the script

Find the checkout first — do not guess blindly:

```bash
for d in "$HOME/Documents/muse-effort-router" "$HOME/projects/muse-effort-router"; do
  [[ -x "$d/muse-effort.sh" ]] && echo "$d" && break
done
```

If neither exists, ask the user where they cloned muse-effort-router.

## Actions

| User says | Run in the checkout dir | Reply |
|---|---|---|
| 꺼줘, 끄기, 고정, off | `./muse-effort.sh --router off` | One line: router off, prompts run at default effort |
| 켜줘, 켜기, 자동, on | `./muse-effort.sh --router on` | One line: router on |
| 상태, status | `./muse-effort.sh --router status` | The command output, one line |

## Rules

- On/off requests never touch `effort-map.json`.
- Keep the chat reply to one line plus the command result. No metaphor, no essay.
