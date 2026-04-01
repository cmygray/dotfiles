Review the user's recent English prompts logged in `~/.claude/english-prompts.log`.

## Output destination

Append the review to a single Obsidian note:
- Path: `/Users/classting-won/Library/Mobile Documents/iCloud~md~obsidian/Documents/English Reviews.md`
- If the file doesn't exist, create it with the header `# English Reviews`.
- Append each review session as a new date section at the end of the file.

## Append format

```markdown

## YYYY-MM-DD

### 1. <short topic label>

- **Original**: the prompt as-is
- **Suggested**: a more natural English version
- **Note**: brief explanation of what changed and why

### 2. ...

**Patterns**: <comma-separated list of recurring patterns>
```

## Instructions

1. Read `~/.claude/english-prompts.log`. If the file doesn't exist or is empty, tell the user there are no prompts to review yet.
2. Focus on the most recent 20 entries.
3. For each prompt that has room for improvement, create a numbered subsection with Original, Suggested, and Note.
4. Skip prompts that are already natural English.
5. If Korean words are mixed in, suggest the English equivalent the user was probably looking for.
6. Append the Patterns line summarizing recurring mistakes for this batch.
7. Append the review to the Obsidian note above.
8. After writing, truncate the log file using Bash: `> ~/.claude/english-prompts.log` (do NOT use the Write tool for this — use Bash to avoid permission prompts).
9. Show the user a brief summary of how many entries were reviewed.
