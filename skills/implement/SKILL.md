---
name: implement
description: "Phase 2 - execution protocol. Run in a fresh session after planning: take an arbitrary plan file as argument, normalize it to .agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md (copy, never edit), create 02_impl.md there (item state + implementation logs), run developer/reviewer subagent cycles per item (max 5), commit once per DONE item (plan dir included, current branch only), ask the user when blocked."
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
VCS: git | branch: <current branch, never changed by you> | base: <HEAD sha at run start> | plan commit: <sha>

## Item state
| id | status (TODO | DOING | REVIEW | DONE | BLOCKED(user-decision)) | cycles | commit (sha) |
|----|------|--------|-------------|
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

BEFORE the first item — VCS pre-flight, once, in this order:
1. Not a git repo (`git rev-parse` fails): write `VCS: none` in the header, tell the user, skip EVERY commit rule below, and run the items uncommitted.
2. Current branch only: never create/switch/delete a branch, never `git worktree`, `git stash`, `git revert`, `git checkout`, never `--amend`, never force-push - on your own initiative. Record `branch:` and `base:` (HEAD sha) in the header.
3. The plan directory IS part of the shipped history, so it must be committed: if it is not already committed, committing it is the FIRST task of the run, before any implementation (`git add -- .agents/plans/<dir>/` then commit). "Already committed" = `git ls-files -- .agents/plans/<dir>/` lists `01_plan.md` AND `git status --short -- .agents/plans/<dir>/01_plan.md` is empty. If only `02_impl.md` is new or changed (resumed run), still commit the plan dir there - it carries state. Record the sha as `plan commit:` in the header. If the project's own ignore rules hide the plan path (`git check-ignore` hits it), ASK THE USER (NEEDS_USER, log it): un-ignore, force-add, or skip plan commits - never decide for them.
4. If the tree is dirty OUTSIDE the plan dir before item 1: ASK THE USER first (NEEDS_USER, log it) - commit, stash, or leave it. Never sweep foreign pre-existing changes into an item commit on your own judgement.

Per plan item, in order (skip DONE, handle BLOCKED per its note; an amended row overrides the original row):
1. Dispatch **developer** subagent with the verbatim plan row + the relevant Findings and Decision entries from BOTH logs (`01_plan.md` planning logs and `02_impl.md` implementation logs; decision entries tell it which choices are already made - it must not re-decide them).
2. Dispatch **reviewer** subagent (fresh context) with the row + developer's handoff (Done / Success check / Notes).
3. On REQUEST_CHANGES: feed the findings table back to the developer for the next cycle. **Max 5 implement/review cycles per item.** Update the cycles column each round.
4. After the 5th cycle still failing: STOP and ASK THE USER how to proceed - another cycle, revise the plan item (re-plan this row only), skip it, or abort the run. Mark it BLOCKED with your question while waiting.
5. On APPROVE (reviewer saw the success check pass): COMMIT the item (Commit rules below - the commit includes every review-driven fix, so it happens only here, after review), then mark the item DONE with its sha in the Item state table, then trigger the next item.

Commit rules (one commit per DONE item + the plan commit):
- Commit ONLY on APPROVE, never mid-cycle, never on REQUEST_CHANGES, never on BLOCKED (leave blocked work in the tree so the user can inspect it). One commit per item squashes all its cycles - intermediate cycles may not pass their own check, so do NOT commit per cycle unless the user asked for it.
- Stage exactly the developer's `## Done` paths plus the plan directory: `git add -- <path> [...] .agents/plans/<dir>/`. NEVER `git add -A`, `git add .`, `git commit -a`, or a bare `git commit` - unrelated dirty files stay out of the commit.
- Subject and body follow the PROJECT's convention, which this workflow deliberately does NOT define: read the repo's CONTRIBUTING/docs and its commit history, then match that style. What the message must convey: the plan item id and its success check (command + result).
- After the commit, write the sha into that item's `commit` column. That write is itself a change to `02_impl.md`, so it is carried by the NEXT item's commit; after the LAST item, if the plan dir is still dirty, make one final state-only commit (`git add -- .agents/plans/<dir>/`).
- The developer never commits and never stages - you own the commit boundary, so the reviewer always sees the item's full uncommitted change and a commit never splits review fixes off.

State rules:
- After EVERY cycle update `02_impl.md`: status (TODO/DOING/REVIEW/DONE/BLOCKED), cycles count, new findings, new decisions (rationale + decider). Append-only logs; never rewrite settled rows.
- Mid-implementation plan revision: add a row to the **Plan amendments** table in `02_impl.md` (original row verbatim, amended row, rationale) — the amendment overrides the original row from then on; `01_plan.md` stays untouched. Revising a row with evidence from review is allowed - it is not gathering. For a FULL re-plan, do not do it here: tell the user to re-enter `/plan` in a fresh session - it writes a new `01_plan.md` in a new dated directory, and the old plan's logs carry the state back in.
- ONE writer at a time; parallelize only read-only agents.
- Structured handoffs: rows, findings, decision entries verbatim - no paraphrasing.
- One-line status per cycle to the user: `item k/N, cycle c/5: intent -> result`.
- When all items are DONE: make the final state-only commit if the plan dir is still dirty, then report the summary (items done, decisions taken, checks passed, amendments made, commits made with their shas) and stop.

Trivial single-edit tasks with no plan file: do them directly, no team.
