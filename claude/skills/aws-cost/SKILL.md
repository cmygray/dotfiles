---
name: aws-cost
description: Classting AWS 비용 조회·분석. "AWS 비용", "빌링", "하이퍼빌링", "비용 모니터링", "지난달 비용", "cost", "비용 추이", "비용 스파이크" 등의 요청에 반응. AWS Cost Explorer 대신 메가존 HyperBilling Open-API 사용.
allowed-tools: Bash(op read *), Bash(curl *), Bash(python3 *), Bash(date *)
---

# aws-cost — HyperBilling 기반 AWS 비용 분석

## 핵심 전제 (2026-07 확인)

- **AWS Cost Explorer(`aws ce`)는 사용 불가.** Classting 계정은 메가존 리셀러 payer 하위라 CE가 차단됨. `aws-vault exec ... aws ce`를 시도하지 말고 바로 HyperBilling Open-API로 간다.
- OpenAPI 스펙: `https://resource.hyper.megazone.com/docs/mzc/ko/open-api/userGuide.json` (billing.mzc.megazone.com의 user-guide 페이지는 SPA — JSON은 이 resource 호스트에 있음). 새 엔드포인트가 필요하면 여기서 확인.
- 로컬 노트: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/wiki/raw/articles/HyperBilling.md`

## ⚠️ STEP 0 (필수): 날짜 확인

```bash
date '+%Y-%m-%d'
```
TimePeriod는 이 결과 기준. 훈련 데이터 연도로 추측 금지.

## 인증 — 1Password (값 노출 금지)

시크릿은 1Password `Classting` 볼트에 있고 Touch ID 승인이 뜬다.
**값을 echo/cat/로그로 출력하지 않는다. 확인은 길이만.**

```bash
ID=$(op read "op://Classting/HyperBilling Open-API/username")     # X-Client-Id
SEC=$(op read "op://Classting/HyperBilling Open-API/credential")  # X-Client-Secret
echo "id_len=${#ID} sec_len=${#SEC}"
```

## API — `https://open.hyperapi.megazone.com`

공통 헤더: `content-type: application/json`, `X-Client-Id: $ID`, `X-Client-Secret: $SEC`

| 용도 | 엔드포인트 | 비고 |
|---|---|---|
| 연결 계정 목록 | `GET /v1/search/linkedaccount` | 인증 확인 겸용 |
| 최근 3개월 합산 | `POST /v2/search/billing/last-3-months` | body: `{"Filter":{"LinkedAccount":[...]}}` |
| 상세 조회(원본) | `POST /v1/search/billing` | 아래 body 참조, 페이지네이션 필수 |

`/v1/search/billing` body:
```json
{"Filter":{"LinkedAccount":["..."],"Granularity":"MONTHLY",
           "TimePeriod":{"Start":"YYYY-MM-01","End":"YYYY-MM-DD"}},
 "GroupBy":["USAGE_DATE","SERVICE_CODE"],"Result":["USAGE_COST"]}
```
- 응답 `Results[]`의 각 row: `GroupBy.USAGE_DATE`, `GroupBy.SERVICE_CODE`, `Value.USAGE_COST`
- **1000건 제한**: 응답의 `NextDataToken`을 `Filter.NextDataToken`에 넣어 빌 때까지 반복 (안전장치로 max 20 페이지)

## 계정

| Account ID | 이름 |
|---|---|
| 220554832478 | prod |
| 291242499047 | stag |
| 561064969579 | (미매핑) |
| 619981949925 | (미매핑) |

기본은 4개 전체 합산. 미매핑 계정의 정체를 확인하게 되면 이 표를 갱신할 것.

## 분석 규칙

1. **계산은 전부 Python 스크립트로** (합계·비중·MoM 등 LLM 암산 금지).
2. **교차검증**: v1 원본 월별 합계 ↔ v2 last-3-months가 일치해야 정합. 불일치하면 페이지네이션 누락부터 의심.
3. **미완료월 주의**: 당월은 빌링 지연 포함 부분 데이터. MoM 비교는 완료월끼리만 유효하다고 명시.
4. **역주행 플래그**: 다른 서비스가 (미완료월 효과로) 감소하는데 홀로 증가하는 서비스는 실제 증가 추세 가능성으로 표시.

## 출력 형식

- 월별 추이 표 (총비용, MoM, 미완료월 `*` 각주)
- Top 서비스 드라이버 표 (월별 × 기간 합 × 비중, 상위 10~15개)
- "눈에 띄는 점" — 역주행·스파이크·절감 후보 (EC2/S3/RDS RI·SP 커버리지 등)
- 마지막에 시크릿 무노출 처리 여부 한 줄 명시
