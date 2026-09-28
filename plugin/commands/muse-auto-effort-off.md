# /muse-auto-effort-off

Turn the per-prompt effort router off. Every prompt then runs at default
effort with no classification (session stickiness still applies).

Run this in the shell:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router" && echo off > "${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router/enabled"
```

Then reply in one line: router off — prompts run at default effort.
