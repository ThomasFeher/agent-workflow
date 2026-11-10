#!/bin/sh
# Install the shared agent-team tree into Pi and OpenCode.
# Run from the repo root (the dir containing agents/, skills/, pi-prompts/, opencode-commands/):
#   ./install.sh
# Everything is plain text + symlinks. Idempotent.
ROOT=$(cd "$(dirname "$0")" && pwd)

# --- agents ---
# OpenCode: real directory with symlinked files (it does not follow symlinked directories)
mkdir -p ~/.config/opencode/agents
for f in "$ROOT/agents"/*.md; do ln -sf "$f" ~/.config/opencode/agents/; done
# Pi: follows directory symlinks
ln -sfn "$ROOT/agents" ~/.pi/agent/agents

# --- skills ---
# Both Pi and OpenCode scan ~/.agents/skills natively.
# If this repo is not ~/.agents, expose it (only if ~/.agents doesn't already exist).
if [ "$ROOT" != "$HOME/.agents" ] && [ ! -e "$HOME/.agents" ]; then
  ln -sfn "$ROOT" ~/.agents
fi

# --- Pi: stock subagent extension (from pi's installed examples) ---
PIEX="$(npm root 2>/dev/null)/pi/packages/coding-agent/examples/extensions/subagent"
if [ -f "$PIEX/index.ts" ]; then
  mkdir -p ~/.pi/agent/extensions/subagent
  ln -sf "$PIEX/index.ts" ~/.pi/agent/extensions/subagent/index.ts
  ln -sf "$PIEX/agents.ts" ~/.pi/agent/extensions/subagent/agents.ts
fi

# --- Pi prompt templates ---
mkdir -p ~/.pi/agent/prompts
for f in "$ROOT/pi-prompts"/*.md; do ln -sf "$f" ~/.pi/agent/prompts/; done

# --- OpenCode commands ---
mkdir -p ~/.config/opencode/commands
for f in "$ROOT/opencode-commands"/*.md; do ln -sf "$f" ~/.config/opencode/commands/; done

echo "Installed. Pi: run /plan then /implement (prompt templates). OpenCode: /plan then /implement (commands)."
