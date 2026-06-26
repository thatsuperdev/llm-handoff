#!/usr/bin/env bash
# Fires before Claude Code stops responding.
# If a handoff was requested (sentinel exists) and handover.md still has
# TODO placeholders, blocks Claude from stopping and asks it to complete the doc.
# Clears the sentinel once the handover is fully complete.

SENTINEL="${HOME}/.claude/llm-handoff/completion-required"

# No handoff in progress — let Claude stop normally
if [ ! -f "$SENTINEL" ]; then
  exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HANDOVER_FILE="${REPO_ROOT}/handover.md"

# Check for incomplete TODO sections
if [ ! -f "$HANDOVER_FILE" ]; then
  echo "llm-handoff: handover.md is missing. Please create it using the llm-handoff skill before stopping."
  exit 2
fi

if grep -q "<!-- TODO:" "$HANDOVER_FILE" 2>/dev/null; then
  REMAINING=$(grep -c "<!-- TODO:" "$HANDOVER_FILE" 2>/dev/null || echo "?")
  echo "llm-handoff: handover.md has ${REMAINING} incomplete section(s) marked <!-- TODO: ... -->."
  echo ""
  echo "Complete ALL TODO sections before stopping — the next LLM needs this context to continue without mistakes. Fill in:"
  echo "  - Original request (verbatim)"
  echo "  - Session goal and constraints"
  echo "  - Progress (completed, in progress, not started)"
  echo "  - Files in play"
  echo "  - Key decisions with WHY reasoning"
  echo "  - Failed approaches (exact errors, root causes)"
  echo "  - Blockers and open questions"
  echo "  - Next steps (specific: file, action, verification)"
  echo "  - Critical context (non-obvious gotchas)"
  echo "  - Environment details"
  echo "  - Your model name and version"
  echo ""
  echo "Then stop again — the handover will be validated and you will be allowed to proceed."
  exit 2
fi

# Handover is complete — clear sentinel and allow Claude to stop
rm -f "$SENTINEL"
echo "llm-handoff: handover.md is complete. Session can end safely."
exit 0
