# dotfiles

macOS 개발 환경과 AI 코딩 에이전트(Claude Code, Codex CLI) 설정의 source of truth입니다.
여기서 파일을 수정하면 심볼릭 링크를 통해 즉시 글로벌 설정에 반영됩니다.

## 설치

```bash
git clone https://github.com/cmygray/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

- 심볼릭 링크는 Homebrew보다 먼저 걸리므로, Homebrew 없는 환경(SSH 등)에서도 링크까지는 동작합니다.
- 패키지 설치 단계부터는 Homebrew가 필요합니다.

## bootstrap.sh가 하는 일

1. **심볼릭 링크** — 셸/앱/에이전트 설정을 홈 디렉터리로 연결 (전체 목록은 `bootstrap.sh` 참조)
2. **git filter 등록** — `claude/settings.json` 커밋 시 시크릿 자동 제거 (아래 참조)
3. **패키지 설치** — `Brewfile`(brew bundle), `requirements-pipx.txt`(pipx), `gh-extensions.txt`(gh extension)

## 레포 구조

| 경로 | 내용 |
|------|------|
| `agent-common/` | Claude·Codex 공용 에이전트 지침 (`global.md`, `won-judgment.md`, `personas/`) |
| `claude/` | Claude Code 글로벌 설정 — `settings.json`, `CLAUDE.md`, `agents/`, `skills/`, `commands/`, `rules/`, `hooks/` → `~/.claude/*` |
| `codex/` | Codex CLI 설정 — `agents/`, `hooks.json` → `~/.codex/*`. `AGENTS.md`는 생성 파일(직접 수정 금지) |
| `scripts/` | 유틸리티 스크립트 (`qv`, `portview`, `secret-{clean,smudge}.sh`, `sync-agent-instructions.sh` 등) |
| `launchagents/` | macOS LaunchAgent (`portview` 서버, merged worktree 자동 정리) |
| `portview/` | portview 설정 |
| `nvim/`, `zed/`, `karabiner/`, `ghostty/`, `zellij/`, `gh-dash/`, `.hammerspoon/` | 앱별 설정 |
| `Brewfile`, `requirements-pipx.txt`, `gh-extensions.txt` | 패키지 목록 |
| `skills-lock.json` | 외부 소스에서 가져온 스킬의 버전 잠금 |

## AI 에이전트 설정

### Claude Code

- `~/.claude/{settings.json, CLAUDE.md, agents, commands, skills, rules}` → `claude/` 하위로 링크됨
- 이 레포에서 수정하면 즉시 반영. 단, skill/rule/agent 추가는 **새 세션**을 띄워야 인식되고, `settings.json` 수정은 `/doctor` 또는 재시작으로 확인

### Codex CLI

- `~/.codex/{agents, hooks.json}` → `codex/` 하위로 링크됨
- `codex/config.toml`은 **의도적으로 링크하지 않음** — Codex 앱이 런타임에 파일을 재작성하므로 앱 관리 파일로 둡니다
- `codex/AGENTS.md`는 `scripts/sync-agent-instructions.sh`가 `agent-common/*.md` + `codex/codex-specific.md`를 합쳐 생성합니다. 공용 지침을 고치려면 `agent-common/`을 수정 후 스크립트를 재실행하세요

## 시크릿 관리

- `.gitattributes`에서 `claude/settings.json`에 `strip-claude-local` filter 적용
- `scripts/secret-{clean,smudge}.sh`가 `~/.zshsecrets`의 `export KEY="VAL"` 목록을 읽어 변환
  - commit 시: 실제값 → `__REDACTED__`
  - checkout 시: `__REDACTED__` → 실제값
- working copy에 평문 토큰이 보여도 정상이며, git 히스토리에는 들어가지 않습니다
- 새 시크릿 추가: `~/.zshsecrets`에 `export KEY="VAL"` 한 줄 추가하면 자동 연동

## 커밋 규칙

- 이 레포에서 `commit push` = 브랜치/PR 없이 `main`에 직접 푸시 (단일 사용자, 설정 동기화 목적)
