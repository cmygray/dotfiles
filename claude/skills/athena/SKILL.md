---
name: athena
description: Classting prod DW를 AWS Athena로 직접 조회. "athena", "아테나", "DW 조회", "데이터 웨어하우스", "prod 데이터 뽑아줘", "이벤트 몇 건", "SQL로 조회" 등의 요청에 반응. Redash 저장 쿼리 재사용이 목적이면 redash 스킬을 쓴다.
allowed-tools: Bash(aws-vault exec classting-prod *), Bash(sleep *), Bash(python3 *), Bash(date *)
---

# athena — prod DW 직접 조회

## 핵심 전제 (2026-07 확인)

- 계정: **classting-prod (220554832478)**, 리전 `ap-northeast-2`. 항상 `aws-vault exec classting-prod -- aws athena ...`.
- 워크그룹: `primary` (Athena engine v3 = Trino SQL). 기본 출력 위치가 없으므로 **`--result-configuration` 필수**.
- 결과 버킷: `s3://athena-won/results/` (개인 버킷 컨벤션 `athena-<이름>`, 30일 자동 만료 라이프사이클 설정됨).
- Glue 카탈로그에 DB 52개. 주요: `classting_dw`, `classting_mart`, `classting_event`, `classting_kpi`, `ai_learning_stats`, `mixpanel`, `minerva-stats`, `account_service_prod`, `classroom_service_prod`.

## 실행 패턴

```bash
QID=$(aws-vault exec classting-prod -- aws athena start-query-execution \
  --work-group primary \
  --result-configuration "OutputLocation=s3://athena-won/results/" \
  --query-string "SELECT ..." \
  --query 'QueryExecutionId' --output text)

# 폴링 (2초 간격, 상태가 SUCCEEDED/FAILED/CANCELLED면 종료)
aws-vault exec classting-prod -- aws athena get-query-execution \
  --query-execution-id "$QID" \
  --query 'QueryExecution.Status.[State,StateChangeReason]' --output text
```

- FAILED면 `StateChangeReason`에 원인이 있다. 추측하지 말고 이걸 먼저 읽는다.
- 스캔 비용 확인: `QueryExecution.Statistics.DataScannedInBytes`. 큰 테이블은 파티션 컬럼(대개 날짜)으로 반드시 프루닝.

## 결과 수신 — 크기에 따라 2가지

**소량(수백 행 이하)**: `get-query-results` (페이지네이션 `NextToken`, 첫 행은 헤더)

```bash
aws-vault exec classting-prod -- aws athena get-query-results \
  --query-execution-id "$QID" --output json
```

**대량**: API 페이지네이션 대신 결과 CSV를 통째로 받는다 (훨씬 빠름)

```bash
aws-vault exec classting-prod -- aws s3 cp \
  "s3://athena-won/results/${QID}.csv" "$CLAUDE_JOB_DIR/tmp/result.csv"
```

## 탐색 순서 (테이블을 모를 때)

1. `SHOW TABLES IN classting_dw` 또는 `information_schema.tables`에서 이름 검색
2. `DESCRIBE <db>.<table>` 또는 `SHOW CREATE TABLE`로 파티션 컬럼 확인
3. 본 쿼리 전에 `LIMIT 10` 샘플로 스키마·값 형태 검증

## 분석 규칙

1. 집계·비율 계산은 Python으로 재검증 (LLM 암산 금지).
2. prod 데이터이므로 **읽기 전용**. DDL/CTAS/INSERT는 사용자가 명시적으로 요청할 때만.
3. 결과에 개인정보(이메일·이름·전화번호)가 포함되면 요약만 보고하고 원본 덤프를 대화에 붙이지 않는다.
