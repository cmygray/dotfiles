# dotfiles — 글로벌 Codex 설정 저장소

이 레포는 `~/.Codex/` 하위 설정의 source of truth입니다.

## 심볼릭 링크 구조

- `~/.Codex/{skills, rules, agents, settings.json, RTK.md}` → `dotfiles/Codex/...`
- `~/.Codex/hooks/rtk-rewrite.sh`는 글로벌 (dotfiles 외)
- 이 경로 아래 파일을 수정하면 **즉시** 글로벌에 반영됨

## 커밋/푸시 규칙

- `commit push` = 브랜치/PR 없이 `main`에 직접 푸시 (이 레포만의 규칙)
- 이유: 본인 단일 사용자, 설정 동기화가 목적

## settings.json 시크릿 관리

- `.gitattributes`에 `Codex/settings.json filter=strip-Codex-local` 등록
- `scripts/secret-{clean,smudge}.sh` 가 `~/.zshsecrets`의 `export KEY="VAL"`을 읽어 자동 변환
  - commit 시: 실제값 → `__REDACTED__`
  - checkout 시: `__REDACTED__` → 실제값
- 따라서 working copy에 평문 토큰이 보여도 정상. git에는 절대 안 들어감.
- 새 시크릿 추가: `~/.zshsecrets`에 `export KEY="VAL"` 한 줄 추가하면 자동 연동

## 변경 후 확인 포인트

- skill/rule/agent 추가: 새 세션을 띄워야 인식됨
- settings.json 수정: `/doctor` 또는 재시작
