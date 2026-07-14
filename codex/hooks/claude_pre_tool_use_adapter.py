#!/usr/bin/env python3
"""Adapt Claude Code PreToolUse hook decisions to Codex exit semantics."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> int:
    print(message, file=sys.stderr)
    return 2


def main() -> int:
    if len(sys.argv) != 2:
        return fail("usage: claude_pre_tool_use_adapter.py <hook-script>")

    hook = Path(sys.argv[1]).expanduser()
    if not hook.is_file():
        return fail(f"hook script not found: {hook}")

    hook_input = sys.stdin.buffer.read()
    try:
        payload = json.loads(hook_input)
    except json.JSONDecodeError:
        return fail("invalid Codex hook input JSON")

    session_cwd = Path(payload.get("cwd") or os.getcwd()).expanduser()
    tool_workdir = payload.get("tool_input", {}).get("workdir")
    hook_cwd = Path(tool_workdir).expanduser() if tool_workdir else session_cwd
    if not hook_cwd.is_absolute():
        hook_cwd = session_cwd / hook_cwd
    if not hook_cwd.is_dir():
        return fail(f"hook cwd not found: {hook_cwd}")

    result = subprocess.run(
        [str(hook)],
        input=hook_input,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=hook_cwd,
        check=False,
    )

    if result.stderr:
        sys.stderr.buffer.write(result.stderr)

    lines = result.stdout.decode("utf-8", errors="replace").splitlines()
    nonempty = [line for line in lines if line.strip()]

    if result.returncode != 0:
        if nonempty:
            print("\n".join(nonempty), file=sys.stderr)
        return 2

    if not nonempty:
        return 0

    # Gate commands can emit lint/test logs before their final decision JSON.
    for line in nonempty[:-1]:
        print(line, file=sys.stderr)

    try:
        decision = json.loads(nonempty[-1])
    except json.JSONDecodeError:
        return fail(f"invalid Claude hook output: {nonempty[-1]}")

    action = decision.get("decision")
    if action in {"approve", "allow"}:
        return 0
    if action in {"deny", "block"}:
        return fail(decision.get("reason") or "blocked by policy hook")
    return fail(f"unsupported Claude hook decision: {action!r}")


if __name__ == "__main__":
    raise SystemExit(main())
