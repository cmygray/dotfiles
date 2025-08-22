# Dotfiles

개인 개발 환경 설정을 위한 dotfiles 저장소입니다.

## 설치

```bash
git clone https://github.com/cmygray/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## 자동 설정되는 항목

### 🔗 심볼릭 링크 설정
- `~/Brewfile` → Homebrew 패키지 목록
- `~/.gitconfig` → Git 전역 설정
- `~/.gitignore` → Git 전역 ignore 패턴
- `~/.hammerspoon/` → Hammerspoon 자동화 스크립트
- `~/.wezterm.lua` → WezTerm 터미널 설정
- `~/.config/starship.toml` → Starship 프롬프트 설정
- `~/.config/gh-dash/` → GitHub Dashboard 설정
- `~/.config/zed/` → Zed 에디터 설정 (keymap, settings)
- Nushell 설정 (`config.nu`, `env.nu`)

### 📦 자동 설치
- **Homebrew 패키지**: Brewfile 기반 일괄 설치
- **Oh My Zsh**: 미설치 시에만 자동 설치
- **Nushell**: 기본 쉘로 설정 (설치되어 있을 경우)

## TODO

- [ ] sync karabiner
- [ ] sync gh extensions
- [ ] GPG 설정 자동화

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
