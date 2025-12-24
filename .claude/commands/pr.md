---
model: haiku
---

# Pull Request Command

Use the `pr` skill to create GitHub Pull Requests with proper title and description.

## Instructions

Execute the `pr` skill:

```
Use the Skill tool to run the "pr" skill
```

The pr skill will:
1. Check current branch and commits
2. Analyze ALL commits since main branch
3. Build PR title and description
4. Get user approval
5. Push and create PR with gh CLI

**Note**: This command delegates all logic to the modular `pr` skill.
