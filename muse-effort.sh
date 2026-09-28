#!/usr/bin/env bash
# muse-effort.sh — pick reasoning effort per prompt, keep one session.
#
# Verified behavior (2026-09-28): `muse exec --session-id <fixed>` keeps
# context across calls even when --reasoning-effort differs per call.
# Same id  -> remembers. Fresh id -> does not remember.
#
# Usage:
#   ./muse-effort.sh "your prompt" [--dry-run] [--session-id ID] [--reasoning-effort EFFORT] [-- <extra muse exec args...>]
#   ./muse-effort.sh --router on|off|status
#
# Session id is sticky: stored at
#   ${XDG_CACHE_HOME:-$HOME/.cache}/muse-effort-router/session-id
# so repeated calls in one machine share context without passing flags.
#
# Router default: on. Turn it off persistently with `--router off`
# (stored in ${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router/enabled).
# One-shot override: MUSE_EFFORT_ROUTER=on|off. When off, every prompt
# runs at the map's default_effort with no classification.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP_FILE="${MUSE_EFFORT_MAP:-$SCRIPT_DIR/effort-map.json}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/muse-effort-router"
SESSION_FILE="$CACHE_DIR/session-id"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/muse-effort-router"
ENABLED_FILE="$CONFIG_DIR/enabled"

router_state() {
  case "${MUSE_EFFORT_ROUTER:-}" in
    on|1) echo on; return ;;
    off|0) echo off; return ;;
  esac
  if [[ -f "$ENABLED_FILE" ]]; then
    cat "$ENABLED_FILE"
  else
    echo on
  fi
}

usage() {
  sed -n '2,12p' "$0"
  exit "${1:-0}"
}

PROMPT=""
DRY_RUN=0
SESSION_OVERRIDE=""
EFFORT_OVERRIDE=""
ROUTER_CMD=""
EXTRA=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --session-id) SESSION_OVERRIDE="${2:-}"; shift 2 ;;
    --reasoning-effort) EFFORT_OVERRIDE="${2:-}"; shift 2 ;;
    --router) ROUTER_CMD="${2:-}"; shift 2 ;;
    --) shift; EXTRA+=("$@"); break ;;
    *) if [[ -z "$PROMPT" ]]; then PROMPT="$1"; else PROMPT="$PROMPT $1"; fi; shift ;;
  esac
done

if [[ -n "$ROUTER_CMD" ]]; then
  case "$ROUTER_CMD" in
    on) mkdir -p "$CONFIG_DIR"; echo on > "$ENABLED_FILE"; echo "router on (default)" ;;
    off) mkdir -p "$CONFIG_DIR"; echo off > "$ENABLED_FILE"; echo "router off (default)" ;;
    status)
      file_state="unset"; [[ -f "$ENABLED_FILE" ]] && file_state="$(cat "$ENABLED_FILE")"
      printf 'router=%s (env=%s, file=%s)\n' "$(router_state)" "${MUSE_EFFORT_ROUTER:-unset}" "$file_state" ;;
    *) echo "error: --router needs on|off|status" >&2; exit 1 ;;
  esac
  exit 0
fi

[[ -z "$PROMPT" ]] && { echo "error: prompt required" >&2; usage 1; }
command -v python3 >/dev/null || { echo "error: python3 required" >&2; exit 1; }
[[ -f "$MAP_FILE" ]] || { echo "error: map file not found: $MAP_FILE" >&2; exit 1; }

ROUTER="$(router_state)"
DEFAULT_EFFORT="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get("default_effort", "medium"))' "$MAP_FILE")"

if [[ "$ROUTER" == "off" ]]; then
  EFFORT="$DEFAULT_EFFORT"
else
  EFFORT="$(python3 - "$MAP_FILE" "$PROMPT" <<'PY'
import json, re, sys
map_file, prompt = sys.argv[1], sys.argv[2]
with open(map_file, encoding="utf-8") as f:
    cfg = json.load(f)
length = len(prompt)
def check_one(expr):
    expr = expr.strip()
    if expr.startswith("len"):
        # tiny DSL: len<=N, len>N, or len>A and /re/flags
        m = re.match(r"len\s*(<=|>=|<|>|==)\s*(\d+)\s*(and\s+(.*))?$", expr)
        if not m:
            return False
        op, n, _, rest = m.groups()
        n = int(n)
        ok = {"<=": length <= n, ">=": length >= n,
              "<": length < n, ">": length > n,
              "==": length == n}[op]
        if not ok:
            return False
        if not rest:
            return True
        expr = rest.strip()
    m = re.match(r"/(.*)/([a-z]*)$", expr)
    if not m:
        return False
    pattern, flags = m.groups()
    fl = re.IGNORECASE if "i" in flags else 0
    return re.search(pattern, prompt, fl) is not None
def check(rule):
    # top-level "or": any clause may match
    return any(check_one(c) for c in rule["match"].split(" or "))
for rule in cfg.get("rules", []):
    try:
        if check(rule):
            print(rule["effort"])
            break
    except re.error:
        continue
else:
    print(cfg.get("default_effort", "medium"))
PY
)"
fi

if [[ -n "$EFFORT_OVERRIDE" ]]; then EFFORT="$EFFORT_OVERRIDE"; fi

if [[ -n "$SESSION_OVERRIDE" ]]; then
  SESSION_ID="$SESSION_OVERRIDE"
else
  mkdir -p "$CACHE_DIR"
  if [[ -f "$SESSION_FILE" ]]; then
    SESSION_ID="$(cat "$SESSION_FILE")"
  else
    if command -v uuidgen >/dev/null; then
      SESSION_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
    else
      SESSION_ID="$(python3 -c 'import uuid; print(uuid.uuid4())')"
    fi
    printf '%s' "$SESSION_ID" > "$SESSION_FILE"
  fi
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'effort=%s session=%s router=%s\n' "$EFFORT" "$SESSION_ID" "$ROUTER"
  exit 0
fi

exec muse exec --session-id "$SESSION_ID" --reasoning-effort "$EFFORT" "${EXTRA[@]}" "$PROMPT"
