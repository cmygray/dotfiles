# Design Doc Template

Use only the sections that fit the project. Keep the first page understandable to a reader without prior discussion.

## Metadata

- **Author**:
- **Status**: Draft | Ready for review | Approved
- **Created**:
- **Last updated**:
- **Authoritative URL**:
- **Related documents**:

## Objective

One sentence in plain language. State the user/team/system outcome, not the implementation.

## Background

Explain:

- Why this project exists.
- What problem it solves.
- Current system behavior and constraints.
- Previous attempts or related designs, if any.

## Goals

Outcome-oriented bullets. Avoid implementation details.

Example:

- Allow students and teachers to comment on visible writing results.
- Keep public-link viewers read-only.

## Non-goals

Explicitly exclude plausible scope:

- Notifications.
- General-purpose comment platform.
- Migration of unrelated existing features.

## Scenarios

Use concrete flows to validate requirements.

```text
Scenario: <name>
1. Actor does ...
2. System responds ...
3. Expected result ...
```

## Proposed Design

Summarize the design in a few paragraphs. Then split details by concern.

### Data Model

Cover:

- entities and ownership
- important fields
- lifecycle/state representation
- indexes and uniqueness constraints
- compatibility/migration considerations

### Interfaces

Cover APIs, DTOs, events, jobs, or file formats. Include only stable contracts and behavior that clients depend on.

### Access And Visibility

Cover:

- viewer relationships
- permission checks
- public/private boundaries
- resource-specific visibility
- moderation or policy calculators

### Lifecycle

Cover state transitions and who can trigger them.

## Dependencies And Constraints

List dependencies that are expensive to change:

- storage
- cross-service calls
- external systems
- runtime/infrastructure
- product or legal constraints

## Security And Privacy

Use when the feature touches user data, public access, moderation, authentication, authorization, or logs.

Answer:

- What sensitive data is handled?
- Who can read/write it?
- What untrusted input is accepted?
- What must not be logged?

## Monitoring And Logging

Cover critical events, operational signals, and sensitive-data limits.

## Rollout And Migration

Cover:

- feature flags or staged rollout
- backfill/migration
- compatibility with existing clients
- rollback path

## Alternatives Considered

Keep brief. Include only strong alternatives or ones reviewers will ask about.

```text
- Alternative:
  Why it seemed plausible:
  Why rejected:
```

## Resolved Issues

Move settled review questions here.

```text
Resolved Issue: <title>
Decision:
Rationale:
```

## Open Issues

Every open issue should have a next step.

```text
Open Issue: <title>
Problem:
Options:
Proposed solution:
Next step:
Owner:
```

## Review Notes

State:

- what needs review now
- what is intentionally deferred
- whose approval or input is needed
