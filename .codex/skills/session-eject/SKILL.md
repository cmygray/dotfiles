---
name: session-eject
description: Recover wide working context from a session ID when the user asks to eject, resume, recover, hand off, 비상탈출, or reconstruct prior context in a Codex session. Use this when given a session ID and asked to pull as much context as possible from ~/.codex, and also check ~/.claude when the same work crossed tools.
---

# Session Eject

Use this skill when the user wants a session-level recovery or handoff by ID.

## What to do

1. Run `scripts/session_eject.sh <session-id>`.
2. Read the output and summarize the durable context:
   - what the session was about
   - key decisions
   - branch / repo / files involved
   - latest unresolved point
   - any stale or conflicting artifacts
3. If the script finds both Codex and Claude artifacts, merge them. Treat Claude transcripts as richer when available.
4. If the script finds only partial data, say what was found and what was missing.

## Output style

- Lead with the working conclusion, not raw logs.
- Keep the summary compact and operational.
- Include concrete file paths when they matter.
- Call out stale plans or mismatches explicitly.

## Notes

- Codex local history may only contain prompt history, not full transcripts.
- Claude project transcripts under `~/.claude/projects/.../<session-id>.jsonl` usually provide the widest reconstruction.
- Prefer exact session IDs over fuzzy search.
