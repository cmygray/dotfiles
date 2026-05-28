---
name: dynamodb
description: DynamoDB natural-language read-only lookup for Classting services. Use when Codex needs to answer requests like "DynamoDB에서 조회", "테이블 확인", "ddb", "dy query", "find account/member/classroom/notification in DynamoDB", or inspect Classting DynamoDB records across dev/stag/prod using the dy CLI and schema references.
---

# DynamoDB Read-Only Lookup

Convert a user's natural-language DynamoDB question into safe read-only `dy` commands, run them when needed, and explain the result.

## Core Rules

- Use only read-only operations: `dy help`, `dy list`, `dy desc`, `dy get`, `dy query`, `dy scan`.
- Never run write/admin operations: `put`, `del`, `upd`, `bwrite`, `admin`, `bootstrap`, `import`, `export`, `backup`, `restore`.
- If the user did not specify an environment, ask whether to use `dev`, `stag`, or `prod` before querying.
- Prefer `query` or `get` over `scan`. Use `scan` only with a small `--limit` and only when no key path is known.
- Before composing a query, read `references/schema.yaml` for table names, key patterns, and GSI usage.
- Do not expose secrets, raw auth tokens, or credentials in the response.

## Environment

Use these AWS profiles through `aws-vault`:

| Environment | Command prefix |
|-------------|----------------|
| `dev` | `aws-vault exec classting-dev --` |
| `stag` | `aws-vault exec classting-stag --` |
| `prod` | `aws-vault exec classting-prod --` |

Table naming is usually `{service}-{env}`, for example `account-service-stag`.

## Workflow

1. Identify the target environment, service, entity, and lookup condition from the user request.
2. Read `references/schema.yaml` and choose the table, PK/SK pattern, and GSI.
3. Build the narrowest read-only `dy` command.
4. Run the command if the user asked for actual data or if the task needs verification.
5. Summarize the relevant fields and include the command shape when useful.

## dy Commands

```bash
# List tables
aws-vault exec classting-stag -- dy list

# Describe a table
aws-vault exec classting-stag -- dy desc -t account-service-stag

# Get by PK + optional SK
aws-vault exec classting-stag -- dy get -t account-service-stag 'Account#123' 'Account#123'

# Query by PK, optionally with GSI and SK condition
aws-vault exec classting-stag -- dy query -t account-service-stag -i gsi-1 'AccountEmail#user@example.com'
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-3 'Account#123'
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-1 'Member#abc' -s 'begins_with Contract#'

# Return selected attributes for query output
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-1 'Contract#xyz' -a 'id,orgId,licenses,variants'
```

Important CLI details:

- `dy get` does not support `-a` or `--attributes`; it returns the full item.
- `dy query` supports `-a/--attributes`, `--keys-only`, `--filter`, and `--limit`.
- Sort-key expressions commonly use forms like `'begins_with Contract#'` or `'= Member#abc'`.

## Common Lookups

```bash
# Email -> account
aws-vault exec classting-stag -- dy query -t account-service-stag -i gsi-1 'AccountEmail#user@example.com'

# Account -> organization members
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-3 'Account#15089337373340913'

# Organization member -> licenses
aws-vault exec classting-stag -- dy query -t organization-service-stag -i gsi-1 'Member#member-id' -s 'begins_with Contract#'
```

## References

- `references/schema.yaml`: DynamoDB table names, entity key patterns, GSIs, and field notes. Read this file first for any non-trivial query.
