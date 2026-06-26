#!/usr/bin/env bash
# llm-handoff installer
# Installs the llm-handoff skill for any LLM coding tool.
# For Claude Code, prefer: /plugin marketplace add thatsuperdev/llm-handoff && /plugin install llm-handoff
set -e

REPO="thatsuperdev/llm-handoff"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SKILL_NAME="llm-handoff"
SKILL_FILE="llm-handoff.skill.md"

# ── Install paths ─────────────────────────────────────────────────────────────
# SKILL.md-based agents
CLAUDE_SKILL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
CLAUDE_HOOKS_DIR="${HOME}/.claude/hooks"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
CLINE_SKILL_DIR="${HOME}/.cline/skills/${SKILL_NAME}"
KILO_SKILL_DIR="${HOME}/.kilo/skills/${SKILL_NAME}"
AMP_SKILL_DIR="${HOME}/.amp/skills/${SKILL_NAME}"
OPENCODE_SKILL_DIR="${HOME}/.config/opencode/skills/${SKILL_NAME}"
GEMINI_SKILL_DIR="${HOME}/.gemini/skills/${SKILL_NAME}"
GEMINI_SETTINGS="${HOME}/.gemini/settings.json"

# Body-append / rules-based agents
CODEX_SKILL_DIR="${HOME}/.codex/skills/${SKILL_NAME}"
CODEX_AGENTS_MD="${HOME}/.codex/AGENTS.md"
CODEX_HOOKS_FILE="${HOME}/.codex/hooks.json"
CONTINUE_RULES_DIR="${HOME}/.continue/rules"
WINDSURF_RULES_DIR="${HOME}/.windsurf/rules"
AIDER_CONVENTIONS="${HOME}/.aider.llm-handoff.md"
AIDER_CONF="${HOME}/.aider.conf.yml"
CLAUDE_DESKTOP_APP_DIR="${HOME}/Library/Application Support/Claude"

# ── Flags ─────────────────────────────────────────────────────────────────────
INSTALL_CLAUDE=false
INSTALL_CODEX=false
INSTALL_CLINE=false
INSTALL_KILO=false
INSTALL_AMP=false
INSTALL_OPENCODE=false
INSTALL_GEMINI=false
INSTALL_CONTINUE=false
INSTALL_WINDSURF=false
INSTALL_AIDER=false
INSTALL_CLAUDE_DESKTOP=false
AUTO=true

usage() {
  echo "Usage: install.sh [options]"
  echo ""
  echo "  (no flags)       auto-detect installed agents and install for all found"
  echo "  --all            install for all agents regardless of detection"
  echo ""
  echo "  --claude         Claude Code (skill + hooks; prefer /plugin install for native commands)"
  echo "  --codex          Codex CLI (skill + PreCompact hook)"
  echo "  --cline          Cline (VS Code)"
  echo "  --kilo           KiloCode"
  echo "  --amp            Amp (Sourcegraph)"
  echo "  --opencode       OpenCode"
  echo "  --gemini         Gemini CLI (skill + PreCompress hook)"
  echo "  --continue       Continue.dev"
  echo "  --windsurf       Windsurf"
  echo "  --aider          Aider"
  echo "  --claude-desktop Claude desktop app (guided)"
  echo ""
  echo "  --help           show this message"
  echo ""
  echo "Plugin install (Claude Code only, recommended):"
  echo "  /plugin marketplace add thatsuperdev/llm-handoff"
  echo "  /plugin install llm-handoff"
}

for arg in "$@"; do
  case "$arg" in
    --claude)        INSTALL_CLAUDE=true;        AUTO=false ;;
    --codex)         INSTALL_CODEX=true;         AUTO=false ;;
    --cline)         INSTALL_CLINE=true;         AUTO=false ;;
    --kilo)          INSTALL_KILO=true;          AUTO=false ;;
    --amp)           INSTALL_AMP=true;           AUTO=false ;;
    --opencode)      INSTALL_OPENCODE=true;      AUTO=false ;;
    --gemini)        INSTALL_GEMINI=true;        AUTO=false ;;
    --continue)      INSTALL_CONTINUE=true;      AUTO=false ;;
    --windsurf)      INSTALL_WINDSURF=true;      AUTO=false ;;
    --aider)         INSTALL_AIDER=true;         AUTO=false ;;
    --claude-desktop) INSTALL_CLAUDE_DESKTOP=true; AUTO=false ;;
    --all)
      INSTALL_CLAUDE=true; INSTALL_CODEX=true; INSTALL_CLINE=true
      INSTALL_KILO=true; INSTALL_AMP=true; INSTALL_OPENCODE=true
      INSTALL_GEMINI=true; INSTALL_CONTINUE=true; INSTALL_WINDSURF=true
      INSTALL_AIDER=true; INSTALL_CLAUDE_DESKTOP=true
      AUTO=false ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown flag: $arg"; usage; exit 1 ;;
  esac
done

# ── Auto-detect ───────────────────────────────────────────────────────────────
if [ "$AUTO" = true ]; then
  command -v claude    >/dev/null 2>&1                                        && INSTALL_CLAUDE=true
  command -v codex     >/dev/null 2>&1                                        && INSTALL_CODEX=true
  [ -d "${HOME}/.cline" ]                                                     && INSTALL_CLINE=true
  command -v kilo      >/dev/null 2>&1 || [ -d "${HOME}/.kilo" ]              && INSTALL_KILO=true
  command -v amp       >/dev/null 2>&1 || [ -d "${HOME}/.amp" ]               && INSTALL_AMP=true
  command -v opencode  >/dev/null 2>&1 || [ -d "${HOME}/.config/opencode" ]   && INSTALL_OPENCODE=true
  command -v gemini    >/dev/null 2>&1 || [ -d "${HOME}/.gemini/skills" ]     && INSTALL_GEMINI=true
  [ -d "${HOME}/.continue" ]                                                   && INSTALL_CONTINUE=true
  [ -d "${HOME}/.windsurf" ] || [ -d "${HOME}/.codeium/windsurf" ]            && INSTALL_WINDSURF=true
  command -v aider     >/dev/null 2>&1                                         && INSTALL_AIDER=true
  [ -d "${CLAUDE_DESKTOP_APP_DIR}" ]                                           && INSTALL_CLAUDE_DESKTOP=true
fi

# Check at least one target
NONE=true
for flag in "$INSTALL_CLAUDE" "$INSTALL_CODEX" "$INSTALL_CLINE" "$INSTALL_KILO" \
            "$INSTALL_AMP" "$INSTALL_OPENCODE" "$INSTALL_GEMINI" \
            "$INSTALL_CONTINUE" "$INSTALL_WINDSURF" "$INSTALL_AIDER" "$INSTALL_CLAUDE_DESKTOP"; do
  [ "$flag" = true ] && NONE=false && break
done
if [ "$NONE" = true ]; then
  echo "No supported agents detected."
  echo "Use --all to install for all agents, or pick one with a flag (--help for list)."
  exit 1
fi

# ── Fetch skill once ──────────────────────────────────────────────────────────
TMP_SKILL=$(mktemp)
TMP_PRECOMPACT=$(mktemp)
TMP_STOP=$(mktemp)
TMP_GEMINI_PRECOMPRESS=$(mktemp)
trap 'rm -f "$TMP_SKILL" "$TMP_PRECOMPACT" "$TMP_STOP" "$TMP_GEMINI_PRECOMPRESS"' EXIT

if ! curl -fsSL "${RAW_BASE}/${SKILL_FILE}" -o "$TMP_SKILL"; then
  echo "Error: failed to fetch skill file from ${RAW_BASE}/${SKILL_FILE}"
  echo "Check your internet connection or try again."
  exit 1
fi

# Fetch hook scripts
curl -fsSL "${RAW_BASE}/plugins/llm-handoff/scripts/precompact-write-skeleton.sh" -o "$TMP_PRECOMPACT" 2>/dev/null || true
curl -fsSL "${RAW_BASE}/plugins/llm-handoff/scripts/stop-enforce-completion.sh" -o "$TMP_STOP" 2>/dev/null || true
curl -fsSL "${RAW_BASE}/hooks/gemini-precompress.sh" -o "$TMP_GEMINI_PRECOMPRESS" 2>/dev/null || true

# Strip YAML frontmatter (--- ... ---) for agents that take plain markdown
skill_body() {
  awk 'NR==1&&/^---\r?$/{skip=1;next} skip&&/^---\r?$/{skip=0;next} !skip{gsub(/\r$/,""); print}' "$1"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
install_skill_md() {
  local dir="$1"
  mkdir -p "$dir"
  cp "$TMP_SKILL" "${dir}/SKILL.md"
  echo "  skill  → ${dir}/SKILL.md"
}

already_installed() {
  local file="$1" marker="$2"
  [ -f "$file" ] && grep -q "$marker" "$file" 2>/dev/null
}

# Install a hook script to the target path and make it executable
install_hook_script() {
  local src="$1" dest="$2"
  if [ -s "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    chmod +x "$dest"
    echo "  hook   → ${dest}"
  else
    echo "  hook   (script not available — hooks will not fire for this event)"
  fi
}

# Merge a new hook entry into settings.json using Python (available on macOS/Linux)
merge_claude_hooks() {
  local settings="$1"
  python3 - "$settings" << 'PYEOF'
import json, sys, os

path = sys.argv[1]
data = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            data = json.load(f)
        except Exception:
            data = {}

hooks_dir = os.path.expanduser("~/.claude/hooks/llm-handoff")

new_hooks = {
  "PreCompact": [{"hooks": [{"type": "command", "command": f"bash \"{hooks_dir}/precompact.sh\"", "timeout": 30}]}],
  "Stop": [{"hooks": [{"type": "command", "command": f"bash \"{hooks_dir}/stop-enforce.sh\"", "timeout": 15}]}]
}

existing = data.setdefault("hooks", {})
for event, matchers in new_hooks.items():
  event_list = existing.setdefault(event, [])
  for m in matchers:
    cmd = m["hooks"][0]["command"]
    if not any(
      any(h.get("command") == cmd for h in entry.get("hooks", []))
      for entry in event_list
    ):
      event_list.append(m)

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  hooks  → {path}")
PYEOF
}

# Merge a PreCompact hook into Codex hooks.json
merge_codex_hooks() {
  local hooks_file="$1" hooks_dir="$2"
  python3 - "$hooks_file" "$hooks_dir" << 'PYEOF'
import json, sys, os

path, hooks_dir = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            data = json.load(f)
        except Exception:
            data = {}

hook_cmd = f"bash \"{hooks_dir}/precompact.sh\""
hook_entry = {
  "matcher": {"trigger": "auto"},
  "hooks": [{"type": "command", "command": hook_cmd, "timeout": 30}]
}

prehooks = data.setdefault("PreCompact", [])
if not any(
  any(h.get("command") == hook_cmd for h in e.get("hooks", []))
  for e in prehooks
):
  prehooks.append(hook_entry)

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  hooks  → {path}")
PYEOF
}

# Merge a PreCompress hook into Gemini CLI settings.json
merge_gemini_hooks() {
  local settings="$1" hooks_dir="$2"
  python3 - "$settings" "$hooks_dir" << 'PYEOF'
import json, sys, os

path, hooks_dir = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            data = json.load(f)
        except Exception:
            data = {}

hook_cmd = f"bash \"{hooks_dir}/gemini-precompress.sh\""
hook_entry = {"hooks": [{"type": "command", "command": hook_cmd, "timeout": 30}]}

prehooks = data.setdefault("hooks", {}).setdefault("PreCompress", [])
if not any(
  any(h.get("command") == hook_cmd for h in e.get("hooks", []))
  for e in prehooks
):
  prehooks.append(hook_entry)

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  hooks  → {path}")
PYEOF
}

# ── Claude Code ───────────────────────────────────────────────────────────────
install_claude() {
  echo "[claude]"
  echo "  Note: for native commands (/llm-handoff:create, /llm-handoff:resume), use:"
  echo "        /plugin marketplace add thatsuperdev/llm-handoff"
  echo "        /plugin install llm-handoff"
  echo "  Continuing with manual skill + hooks install..."
  echo ""

  install_skill_md "$CLAUDE_SKILL_DIR"

  # Install hook scripts
  CLAUDE_HOOKS_LHO="${CLAUDE_HOOKS_DIR}/llm-handoff"
  mkdir -p "$CLAUDE_HOOKS_LHO"
  install_hook_script "$TMP_PRECOMPACT" "${CLAUDE_HOOKS_LHO}/precompact.sh"
  install_hook_script "$TMP_STOP"       "${CLAUDE_HOOKS_LHO}/stop-enforce.sh"

  # Merge hooks into settings.json
  if command -v python3 >/dev/null 2>&1; then
    merge_claude_hooks "$CLAUDE_SETTINGS"
  else
    echo "  hooks  (python3 not found — add hooks manually to ${CLAUDE_SETTINGS})"
  fi

  # CLAUDE.md entry
  local entry
  entry="
# llm-handoff
- **llm-handoff** (\`~/.claude/skills/llm-handoff/SKILL.md\`) — cross-LLM context handoff. Creates handover.md so any LLM can continue without mistakes. Trigger: \`/llm-handoff\`
When the user types \`/llm-handoff\`, \`/handoff\`, or \`/handover\`, invoke the Skill tool with \`skill: \"llm-handoff\"\` before doing anything else."

  if [ -f "$CLAUDE_MD" ]; then
    if already_installed "$CLAUDE_MD" 'skill: "llm-handoff"'; then
      echo "  CLAUDE.md already configured — skipping"
    else
      printf '%s\n' "$entry" >> "$CLAUDE_MD"
      echo "  CLAUDE.md → ${CLAUDE_MD}"
    fi
  else
    echo "  No CLAUDE.md at ${CLAUDE_MD} — create it and add:${entry}"
  fi
  echo "  Trigger: /llm-handoff  (or /handoff, /handover)"
}

# ── Codex ─────────────────────────────────────────────────────────────────────
install_codex() {
  echo "[codex]"
  install_skill_md "$CODEX_SKILL_DIR"

  # Install PreCompact hook script
  CODEX_HOOKS_LHO="${HOME}/.codex/hooks/llm-handoff"
  mkdir -p "$CODEX_HOOKS_LHO"
  install_hook_script "$TMP_PRECOMPACT" "${CODEX_HOOKS_LHO}/precompact.sh"

  # Merge into codex hooks.json
  if command -v python3 >/dev/null 2>&1; then
    merge_codex_hooks "$CODEX_HOOKS_FILE" "$CODEX_HOOKS_LHO"
  else
    echo "  hooks  (python3 not found — add PreCompact hook manually to ${CODEX_HOOKS_FILE})"
  fi

  # AGENTS.md entry
  if [ ! -f "$CODEX_AGENTS_MD" ]; then
    mkdir -p "$(dirname "$CODEX_AGENTS_MD")"
    touch "$CODEX_AGENTS_MD"
    echo "  created ${CODEX_AGENTS_MD}"
  fi
  if already_installed "$CODEX_AGENTS_MD" "## LLM Handoff"; then
    echo "  AGENTS.md already has llm-handoff — skipping"
  else
    printf '\n## LLM Handoff\n\nWhen a request contains `/llm-handoff`, `/handoff`, `/handover`, or "create handover", apply the llm-handoff skill to generate a complete handover.md before responding.\n\nThe skill is at ~/.codex/skills/llm-handoff/SKILL.md\n' >> "$CODEX_AGENTS_MD"
    echo "  AGENTS.md → ${CODEX_AGENTS_MD}"
  fi

  echo "  Auto-trigger: PreCompact hook blocks compaction until handover is complete"
  echo "  Manual trigger: /llm-handoff or 'create handover'"
}

# ── Gemini CLI ────────────────────────────────────────────────────────────────
install_gemini() {
  echo "[gemini]"
  install_skill_md "$GEMINI_SKILL_DIR"

  # Install PreCompress hook script (async — writes snapshot, cannot block)
  GEMINI_HOOKS_LHO="${HOME}/.gemini/hooks/llm-handoff"
  mkdir -p "$GEMINI_HOOKS_LHO"
  install_hook_script "$TMP_GEMINI_PRECOMPRESS" "${GEMINI_HOOKS_LHO}/gemini-precompress.sh"

  # Merge into Gemini settings.json
  if command -v python3 >/dev/null 2>&1; then
    merge_gemini_hooks "$GEMINI_SETTINGS" "$GEMINI_HOOKS_LHO"
  else
    echo "  hooks  (python3 not found — add PreCompress hook manually to ${GEMINI_SETTINGS})"
  fi

  echo "  Auto-trigger: PreCompress hook writes snapshot (async — cannot block compression)"
  echo "  Full handover: invoke manually with 'llm-handoff' or '/llm-handoff'"
}

# ── Cline ─────────────────────────────────────────────────────────────────────
install_cline() {
  echo "[cline]"
  install_skill_md "$CLINE_SKILL_DIR"
  echo "  No lifecycle hooks available in Cline — invoke manually before context degrades"
  echo "  Trigger: /llm-handoff  (enable Skills in Cline settings if not already on)"
}

# ── KiloCode ──────────────────────────────────────────────────────────────────
install_kilo() {
  echo "[kilo]"
  install_skill_md "$KILO_SKILL_DIR"
  echo "  No lifecycle hooks available yet in KiloCode — invoke manually before context degrades"
  echo "  Trigger: /llm-handoff"
}

# ── Amp ───────────────────────────────────────────────────────────────────────
install_amp() {
  echo "[amp]"
  install_skill_md "$AMP_SKILL_DIR"
  echo "  Trigger: /llm-handoff"
}

# ── OpenCode ──────────────────────────────────────────────────────────────────
install_opencode() {
  echo "[opencode]"
  install_skill_md "$OPENCODE_SKILL_DIR"
  echo "  Trigger: /llm-handoff"
}

# ── Continue.dev ──────────────────────────────────────────────────────────────
install_continue() {
  echo "[continue]"
  mkdir -p "$CONTINUE_RULES_DIR"
  local dest="${CONTINUE_RULES_DIR}/llm-handoff.md"
  if [ -f "$dest" ]; then
    echo "  already installed — skipping"
  else
    skill_body "$TMP_SKILL" > "$dest"
    echo "  rule   → ${dest}"
  fi
  echo "  Trigger: /llm-handoff or 'create handover'"
}

# ── Windsurf ──────────────────────────────────────────────────────────────────
install_windsurf() {
  echo "[windsurf]"
  mkdir -p "$WINDSURF_RULES_DIR"
  local dest="${WINDSURF_RULES_DIR}/global_rules.md"
  if already_installed "$dest" "## LLM Handoff"; then
    echo "  global_rules.md already has llm-handoff — skipping"
  else
    { printf '\n## LLM Handoff\n\n'; skill_body "$TMP_SKILL"; } >> "$dest"
    echo "  rules  → ${dest}"
  fi
  echo "  Trigger: /llm-handoff or 'create handover'"
}

# ── Aider ─────────────────────────────────────────────────────────────────────
install_aider() {
  echo "[aider]"
  skill_body "$TMP_SKILL" > "$AIDER_CONVENTIONS"
  echo "  conventions → ${AIDER_CONVENTIONS}"

  if already_installed "$AIDER_CONF" "aider.llm-handoff"; then
    echo "  ${AIDER_CONF} already references llm-handoff — skipping"
  elif [ -f "$AIDER_CONF" ]; then
    echo "  Add this to ${AIDER_CONF} to auto-load on every session:"
    echo "    read:"
    echo "      - ${AIDER_CONVENTIONS}"
  else
    printf 'read:\n  - %s\n' "$AIDER_CONVENTIONS" > "$AIDER_CONF"
    echo "  conf   → ${AIDER_CONF}"
  fi
  echo "  No lifecycle hooks in Aider — invoke manually: /llm-handoff before context degrades"
  echo "  Or: aider --read ${AIDER_CONVENTIONS}"
}

# ── Claude desktop app ────────────────────────────────────────────────────────
install_claude_desktop() {
  echo "[claude-desktop]"
  if command -v pbcopy >/dev/null 2>&1; then
    skill_body "$TMP_SKILL" | pbcopy
    echo "  clipboard ← llm-handoff skill content copied"
  else
    echo "  pbcopy not available — paste skill body from llm-handoff.skill.md manually"
  fi

  open -a "Claude" 2>/dev/null || true

  osascript -e '
    tell application "System Events"
      display dialog "llm-handoff is in your clipboard.\n\n1. Start a new chat in Claude\n2. Type:  skill-creator\n3. Paste with ⌘V when asked for content\n4. Name it \"llm-handoff\"\n\nTrigger with /llm-handoff once created." ¬
        buttons {"OK"} default button "OK" ¬
        with title "Install llm-handoff → Claude Desktop" ¬
        with icon note
    end tell
  ' 2>/dev/null || echo "  (osascript unavailable — see instructions above)"

  echo "  Trigger: /llm-handoff"
}

# ── Run ───────────────────────────────────────────────────────────────────────
echo "Installing llm-handoff..."
echo ""
[ "$INSTALL_CLAUDE" = true ]        && install_claude        && echo ""
[ "$INSTALL_CODEX" = true ]         && install_codex         && echo ""
[ "$INSTALL_GEMINI" = true ]        && install_gemini        && echo ""
[ "$INSTALL_CLINE" = true ]         && install_cline         && echo ""
[ "$INSTALL_KILO" = true ]          && install_kilo          && echo ""
[ "$INSTALL_AMP" = true ]           && install_amp           && echo ""
[ "$INSTALL_OPENCODE" = true ]      && install_opencode      && echo ""
[ "$INSTALL_CONTINUE" = true ]      && install_continue      && echo ""
[ "$INSTALL_WINDSURF" = true ]      && install_windsurf      && echo ""
[ "$INSTALL_AIDER" = true ]         && install_aider         && echo ""
[ "$INSTALL_CLAUDE_DESKTOP" = true ] && install_claude_desktop && echo ""

echo "Done."
echo ""
echo "Hook support:"
echo "  Claude Code  — PreCompact + Stop enforcement + SessionStart injection (full auto)"
echo "  Codex CLI    — PreCompact blocks compaction until handover complete (full auto)"
echo "  Gemini CLI   — PreCompress snapshot (async — manual invoke for full handover)"
echo "  All others   — manual invoke: /llm-handoff or 'create handover'"
echo ""
echo "Note: Cursor requires manual setup — add llm-handoff to Settings → Rules for AI."
echo "      Paste the body of llm-handoff.skill.md (below the --- frontmatter)."
echo ""
echo "Plugin install (Claude Code, recommended for native commands):"
echo "  /plugin marketplace add thatsuperdev/llm-handoff"
echo "  /plugin install llm-handoff"
