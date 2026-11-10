---
name: implement
description: "Phase 2 - execution protocol. Run in a fresh session after planning: read .agents/plan.md, run developer/reviewer subagent cycles per item (max 5), update plan state, ask the user when blocked."
disable-model-invocation: true
---

# Phase 2: you are the ORCHESTRATOR (executor)

You run in a fresh session. Your state is the plan file: **read `.agents/plan.md` first** (if missing, tell the user to run `/skill:plan` in a fresh session instead). Do not re-plan from scratch; the plan and its logs are the source of truth.

Per plan item, in order (skip DONE, handle BLOCKED per its note):
1. Dispatch **developer** subagent with the verbatim plan row + the relevant Findings log and Decision log entries (decision entries tell it which choices are already made - it must not re-decide them).
2. Dispatch **reviewer** subagent (fresh context) with the row + developer's handoff (Done / Success check / Notes).
3. On REQUEST_CHANGES: feed the findings table back to the developer for the next cycle. **Max 5 implement/review cycles per item.** Update the cycles column each round.
4. After the 5th cycle still failing: STOP and ASK THE USER how to proceed - another cycle, revise the plan item (re-plan this row only), skip it, or abort the run. Mark it BLOCKED with your question while waiting.
5. On APPROVE (reviewer saw the success check pass): mark the item DONE in the plan, then trigger the next item.

State rules:
- After EVERY cycle update `.agents/plan.md`: status (TODO/DOING/REVIEW/DONE/BLOCKED), cycles count, new findings, new decisions (rationale + decider). Append-only logs; never rewrite settled rows.
- Mid-implementation plan revision: revise the affected plan row yourself in `.agents/plan.md` (revising a row with evidence from review is allowed - it is not gathering); log the change in the Decision log. For a FULL re-plan, do not do it here: tell the user to re-enter `/plan` in a fresh session - the plan file carries all state back in.
- ONE writer at a time; parallelize only read-only agents.
- Structured handoffs: rows, findings, decision entries verbatim - no paraphrasing.
- One-line status per cycle to the user: `item k/N, cycle c/5: intent -> result`.
- When all items are DONE: report the summary (items done, decisions taken, checks passed) and stop.

Trivial single-edit tasks with no plan file: do them directly, no team.
