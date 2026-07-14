---
name: design-doc
description: Create, restructure, or review software design documents so they are useful for engineering review. Use when the user asks to write a design doc, improve a design proposal, turn notes/PRD/comments into a reviewable technical design, identify open questions and alternatives, or apply design-doc standards to an existing document.
---

# Design Doc

Use this skill to produce a design doc that helps reviewers focus on expensive-to-change decisions, not incidental implementation details.

## Core Rule

Include a decision when the penalty for being wrong is meaningful: data model, API contract, persistence, access control, privacy/security, cross-team dependency, rollout, or compatibility. Demote easy-to-change details to implementation notes or omit them.

## Workflow

1. Establish the objective in one sentence.
2. Separate context from decisions:
   - **Background**: facts, constraints, current system shape, product requirement.
   - **Resolved issues**: decisions already made and why.
   - **Open issues**: decisions still needing input, each with options and a next step.
3. Put scope up front:
   - **Goals**: user/team/system outcomes.
   - **Non-goals**: plausible-but-excluded work.
4. Add scenarios before low-level design when requirements are ambiguous. Use scenarios to test whether the model handles real product paths.
5. Present the proposed design around stable interfaces:
   - data model and ownership
   - APIs/DTOs/events
   - policy and permission boundaries
   - lifecycle/state transitions
   - indexing/query paths that matter
6. Add alternatives only for options reviewers are likely to ask about or options already investigated.
7. End with review status:
   - what is decided
   - what needs review
   - who/what can unblock remaining issues

## Editing Existing Docs

When improving an existing document, avoid a full rewrite unless requested. Prefer:

- Move the objective, goals, non-goals, and key decisions toward the top.
- Convert chronological notes into **Resolved issues** and **Open issues**.
- Remove contradictions between old text and review updates.
- Keep investigation details only when they justify a costly decision.
- Preserve useful inline comments or reply to them with the paired decision.

## Review Checklist

Before finalizing, check:

- The first page makes sense without verbal context.
- Goals are outcomes, not implementation tasks.
- Non-goals block likely scope misunderstandings.
- Open issues state the problem, options, proposed solution if any, and next step.
- Alternatives explain why rejected options were not chosen.
- Security, privacy, logging, and monitoring are included when the feature touches user data, public access, moderation, or production operation.
- Easy-to-change details are not stealing review attention.

## References

Read `references/template.md` when the user asks for a template, asks to create a full design doc, or the document needs more than a small edit.
