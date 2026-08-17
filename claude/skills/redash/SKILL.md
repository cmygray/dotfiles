---
name: redash
description: Classting Redash 저장 쿼리 검색·실행·결과 조회. "redash", "리대시", "대시보드 쿼리", "저장된 쿼리 돌려줘" 등의 요청에 반응. ad-hoc SQL이 목적이면 athena 스킬이 우선.
allowed-tools: Bash(op read *), Bash(curl *), Bash(python3 *), Bash(sleep *)
---

# redash — 저장 쿼리 재사용

## 핵심 전제 (2026-07 확인)

- 엔드포인트: `https://redash.classting.com`
- 팀이 검증해둔 저장 쿼리 재사용이 주 용도. 새 ad-hoc SQL은 athena 스킬로 직접 치는 게 낫다.

## 인증 — 1Password (값 노출 금지)

User API Key는 1Password `Classting` 볼트 `Redash` 항목의 `credential` 필드에 있다. Touch ID 승인이 뜬다.
**키 값을 echo/cat/로그로 출력하지 않는다. 확인은 길이만.** aws-cost 스킬과 같은 규칙.

Redash REST API는 `Authorization: Key <api_key>` 헤더로 인증한다 (Bearer 아님).

## API 레시피

| 용도 | 엔드포인트 |
|---|---|
| 쿼리 검색 | `GET /api/queries?q=<검색어>&page_size=25` |
| 쿼리 상세(SQL 본문) | `GET /api/queries/{id}` |
| 재실행(refresh) | `POST /api/queries/{id}/refresh` → `job` 반환 |
| 잡 폴링 | `GET /api/jobs/{job_id}` → `status:3`=성공, `4`=실패 |
| 결과 조회 | `GET /api/query_results/{query_result_id}.json` (`.csv`도 가능) |
| 캐시된 최신 결과 | `GET /api/queries/{id}/results.json` |
| 데이터소스 목록 | `GET /api/data_sources` |

실행 흐름: refresh → job 폴링(2초 간격, `status`가 3 또는 4면 종료) → `job.query_result_id`로 결과 조회.
파라미터 있는 쿼리는 refresh body에 `{"parameters": {...}, "max_age": 0}`.

## 규칙

1. 신선한 데이터가 필요하면 refresh, 대략적 추이면 캐시된 최신 결과로 충분 — DW 스캔 비용을 아낀다.
2. 저장 쿼리를 수정(POST/DELETE)하지 않는다. 조회·실행만.
3. 결과에 개인정보가 포함되면 요약만 보고하고 원본 덤프를 대화에 붙이지 않는다.
