---
name: company-brief
description: 한국 스타트업/기업 분석 리포트 작성. 회사명이 주어지고 "리포트", "기업 분석", "기업 브리프", "company brief" 등의 키워드가 함께 나오면 자동 발동. DART(외감 대상)·혁신의숲(로그인 인증)·웹 검색을 통합해 HTML 리포트로 산출하고 home.two.kim에 배포한다. 다른 회사 조사·간단한 사실 확인은 이 스킬을 쓰지 말 것.
metadata:
  version: "1.0.0"
---

# Company Brief — 한국 스타트업/기업 분석 리포트

🥷 한국 스타트업/기업을 외부 공개 데이터로 분석해 일관된 디자인의 HTML 리포트를 생성합니다.

## 발동 조건

다음을 동시에 만족하면 발동:
- 사용자가 특정 회사명을 지목
- "기업 분석", "리포트 만들어", "company brief", "기업 정보 정리", "투자 정보 조사" 등의 의도 표명

발동 안 함:
- 단순 사실 확인 ("○○○ CEO 누구야?")
- 인물 추적 (그건 그냥 검색)
- 회사명 없는 "스타트업 시장 분석" 같은 일반 주제

## 출력물

- `${REPORTS_DIR:-./reports}/<slug>.html` — 자립 HTML 리포트
- 정적 호스팅 환경이 있으면 즉시 배포 (이 사용자 환경: `https://home.two.kim/<slug>.html`)
- `${REPORTS_DIR}/index.html`에 카드 1개 추가

## 인프라 가정 (사용자 `won`의 환경 기준)

- **reports 디렉토리**: `/Users/won/Workspace/research/reports/` — 정적 파일을 두면 즉시 `https://home.two.kim/`에서 서빙됨 (Cloudflare Named Tunnel + Tailscale)
- **공통 CSS**: `reports/assets/report.css` — 변경 없이 link 참조만
- **HTML skeleton**: `reports/_template/skeleton.html`
- **데이터 수집 스크립트**: `reports/_scripts/restore-cookies.sh`, `fetch-company.sh`
- **DART API key**: `/Users/won/Workspace/research/.env`의 `DART_API_KEY`
- **혁신의숲 쿠키**: `~/.innoforest_cookies.txt` (chmod 600)

`REPORTS_DIR` 환경변수가 있으면 그쪽 사용. 없으면 위 절대 경로 폴백.

## 4단계 워크플로

### 1) 정보 수집 분기

```bash
# 세션마다 한 번 (이미 인증된 상태면 스킵)
bash "${REPORTS_DIR:-/Users/won/Workspace/research/reports}/_scripts/restore-cookies.sh"
```

회사명 받았으면 다음을 병렬로:
- `dartcli search "<회사명>"` — DART 등록 여부 확인 (등록이면 외감 대상)
- 사용자가 혁신의숲 URL을 같이 줬는지 확인 — 없으면 검색 시도, 단 **혁신의숲 검색은 인덱싱 누락이 빈번**하니 못 찾으면 사용자에게 URL 요청
- WebSearch — 투자 라운드, 뉴스, 인물

```bash
bash "${REPORTS_DIR:-...}/_scripts/fetch-company.sh" "<회사명>" "<innoforest_url>"
```

DART 등록이면 다음도:
- `dartcli company "<회사명>"` — 기업개황
- `dartcli list "<회사명>" --limit 5` — 공시 리스트
- 가장 최신 감사보고서 접수번호로 `dartcli view <번호>` — 매출/영업이익/자본 추출

### 2) 데이터 분류 — 어떤 패턴인가

수집된 데이터로 다음 중 분류:

| 패턴 | 트리거 | 참고 sister report |
|---|---|---|
| **재무 풍부형** | DART 감사보고서 다년치 + 매출/영업이익 명확 | `washswat.html`, `bosalpim_analysis.html` |
| **매출 비공개형** | 외감 미대상 또는 신생 스타트업, 매출 "-" | `aim_intelligence.html` |
| **양면 회사** | innoforest에 회사+투자사 둘 다 등록 | `vntg.html` |
| **순수 VC** | innoforest investor 페이지만 | (없음 — 처음 만들면 sister 됨) |

패턴별로 강조점이 다름:
- **재무 풍부형**: 3개년 손익·재무 차트, 자본 변동 분해, 판관비 분해
- **매출 비공개형**: 투자 벨로시티, Lead VC 격상, 고객 레퍼런스, 글로벌 인증, 인력 시그널, 트래픽
- **양면 회사**: `.duality` 헤드라인 + 본업/투자 섹션 명확 구분 + 시너지 검증
- **순수 VC**: 포트폴리오 통계, 공동투자사 네트워크, exit 추적

### 3) HTML 작성

```bash
SLUG=<영문_소문자_slug>
cp "${REPORTS_DIR}/_template/skeleton.html" "${REPORTS_DIR}/${SLUG}.html"
```

skeleton의 `{{placeholder}}`를 데이터로 치환. 불필요 섹션은 통째 삭제. 추가 컴포넌트는 sister report에서 복사:

| 컴포넌트 | CSS class | 용도 |
|---|---|---|
| Executive summary | `.tldr` | 3~5문장 결론 |
| KPI grid | `.kpis` + `.kpi` | 4 또는 8 카드 |
| Card | `.card` | 표·차트 컨테이너 |
| Two-column | `.two-col` | 표+차트 나란히 |
| Signal list | `ol.signals` | 5~7개 번호 카드 |
| Verify grid | `.verify` | 3-grid 검증 항목 |
| Timeline | `.timeline` | VC 라운드 시계열 |
| Product cards | `.product-grid` + `.product` | 3-up 제품 |
| Logo pills | `.logos` + `<span>` | 고객·파트너 |
| Duality | `.duality` | 양면 회사 헤드라인 |
| Badge | `.badge.pos/.neg/.warn` | 시그널 분류 |

### 4) 배포 + 인덱스 갱신

```bash
# 정적 호스팅 환경이면 파일을 두는 것만으로 즉시 서빙됨
# home.two.kim 사용자 환경에서 검증:
curl -sS -o /dev/null -w "HTTP %{http_code}\n" "https://home.two.kim/${SLUG}.html"
```

`index.html`에 새 카드 1개 추가 (기존 카드들과 같은 형식, `<a class="report-card" href="...">` 구조).

## 디자인 원칙

- **CSS는 만들지 말 것** — `assets/report.css` 외에 추가 inline 스타일 금지. 색상이 부족하면 그 파일에 추가 (CSS 변수 이용)
- **차트는 Chart.js 4.4.1 (CDN)** — 다른 라이브러리 도입 X
- **이모지 사용 안 함** — 사용자가 명시적으로 요청한 경우 외엔 본문에 이모지 넣지 말 것
- **숫자는 한글 단위로** — "1,000,000,000원"이 아니라 "10억원"
- **출처 표기** — 푸터에 `DART corp_code: ...`, `혁신의숲 ID: ...` 등 추적성 확보
- **시그널은 긍정·주의·위험 혼합** — 한쪽만 보이게 쓰지 말 것. 비판적 거리 유지

## 데이터 없을 때의 대체 시그널 (매출 비공개형)

- **투자 벨로시티** — 시드→Pre-A→Series A 간격
- **Lead VC 격상** — 라운드마다 더 큰 VC가 lead 되는지
- **고객 톱티어** — 금융·대기업·정부기관 도입 여부
- **글로벌 인증** — GITEX, Meta Award, OutSystems Premier 등
- **인력 시그널** — 헤드카운트, 채용 공고 수, CTO 영입 출신
- **트래픽** — MUV, 거래액, 단가, 전환율, 재구매율
- **외부 시각** — 혁신의숲 "함께 본 기업", 조회 순위
- **카테고리** — 시장 포지션

## 자주 발생하는 함정

- **혁신의숲 검색 누락**: 회사가 등록되어 있어도 검색이 안 잡힐 수 있음. 사용자에게 URL 직접 요청
- **DART corp_code 검색**: 한글/영문 표기 다양화 필요 ("AIM Suho" vs "에임인텔리전스")
- **dartcli finance 없음**: 비상장은 사업보고서 미제출 → 감사보고서를 `dartcli view <접수번호>`로 직접 fetch
- **agent-browser 세션 만료**: `restore-cookies.sh`로 재인증, 안 되면 사용자에게 알림
- **양면 회사 놓침**: 회사 페이지만 보고 끝내지 말고 같은 슬러그의 investor 페이지도 확인
- **누적 투자 차이**: 혁신의숲은 비공개 라운드 미집계 → 미디어 보도와 차이날 수 있음, 둘 다 표기

## 사용자 자격증명 보안

- ID/PW 받아서 쓸 때 `${VAR:+yes}${VAR:-no}` 같은 표현 금지 — set이면 값 출력됨. 길이 체크는 `[ -n "$VAR" ] && echo yes` 패턴 사용
- 로그인 후 즉시 쿠키만 저장하고 ID/PW는 더 이상 사용 X
- 작업 종료 시 사용자에게 `.env` 정리 + (가능하면) 비밀번호 변경 안내
