# Initialize mise for all zsh sessions
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi
. "$HOME/.cargo/env"
