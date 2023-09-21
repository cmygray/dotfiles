alias alf="alias | fzf"
alias caff="export CAFFEINATED=true && caffeinate -d &"
alias decaff='unset CAFFEINATED && jobs -l | grep -e "caffeinate -d" | head -1 | cut -d " " -f 4 | xargs kill -9'
alias xargs="xargs "
alias cat="bat"
alias c="clipcopy"
alias v="clippaste"
alias n="noti -m 'Done'"
alias vim="nvim"
alias wz="wezterm"

# aws-vault
alias ave="aws-vault exec"
alias avl="aws-vault login"

# git
alias glgf="fzf-git-log"
alias gbf="fzf-git-branch"
alias gcof="fzf-git-checkout"
alias gg="git gone"

# github CLI
alias ghd="gh pr create --assignee @me --draft"
alias ghw="gh run watch"
alias ghr="gh pr ready"
alias ghwr="ghw && ghr"
alias ghcof="gh pr list --search \"user-review-requested:@me draft:false\" | fzf | grep -E -o \"^[0-9]+\" | c && v | xargs gh pr checkout"
alias lgtm="gh pr review --approve"

# docker
alias dcu="docker-compose up -d"
alias dcd="docker-compose down"
