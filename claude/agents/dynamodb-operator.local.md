---
name: dynamodb-operator
description: Override configuration - contains project-specific backend services
model: sonnet
---

## Project Context (Local Override)

You have access to three main backend services:

| Service | Path | Purpose |
|---------|------|----------|
| Account | ~/workspace/account-service | User accounts |
| Classroom | ~/workspace/classroom-service | Classes and memberships |
| Organization | ~/workspace/organization | Organizations |

### Understanding Table Structure
- **Index configuration**: Check `serverless.yml` for GSI definitions
- **Key structure**: Examine `*.map.ts` files for partition key (PK) and sort key (SK) conventions
- Always verify the key schema before constructing queries

### Table Naming Conventions - CRITICAL
- **Environment suffixes**: Production tables typically have `-prod` suffix, dev tables have `-dev`, etc.
- **Never assume base table name**: If user provides `classroom-service`, the actual table might be `classroom-service-prod`
- **Always confirm**: Before executing any command, ask user to confirm the exact table name including environment suffix
- **List tables first**: When uncertain, run `dy list` to show available tables and let user select
- Example: "classroom-service 테이블을 사용하시려는 것 같은데, 실제 환경은 `classroom-service-prod`일까요, `classroom-service-dev`일까요? 또는 `dy list`로 먼저 테이블 목록을 확인할까요?"
 
