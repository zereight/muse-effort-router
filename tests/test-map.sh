#!/usr/bin/env bash
# Dry-run E2E for the prompt -> effort map. No API calls, no tokens.
# Verdict: exit 0 + table when every case maps as expected.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAP="$SCRIPT_DIR/muse-effort.sh"

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

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
