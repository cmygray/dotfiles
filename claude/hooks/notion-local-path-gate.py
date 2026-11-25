#!/usr/bin/env python3
# PreToolUse hook: 노션 쓰기 도구의 본문에 로컬 파일 경로가 들어가면 막는다.
# 노션 독자는 이 컴퓨터의 파일을 열 수 없으므로, 파일은 첨부(notion-create-file-upload)로 올려야 한다.
#
# 검사 대상: tool_input 안의 모든 문자열(content, new_str, content_updates[].new_str, pages[].content 등). old_str은 제외
# 막는 것:
#   - 절대 경로와 홈 경로: /Users/, ~/, /var/folders/, /private/tmp/, /tmp/, /home/
#   - 백틱 안의 파일·폴더 경로: `a/b`, `x.md`, `scripts/run.py` 같은 것
#   - 꺽쇠 괄호 「」 (원이 슬롭이라고 함. 인용은 큰따옴표로)
# 막지 않는 것:
#   - URL(://가 있는 것). notion-file-block://, file-upload:// 첨부 소스 포함
#   - 백틱 안의 낱말(`text`, `pick`)처럼 경로가 아닌 코드 표기
#
# stdin: {"tool_name": "...", "tool_input": {...}}
# stdout: 막을 때만 PreToolUse permissionDecision deny JSON

import json
import re
import sys

ABS = re.compile(r"(?<![\w:/])(?:/Users/|~/|/var/folders/|/private/tmp/|/tmp/|/home/)[^\s`)\]\"'<>]*")
TICK = re.compile(r"`([^`\n]+)`")
EXT = re.compile(r"\.(md|py|mjs|js|ts|tsx|json|jsonl|html|csv|tsv|yaml|yml|sh|txt|sql|ipynb|zip|pdf)$", re.I)


# old_str는 페이지에 이미 있는 글(지울 대상)이라 검사하지 않는다. 낫표나 경로를 지우는 편집이 막히지 않게 하려는 것이다.
SKIP_KEYS = {"old_str"}


def strings(x):
    if isinstance(x, str):
        yield x
    elif isinstance(x, dict):
        for k, v in x.items():
            if k in SKIP_KEYS:
                continue
            yield from strings(v)
    elif isinstance(x, list):
        for v in x:
            yield from strings(v)


def looks_like_path(s):
    s = s.strip()
    if "://" in s or " " in s:
        return False
    if s.startswith(("/", "~/", "./", "../")):
        return True
    if "/" in s and re.search(r"[A-Za-z0-9_-]/[A-Za-z0-9_.-]", s):
        return True
    return bool(EXT.search(s))


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    hits = []
    for s in strings(data.get("tool_input", {})):
        hits += ABS.findall(s)
        hits += [m for m in TICK.findall(s) if looks_like_path(m)]
    hits = list(dict.fromkeys(h.strip() for h in hits))
    brackets = any(("「" in s or "」" in s) for s in strings(data.get("tool_input", {})))
    if not hits and not brackets:
        return
    if not hits:
        reason = "노션 본문에 꺽쇠 괄호 「」가 있습니다. 인용은 큰따옴표(\"\")로 바꾸십시오."
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}, ensure_ascii=False))
        return
    shown = ", ".join(hits[:6]) + (" 외" if len(hits) > 6 else "")
    reason = (
        "노션 본문에 로컬 파일 경로가 있습니다: " + shown + ". "
        "노션 독자는 이 컴퓨터의 파일을 열 수 없습니다. "
        "보여 줄 파일은 notion-create-file-upload로 받은 upload_url에 upload_headers를 붙여 curl -F file=@<경로>로 올리고, "
        "돌려받은 <file source=\"file-upload://...\"/> 를 본문에 넣으십시오. "
        "파일이 필요 없으면 경로를 지우고 무엇인지 말로 쓰십시오."
        + (" 꺽쇠 괄호 「」도 큰따옴표로 바꾸십시오." if brackets else "")
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
