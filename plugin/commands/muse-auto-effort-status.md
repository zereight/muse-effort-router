# /muse-auto-effort-status

Show whether the per-prompt effort router is on or off.

Run this in the shell:

```bash
f="${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router/enabled"; [[ -f "$f" ]] && cat "$f" || echo "on (default, no config file)"
```

Reply with the output in one line.
