# Git Analyzer

Analyzes git changes and detects commit message style conventions.

## When to Use This Skill

This is a **utility skill** called by other skills (commit, pr).
**DO NOT** invoke this skill directly in user conversations.

## Instructions

### 1. Analyze Git Status

```bash
git status
git diff --cached --stat
git log --pretty=format:"%s" -10
```

### 2. Detect Commit Style

Analyze the last 10 commit messages:
- If majority (6+) use `type(scope):` or `type:` format → **Conventional Commits**
- Otherwise → **Chris Beams Style**

Return the detected style to the calling skill.

### 3. Analyze Staged Changes

Group changes by logical units:
- Related files (same feature/module)
- Change purpose (feat/fix/refactor/docs)
- Work flow order (foundation → core → tests → docs)

**Output Format:**

```json
{
  "style": "conventional" | "beams",
  "stagedFiles": ["file1", "file2"],
  "changeGroups": [
    {
      "type": "feat",
      "scope": "auth",
      "files": ["src/auth.ts"],
      "description": "JWT token validation"
    }
  ],
  "shouldSplit": false,
  "splitSuggestion": null
}
```

### 4. Return Analysis to Caller

Pass the analysis result back to the calling skill (commit or pr).

## Important Notes

- **NEVER** create commits or PRs directly
- **ONLY** analyze and return structured data
- Use Nushell syntax (`;` not `&&`)
- This skill runs with `model: haiku` for efficiency
