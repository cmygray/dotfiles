---
name: dynamodb
model: sonnet
description: DynamoDB 자연어 조회. "DynamoDB에서 조회", "테이블 확인", "dynamodb", "ddb" 등의 요청에 반응.
allowed-tools: Bash(dy *), Bash(aws-vault exec * -- dy *), Bash(aws-vault list), Read, Glob, Grep
---

# DynamoDB 자연어 조회

자연어 질문을 DynamoDB 쿼리로 변환하여 데이터를 조회합니다.

## 워크플로우

1. **질문 분석** — 사용자의 자연어 질문에서 대상 서비스, 엔티티, 조건을 파악
2. **스키마 참조** — `references/schema.yaml`에서 테이블, 키 패턴, GSI 확인
3. **쿼리 구성** — 적절한 dy 명령어 조합
4. **실행 및 해석** — 결과를 사용자 질문에 맞게 해석하여 응답

## 환경

| 환경 | AWS 프로필 | 비고 |
|------|-----------|------|
| dev  | `aws-vault exec classting-dev` | 개발 환경 |
| stag | `aws-vault exec classting-stag` | 스테이징 환경 |

사용자가 환경을 명시하지 않으면 반드시 확인할 것.

## 인증

```bash
# MFA TOTP가 필요한 경우 (aws-vault이 자동 처리)
aws-vault exec <profile> -- dy <command>
```

## dy CLI 명령어 (읽기 전용만 허용)

```bash
# 테이블 목록
dy list

# 테이블 스키마 상세
dy desc -t <table>

# 아이템 조회 (PK + SK)
dy get -t <table> <pk> [<sk>]

# 쿼리 (PK 필수, SK 조건 선택)
dy query -t <table> <pk> [-i <gsi>] [-s <sk_condition>]

# 스캔 (주의: 대량 데이터)
dy scan -t <table> [--limit N]
```

### 차단 명령어

put, del, upd, bwrite, admin, bootstrap, import, export, backup, restore — 쓰기/관리 명령은 절대 실행하지 않는다.

## dy 주요 옵션

- `-t, --table <name>` — 테이블명 (필수)
- `<pk>` — 파티션 키 값 (query/get의 **위치 인자**)
- `-s, --sort-key <expr>` — 소트 키 조건 (예: `'begins_with Contract#'`, `'= Member#abc'`)
- `-i, --index <name>` — GSI 이름 (예: gsi-1, GSI1)
- `-a, --attributes <cols>` — 출력할 속성 (쉼표 구분)
- `--keys-only` — PK/SK만 출력
- `--filter <expression>` — 필터 표현식
- `--limit <N>` — 결과 수 제한

## 테이블명 패턴

`{service}-{env}` (예: `classroom-service-dev`, `writing-service-stag`)

## 쿼리 예시

```bash
# 이메일로 계정 조회
aws-vault exec classting-stag -- dy query -t account-service-stag -i gsi-1 'AccountEmail#user@example.com'

# 계정이 속한 조직의 멤버 조회
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-3 'Account#15089337373340913'

# 멤버의 라이센스 조회 (SK begins_with)
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-1 'Member#abc123' -s 'begins_with Contract#'

# 특정 속성만 출력
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-1 'Contract#xyz' -a 'id,orgId,licenses,variants'
```

## 스키마 참조

쿼리를 구성하기 전에 반드시 `references/schema.yaml`을 읽어 키 패턴과 GSI를 확인할 것.
소스코드에서 키 매핑 로직을 추가로 확인해야 할 경우 Glob/Grep/Read 도구를 사용할 수 있다.
