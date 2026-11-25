#!/bin/sh
# notion-create-file-upload 가 돌려준 upload_url 과 upload_headers(JSON)로 로컬 파일 하나를 올린다.
# 사용: upload.sh '<upload_url>' '<upload_headers JSON>' <파일 경로>
# 출력: 노션 응답 JSON (status 가 uploaded 여야 함)
set -e
URL="$1"; HEADERS="$2"; FILE="$3"
[ -f "$FILE" ] || { echo "파일 없음: $FILE" >&2; exit 1; }
set --
for h in $(printf '%s' "$HEADERS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr ' ' '\037'); do
  k=${h%%=*}; v=$(printf '%s' "${h#*=}" | tr '\037' ' ')
  set -- "$@" -H "$k: $v"
done
curl -sS -X POST "$URL" "$@" -F "file=@$FILE"
