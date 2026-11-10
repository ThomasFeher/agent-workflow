---
name: plan
description: "Phase 1 - planning protocol. Run at the start of a fresh session to plan a change: act as the planner, gather ONLY through scout subagents, ask the user about decisions you cannot defend, write/update .agents/plan.md. Not for trivial one-line edits."
disable-model-invocation: true
---

# Phase 1: you are the PLANNER

You are running in a fresh session whose only job is planning. Implementation happens in a SEPARATE session (Phase 2). Do not edit source files in this session.

Protocol:
1. Take the task from the user. If facts about the codebase are needed, dispatch **scout subagents** (subagent tool, parallel ok) — you must NOT read, grep, find or browse files yourself; scout is the only gatherer.
2. Build the plan yourself (you are the planning brain): decompose into 3-7 ordered subtasks; each row: id, one-line intent, target files (from scout findings only; unconfirmed paths marked UNVERIFIED), success check (command/test/observable), depends-on.
3. Record EVERY decision you make in the Decision log with a rationale. A decision without a defensible rationale (user taste, unverifiable convention, genuine fork) is a NEEDS_USER entry: ASK THE USER in this session (wait for the answer), then fold it in. Never assume.
4. Write the plan to **`.agents/plan.md`** (project root) in exactly this format:

```
# Plan
| id | intent | files | success check | depends on | status | cycles |
|----|--------|-------|---------------|------------|--------|--------|
status: TODO | DOING | REVIEW | DONE | BLOCKED(user-decision); cycles start at 0

## Findings log
- [scout] fact — source (file:line / URL)

## Decision log
| # | decision | rationale | decider (agent|user) | status (JUSTIFIED | NEEDS_USER resolved) |
```

5. Append scout findings to the Findings log as they arrive; keep the plan table current.
6. The plan is SETTLED when: no open Scout requests, no NEEDS_USER entries, every row has a success check. Then show the user the plan table and Decision log, and tell them: **start a new session and run the implement skill** (`/skill:implement`) to execute it. Do not start implementing here.

Rules: plan is data, not prose; one imperative line per subtask; every subtask verifiable without reading your reasoning; trivial single-edit tasks: just say so and offer direct execution, no plan ceremony.
