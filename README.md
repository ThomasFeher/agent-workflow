# Shared multi-agent setup (Pi + OpenCode)

All-text, no binaries, **stock harnesses only** (Pi uses its unmodified example subagent extension). Portable: copy/symlink the whole tree to `~/.agents` and run `./install.sh`.

```
~/.agents/
├── install.sh                     # wires the tree into Pi + OpenCode (symlinks, idempotent)
├── agents/                        # canonical agent definitions
│   ├── planner.md                 # OpenCode Phase-1 PRIMARY (/plan): no gather, scout-only, writes only .agents/plan.md
│   ├── orchestrator.md            # OpenCode Phase-2 PRIMARY (/implement): dev/reviewer/scout only, writes only .agents/plan.md
│   ├── scout.md                   # subagent (both harnesses): the ONLY gatherer - files, git, web; facts only, cited
│   ├── developer.md               # subagent (both): single writer, self-verifies, handoff contract
│   └── reviewer.md                # subagent (both): clean-context gate, findings table, never edits
├── skills/plan/SKILL.md           # Phase-1 protocol (planning brain)
├── skills/implement/SKILL.md      # Phase-2 protocol (executor)
├── pi-prompts/                    # /plan /implement - thin wrappers loading the skills
└── opencode-commands/             # /plan (agent: planner) /implement (agent: orchestrator) /review ...
```

## Workflow (two phases, two sessions, no planner subagent anywhere)
1. PLANNING session: `/plan` (or `/skill:plan`). Planning brain = the MAIN session following the plan skill: gathers ONLY via scout subagents, asks the user NEEDS_USER questions in place, writes `.agents/plan.md`. In OpenCode this runs as the **planner primary** (enforced: no read/glob/grep/web/shell; edit only on `.agents/plan.md`; may dispatch `scout` only; loads the plan skill via the skill tool). In Pi it is prompt-level discipline (stock main session, all tools).
2. USER CLEARS/STARTS NEW SESSION (context hygiene; the plan file carries all state across the boundary).
3. IMPLEMENTING session: `/implement` (or `/skill:implement`). Per plan item: developer -> reviewer (fresh context), **max 5 cycles**; 5th failing cycle -> user decides (cycle/revise/skip/abort); DONE only on reviewer APPROVE. In OpenCode runs as the **orchestrator primary** (enforced: edit only `.agents/plan.md`, dispatches developer/reviewer/scout). In Pi the stock main session + skill.
4. Re-planning is DECOUPLED: mid-implementation the executor may revise a plan row in the plan file (logged in the Decision log); a full re-plan = re-enter `/plan` in a fresh session with the plan file. No harness ever dispatches a planner subagent.
State lives in the plan file **`.agents/plan.md`** (project root): plan table with status (TODO/DOING/REVIEW/DONE/BLOCKED) + cycle counts, findings log, decision log (rationale + decider). Append-only logs; settled rows never rewritten.

## Wiring (done automatically by ./install.sh)
- Pi: `~/.pi/agent/agents -> <repo>/agents`; **stock** subagent extension symlinked from pi's installed examples (`$(npm root)/pi/packages/coding-agent/examples/extensions/subagent/`); prompt templates from `<repo>/pi-prompts/`.
- OpenCode: `~/.config/opencode/agents/` = real dir with symlinked agent files; commands symlinked from `<repo>/opencode-commands/`; skills read natively from `~/.agents/skills`.

## Frontmatter compatibility
Superset format: Pi reads `name`, `description`, `model` and ignores the rest; OpenCode reads `description`, `mode`, `model`, `permissions` and ignores unknown keys (`name`, `skills`). Do NOT add a `tools:` key — OpenCode V2 treats it as a deprecated V1 map and silently skips the agent when it's a string. Pi ignores `permissions:` (stock extension) — Pi enforcement is prompt-level only; OpenCode enforces natively. `model:` omitted -> inherit session model; provider names differ (`localai/*` vs `llama.cpp/*`), pin models only in per-harness copies.

Role enforcement (single source of truth = `permissions:` frontmatter, enforced by OpenCode; Pi = prompt-level via skills):
- **planner** (OpenCode primary only): all gather+shell denied; edit denied except `.agents/plan.md`; only `scout` subagent + `plan` skill allowed.
- **orchestrator** (OpenCode primary only): edit denied except `.agents/plan.md`; only developer/reviewer/scout subagents.
- **scout**: edit denied (the gatherer: files, git, web).
- **reviewer**: edit denied (runs checks, never fixes).
- **developer**: unrestricted (the single writer).

Note: `~/.config/opencode/agents` must be a real directory containing symlinked `.md` files — OpenCode does not follow a symlinked directory. `~/.pi/agent/agents` may be a directory symlink (Pi follows it). Pi never uses planner.md/orchestrator.md as subagents (they'd load but be unused); they exist for OpenCode primaries.
