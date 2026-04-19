---
name: health
description: Invoke when Claude ignores instructions, behaves inconsistently, hooks malfunction, or MCP servers need auditing. Audits the full six-layer config stack and flags issues by severity. Not for debugging code or reviewing PRs.
metadata:
  version: "3.9.0"
---

# Health: Audit the Six-Layer Stack

Prefix your first line with 🥷 inline, not as its own paragraph.


Audit the current project's Claude Code setup against the six-layer framework:
`CLAUDE.md → rules → skills → hooks → subagents → verifiers`

Find violations. Identify the misaligned layer. Calibrate to project complexity only.

**Output language:** Check in order: (1) CLAUDE.md `## Communication` rule (global takes precedence over local); (2) language of the user's recent conversation messages; (3) default English. Apply the detected language to all output.

Keep the user informed of progress through the three steps: data collection, analysis, and synthesis.

## Step 0: Assess project tier

Pick one. Apply only that tier's requirements.

| Tier | Signal | What's expected |
|------|--------|-----------------|
| **Simple** | <500 project files, 1 contributor, no CI | CLAUDE.md only; 0–1 skills; no rules/; hooks optional |
| **Standard** | 500–5K project files, small team or CI present | CLAUDE.md + 1–2 rules files; 2–4 skills; basic hooks |
| **Complex** | >5K project files, multi-contributor, multi-language, active CI | Full six-layer setup required |

## Step 1: Collect all data

Run the data collection script and keep the full output. Do not interpret it yet.

```bash
bash "${CLAUDE_SKILL_DIR:-$HOME/.agents/skills/health}/scripts/collect-data.sh"
```

The script outputs labeled sections: tier metrics, CLAUDE.md (global + local), settings/hooks/MCP, rules, skill inventory, context budget, conversation signals, and skill security content.

Interpretation guardrails before Step 2:
- If `jq` is missing, conversation sections may show `(unavailable)`. Treat that as insufficient data, not a finding.
- If `python3` is missing, MCP/hooks/allowedTools sections may show `(unavailable)`. Do not flag those areas from missing collection.
- If `settings.local.json` is absent, hooks/MCP/allowedTools may be unavailable. That can be normal for global-settings-only projects.
- Conversation sampling is limited and MCP token estimates are directional. Use low confidence when the evidence is thin, and re-check tier manually if generated directories inflated the file count.

## Step 1b: MCP Live Check

After the bash block completes, test every MCP server from the settings before launching analysis agents.

For each server:
1. Call one harmless tool from that server with minimal input.
2. If the call succeeds: mark `live=yes`.
3. If it fails or times out: mark `live=no` and note the exact error.

Summarize the results in a short table, for example:

```
MCP Live Status:
  server_name    live=yes  (N tools available)
  other_server   live=no   error: connection refused / tool not found / API key invalid
```

Include this table in Agent 1's input.

**If API keys are required:** look for relevant env var names in the server config (e.g., `XCRAWL_API_KEY`, `OPENAI_API_KEY`). Do not validate the key value. Only note whether the env var is set: `echo $VAR_NAME | head -c 5` (5 chars only, do not print the full key).

## Step 2: Analyze with tier-adjusted depth

State the collected summary in one sentence (word counts, skills found, conversation files sampled). Confirm the tier. Then route:

- **SIMPLE:** Analyze locally from Step 1 data. Do not launch subagents. Prioritize core config checks; skip conversation cross-validation unless evidence is obvious.
- **STANDARD/COMPLEX:** Launch two subagents in parallel with the relevant Step 1 sections pasted inline. Keep them off file paths. Redact all credentials (API keys, tokens, passwords) to `[REDACTED]` before sharing the data.

**Fallback:** If either subagent fails (API error, timeout, or empty result), do not abort. Analyze that layer locally from Step 1 data instead and note "(analyzed locally -- subagent unavailable)" in the affected section of the report.

### Agent 1 -- Context + Security Audit (uses conversation signals only)

Read `agents/inspector-context.md`. Give Agent 1 the sections it needs. Include `CONVERSATION SIGNALS`, not the full `CONVERSATION EXTRACT`, so it can inspect enforcement gaps and context pressure without dragging in the heaviest evidence block.

### Agent 2 -- Control + Behavior Audit (uses conversation evidence)

Read `agents/inspector-control.md`. Give Agent 2 the sections it needs, including the detected tier.

## Step 3: Synthesize and present

Aggregate the local analysis and any agent outputs into one report:

---

**Health Report: {project} ({tier} tier, {file_count} files)**

### [PASS] Passing

Render a compact table of checks that passed. Include only checks relevant to the detected tier. Limit to 5 rows. Omit rows for checks that have findings.

| Check | Detail |
|-------|--------|
| settings.local.json gitignored | ok |
| No nested CLAUDE.md | ok |
| Skill security scan | no flags |

### [!] Critical -- fix now

Rules violated, missing verification definitions, dangerous allowedTools, MCP overhead >12.5%, required-path `Access denied`, active cache-breakers, and security findings.

### [~] Structural -- fix soon

CLAUDE.md content that belongs elsewhere, missing hooks, oversized skill descriptions, single-layer critical rules, model switching, verifier gaps, subagent permission gaps, and skill structural issues.

### [-] Incremental -- nice to have

New patterns to add, outdated items to remove, global vs local placement, context hygiene, HANDOFF.md adoption, skill invoke tuning, and provenance issues.

---

If all three issue sections are empty, output one short line in the output language like: `All relevant checks passed. Nothing to fix.`

## Non-goals

- Never auto-apply fixes without confirmation.
- Never apply complex-tier checks to simple projects.
- Flag issues, do not replace architectural judgment.


**Stop condition:** After the report, ask in the output language:
> "Should I draft the changes? I can handle each layer separately: global CLAUDE.md / local CLAUDE.md / rules / hooks / skills / MCP."

Do not make any edits without explicit confirmation.
