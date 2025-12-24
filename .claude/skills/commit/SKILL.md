# Commit

Automatically creates git commits with proper commit messages following project conventions.

## When to Use This Skill

**Proactively use this skill when:**
- User mentions "커밋" in any form (커밋해, 커밋해줘, 커밋 생성, etc.)
- User says "commit" or asks to create a commit
- User completed a task and needs to save changes
- User explicitly requests `/commit`

**DO NOT use when:**
- No staged changes exist
- User is just discussing commits without wanting to create one
- User asks about commit history (use git log instead)

## Instructions

### 1. Check Prerequisites

```bash
# Check git config
git config user.name
git config user.email

# Check for staged changes
git status
```

If no staged changes, inform user and exit.

### 2. Analyze Changes

Use the `git-analyzer` skill to:
- Detect commit message style (Conventional Commits or Chris Beams)
- Analyze staged changes
- Determine if changes should be split into multiple commits

### 3. Build Commit Message

Based on the detected style:

#### Conventional Commits Format:
```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

**Types**: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
- **scope**: 변경 범위 (영어, optional)
- **description**: 변경사항 요약 (한글, ≤50자)
- **body**: 상세 설명 (한글, optional)
- **footer**:
  - `BREAKING CHANGE:` for breaking changes
  - `Fixes #123` / `Closes #456` for issues
  - `Co-Authored-By: Claude <noreply@anthropic.com>` (required)

#### Chris Beams Style Format:
```
<Capitalized imperative title ≤50 chars>

<Body: what and why, wrapped at 72 chars>

<Footer: issue refs, co-author>
```

### 4. Ask for Issue Link (Optional)

If no issue reference is obvious:
- "이 커밋과 연결할 이슈 번호가 있나요? (예: #123, 없으면 skip)"

### 5. Show Draft and Confirm

Present the commit message draft to user:
- Show the complete message
- Ask for modifications if needed
- Get final approval

### 6. Execute Commit

```bash
git commit --signoff -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

**Important:**
- ALWAYS use `--signoff`
- Use heredoc for multi-line messages
- Use `;` not `&&` (Nushell syntax)
- NO emojis unless user explicitly requests

### 7. Report Success

Show commit hash and summary:
```
✅ Commit created: abc1234
feat(auth): JWT 토큰 검증 기능 추가
```

## Multiple Commits

If `git-analyzer` suggests splitting:
1. Explain the split plan to user
2. Get user approval
3. For each commit:
   - Use `git reset` to unstage files
   - Stage only relevant files
   - Create commit
   - Repeat

## Error Handling

- **No staged changes**: "Staged changes가 없습니다. 먼저 `git add`로 파일을 추가해주세요."
- **Git config missing**: Guide user to set `user.name` and `user.email`
- **Commit failed**: Show error message and suggest solutions

## Notes

- Use Nushell syntax (`;` not `&&`)
- Always include Co-Authored-By footer
- NO emojis by default
- Respect user's commit style history
