#!/bin/sh
# git clean filter: replace secret values with __REDACTED__ in claude/settings.json
# Also strips .model and .effortLevel (previous filter behavior)
SECRETS_FILE="$HOME/dotfiles/.zshsecrets"

input=$(cat)

if [ -f "$SECRETS_FILE" ]; then
  while IFS= read -r line; do
    case "$line" in
      export\ *=*)
        val=$(printf '%s' "$line" | sed 's/^export [^=]*="\(.*\)"/\1/')
        [ -n "$val" ] && input=$(printf '%s' "$input" | sed "s|$val|__REDACTED__|g")
        ;;
    esac
  done < "$SECRETS_FILE"
fi

printf '%s' "$input" | jq 'del(.model, .effortLevel)'
