#!/usr/bin/env bash
# ddb - DynamoDB 읽기 전용 CLI (LLM 에이전트용)
# 의존: op (1Password CLI), aws-vault, dy (dynein)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
SECRETS_DIR="$SCRIPT_DIR/secrets"
SCHEMA_FILE="$SECRETS_DIR/schema.yaml"
CONFIG_FILE="$SECRETS_DIR/config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "오류: 설정 파일이 없습니다: $CONFIG_FILE" >&2
  echo "secrets/config 파일을 생성하세요. (secrets/config.example 참고)" >&2
  exit 1
fi
# shellcheck source=secrets/config
source "$CONFIG_FILE"

READONLY_COMMANDS=(list desc scan get query)
BLOCKED_COMMANDS=(put del upd bwrite admin bootstrap import export backup restore use config)

# ──────────────────────────────────────────

usage() {
  cat <<'EOF'
ddb - DynamoDB 읽기 전용 CLI (LLM 에이전트용)

사용법:
  ddb context [service]                    스키마 컨텍스트 출력 (서비스명 지정 시 해당 서비스만)
  ddb [dev|stag] list                      테이블 목록
  ddb [dev|stag] desc <table>              테이블 스키마 상세 조회
  ddb [dev|stag] get -t <table> <pk> [<sk>]    아이템 조회
  ddb [dev|stag] query -t <table> [options]    쿼리
  ddb [dev|stag] scan -t <table> [options]     스캔

dy 주요 옵션:
  -t, --table <name>             테이블명 (필수)
  -p, --partition-key <value>    파티션 키 값
  -s, --sort-key <value>         소트 키 값 또는 begins_with 프리픽스
  -i, --index <name>             GSI 이름 (예: gsi-1, GSI1)
  --filter <expression>          필터 표현식

쓰기 명령어(put, del, upd, bwrite)는 차단됩니다.
EOF
}

# ──────────────────────────────────────────

is_readonly() {
  local cmd="$1"
  for allowed in "${READONLY_COMMANDS[@]}"; do
    [[ "$cmd" == "$allowed" ]] && return 0
  done
  return 1
}

# op로 TOTP를 가져온 뒤 aws-vault exec 실행
run_with_auth() {
  local env="$1"
  shift

  local aws_profile="${AWS_PROFILES[$env]}"
  local op_item="${OP_ITEMS[$env]}"

  local totp
  totp=$(op item get "$op_item" --otp --account "$OP_ACCOUNT" 2>/dev/null) || totp=""

  if [[ -n "$totp" ]]; then
    aws-vault exec "$aws_profile" --mfa-token="$totp" -- "$@"
  else
    aws-vault exec "$aws_profile" -- "$@"
  fi
}

# ──────────────────────────────────────────

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi

  case "$1" in
    context)
      if [[ $# -ge 2 ]]; then
        # 서비스명 지정 시 해당 블록만 추출 (최상위 키 기준)
        local service="$2"
        awk "/^${service}:/{found=1} found{print} found && /^[^ ]/ && !/^${service}:/{exit}" "$SCHEMA_FILE"
      else
        cat "$SCHEMA_FILE"
      fi
      ;;

    dev|stag)
      local env="$1"
      shift

      if [[ $# -eq 0 ]]; then
        echo "오류: dy 명령어를 지정하세요." >&2
        usage
        exit 1
      fi

      local dy_cmd="$1"

      if ! is_readonly "$dy_cmd"; then
        echo "오류: '$dy_cmd'는 허용되지 않습니다. 읽기 전용 명령어만 사용 가능합니다." >&2
        echo "허용: ${READONLY_COMMANDS[*]}" >&2
        exit 1
      fi

      run_with_auth "$env" dy "$@"
      ;;

    -h|--help|help)
      usage
      ;;

    *)
      echo "오류: 알 수 없는 명령어 또는 환경: $1" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
