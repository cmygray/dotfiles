# Blast Radius — Typed Edge Propagation Graph

대상 저장소의 아키텍처 의존성 그래프를 인터랙티브 HTML로 시각화합니다.

## 입력

$ARGUMENTS 형식: `<repo-path> [--scope <keyword>] [--output <path>]`

- `repo-path`: 대상 저장소 경로 (필수)
- `--scope`: 특정 도메인/에픽에 집중 (선택, 예: "writing", "member")
- `--output`: 출력 HTML 경로 (선택, 기본: `<repo-path>/blast-radius.html`)

## 실행 절차

### Step 1 — 저장소 탐색

대상 저장소를 탐색하여 아키텍처를 파악합니다.

1. **메타 파일 분석**: `package.json`, `README.md`, `serverless.yml`, `tsconfig.json`
2. **아키텍처 패턴 식별**:
   - React 프로젝트: `pages/`, `components/`, `hooks/`, `services/` 디렉토리 구조
   - NestJS CQRS: `modules/`, `use-cases/`, `domain/`, `controllers/` 구조
   - Worker: `functions/`, `event-handlers/`, `consumers/` 구조
3. **핵심 컴포넌트 수집**:
   - Controllers/Routes (API 엔드포인트)
   - Handlers/UseCases (비즈니스 로직)
   - Entities/Models (도메인 모델)
   - Event Publishers/Subscribers (이벤트 흐름)
   - Repository/DB 접근 패턴
4. **의존 관계 매핑**:
   - import graph (calls 엣지)
   - HTTP API 호출 (api 엣지)
   - EventBridge/SQS 이벤트 (event 엣지)
   - DynamoDB/MySQL 접근 (ddb/mysql 엣지)

`--scope`가 지정된 경우 해당 키워드와 관련된 컴포넌트만 수집합니다.

### Step 2 — graph-data.json 생성

탐색 결과를 아래 스키마에 맞춰 JSON으로 구조화합니다.

```jsonc
{
  "meta": {
    "title": "프로젝트명 — Architecture Graph",
    "description": "설명",
    "services": ["service1", "service2"],  // compound node 그룹
    "tags": [                               // 선택: 에픽/스프린트 태그
      {"id": "tag1", "label": "Label", "color": "#hex"}
    ]
  },
  "nodes": [
    {
      "id": "unique_id",        // 고유 식별자 (svc_layer_name 패턴 권장)
      "label": "DisplayName",   // 노드에 표시
      "kind": "handler",        // 노드 타입 (아래 목록 참조)
      "svc": "service1",        // 소속 서비스 (meta.services와 일치)
      "layer": "handler",       // 아키텍처 레이어
      "wci": ["tag1"],          // 태그 (선택)
      "path": "relative/path"   // 파일 경로 (info 패널에 표시)
    }
  ],
  "edges": [
    {
      "s": "source_id",    // 출발 노드
      "t": "target_id",    // 도착 노드
      "type": "calls",     // 엣지 타입 (아래 목록 참조)
      "label": "optional"  // 엣지 라벨 (선택)
    }
  ]
}
```

**Node kind 목록**: component, hook, api, handler, entity, vo, event, worker, ddb, mysql, newapi

**Edge type 목록**: calls, api, event, ddb, mysql

**Layer 매핑 규칙**:

| 아키텍처 | 레이어 순서 |
|---------|------------|
| Bulletproof React | page → component → hook → service |
| NestJS CQRS | controller → handler → domain → infra |
| Worker/Consumer | consumer → handler → state → notification |

**ID 네이밍 컨벤션**:
- FE 컴포넌트: `fe_<name>` (예: `fe_upload_dialog`)
- BE 핸들러: `be_<name>` (예: `be_create_order`)
- 이벤트: `evt_<name>` (예: `evt_order_created`)
- DB 상태: `ddb_<field>` 또는 `mysql_<field>`

### Step 3 — 빌드

```bash
node ~/Workspace/serviz/blast-radius/build.mjs <data-dir> <output-path>
```

이 명령은 `graph-data.json`과 `graph-config.json`을 `index.html` 템플릿에 인라인하여 single HTML 파일을 생성합니다.

`graph-config.json`이 data-dir에 없으면 `~/Workspace/serviz/blast-radius/graph-config.json` 기본값을 사용합니다.

### Step 4 — 결과 공유

```bash
open <output-path>
```

또는 mdgate로 공유:
```bash
mdgate <output-path>
```

## 주의사항

- 노드 수는 20~60개가 적정 범위. 너무 많으면 핵심 컴포넌트만 선별
- cross-service 이벤트 흐름은 자동 추출이 어려우므로 수동 매핑 필요
- NestJS CQRS의 CommandBus 간접 호출은 정적 분석으로 추적 불가 — 컨벤션 기반으로 매핑
- `newapi` kind는 아직 구현되지 않은 계획 중인 엔드포인트에 사용
- 태그(wci)는 비즈니스 스코프 — 코드에서 자동 추출 불가, 사용자에게 확인 필요

## 예시

```bash
# 전체 아키텍처
/blast-radius ~/Workspace/organization

# 특정 도메인 집중
/blast-radius ~/Workspace/generative-ai-service --scope writing

# 여러 저장소 통합 (수동)
# 1. 각 저장소 탐색 → 하나의 graph-data.json에 합치기
# 2. services 배열에 모든 서비스 나열
/blast-radius ~/Workspace/ai-web ~/Workspace/generative-ai-service ~/Workspace/minerva-api
```

## 툴체인 파일 위치

```
~/Workspace/serviz/blast-radius/
├── index.html          ← Cytoscape.js 렌더러 템플릿
├── graph-config.json   ← 기본 스타일/레이아웃 설정
├── build.mjs           ← single HTML 빌더
├── example-wci.json    ← WCI 예시 (multi-service, 50+ nodes)
├── example-org.json    ← Organization 예시 (single service, event-driven)
└── README.md           ← 스키마 문서
```
