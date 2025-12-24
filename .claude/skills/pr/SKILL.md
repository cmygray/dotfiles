# Pull Request

Automatically creates GitHub Pull Requests with proper title and description.

## When to Use This Skill

**Proactively use this skill when:**
- User mentions "PR" in any form (PR 만들어, PR 생성, Pull Request, etc.)
- User says "pull request" or asks to create a PR
- User completed a feature and wants to merge
- User explicitly requests `/pr`

**DO NOT use when:**
- User is just discussing PRs without wanting to create one
- No commits to push
- User asks about existing PRs (use `gh pr list` instead)

## Instructions

### 1. Check Prerequisites

```bash
# Check current branch and remote status
git status
git branch --show-current
git log origin/main..HEAD --oneline

# Check if gh CLI is authenticated
gh auth status
```

### 2. Analyze Branch Changes

Use the `git-analyzer` skill to:
- Get full commit history since divergence from main
- Analyze all commits (NOT just the latest!)
- Understand the complete scope of changes

```bash
git log main..HEAD --pretty=format:"%h %s"
git diff main...HEAD --stat
git diff main...HEAD
```

### 3. Build PR Title and Description

Based on detected commit style:

#### Format:
```markdown
## Summary
<1-3 bullet points summarizing ALL commits in this PR>

## Changes
- <What was added/changed/fixed>
- <Why these changes were made>
- <Impact of the changes>

## Test Plan
- [ ] TODO item 1
- [ ] TODO item 2
- [ ] TODO item 3

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Important:**
- Title should reflect the OVERALL purpose of the PR
- Summary must cover ALL commits, not just the latest one
- Use Korean for descriptions
- Include test plan as checklist

### 4. Confirm with User

Show the PR draft:
```
Title: feat(auth): JWT 토큰 검증 기능 추가

Description:
## Summary
- JWT 토큰 검증 로직 구현
- 토큰 만료 검사 및 자동 갱신
- 리프레시 토큰 메커니즘 추가

...
```

Ask for modifications if needed.

### 5. Push and Create PR

```bash
# Push to remote (with -u if new branch)
git push -u origin <branch-name>

# Create PR with gh CLI
gh pr create --title "<title>" --body "$(cat <<'EOF'
<description>
EOF
)"
```

**Use heredoc** for proper formatting of multi-line descriptions.

### 6. Return PR URL

```
✅ Pull Request created: https://github.com/user/repo/pull/123

Title: feat(auth): JWT 토큰 검증 기능 추가
```

## Important Notes

### Analyze ALL Commits
- Run `git log main..HEAD` to see full history
- Run `git diff main...HEAD` to see complete changes
- DON'T just look at the latest commit

### PR vs Commit Messages
- **Commit**: Individual change description
- **PR**: Overall feature/fix summary
- PR should tell the complete story

### Using gh CLI

```bash
# Basic PR creation
gh pr create --title "..." --body "..."

# Specify base branch
gh pr create --base main --title "..." --body "..."

# Draft PR
gh pr create --draft --title "..." --body "..."

# With assignee
gh pr create --assignee @me --title "..." --body "..."
```

## Error Handling

- **No commits**: "푸시할 커밋이 없습니다."
- **gh not authenticated**: "gh auth login을 먼저 실행해주세요."
- **Push failed**: Show error and suggest solutions
- **No upstream branch**: Automatically use `-u` flag

## Notes

- Use Nushell syntax (`;` not `&&`)
- Always include Claude Code attribution
- Use heredoc for body formatting
- Return the PR URL when done
