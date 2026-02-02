---
name: event-storm
description: |
  이벤트 스토밍 다이어그램을 대화형으로 생성하는 스킬. 사용자와의 질문-응답을 통해
  Domain Event, Command, System, Actor, Policy 등의 구성요소를 점진적으로 도출하고
  Mermaid flowchart (.md 파일)과 PNG 이미지를 생성한다.
  YAML DSL (.es.yaml)로 구조화된 이벤트 카탈로그를 관리하고
  Mermaid, CML, MDSL Flow, JSON 등 다중 포맷으로 변환할 수 있다.

  When to use: 도메인 프로세스 분석, 소프트웨어 설계, 비즈니스 플로우 시각화 시 사용.
---

# Event Storm

이벤트 스토밍 다이어그램을 대화형으로 생성하는 스킬입니다.

## 사용 시점

**이 스킬을 사용하는 경우:**
- 도메인 프로세스를 시각화하고 싶을 때
- 시스템 간 이벤트 흐름을 분석할 때
- 비즈니스 요구사항을 이벤트 중심으로 정리할 때
- `/event-storm` 명령어 실행 시

**사용하지 않는 경우:**
- 단순 플로우차트가 필요한 경우
- 이미 완성된 다이어그램을 편집하는 경우
- 시퀀스 다이어그램이 더 적합한 경우

## 구성요소 요약

| 구성요소 | Mermaid 노드 | 색상 | 설명 |
|---------|-------------|------|------|
| Actor/Agent | `{{"고객"}}` (hexagon) | 노란색 | 행위자, 관련 인물/팀 |
| Command | `["주문 생성"]` (rectangle) | 파란색 | 결정/액션/의도 |
| System | `(["주문 시스템"])` (stadium) | 분홍색 | IT 시스템 |
| Domain Event | `(("주문 접수됨"))` (circle) | 주황색 | 도메인 이벤트 (과거형) |
| Policy | `{{"결제 정책"}}` (diamond) | 보라색 | 반응 규칙 (Whenever...) |
| Query Model | `[/"재고 현황"/]` (parallelogram) | 연두색 | 정보/읽기 모델 |
| Constraint | `[["재고 확인"]]` (subroutine) | 노란색 | 제약조건 |
| Hotspot | `(((("미정"))))` (double circle) | 빨간색 | 논쟁점/불확실성 |

> 상세 스펙은 `references/component-spec.md` 참조

## DSL 포맷 (YAML)

시나리오가 복잡하거나 카탈로그가 방대할 때 YAML DSL(`.es.yaml`)을 사용하여 이벤트 스토밍을 구조화한다.

### Flow Step 구조: `Trigger → Action (+ Context) → Result`

| 역할 | 필드 | 설명 |
|------|------|------|
| Trigger | `actor:`, `event:`, `external:` | 시작점 (하나만) |
| Action | `command:`, `query:` | 실행할 행위 |
| Context | `system:`, `via:`, `endpoint:`, `constraints:` | 환경/조건 |
| Result | `emits:` | 발생하는 이벤트 |
| Flow | `policy:`, `parallel:`, `branch:`, `after:` | 흐름 제어 |
| Doc | `note:`, `hotspot:` | 문서화 |

### 순서 결정 규칙

1. trigger 필드(`actor:`, `event:`, `external:`)가 있으면 자체 트리거
2. trigger 없이 `command:`/`query:`만 있으면 배열 순서상 이전 step에 이어짐
3. `after:` 명시 시 비선형 의존성 (배열 순서 무시)

### 에디터 스키마 지원

`.es.yaml` 파일 첫 줄에 다음 modeline을 추가하면 yamlls 기반 에디터에서 자동완성과 검증을 받을 수 있다:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/cmygray/dotfiles/refs/heads/main/.claude/skills/event-storm/references/dsl-schema.json
```

### DSL 예시

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/cmygray/dotfiles/refs/heads/main/.claude/skills/event-storm/references/dsl-schema.json
event-storm: "주문 처리"
type: software_design
metadata:
  scope: order-service

scenarios:
  - name: "주문 생성"
    flows:
      - actor: 고객
        command: CreateOrder
        system: 주문시스템
        constraints:
          - "재고 >= 주문수량"
        emits: OrderCreated

      - event: OrderCreated
        policy: "결제 필요 정책"
        command: ProcessPayment
        emits: PaymentCompleted

      - external: "결제 게이트웨이"
        after: PaymentCompleted
        command: ConfirmPayment
        emits: PaymentConfirmed

      - event: PaymentConfirmed
        parallel:
          - command: UpdateInventory
            emits: InventoryUpdated
          - command: SendNotification

states:
  - entity: Order
    transitions:
      - from: "[*]"
        to: Created
        trigger: CreateOrder
      - from: Created
        to: Paid
        trigger: ProcessPayment

decisions:
  - title: "결제 방식"
    decision: "외부 게이트웨이 연동"
    rationale: "PG사 의존성 분리"

hotspots:
  - name: "환불 정책"
    note: "환불 기준 미정"
```

> 스키마 상세: `references/dsl-schema.json`

## 워크플로우

### A. 대화형 → Mermaid (단순 프로세스)

#### Phase 1: 컨텍스트 파악

사용자에게 다음 질문을 순차적으로 한다:

**Q1. 이벤트 스토밍 유형**
```
어떤 유형의 이벤트 스토밍을 진행하시겠습니까?

1. Process Modelling - 비즈니스 프로세스 분석
2. Software Design - 소프트웨어 설계
```

**Q2. 도메인/프로세스명**
```
분석할 도메인 또는 프로세스의 이름을 알려주세요.
예: "주문 처리", "회원 가입", "결제 시스템"
```

**Q3. 초기 Domain Event 나열**
```
이 프로세스에서 발생하는 주요 이벤트를 나열해주세요.
이벤트는 과거형으로 작성합니다.

예시:
- 주문이 접수됨
- 결제가 완료됨
- 상품이 배송됨
```

#### Phase 2: 구성요소 도출 (반복)

각 Domain Event에 대해 다음 질문을 반복한다:

```
[이벤트: {event_name}]

1. 어떤 System이 이 이벤트를 발생시키나요?
2. 어떤 Command가 System을 호출하나요?
3. 누가(Actor) 이 Command를 실행하나요?
4. 이 이벤트 후 어떤 Policy가 반응하나요? (선택)
5. Actor가 결정에 필요한 정보(Query Model)는? (선택)
6. 제약조건(Constraint)이 있나요? (선택)
7. 불확실한 점(Hotspot)이 있나요? (선택)
```

**진행 중 표시:**
```
진행률: [██████░░░░] 3/5 이벤트 완료

수집된 구성요소:
- Domain Events: 5
- Actors: 2
- Commands: 4
- Systems: 3
- Policies: 1
```

#### Phase 3: 연결 관계 확인

수집된 구성요소 간의 연결 관계를 확인한다:

```
다음 연결 관계가 맞는지 확인해주세요:

1. [고객] --Decides to--> [주문 생성]
2. [주문 생성] --Invoked On--> [주문 시스템]
3. [주문 시스템] --Produces--> [주문 접수됨]
4. [주문 접수됨] --Activates--> [재고 확인 정책]

수정이 필요한 항목이 있으면 번호와 함께 알려주세요.
```

#### Phase 4: 출력 생성

사용자에게 출력 형식을 선택하게 한다:

**옵션 1: DSL 파일 생성 (권장 - 복잡한 도메인)**

수집된 정보를 `.es.yaml` DSL 파일로 출력한다. 이후 `parse_dsl.py`로 다중 포맷 생성 가능.

**옵션 2: Mermaid 다이어그램 직접 생성 (단순 프로세스)**

```bash
echo '<JSON_DATA>' | python3 ~/.claude/skills/event-storm/scripts/generate_mermaid.py
echo '<JSON_DATA>' | python3 ~/.claude/skills/event-storm/scripts/generate_mermaid.py --png
```

### B. DSL 기반 (복잡한 도메인/카탈로그)

**Step 1: DSL 작성 또는 생성**

대화에서 이벤트 스토밍 후 `.es.yaml` 파일로 출력하거나, 사용자가 직접 작성/편집.

**Step 2: 다중 포맷 생성**

```bash
# 모든 포맷 생성 (Mermaid + CML + MDSL + JSON)
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -o ./output

# Mermaid만 + PNG
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -f mermaid --png

# 특정 포맷
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -f cml
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -f mdsl
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -f json
```

**Step 3: 검증만**

```bash
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml --validate-only
```

## 스크립트 사용법

### generate_mermaid.py (레거시)

```bash
echo '{"title": "test", ...}' | python3 ~/.claude/skills/event-storm/scripts/generate_mermaid.py
python3 ~/.claude/skills/event-storm/scripts/generate_mermaid.py --png < input.json
```

### parse_dsl.py (신규)

```bash
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml           # 모든 포맷
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -f mermaid # Mermaid만
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml -f all --png -o ./out
python3 ~/.claude/skills/event-storm/scripts/parse_dsl.py input.es.yaml --validate-only
```

**출력 포맷:**

| 포맷 | 파일 | 용도 |
|------|------|------|
| `mermaid` | `{title}.md` | 시나리오별 flowchart + stateDiagram |
| `cml` | `{title}.cml` | Context Mapper DDD 도구 연동 |
| `mdsl` | `{title}.mdsl` | MDSL Flow (API 설계 파이프라인) |
| `json` | `{title}_{scenario}.json` | 레거시 generate_mermaid.py 호환 |

## 에러 처리

- **구성요소 누락**: 필수 구성요소(Event, System, Command, Actor)가 하나라도 없으면 다시 질문
- **순환 의존성 감지**: Policy → Command → System → Event → Policy 순환 시 경고
- **JSON 파싱 오류**: 스크립트 입력 JSON 형식 오류 시 상세 에러 메시지 출력
- **DSL 검증 오류**: 필수 필드 누락, 잘못된 YAML 구조 시 상세 에러 메시지

## 참고사항

- Nushell 문법 사용 (`;` 구분자)
- 이벤트 이름은 항상 과거형으로 작성
- Mermaid 노드 형태와 색상은 `references/component-spec.md` 참조
- DSL 스키마 상세는 `references/dsl-schema.json` 참조
