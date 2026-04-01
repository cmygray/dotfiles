#!/bin/sh
# git smudge filter: restore __REDACTED__ with actual secret values
SECRETS_FILE="$HOME/dotfiles/.zshsecrets"

input=$(cat)

if [ -f "$SECRETS_FILE" ]; then
  while IFS= read -r line; do
    case "$line" in
      export\ *=*)
        key=$(printf '%s' "$line" | sed 's/^export \([^=]*\)=.*/\1/')
        val=$(printf '%s' "$line" | sed 's/^export [^=]*="\(.*\)"/\1/')
        [ -n "$val" ] && input=$(printf '%s' "$input" | sed "s|\"$key\": \"__REDACTED__\"|\"$key\": \"$val\"|g")
        ;;
    esac
  done < "$SECRETS_FILE"
fi

printf '%s\n' "$input"
