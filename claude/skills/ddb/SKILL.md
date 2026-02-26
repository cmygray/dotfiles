---
name: ddb
description: DynamoDB 읽기 전용 조회. DynamoDB 데이터를 조회할 때 사용. "DynamoDB에서 조회", "테이블 확인", "ddb" 등의 요청에 반응.
allowed-tools: Bash(ddb *)
---

# DynamoDB 읽기 전용 조회

`ddb` CLI를 통해 DynamoDB 데이터를 읽기 전용으로 조회합니다.
쓰기 명령(put, del, upd)은 차단됩니다.

## 워크플로우

1. **스키마 파악** — 반드시 `ddb context`를 먼저 실행해 테이블명, 키 패턴, GSI를 확인
2. **환경 지정** — `dev` 또는 `stag` 필수
3. **쿼리 실행** — 읽기 전용 명령어만 허용

## 명령어

```
ddb context                                          # 스키마 전체 출력
ddb context classroom-service                        # 특정 서비스 스키마만
ddb [dev|stag] list                                  # 테이블 목록
ddb [dev|stag] desc -t <table>                       # 테이블 스키마 상세
ddb [dev|stag] get -t <table> <pk> [<sk>]            # 아이템 조회
ddb [dev|stag] query -t <table> -p <pk> [-i <gsi>]   # 쿼리
ddb [dev|stag] scan -t <table> [options]             # 스캔
```

## 테이블명 패턴

`{service}-{env}` (예: `classroom-service-dev`, `writing-service-stag`)

## dy 주요 옵션

- `-t, --table <name>` — 테이블명 (필수)
- `-p, --partition-key <value>` — 파티션 키 값
- `-s, --sort-key <value>` — 소트 키 값 또는 begins_with 프리픽스
- `-i, --index <name>` — GSI 이름 (예: gsi-1, GSI1)
- `--filter <expression>` — 필터 표현식
