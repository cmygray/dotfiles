---
name: nview
description: Rex 터미널에서 옆 팬에 nvim 을 띄워 사용자에게 코드를 보여 준다. diff 검토, 특정 라인 하이라이트와 설명, 2~3곳 나란히 비교, 위치 목록(quickfix). "nview", "보여줘", "diff 띄워줘", "옆에 열어줘", "라인 하이라이트" 요청이나, 변경을 마치고 검토를 요청할 때 사용. REX_SESSION 이 있을 때만 쓴다.
---

# nview — 옆 팬 nvim 으로 코드 보여 주기

채팅에 코드를 길게 붙이는 대신, 사용자가 평소 쓰는 nvim 에서 바로 보게 합니다. 탭마다 nvim 하나를 따로 두고 재사용하며, 처음 부르면 현재 팬 오른쪽에 포커스를 옮기지 않고 split 해서 띄웁니다. 모든 명령은 읽기 전용으로 엽니다.

## 언제 쓰는가

- `REX_SESSION` 환경 변수가 있을 때만 씁니다. 없으면 평소처럼 채팅에 보여 줍니다.
- 사용자가 직접 보는 게 나은 경우에만 씁니다. 에이전트 혼자 읽을 코드는 Read 로 읽습니다.
- 한 응답에 nview 호출은 1~2번으로 제한합니다. 탭을 쏟아 내지 않습니다.

## 명령 4개 + 정리

| 상황 | 명령 |
|---|---|
| 변경을 마치고 검토를 요청할 때 | `nview diff` (작업 트리 vs HEAD), `nview diff <rev>`, `nview diff <a> <b>` |
| "여기 보세요" 한 곳 | `nview show <file>:<from>-<to> "한 줄 설명"` |
| 호출부↔정의, 타입↔사용처처럼 2~3곳 | `nview side <file>:<l> <file>:<l> [<file>:<l>]` |
| 위치가 4곳 이상(근거, grep 결과, 리뷰 지적) | `rg -n <pat> \| nview list "제목"` 또는 `printf 'a.ts:10:설명\n…' \| nview list "제목"` |
| 다 보고 정리 | `nview clear` (nview 탭과 표시만 지움), `nview close` (팬 종료) |

- 경로는 현재 작업 디렉터리 기준 상대 경로로 써도 됩니다.
- `show` 설명은 한 줄로, 왜 이 줄을 보라는지를 씁니다.
- diff 는 파일 8개까지만 탭으로 엽니다. 더 많으면 결과에 생략 개수가 나오니, 나머지는 `git diff --name-only | sed 's/$/:1/' | nview list` 로 넘깁니다.

## 결과 확인

- 출력이 `ok …` 이면 성공이고, `ERR …` 이면 exit 1 로 실패합니다. 실패하면 메시지를 보고 고쳐서 다시 부릅니다.
- 화면까지 확인해야 할 때만 `rex capture -s "$REX_SESSION" -b <nview 블록>` 을 씁니다. 블록 이름은 `nview` 입니다(`rex block ls -s "$REX_SESSION"`).
- 응답에는 무엇을 띄웠는지 한 줄로 알립니다. 예: "옆 팬에 diff 3개 파일을 띄웠습니다."

## 구성

- 엔진: `~/dotfiles/scripts/nview` (bash, PATH 에 있음)
- nvim 쪽 로직: `~/dotfiles/nvim/lua/nview.lua` (매 호출마다 dofile, 하이라이트 그룹 `NviewFocus`·`NviewNote`)
- 소켓: `$TMPDIR/nview-<탭(window) ID 끝 12자>.sock` (탭을 못 찾으면 세션 ID), `NVIEW_SOCK` 으로 바꿀 수 있습니다.
