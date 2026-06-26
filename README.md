# llm-handoff

Cross-LLM context handoff. When your context is full, creates a complete `handover.md` so any LLM — Claude, Codex, Gemini, KiloCode, Aider, GPT — can continue your work without mistakes.

---

## The problem

Every LLM coding tool has a context limit. When you hit it:

- Decisions made this session are gone — the next LLM will second-guess them
- Failed approaches aren't recorded — the next LLM will retry them
- "What were we working on?" requires re-explanation
- Switching to a different LLM means starting from scratch

Existing tools ([thepushkarp/handoff](https://github.com/thepushkarp/handoff), [who96/claude-code-context-handoff](https://github.com/who96/claude-code-context-handoff), and others) solve this for Claude Code only and focus on resuming in the same tool. **llm-handoff is cross-LLM by design** — the output is a portable Markdown document you paste into any chat.

---

## How it works

```
Context approaches limit
        ↓
PreCompact hook fires (Claude Code / Codex)
        ↓
Git state, branch, recent commits written to handover.md automatically
        ↓
LLM is instructed to fill in reasoning sections:
  - Original request
  - What was done and why
  - Decisions + WHY (most important)
  - Failed approaches + exact errors
  - Blockers
  - Specific next steps with file paths
        ↓
Stop hook verifies all sections are complete
        ↓
handover.md is ready — gitignored, sitting in project root
        ↓
User pastes it into any LLM to continue
```

The handover is a **portable document**, not a tool-specific session state. It works with any LLM that can read Markdown.

---

## Install

### Claude Code — plugin (recommended)

Gets you native `/llm-handoff:create` and `/llm-handoff:resume` commands, plus automatic hook wiring.

```
/plugin marketplace add thatsuperdev/llm-handoff
/plugin install llm-handoff
```

### All other tools — install script

Auto-detects which tools are installed and configures each one.

```bash
curl -fsSL https://raw.githubusercontent.com/thatsuperdev/llm-handoff/main/install.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/thatsuperdev/llm-handoff
cd llm-handoff
bash install.sh
```

Supported tools: **Claude Code**, **Codex CLI**, **Gemini CLI**, **KiloCode**, **Amp**, **Cline**, **OpenCode**, **Continue.dev**, **Windsurf**, **Aider**, **Claude desktop app**

Install for a specific tool:

```bash
bash install.sh --codex
bash install.sh --gemini
bash install.sh --kilo
bash install.sh --all    # install for every supported tool
```

---

## Usage

### Trigger manually

In any LLM tool, invoke:

```
/llm-handoff
/handoff
/handover
```

Or phrase it naturally:

```
create a handover before we stop
write handover.md, context is running out
generate handoff document
```

### Claude Code — plugin commands

```
/llm-handoff:create    create a complete handover.md now
/llm-handoff:resume    load an existing handover.md and brief yourself
```

### Auto-trigger (Claude Code and Codex only)

When context approaches the limit, the PreCompact hook fires automatically:

1. Git state is written to `handover.md` immediately (no LLM needed for this part)
2. The LLM is asked to complete the reasoning sections
3. The Stop hook blocks the session from ending until every `<!-- TODO -->` is filled
4. Session ends cleanly, `handover.md` is complete

---

## Hook support by platform

| Platform | Auto-trigger | Behavior |
|---|---|---|
| **Claude Code** | Yes | PreCompact writes skeleton → Stop enforces completion |
| **Codex CLI** | Yes | PreCompact blocks compaction until handover complete |
| **Gemini CLI** | Partial | PreCompress writes git snapshot (async — cannot block); full handover is manual |
| **KiloCode** | No | No lifecycle hooks yet — invoke manually |
| **Aider** | No | No lifecycle hooks — invoke manually |
| **Amazon Q** | No | Context hooks deprecated — invoke manually |
| **Continue.dev / Windsurf / Cline** | No | Invoke manually before context degrades |

> **Why doesn't Gemini auto-trigger a full handover?**
> Gemini CLI's `PreCompress` hook fires asynchronously and cannot block or pause compression. By the time the hook runs, it's too late to ask the model to write reasoning. The snapshot (git state only) is the best that can be done automatically. Run `/llm-handoff` a turn before you expect the context to fill.

---

## The handover.md format

Every `handover.md` contains:

| Section | What it captures |
|---|---|
| **Quick start checklist** | Steps to verify state before acting |
| **Original request** | Verbatim user request from session start |
| **Session goal + scope** | What we're trying to achieve, what's out of scope |
| **Repository state** | Branch, last commit, uncommitted changes, stash |
| **Progress** | Completed, in progress, not started |
| **Files in play** | Files the next LLM must read first |
| **Key decisions + WHY** | Every decision made with full reasoning |
| **Failed approaches** | What was tried, exact error, root cause |
| **Blockers** | Unresolved issues with enough detail to act on |
| **Next steps** | Ordered, specific — file path, action, verification |
| **Critical context** | Non-obvious things that would cause mistakes |
| **Environment** | Runtime, services, env vars, test command |
| **Handoff metadata** | Previous LLM, tool, timestamp, trigger |

---

## Starting the next session

Open a new chat with any LLM and paste `handover.md` (or attach it if the tool supports file upload). Then say:

```
Read the handover.md above and continue from "Next steps item 1".
Ask me before making any changes.
```

Or with Claude Code plugin installed in the new session:

```
/llm-handoff:resume
```

---

## Always-on mode

To have the skill active in every Claude Code session without invoking it manually, add to `~/.claude/CLAUDE.md`:

```markdown
## LLM Handoff — always-on
Apply the llm-handoff skill proactively: if context usage appears high, or if the user
says "we're almost out of context", generate handover.md before responding to anything else.
Skill: ~/.claude/skills/llm-handoff/SKILL.md
```

---

## Compared to existing tools

| | llm-handoff | thepushkarp/handoff | who96/context-handoff | CyPack/session-handoff |
|---|---|---|---|---|
| Cross-LLM | **Yes** | No | No | No |
| Portable output | **Yes (Markdown)** | Claude-only inject | Claude-only inject | Paste prompt |
| Auto-trigger | Claude Code + Codex | Claude Code | Claude Code | Manual only |
| Gemini support | **Snapshot** | No | No | No |
| Codex hooks | **Yes** | No | No | No |
| Plugin marketplace | **Yes** | Yes | No | No |
| Decisions + WHY | **Yes** | Partial | No | Yes |
| Failed approaches | **Yes** | No | No | Yes |

---

## Contributing

Issues and PRs welcome. The skill file (`llm-handoff.skill.md`) is the authoritative definition — if you improve the handover format or add platform support, that's the place to start.

To add support for a new LLM tool, add an `install_<tool>()` function to `install.sh` and document the hook availability (or lack of it) in the README table above.

---

## License

MIT
