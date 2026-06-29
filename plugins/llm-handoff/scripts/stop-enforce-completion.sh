#!/usr/bin/env bash
# Fires before Claude Code stops responding.
# If a handoff was requested (sentinel exists) and handover.md still has
# TODO placeholders, blocks Claude from stopping and asks it to complete the doc.
# Clears the sentinel once the handover is fully complete.

SENTINEL="${HOME}/.claude/llm-handoff/completion-required"

# No handoff in progress — let Claude stop normally
if [ ! -f "$SENTINEL" ]; then
  echo "llm-handoff: no handoff in progress." >&2
  exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HANDOVER_FILE="${REPO_ROOT}/handover.md"

# Check for incomplete TODO sections
if [ ! -f "$HANDOVER_FILE" ]; then
  echo "llm-handoff: handover.md is missing. Please create it using the llm-handoff skill before stopping." >&2
  exit 2
fi

if grep -q "<!-- TODO:" "$HANDOVER_FILE" 2>/dev/null; then
  REMAINING=$(grep -c "<!-- TODO:" "$HANDOVER_FILE" 2>/dev/null || echo "?")
  echo "llm-handoff: handover.md has ${REMAINING} incomplete section(s) marked <!-- TODO: ... -->." >&2
  echo "" >&2
  echo "Complete ALL TODO sections before stopping — the next LLM needs this context to continue without mistakes. Fill in:" >&2
  echo "  - Original request (verbatim)" >&2
  echo "  - Session goal and constraints" >&2
  echo "  - Progress (completed, in progress, not started)" >&2
  echo "  - Files in play" >&2
  echo "  - Key decisions with WHY reasoning" >&2
  echo "  - Failed approaches (exact errors, root causes)" >&2
  echo "  - Blockers and open questions" >&2
  echo "  - Next steps (specific: file, action, verification)" >&2
  echo "  - Critical context (non-obvious gotchas)" >&2
  echo "  - Environment details" >&2
  echo "  - Your model name and version" >&2
  echo "" >&2
  echo "Then stop again — the handover will be validated and you will be allowed to proceed." >&2
  exit 2
fi

# Handover is complete — clear sentinel and allow Claude to stop
rm -f "$SENTINEL"
echo "llm-handoff: handover.md is complete. Session can end safely." >&2
exit 0
