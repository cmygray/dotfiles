// Single source of truth for the eval glossary. Edit here; the mod reloads.
//
// scope: 채점 프롬프트 eval 하네스 (generative-ai-service writing-service/eval/report, english-writing-service/eval/report)
// sources:
//   - writing-service/eval/report/README.md (origin/main) — 측정 계층, 회귀 판정 규칙, 라벨 규칙
//   - writing-service/eval/report/metrics/compute.py (origin/main) — nMAE·편향·급락·flip 계산식
//   - ~/src/grading-eval-data/baseline-2026-10-21/metrics.md — 표 머리글 정의
//
// match: regular expressions tried on the prose of a reply (code spans and
// fences removed); keep single letters (A, B, C, S) tied to their context.
// context: the notation is common elsewhere (L1 of a curriculum, a cache, a
// norm; 급락 and drift as plain words), so the term counts only where the same
// text also shows the eval context: a term without `context`, or an ANCHOR.

export type Term = {
  id: string
  term: string
  short: string
  long: string
  match: readonly string[]
  context?: true
}

export const ANCHORS: readonly string[] = ['하네스', '(?<![A-Za-z])eval(?![A-Za-z])', '베이스라인', 'baseline', '골드셋', '교사 점수', '채점 프롬프트']

export const TERMS: readonly Term[] = [
  {
    "id": "flows",
    "context": true,
    "term": "A·B·C",
    "short": "채점 흐름 3종: A 국어 글쓰기 초3~중3, B 국어 글쓰기 고1~3, C 서논술형",
    "long": "운영 중인 채점 프롬프트 ID. A는 ko-default 번들, B는 ko-high 번들(둘 다 gpt-4.1), C는 ko-essay 프롬프트(ESSAY_GPT_MODEL·ESSAY_REASONING_EFFORT, prod는 gpt-5 / low).",
    "match": [
      "A·B·C",
      "A·B(?!·)",
      "(?:흐름|프롬프트) [ABC](?![A-Za-z0-9-])",
      "(?<![A-Za-z0-9-])[ABC] 흐름"
    ]
  },
  {
    "id": "c-d",
    "term": "C-D",
    "short": "서논술형 중 교사가 AI 점수를 수정한 건(불일치 집합). 교사 점수가 정답",
    "long": "L3 교사 (불)일치를 재는 표본. 신양중과 그 외 학교로 나눠 보고하고, 학급 수가 적어 클래스 bootstrap CI가 넓다.",
    "match": [
      "(?<![A-Za-z0-9])C-D(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "c-u",
    "term": "C-U",
    "short": "서논술형 중 교사가 수정하지 않은 건. 일치로 간주하지 않고 drift 감시에만 사용",
    "long": "교사가 손대지 않았다고 AI 점수가 맞다는 뜻은 아니므로 정답 라벨로 쓰지 않는다. 운영 저장 점수(A0)와 재채점 점수(A1)의 차이(drift)만 본다.",
    "match": [
      "(?<![A-Za-z0-9])C-U(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "set-s",
    "term": "S(참고)",
    "short": "teacherScore가 AI 점수와 같은 건. 참고 지표로만 보고",
    "long": "교사가 같은 값을 다시 저장한 경우로, 일치 근거로 쓰기엔 표본이 작아(베이스라인 5건) 참고용으로 분리했다.",
    "match": [
      "S\\(참고\\)",
      "집합 S(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "a0-a1",
    "context": true,
    "term": "A0 / A1",
    "short": "A0 = 운영에 저장된 당시 AI 점수, A1 = eval에서 다시 채점한 점수",
    "long": "같은 글에 대해 운영 기록(A0)과 현재 프롬프트로 재채점한 결과(A1)를 나란히 놓고, 어느 쪽이 교사에 더 가까운지 비교한다.",
    "match": [
      "(?<![A-Za-z0-9])A[01](?![A-Za-z0-9])"
    ]
  },
  {
    "id": "l0",
    "context": true,
    "term": "L0 계약",
    "short": "출력 계약 위반: Zod 통과, 항목 수·이름, 점수 범위, 루브릭 허용 집합, band 사이값, 총점 재계산 일치",
    "long": "회귀 판정에서 L0 위반은 1건이라도 회귀 후보다.",
    "match": [
      "(?<![A-Za-z0-9])L0(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "l1",
    "context": true,
    "term": "L1 노이즈 플로어",
    "short": "같은 입력을 N회(기본 3) 반복 채점했을 때의 흔들림: 총점 SD·최대 편차, flip률",
    "long": "반복을 가로지르는 지표라 단일 실행 화면(예: Datadog 실험)에서는 계산할 수 없다. 회귀 판정은 베이스라인 클래스 bootstrap 95% CI 상한 초과 여부로 한다.",
    "match": [
      "(?<![A-Za-z0-9])L1(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "l2",
    "context": true,
    "term": "L2 변별력",
    "short": "원본 vs 규칙 기반 변형(truncate·repeat·noun_stuff·off_topic). 기대: 원본 점수 ≥ 변형 점수",
    "long": "위반률과 하락 폭을 본다. 베이스라인에서 repeat·noun_stuff 변형은 점수가 거의 떨어지지 않았다.",
    "match": [
      "(?<![A-Za-z0-9])L2(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "l3",
    "context": true,
    "term": "L3 교사 (불)일치",
    "short": "AI 점수와 교사 점수의 차이: nMAE, 방향 편향, 항목 정확·인접 일치, A0 vs A1",
    "long": "C-D 집합에서 잰다. A·B는 교사 수정 기록이 없어 운영 데이터로는 측정할 수 없다(HIL 라벨 필요).",
    "match": [
      "(?<![A-Za-z0-9])L3(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "l4",
    "context": true,
    "term": "L4 judge",
    "short": "LLM judge(gpt-4o-mini)로 점수·피드백 정합과 학년 수준 어휘를 판정",
    "long": "judge 자체의 보정은 아직 하지 않았다.",
    "match": [
      "(?<![A-Za-z0-9])L4(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "nmae",
    "term": "nMAE",
    "short": "정규화 평균 절대 오차 = |AI 총점 − 교사 총점| ÷ 만점의 평균. 0이면 완전 일치",
    "long": "글마다 만점이 달라 만점으로 나눠 비교한다. 베이스라인 C-D nMAE(A1)는 0.138이었다.",
    "match": [
      "(?<![A-Za-z0-9])nMAE(?![A-Za-z0-9])"
    ]
  },
  {
    "id": "bias",
    "context": true,
    "term": "편향",
    "short": "(AI 총점 − 교사 총점) ÷ 만점의 평균. 음수면 AI가 교사보다 낮게 줌",
    "long": "채점 정책이 정해지지 않아 회귀 판정에서는 CI 밖이면 '변화'로만 표시한다. 베이스라인 C-D는 −0.129.",
    "match": [
      "방향 편향",
      "편향(?= ?(?:A[01]|[-−+]?\\d|\\())"
    ]
  },
  {
    "id": "flip",
    "term": "flip률",
    "short": "반복 채점 사이에 항목 band(상·중·하)나 루브릭 단계, 성취수준이 바뀐 비율",
    "long": "항목 flip률은 항목 단위, 성취수준 flip률은 글 단위(C만)로 센다. 비율 지표라 회귀 판정 허용 오차는 ±2pt.",
    "match": [
      "flip ?률",
      "flip rate"
    ]
  },
  {
    "id": "collapse",
    "context": true,
    "term": "급락",
    "short": "같은 글의 최고 반복보다 30pt(만점 대비) 이상 낮게 나온 반복",
    "long": "반복 채점 중 한 회차만 크게 무너지는 현상. 베이스라인 C에서 9.1%.",
    "match": [
      "급락"
    ]
  },
  {
    "id": "between-band",
    "term": "band 사이값",
    "short": "A·B 항목 점수가 band 경계 사이(31~39, 71~79)에 떨어진 경우. 계약 위반",
    "long": "band는 상 80~100, 중 40~70, 하 0~30이다.",
    "match": [
      "band 사이값",
      "사이값"
    ]
  },
  {
    "id": "adjacent",
    "term": "인접 일치",
    "short": "항목 점수가 교사와 루브릭 한 단계 이내로 같은 비율(정확 일치보다 느슨함)",
    "long": "",
    "match": [
      "인접 일치"
    ]
  },
  {
    "id": "cluster-ci",
    "term": "클래스 bootstrap CI",
    "short": "학급 단위로 재표집한 95% 신뢰구간. 같은 학급 글끼리 닮은 점을 반영",
    "long": "학급이 적으면 폭이 넓어지고, 학급이 1개면 폭이 0이 되어 판정 의미가 없다.",
    "match": [
      "bootstrap ?CI",
      "95% ?CI",
      "CI 폭",
      "클래스 boot(?:strap)?"
    ]
  },
  {
    "id": "regression-candidate",
    "term": "회귀 후보",
    "short": "compare.py가 베이스라인 대비 나빠졌다고 표시한 지표. 자동 차단이 아니라 사람 확인 대상",
    "long": "L0 1건 이상, L1 SD·L2 위반률·L3 nMAE의 CI 상한 초과, 비율 지표 ±2pt 초과가 기준이다.",
    "match": [
      "회귀 후보"
    ]
  },
  {
    "id": "drift",
    "context": true,
    "term": "drift",
    "short": "C-U에서 운영 저장 점수(A0)와 재채점 점수(A1)의 차이 ÷ 만점",
    "long": "",
    "match": [
      "(?<![A-Za-z])drift(?![A-Za-z])"
    ]
  },
  {
    "id": "hil",
    "term": "HIL",
    "short": "human-in-the-loop. 사람이 직접 라벨을 다는 검토 팩",
    "long": "A·B는 교사 라벨이 없어 HIL 라벨링 팩으로 정답을 만든다.",
    "match": [
      "(?<![A-Za-z])HIL(?![A-Za-z])"
    ]
  },
  {
    "id": "qwk",
    "term": "QWK",
    "short": "quadratic weighted kappa. 순서형 점수의 일치도, 큰 차이에 더 큰 벌점",
    "long": "골드셋 설계 문서의 통과 기준은 Williamson 재인용으로 QWK .70.",
    "match": [
      "(?<![A-Za-z])QWK(?![A-Za-z])"
    ]
  },
  {
    "id": "smd",
    "term": "SMD",
    "short": "standardized mean difference. AI와 사람 점수 평균 차이를 표준편차로 나눈 값",
    "long": "골드셋 설계 문서의 통과 기준은 SMD .15 이내.",
    "match": [
      "(?<![A-Za-z])SMD(?![A-Za-z])"
    ]
  },
  {
    "id": "mcnemar",
    "term": "McNemar 정확검정",
    "short": "같은 표본의 두 조건 결과(예: 흔들림 여부)가 엇갈린 건수만으로 차이를 보는 검정",
    "long": "조건 A에서만 바뀐 건과 조건 B에서만 바뀐 건의 비대칭을 이항 분포로 검정한다. 평가 루프 PoC에서는 low→medium에서 새로 흔들린 표본 7 vs 안정된 0, p=0.016.",
    "match": [
      "McNemar"
    ]
  }
]
