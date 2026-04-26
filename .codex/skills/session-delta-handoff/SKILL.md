---
name: session-delta-handoff
description: Export only the new session context created after the last eject marker and produce a paste-ready handoff message. Use when Claude/Codex sessions are interrupted (for example usage-limit windows ending) and you need to resume the original thread with delta updates only, not full history. Supports clipboard copy with fallback file output.
---

# Session Delta Handoff

Use this skill to generate a compact handoff that contains only new user messages after the last eject marker.

## Workflow

1. Resolve the session ID.
- Prefer explicit ID from user input.
- Otherwise use `CODEX_THREAD_ID`.

2. Run the exporter script.
- Default (auto marker + clipboard best effort):
  - `scripts/session_delta_handoff.sh`
- Explicit session:
  - `scripts/session_delta_handoff.sh --session-id <session-id>`
- Explicit timestamp anchor:
  - `scripts/session_delta_handoff.sh --since-ts <epoch-seconds>`

3. Return the generated handoff text.
- If clipboard copy succeeds, say so.
- If clipboard copy fails, provide the output file path and paste the text directly.

## Script Behavior

`scripts/session_delta_handoff.sh` does all of the following:
- Find the latest anchor message matching `eject|이젝트` unless overridden.
- Collect only newer messages from `~/.codex/history.jsonl` for the session.
- Build a paste-ready Korean handoff block with:
  - anchor timestamp
  - delta message bullets
  - current git branch and latest two commits (if in a repo)
- Write to a timestamped file.
- Try clipboard tools in order: `pbcopy`, `wl-copy`, `xclip`.

## Failure Handling

- If session ID is missing, ask for session ID.
- If no anchor is found, treat the full session as delta and call that out.
- If no delta exists, return a short message that no new entries were found.
