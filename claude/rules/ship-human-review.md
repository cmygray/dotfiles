## ship: 사람 확인 단계 (terminal-browser)

`/ship`(dev@superct)을 대화형으로 실행해 stage 5(report)에 도달했고, `REX_SESSION`이 있으며 `terminal-browser`를 쓸 수 있으면, 리포트만 보여 주지 말고 화면을 같이 띄워 원이 직접 확인하게 합니다. 이 단계는 PR을 만들기 전(stage 6 전)이므로, 승인이 곧 "ready to review"로 넘어간다는 뜻입니다.

1. **빌드 확인:** 프리뷰(`ct app deploy`)는 `index.html`이 최대 60초 캐시됩니다. 배포된 빌드의 sha가 `verified_head`와 같은지 먼저 확인합니다. 다르거나 확인할 수 없으면 탭을 열지 않고 그 사실을 보고합니다.
2. **첫 탭:** 프리뷰면 `<preview_base_url>/__switch__?to=<instance>`, 로컬이면 runner 매니페스트의 `base_url`을 `terminal-browser open <url> --split right`로 엽니다. 이미 이 Rex 탭에 terminal-browser가 있으면 split하지 않고 `new-tab`을 씁니다.
3. **AC 탭:** verifier가 돌려준 UI AC의 `url`마다 `terminal-browser new-tab <url>`로 탭을 하나씩 엽니다. 같은 URL은 한 번만 엽니다.
4. **리포트:** stage 5 검증 리포트 표에 `탭` 열을 붙여 AC와 탭 번호를 잇습니다(`terminal-browser ls`로 확인). `NOT COVERED`·FAIL 행은 맨 위에 올리고, 사람이 무엇을 눌러 봐야 하는지 한 줄로 적습니다.
5. **승인:** 원이 승인하면 stage 6(pr)으로 진행합니다. 문제를 지적하면 해당 AC를 고치고 재배포·재검증한 뒤 이 단계를 다시 합니다. `terminal-browser action`으로 화면을 조작했다면 마지막에 `terminal-browser action done`을 실행합니다.

조건(대화형, `REX_SESSION`, `terminal-browser`)이 하나라도 없으면 이 규칙을 건너뛰고 ship의 원래 stage 5를 따릅니다. 이 규칙은 ship의 다른 단계와 불변식을 바꾸지 않습니다.
