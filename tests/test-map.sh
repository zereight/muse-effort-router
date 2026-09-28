#!/usr/bin/env bash
# Dry-run E2E for the prompt -> effort map. No API calls, no tokens.
# Verdict: exit 0 + table when every case maps as expected.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAP="$SCRIPT_DIR/muse-effort.sh"

# Isolated config/cache so the real ~/.config and ~/.cache are untouched.
export XDG_CONFIG_HOME="$(mktemp -d)"
export XDG_CACHE_HOME="$(mktemp -d)"
trap 'rm -rf "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"' EXIT

pass=0; fail=0
check() { # prompt -> expected effort
  local prompt="$1" expected="$2" got
  got="$("$WRAP" "$prompt" --dry-run | sed -E 's/^effort=([a-z]+) .*/\1/')"
  if [[ "$got" == "$expected" ]]; then
    pass=$((pass + 1)); printf 'ok   [%s] <- %s\n' "$got" "$prompt"
  else
    fail=$((fail + 1)); printf 'FAIL [got %s, want %s] <- %s\n' "$got" "$expected" "$prompt"
  fi
}

check "ㅇㅇ" minimal
check "고마워" minimal
check "이 함수 뭐야? 간단히 설명해줘" low
check "list open PRs and summarize them" low
check "이 스택 트레이스 보고 디버그해줘: NullPointer at line 42" high
check "리뷰해줘: 인증 우회 가능성 위주로 봐줘" high
check "우리 결제 아키텍처 전체를 보안 관점에서 다시 설계해줘, 마이그레이션 계획까지 포함해서" max

# Router toggle cases.
# default is on
[[ "$("$WRAP" --router status)" == "router=on (env=unset, file=unset)" ]] \
  && { pass=$((pass + 1)); echo "ok   [router default on]"; } \
  || { fail=$((fail + 1)); echo "FAIL [router default should be on]"; }

# off: hard prompt still runs at default effort
"$WRAP" --router off >/dev/null
got="$(MUSE_EFFORT_ROUTER= "$WRAP" "리뷰해줘: 인증 우회 가능성 위주로 봐줘" --dry-run | sed -E 's/^effort=([a-z]+) .*/\1/')"
[[ "$got" == "medium" ]] \
  && { pass=$((pass + 1)); echo "ok   [router off -> default medium]"; } \
  || { fail=$((fail + 1)); echo "FAIL [router off gave $got, want medium]"; }

# env override beats file: file says off, env says on
got="$(MUSE_EFFORT_ROUTER=on "$WRAP" "리뷰해줘: 인증 우회 가능성 위주로 봐줘" --dry-run | sed -E 's/^effort=([a-z]+) .*/\1/')"
[[ "$got" == "high" ]] \
  && { pass=$((pass + 1)); echo "ok   [env on beats file off]"; } \
  || { fail=$((fail + 1)); echo "FAIL [env override gave $got, want high]"; }

# back on
"$WRAP" --router on >/dev/null
got="$("$WRAP" "리뷰해줘: 인증 우회 가능성 위주로 봐줘" --dry-run | sed -E 's/^effort=([a-z]+) .*/\1/')"
[[ "$got" == "high" ]] \
  && { pass=$((pass + 1)); echo "ok   [router back on]"; } \
  || { fail=$((fail + 1)); echo "FAIL [router on gave $got, want high]"; }

# In-prompt control phrases toggle locally with no model call.
out="$("$WRAP" "라우터 꺼줘")"
[[ "$out" == "router off (default)" && "$(cat "$XDG_CONFIG_HOME/muse-effort-router/enabled")" == "off" ]] \
  && { pass=$((pass + 1)); echo "ok   [prompt 라우터 꺼줘 -> off]"; } \
  || { fail=$((fail + 1)); echo "FAIL [prompt off gave: $out]"; }

out="$("$WRAP" "router off.")"
[[ "$out" == "router off (default)" ]] \
  && { pass=$((pass + 1)); echo "ok   [prompt router off. -> off]"; } \
  || { fail=$((fail + 1)); echo "FAIL [prompt router off gave: $out]"; }

out="$("$WRAP" "라우터 켜줘")"
[[ "$out" == "router on (default)" && "$(cat "$XDG_CONFIG_HOME/muse-effort-router/enabled")" == "on" ]] \
  && { pass=$((pass + 1)); echo "ok   [prompt 라우터 켜줘 -> on]"; } \
  || { fail=$((fail + 1)); echo "FAIL [prompt on gave: $out]"; }

out="$("$WRAP" "라우터 상태")"
[[ "$out" == "router=on (env=unset, file=on)" ]] \
  && { pass=$((pass + 1)); echo "ok   [prompt 라우터 상태]"; } \
  || { fail=$((fail + 1)); echo "FAIL [prompt status gave: $out]"; }

# Near-miss still routes instead of toggling.
"$WRAP" --router on >/dev/null
got="$("$WRAP" "라우터 꺼줘가 뭐야? 설명해줘" --dry-run | sed -E 's/^effort=([a-z]+) .*/\1/')"
[[ "$got" == "low" ]] \
  && { pass=$((pass + 1)); echo "ok   [near-miss routes, not toggles]"; } \
  || { fail=$((fail + 1)); echo "FAIL [near-miss gave $got, want low]"; }

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
