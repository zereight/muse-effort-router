#!/usr/bin/env bash
# Plugin bundle check: manifest parses, 3 commands registered, files exist,
# and `muse plugins validate` passes when muse is available.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$SCRIPT_DIR/plugin"

pass=0; fail=0
ok() { pass=$((pass + 1)); echo "ok   [$1]"; }
bad() { fail=$((fail + 1)); echo "FAIL [$1]"; }

ids="$(python3 -c 'import json; print(" ".join(c["id"] for c in json.load(open("'"$PLUGIN"'/.muse-plugin/plugin.json"))["capabilities"]["commands"]))')"
[[ "$ids" == "muse-auto-effort-on muse-auto-effort-off muse-auto-effort-status" ]] \
  && ok "manifest lists 3 commands" || bad "manifest commands: $ids"

for id in $ids; do
  [[ -f "$PLUGIN/commands/$id.md" ]] && ok "file $id.md" || bad "missing $id.md"
done

if command -v muse >/dev/null; then
  muse plugins validate ./plugin >/dev/null 2>&1 \
    && ok "muse plugins validate" || bad "muse plugins validate"
else
  echo "skip [muse not on PATH]"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
