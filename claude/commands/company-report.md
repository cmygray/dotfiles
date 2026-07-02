---
name: company-report
description: '한국 기업 분석 리포트 1건 생성 + home.two.kim 배포 (/company-report <회사명> [innoforest_URL])'
---

# Company Report — 한국 스타트업/기업 분석 리포트 생성

인자: $ARGUMENTS

## 사용법

```
/company-report <회사명> [innoforest_company_URL] [innoforest_investor_URL]
```

- `<회사명>`: 정확한 한글/영문 표기 (예: "에임인텔리전스", "VNTG")
- `[innoforest_company_URL]` (선택, 권장): 혁신의숲 회사 페이지 URL. **검색이 인덱싱 누락이 잦으니 직접 주는 게 안전**
- `[innoforest_investor_URL]` (선택): 회사가 투자사 페이지도 가지면 함께

## 예시

```
/company-report 에임인텔리전스 https://www.innoforest.co.kr/company/CP00019435/...
/company-report VNTG https://www.innoforest.co.kr/company/CP00011257/... https://www.innoforest.co.kr/investor/IV00000608/...
/company-report 워시스왓
```

## 절차

이 명령은 `company-brief` 스킬을 발동시킵니다. 스킬이 다음 4단계를 자동 진행:

### 1단계 — 인자 파싱

`$ARGUMENTS`에서:
- 첫 번째 토큰: 회사명
- 두 번째 토큰(있으면): innoforest company URL
- 세 번째 토큰(있으면): innoforest investor URL

회사명만 있고 URL이 없으면 사용자에게 한 번 더 확인 (혁신의숲 검색이 자주 누락되므로). 단순 회사명 조회로 충분히 신뢰할 수 있는 경우(이미 알려진 대형 기업 등)에는 URL 없이 진행.

### 2단계 — 인증 + 데이터 수집

```bash
REPORTS_DIR="${REPORTS_DIR:-/Users/won/Workspace/research/reports}"

# 세션마다 한 번 (이미 인증된 상태면 빠르게 통과)
bash "${REPORTS_DIR}/_scripts/restore-cookies.sh"

# 통합 데이터 수집
bash "${REPORTS_DIR}/_scripts/fetch-company.sh" "<회사명>" "<url>" "<investor_url>"
```

→ `$CLAUDE_JOB_DIR/<slug>/` 안에 innoforest + DART + 웹 검색 결과 저장됨.

WebSearch도 병렬로 호출하여 투자 라운드 상세, 최근 뉴스, 인물 정보 보강.

### 3단계 — HTML 작성

수집된 데이터에서 다음 분류:

| 패턴 | 트리거 | 참고 |
|---|---|---|
| 재무 풍부형 | DART 감사보고서 + 매출 수치 명확 | `washswat.html`, `bosalpim_analysis.html` |
| 매출 비공개형 | 외감 미대상 / 신생 / 매출 "-" | `aim_intelligence.html` |
| 양면 회사 | innoforest 회사+투자사 둘 다 | `vntg.html` |

```bash
SLUG=<영문_소문자_slug>
cp "${REPORTS_DIR}/_template/skeleton.html" "${REPORTS_DIR}/${SLUG}.html"
```

`{{placeholder}}`를 데이터로 치환. 불필요 섹션 삭제. sister report에서 컴포넌트 복사.

리포트 구성 권장 섹션:
1. Executive summary (`.tldr`)
2. 핵심 지표 (`.kpis` 4 or 8개)
3. 손익 분석 (재무 데이터 있을 때만)
4. 재무 분석 (재무 데이터 있을 때만)
5. 투자 타임라인 (`.timeline`)
6. 비즈니스/제품 (`.product-grid`)
7. 고객·파트너 (`.logos`)
8. 핵심 시그널 (`ol.signals`, 5~7개 긍정·주의·위험 혼합)
9. 검증해야 할 항목 (`.verify`, 3-grid)

### 4단계 — 배포 + 인덱스 갱신

```bash
# 정적 호스팅 자동 서빙
curl -sS -o /dev/null -w "HTTP %{http_code}\n" "https://home.two.kim/${SLUG}.html"
```

`index.html`에 새 카드 1개 추가 (기존 카드 동일 형식).

## 출력 형식 (사용자에게 보여줄 것)

```
✓ <회사명> 리포트 생성 완료

URL:  https://home.two.kim/<slug>.html
크기: NN,NNN bytes
패턴: 재무 풍부형 / 매출 비공개형 / 양면 회사

핵심 발견:
1. ...
2. ...
3. ...

검증해야 할 핵심 3가지:
- ...
```

## 디자인 규칙 — 반드시 지킬 것

- **CSS는 `assets/report.css`만** — 새 파일 만들지 말 것
- **차트는 Chart.js 4.4.1 (CDN)**
- **이모지 사용 X** (사용자 명시 요청 외)
- **숫자 한글 단위** — "10억원", "228명"
- **푸터에 출처 표기** — `DART corp_code: ...`, `혁신의숲 ID: ...`
- **시그널은 긍정·주의·위험 혼합**

## 데이터 수집 시 자주 만나는 함정

- **혁신의숲 검색 인덱싱 누락**: 회사명 검색에 결과 0건이어도 페이지가 존재할 수 있음 → 사용자에게 URL 요청
- **DART 표기 다양화**: "AIM Suho" vs "에임인텔리전스" — 한글/영문 둘 다 시도
- **dartcli finance 미동작**: 비상장은 사업보고서 미제출. 감사보고서 접수번호로 `dartcli view <번호>`
- **agent-browser 세션 만료**: `restore-cookies.sh` 재실행, 안 되면 ID/PW 재로그인 필요 알림
- **누적 투자 차이**: 혁신의숲은 비공개 라운드 미집계 → 미디어 보도와 차이 가능, 둘 다 표기

## 보안

- 사용자 ID/PW를 받았다면 한 번만 사용 후 쿠키만 저장 (`~/.innoforest_cookies.txt`)
- `${VAR:+yes}${VAR:-no}` 같은 길이 체크 표현 절대 금지 — 값이 노출됨. `[ -n "$VAR" ]` 패턴 사용
- 작업 종료 시 `.env` 정리 안내
