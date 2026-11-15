# Shared multi-agent setup (Pi + OpenCode)

All-text, no binaries, **stock harnesses only** (Pi uses its unmodified example subagent extension). Portable: copy/symlink the whole tree to `~/.agents` and run `./install.sh`.

```
~/.agents/
├── install.sh                     # wires the tree into Pi + OpenCode (symlinks, idempotent)
├── agents/                        # canonical agent definitions
│   ├── planner.md                 # OpenCode Phase-1 PRIMARY (/plan): no gather, scout-only, writes only .agents/plans/**
│   ├── orchestrator.md            # OpenCode Phase-2 PRIMARY (/implement): dev/reviewer/scout only, writes only .agents/plans/**
│   ├── scout.md                   # subagent (both harnesses): the ONLY gatherer - files, git, web; facts only, cited
│   ├── developer.md               # subagent (both): single writer, self-verifies, handoff contract
│   └── reviewer.md                # subagent (both): clean-context gate, findings table, never edits
├── skills/plan/SKILL.md           # Phase-1 protocol (planning brain)
├── skills/implement/SKILL.md      # Phase-2 protocol (executor)
├── pi-prompts/                    # /plan /implement - thin wrappers loading the skills
└── opencode-commands/             # /plan (agent: planner) /implement (agent: orchestrator) /review ...
```

## Workflow (two phases, two sessions, no planner subagent anywhere)
1. PLANNING session: `/plan` (or `/skill:plan`). Planning brain = the MAIN session following the plan skill: gathers ONLY via scout subagents, asks the user NEEDS_USER questions in place, writes ONE frozen file `.agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md` (plan table + planning Findings/Decision logs). In OpenCode this runs as the **planner primary** (enforced: no read/glob/grep/web/shell; edit only under `.agents/plans/`; may dispatch `scout` only; loads the plan skill via the skill tool). In Pi it is prompt-level discipline (stock main session, all tools).
2. USER CLEARS/STARTS NEW SESSION (context hygiene; the plan DIRECTORY carries all state across the boundary).
3. IMPLEMENTING session: `/implement <plan-file>` (or `/skill:implement`) — **the plan file is an arbitrary argument** (any path, any name; empty argument = the only/last plan directory). The executor normalizes it to `.agents/plans/<YYYY-MM-DD>_<short-slug>/01_plan.md` (reusing the date/description the file already carries, else today's date + a short-slug; the file is copied VERBATIM and never edited) and **creates `02_impl.md` there itself**. Per plan item: developer -> reviewer (fresh context), **max 5 cycles**; 5th failing cycle -> user decides (cycle/revise/skip/abort); DONE only on reviewer APPROVE. In OpenCode runs as the **orchestrator primary** (enforced: edit only under `.agents/plans/`, dispatches developer/reviewer/scout). In Pi the stock main session + skill.
4. Re-planning is DECOUPLED: mid-implementation the executor amends a row in `02_impl.md` (`Plan amendments` table, logged rationale; `01_plan.md` stays frozen); a full re-plan = re-enter `/plan` in a fresh session (new dated directory, old plan's logs carry the state back in). No harness ever dispatches a planner subagent.
5. **Commits are the orchestrator's, one per DONE item** (the developer never commits and never stages, so the reviewer always sees the item's full uncommitted change and review fixes land in the SAME commit as the item's own work): pre-flight before item 1 = commit the plan directory first if it is not committed yet (plans are part of the shipped history), and ask the user before touching a tree that is dirty outside the plan dir; then per item, only on reviewer APPROVE, `git add -- <developer's Done paths> .agents/plans/<dir>/` + commit, then write the sha into the item's `commit` column (that write is carried by the next item's commit; after the last item, one final state-only commit if the plan dir is still dirty). Current branch only — never branch/worktree/stash/revert/`--amend`/force-push, never `git add -A` or `git commit -a`. **Subject and body conventions are deliberately NOT defined here** — they belong to the target project (read its CONTRIBUTING/commit history and match); the message must convey the plan item id + its success check. Not a git repo (`git rev-parse` fails) -> `VCS: none`, skip all commits. A project whose own ignore rules hide `.agents/plans/` -> NEEDS_USER (un-ignore / force-add / skip).

State lives in a plan DIRECTORY **`.agents/plans/<YYYY-MM-DD>_<short-slug>/`** (project root `.agents/plans/`), one directory per plan, e.g. `.agents/plans/2025-11-03_drop-legacy-shim/`:
- **`01_plan.md`** — the frozen plan + planning record, written ONCE by the plan skill: header `Date:`, `Goal:`, table `id | intent | files | success check | depends on`, `## Findings log (planning)`, `## Decision log (planning)`. **Never modified by anyone** (read-only for the whole run); a plan handed in from elsewhere is copied verbatim to this name.
- **`02_impl.md`** — created by the ORCHESTRATOR in the Phase-2 session (Phase 1 never writes it): `Plan:` pointer, `VCS:` line (`branch`, `base` HEAD sha, `plan commit` sha), `Item state` table (status TODO/DOING/REVIEW/DONE/BLOCKED + cycle counts + commit sha), `Findings log (implementation)`, `Decision log (implementation)`, `Plan amendments` (original row verbatim -> amended row + rationale; overrides the original row, `01_plan.md` stays untouched). Append-only logs; settled rows never rewritten.

Phases stay decoupled: Phase 1 produces only the plan, Phase 2 produces only the state; the plan directory is the hand-off.

## Wiring (done automatically by ./install.sh)
- Pi: `~/.pi/agent/agents -> <repo>/agents`; **stock** subagent extension symlinked from pi's installed examples (`$(npm root)/pi/packages/coding-agent/examples/extensions/subagent/`); prompt templates from `<repo>/pi-prompts/`.
- OpenCode: `~/.config/opencode/agents/` = real dir with symlinked agent files; commands symlinked from `<repo>/opencode-commands/`; skills read natively from `~/.agents/skills`.
- Skills: each `<repo>/skills/<name>/` is symlinked into `~/.agents/skills/<name>` (per-directory links, so an existing `~/.agents` holding other skills is fine). Both harnesses follow symlinked skill directories.
- Both skills set `disable-model-invocation: true`, so they are NOT advertised in the system prompt and the model will never auto-load them: the entry points are the `/plan` and `/implement` prompt templates (Pi) / commands (OpenCode); `/skill:plan <task>` also works directly in Pi.

## Frontmatter compatibility
Superset format: Pi reads `name`, `description`, `model` and ignores the rest; OpenCode reads `description`, `mode`, `model`, `permissions` and ignores unknown keys (`name`, `skills`). Do NOT add a `tools:` key — OpenCode V2 treats it as a deprecated V1 map and silently skips the agent when it's a string. Pi ignores `permissions:` (stock extension) — Pi enforcement is prompt-level only; OpenCode enforces natively. `model:` omitted -> inherit session model; provider names differ between harnesses, so pin models only in per-harness copies.

Role enforcement (single source of truth = `permissions:` frontmatter, enforced by OpenCode; Pi = prompt-level via skills):
- **planner** (OpenCode primary only): all gather+shell denied; edit denied except `.agents/plans/**` (exactly one file: `01_plan.md`, written once); only `scout` subagent + `plan` skill allowed.
- **orchestrator** (OpenCode primary only): edit denied except `.agents/plans/**` (creates/updates `02_impl.md`; a foreign plan file may only be copied verbatim to `01_plan.md`, never edited); shell explicitly ALLOWED (it owns the git commit boundary — committing is not an edit, so the edit rule keeps it out of source files); only developer/reviewer/scout subagents.
- **scout**: edit denied (the gatherer: files, git, web).
- **reviewer**: edit denied (runs checks, never fixes).
- **developer**: unrestricted (the single writer).

Note: `~/.config/opencode/agents` must be a real directory containing symlinked `.md` files — OpenCode does not follow a symlinked directory. `~/.pi/agent/agents` may be a directory symlink (Pi follows it). Pi never uses planner.md/orchestrator.md as subagents (they'd load but be unused); they exist for OpenCode primaries.
