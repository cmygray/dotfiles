---
name: reportbot
description: 작업 결과나 결정 요청을 인터랙티브 HTML 리포트로 만들어 mdgate로 서빙. "리포트로 보여줘", "리치 보고서", "인터랙티브하게", "reportbot" 등의 요청에 반응. 휴먼 인 더 루프 UX가 필요할 때 사용.
allowed-tools: Bash(mdgate *), Bash(curl http://localhost:9483/*), Bash(curl -X * http://localhost:9483/*), Bash(open *), Bash(mkdir *), Read, Write, Edit
---

# reportbot — 인터랙티브 HTML 리포트

작업 결과를 단순 마크다운보다 풍부하게 보여주거나, 사용자에게 의견·결정·평가를 받아야 할 때 사용한다.
raw HTML을 자유롭게 작성해 `mdgate`로 서빙하고, 사용자의 인터랙션을 JSONL 사이드카로 받아 후속 작업에 활용한다.

## 핵심 원칙

1. **자유로운 HTML** — 정형화된 템플릿 없음. 컨텍스트에 맞는 UX를 그때마다 생성. 단일 `.html` 파일로 self-contained 하게 작성 (외부 JS/CSS 의존 X, inline style/script).
2. **인터랙션은 `window.mdgate.record(kind, payload)` 로** — mdgate가 서빙하면서 자동으로 inject하는 헬퍼. 모든 사용자 액션은 이걸로 기록.
3. **kind는 의미 있게** — `button-click`, `form-submit`, `choice-selected`, `annotation-added` 등 의도가 드러나는 이름.

## 워크플로우

### 1. 데몬 확인

```bash
curl -sf http://localhost:9483/health || mdgate --daemon &
```

### 2. HTML 작성

저장 위치: `~/.mdgate/reports/$(date +%Y%m%d-%H%M%S)-<slug>.html` (또는 작업 디렉토리 안).

기본 스켈레톤:

```html
<!DOCTYPE html>
<html><head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>...</title>
  <style>/* inline */</style>
</head>
<body>
  <!-- 컨텐츠 -->
  <button onclick="window.mdgate.record('button-click', {id: 'approve'})">승인</button>
</body></html>
```

### 3. 등록 + URL 출력

```bash
FILE=/path/to/report.html
SLUG=$(curl -s -X POST http://localhost:9483/_api/register \
  -H 'Content-Type: application/json' \
  -d "{\"filePath\":\"$FILE\",\"baseDir\":\"$(dirname $FILE)\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['slug'])")

echo "Local:  http://localhost:9483/$SLUG/"
echo "Share:  https://docs.two.kim/$SLUG/   (터널 활성화 시)"
open "http://localhost:9483/$SLUG/"
```

### 4. 인터랙션 폴링 (필요한 경우)

사용자 피드백을 기다려 후속 작업을 해야 한다면:

```bash
REL=$(basename $FILE)
SINCE=""
while true; do
  RES=$(curl -sG "http://localhost:9483/$SLUG/_api/interactions/$REL" --data-urlencode "since=$SINCE")
  COUNT=$(echo "$RES" | python3 -c "import sys,json;print(len(json.load(sys.stdin)))")
  if [ "$COUNT" -gt 0 ]; then
    echo "$RES" | python3 -m json.tool
    SINCE=$(echo "$RES" | python3 -c "import sys,json;print(json.load(sys.stdin)[-1]['ts'])")
    # 여기서 사용자 의도 파악 → 후속 작업
    break  # 또는 계속 폴링
  fi
  sleep 3
done
```

폴링은 3~5초 간격으로. 불필요한 출력 없이 조용히 대기.

### 5. 정리 (선택)

리포트가 더 이상 필요 없으면:

```bash
curl -s -X POST http://localhost:9483/_api/unregister \
  -H 'Content-Type: application/json' \
  -d "{\"slug\":\"$SLUG\"}"
```

대시보드(http://localhost:9483/)에서 직접 제거해도 됨.

## 자주 쓰는 인터랙션 패턴

- **단일 선택지 결정**: 버튼들에 `mdgate.record('choice', {value: 'A'})`
- **자유 피드백**: textarea + 제출 버튼 → `mdgate.record('feedback', {text: ta.value})`
- **다중 평가**: 체크박스/슬라이더 + 제출 → `mdgate.record('rating', {item: 'X', score: 4})`
- **어노테이션**: 클릭한 좌표/대상 → `mdgate.record('annotate', {target: id, note: ...})`

## 언제 reportbot이 아닌 다른 걸 써야 하나

- 단순 마크다운 문서 검토 → `mdgate-review` 또는 `mdgate <file.md>`
- 코드 실행 결과 데모 → `showme` (showboat + mdgate)
- 일회성 짧은 질문 → 굳이 HTML 안 만들고 AskUserQuestion 도구로

## 저장된 인터랙션

- 위치: `<html-file>.interactions.jsonl`
- 포맷: `{"ts": ISO8601, "kind": str, "payload": any}` 줄 단위 append-only
- 같은 리포트가 여러 번 사용되면 이력이 누적됨
