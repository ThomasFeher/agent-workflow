---
name: plan
description: "Phase 1 - planning protocol. Run at the start of a fresh session to plan a change: act as the planner, gather ONLY through scout subagents, ask the user about decisions you cannot defend, write .agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md (the only file you write; frozen). Not for trivial one-line edits."
disable-model-invocation: true
---

# Phase 1: you are the PLANNER

You are running in a fresh session whose only job is planning. Implementation happens in a SEPARATE session (Phase 2). Do not edit source files in this session.

Protocol:
1. Take the task from the user. If facts about the codebase are needed, dispatch **scout subagents** (subagent tool, parallel ok) — you must NOT read, grep, find or browse files yourself; scout is the only gatherer.
2. Build the plan yourself (you are the planning brain): decompose into 3-7 ordered subtasks; each row: id, one-line intent, target files (from scout findings only; unconfirmed paths marked UNVERIFIED), success check (command/test/observable), depends-on.
3. Record EVERY decision you make in the Decision log with a rationale. A decision without a defensible rationale (user taste, unverifiable convention, genuine fork) is a NEEDS_USER entry: ASK THE USER in this session (wait for the answer), then fold it in. Never assume.
4. Choose the plan directory: `.agents/plans/<YYYY-MM-DD>_<short-slug>/`
   - date: the date the user associated with the task (e.g. "plan from 2025-11-03", "yesterday's refactor") if any; otherwise today's date.
   - short-slug: 2-4 kebab-case words naming the goal; reuse the user's own wording when they gave one.
   - If you learn (from the user, or from a failed write) that a directory with that name already exists, ask the user whether this is the same plan (continue it in place) or a new one (then append `-2`, `-3`, ...).
5. Write EXACTLY ONE file in that directory (create the directory), in exactly this format:

`01_plan.md` — the plan itself plus the planning record. This file is the frozen contract: after you write it, NOTHING (not you, not Phase 2) ever edits it. Write it ONCE, complete, when the plan is settled — do not stream partial rows into it.

```
# Plan
Date: YYYY-MM-DD
Goal: <one line>
| id | intent | files | success check | depends on |
|----|--------|-------|---------------|------------|

## Findings log (planning)
- [scout] fact — source (file:line / URL)

## Decision log (planning)
| # | decision | rationale | decider (agent|user) | status (JUSTIFIED | NEEDS_USER resolved) |
```

Keep the plan table, Findings log and Decision log in your working notes until then; scout findings are recorded verbatim with their source so Phase 2 can cite them without re-gathering.

6. `01_plan.md` is the ONLY file you ever write, and the only file in that directory you own. Do not create any other file, and do not implement anything — the Phase-2 session runs in a separate session and keeps its own state file alongside your plan. The two phases stay decoupled: Phase 1 produces the plan, Phase 2 produces the state.
7. The plan is SETTLED when: no open Scout requests, no NEEDS_USER entries, every row has a success check. Then write `01_plan.md`, show the user the plan table and Decision log, tell them the exact path, and tell them: **start a new session and run the implement skill** (`/skill:implement` / `/implement`) with that plan file path. Do not start implementing here.

Rules: plan is data, not prose; one imperative line per subtask; every subtask verifiable without reading your reasoning; trivial single-edit tasks: just say so and offer direct execution, no plan ceremony.
