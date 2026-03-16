# Dotfiles

개인 개발 환경 설정을 위한 dotfiles 저장소입니다.

## 설치

```bash
git clone https://github.com/cmygray/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

> Homebrew가 먼저 설치되어 있어야 합니다.

## 자동 설정되는 항목

### 🔗 심볼릭 링크 설정

| 소스 | 대상 |
|------|------|
| `.zshrc` | `~/.zshrc` |
| `.zshenv` | `~/.zshenv` |
| `.gitconfig` | `~/.gitconfig` |
| `.gitignore` | `~/.gitignore` |
| `.wezterm.lua` | `~/.wezterm.lua` |
| `.hammerspoon/` | `~/.hammerspoon/` |
| `starship.toml` | `~/.config/starship.toml` |
| `nvim/` | `~/.config/nvim/` |
| `gh-dash/` | `~/.config/gh-dash/` |
| `zed/keymap.json` | `~/.config/zed/keymap.json` |
| `zed/settings.json` | `~/.config/zed/settings.json` |
| `karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/agents/` | `~/.claude/agents/` |
| `claude/commands/` | `~/.claude/commands/` |
| `claude/skills/` | `~/.claude/skills/` |

### 📦 자동 설치

- **Homebrew 패키지**: `Brewfile` 기반 일괄 설치
- **pipx 패키지**: `requirements-pipx.txt` 기반 설치
- **gh 확장**: `gh-extensions.txt` 기반 설치

### ⚙️ Git 필터

Claude Code `settings.json`에서 `model` 필드를 커밋 시 자동 제거합니다.

```
filter.strip-claude-local.clean = jq 'del(.model, .effortLevel)'
```

## TODO

- [x] sync gh extensions (`gh-extensions.txt`)
- [x] zellij 설정 링크 추가

직접 설치할 앱들:

- 1password
- authy
- karabiner
- appcleaner
- brave
- fantastical
- hammerspoon
- monitorcontrol (appstore)
- pdf expert
- homerow
- wezterm

참고:

- https://blog.appkr.dev/work-n-play/dotfiles/
