# /muse-auto-effort-on

Turn the per-prompt effort router back on (it is on by default).

Run this in the shell:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router" && echo on > "${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router/enabled"
```

Then reply in one line: router on — prompts route to effort automatically again.
