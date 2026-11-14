---
name: implement
description: "Phase 2 - execution protocol. Run in a fresh session after planning: take an arbitrary plan file as argument, normalize it to .agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md (copy, never edit), create 02_impl.md there (item state + implementation logs), run developer/reviewer subagent cycles per item (max 5), ask the user when blocked."
disable-model-invocation: true
---

# Phase 2: you are the ORCHESTRATOR (executor)

You run in a fresh session. Your state is a plan DIRECTORY: `.agents/plans/<YYYY-MM-DD>_<short-slug>/` containing `01_plan.md` (the frozen plan + planning logs, written by Phase 1) and `02_impl.md` (the implementation state + logs, created by YOU in this session). Do not re-plan from scratch; the plan and its logs are the source of truth.

Locating the plan (the plan file is an ARGUMENT — any path, any name):
1. If the user passed a plan file path, use it. If they passed a directory, use the `01_plan.md` inside it.
2. If no argument was passed: list `.agents/plans/*/` and use the single one if there is exactly one; otherwise ask the user which plan to run and wait. If there is none, tell the user to run `/skill:plan` in a fresh session instead and stop.
3. Normalize to the canonical layout WITHOUT ever modifying the plan content:
   - Already `.agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md` → use it as it is, no copy.
   - Any other path (e.g. `~/notes/my-plan.md`, `plan.md`, a scratch file) → derive the directory name: reuse the date and short description the file already carries (its header, title, or filename); only fall back to today's date + a short-slug (2-4 words) from the plan's Goal line when the file carries none. Copy the file VERBATIM to `.agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md` and work on that copy.
   - `02_impl.md` next to it: you create it (Phase 1 never does). Reuse it if it already exists (resumed run), otherwise write it fresh, seeding the Item state table from the plan rows:

```
# Implementation state
Plan: ./01_plan.md (read-only, never edit)

## Item state
| id | status (TODO | DOING | REVIEW | DONE | BLOCKED(user-decision)) | cycles |
|----|------|--------|
(one row per plan row, all TODO, cycles 0)

## Findings log (implementation)
- [developer|reviewer|scout] fact — source (file:line / command output)

## Decision log (implementation)
| # | decision | rationale | decider (agent|user) | status (JUSTIFIED | NEEDS_USER resolved) |

## Plan amendments
| id | original row | amended row | rationale |
|----|--------------|-------------|-----------|
```

   - Planning findings and decisions are read from the `Findings log (planning)` / `Decision log (planning)` sections of `01_plan.md`; your own entries go to the `(implementation)` sections of `02_impl.md`. Never append to, reorder, or restyle `01_plan.md`.
4. `01_plan.md` is READ-ONLY for the whole run — you, and every subagent you dispatch, never edit it (copied or not). All writing goes to `02_impl.md`.

Per plan item, in order (skip DONE, handle BLOCKED per its note; an amended row overrides the original row):
1. Dispatch **developer** subagent with the verbatim plan row + the relevant Findings and Decision entries from BOTH logs (`01_plan.md` planning logs and `02_impl.md` implementation logs; decision entries tell it which choices are already made - it must not re-decide them).
2. Dispatch **reviewer** subagent (fresh context) with the row + developer's handoff (Done / Success check / Notes).
3. On REQUEST_CHANGES: feed the findings table back to the developer for the next cycle. **Max 5 implement/review cycles per item.** Update the cycles column each round.
4. After the 5th cycle still failing: STOP and ASK THE USER how to proceed - another cycle, revise the plan item (re-plan this row only), skip it, or abort the run. Mark it BLOCKED with your question while waiting.
5. On APPROVE (reviewer saw the success check pass): mark the item DONE in the Item state table, then trigger the next item.

State rules:
- After EVERY cycle update `02_impl.md`: status (TODO/DOING/REVIEW/DONE/BLOCKED), cycles count, new findings, new decisions (rationale + decider). Append-only logs; never rewrite settled rows.
- Mid-implementation plan revision: add a row to the **Plan amendments** table in `02_impl.md` (original row verbatim, amended row, rationale) — the amendment overrides the original row from then on; `01_plan.md` stays untouched. Revising a row with evidence from review is allowed - it is not gathering. For a FULL re-plan, do not do it here: tell the user to re-enter `/plan` in a fresh session - it writes a new `01_plan.md` in a new dated directory, and the old plan's logs carry the state back in.
- ONE writer at a time; parallelize only read-only agents.
- Structured handoffs: rows, findings, decision entries verbatim - no paraphrasing.
- One-line status per cycle to the user: `item k/N, cycle c/5: intent -> result`.
- When all items are DONE: report the summary (items done, decisions taken, checks passed, amendments made) and stop.

Trivial single-edit tasks with no plan file: do them directly, no team.
