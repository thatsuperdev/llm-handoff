# llm-handoff

**Context ran out. Work didn't stop.**

Cross-LLM context handoff — generates a complete `handover.md` so Claude, Codex, Gemini, KiloCode, Aider, or any other LLM can pick up exactly where you left off, on the first try, without re-explaining anything.

```
/plugin marketplace add thatsuperdev/llm-handoff
/plugin install llm-handoff
```

---

## What actually happens when context runs out

You've spent two hours on a hard problem. The LLM has learned things that aren't in the code: which approaches failed and why, the decision you made to use X instead of Y (and the non-obvious reason), the gotcha you discovered at line 847, the exact next step you were about to take.

Then context fills up. The session compacts. That knowledge is gone.

The next LLM — even the same model, even in the same tool — starts fresh. It doesn't know what was tried. It will suggest the approach that already failed. It will re-derive decisions you already made and probably make them differently. You spend the first twenty minutes of the new session just getting it back to where you were.

**llm-handoff stops this.** When context approaches its limit, it writes everything the next LLM needs — not a summary, a complete transfer of working state. Decisions and why they were made. Approaches that failed and the exact error. Specific next steps with file paths. The non-obvious things that will cause mistakes if the next LLM doesn't know them.

You paste `handover.md` into any LLM and it continues. No re-explanation. No repeated mistakes. No wasted turns getting back up to speed.

---

## Why this one, not the others

Every other handoff tool in this space ([thepushkarp/handoff](https://github.com/thepushkarp/handoff), [who96/claude-code-context-handoff](https://github.com/who96/claude-code-context-handoff), [CyPack/claude-session-handoff](https://github.com/CyPack/claude-session-handoff)) solves the same-tool problem: Claude Code → Claude Code. The handover is injected back into the next Claude session automatically.

That's not enough if you're mid-task and Claude's context is full but Codex has a fresh 400K window. Or if you want to throw a hard bug at GPT-4o. Or if you're on a plan with token limits and need to switch tools to keep going.

**llm-handoff is built for the cross-LLM case.** The output is a portable Markdown document. It works with any tool that can read a file. Claude, Codex, Gemini, ChatGPT, Aider, a human engineer — anyone can pick it up.

| | llm-handoff | thepushkarp/handoff | who96/context-handoff | CyPack/session-handoff |
|---|---|---|---|---|
| Works across different LLMs | **Yes** | No | No | No |
| Portable Markdown output | **Yes** | No (Claude inject) | No (Claude inject) | No (paste prompt) |
| Auto-trigger on context limit | **Claude + Codex** | Claude only | Claude only | Manual only |
| Gemini CLI support | **Snapshot** | No | No | No |
| Codex hooks | **Yes** | No | No | No |
| Claude Code plugin | **Yes** | Yes | No | No |
| Decisions captured with WHY | **Yes** | Partial | No | Yes |
| Failed approaches | **Yes** | No | No | Yes |

---

## Install

### Claude Code — plugin (zero friction)

```
/plugin marketplace add thatsuperdev/llm-handoff
/plugin install llm-handoff
```

Gives you native `/llm-handoff:create` and `/llm-handoff:resume` commands with hooks wired automatically.

### All other tools — one command

```bash
curl -fsSL https://raw.githubusercontent.com/thatsuperdev/llm-handoff/main/install.sh | bash
```

Auto-detects which tools are installed and configures each one.

**Supported:** Claude Code · Codex CLI · Gemini CLI · KiloCode · Amp · Cline · OpenCode · Continue.dev · Windsurf · Aider · Claude desktop app

Target a specific tool:

```bash
bash install.sh --codex
bash install.sh --gemini
bash install.sh --kilo
bash install.sh --all
```

---

## How to use it

### Manual (works everywhere)

Say any of these in your LLM session before context gets critical:

```
/llm-handoff
/handoff
create a handover before we stop
write handover.md, context is running out
```

### Claude Code plugin commands

```
/llm-handoff:create    generate complete handover.md now
/llm-handoff:resume    load handover.md and brief yourself for this session
```

### Auto-trigger (Claude Code and Codex)

When context approaches the limit, the PreCompact hook fires automatically:

1. Git state, branch, recent commits written to `handover.md` immediately — no LLM required for this part
2. The LLM is asked to complete the reasoning sections while context is still intact
3. The Stop hook blocks the session from ending until every `<!-- TODO -->` is filled
4. Session ends cleanly. `handover.md` is complete on disk, gitignored.

You open a new session with any LLM and paste `handover.md`. Done.

---

## What the handover contains

Every section exists because its absence causes a mistake in the next session.

| Section | Why it matters |
|---|---|
| **Original request** | The next LLM needs to know what was actually asked, not an AI summary of it |
| **Session goal + scope** | Stops the next LLM from gold-plating or going out of scope |
| **Repository state** | Branch, commit, dirty files — so the next LLM can verify before touching anything |
| **Progress** | What's done, what's in flight, what hasn't started |
| **Files in play** | The 3-5 files that actually matter for this task, so the next LLM reads the right things first |
| **Key decisions + WHY** | The most important section. Without the reasoning, the next LLM will undo good decisions |
| **Failed approaches** | Prevents the next LLM from spending time retrying what already didn't work |
| **Blockers** | Open questions that need answering before progress can continue |
| **Next steps** | Ordered, specific: file path, what to change, how to verify it worked |
| **Critical context** | The non-obvious things — workarounds, gotchas, constraints — that only exist in session memory |
| **Environment** | Runtime, services, env vars, test command — so the next LLM can run things correctly |

---

## Starting the next session

Paste `handover.md` into any LLM and say:

```
Read the attached handover and continue from "Next steps item 1".
Ask before making any changes.
```

Or with the plugin installed:

```
/llm-handoff:resume
```

The plugin reads `handover.md`, verifies your git state matches what's documented, briefs you on the situation, and waits for your go-ahead before touching anything.

---

## Hook coverage

| Platform | Auto-trigger | What happens |
|---|---|---|
| **Claude Code** | Yes | PreCompact writes skeleton → Stop hook enforces LLM completes all sections before session ends |
| **Codex CLI** | Yes | PreCompact blocks compaction until handover is complete |
| **Gemini CLI** | Partial | PreCompress writes git snapshot (async — cannot block compression). Full handover requires manual `/llm-handoff` |
| **KiloCode / Aider / Amazon Q / others** | No | Invoke manually before context degrades. No lifecycle hooks available on these platforms yet |

> Gemini's `PreCompress` fires asynchronously and can't block compression. By the time it runs, it's too late to ask the model to write reasoning. Run `/llm-handoff` a turn before you expect context to fill.

---

## Get into the Claude Code community marketplace

The plugin is installable right now via self-hosted marketplace. To get listed in the official community marketplace for broader discovery:

1. Go to [clau.de/plugin-directory-submission](https://clau.de/plugin-directory-submission)
2. Submit `thatsuperdev/llm-handoff`
3. Anthropic runs automated security scanning + human review
4. Once approved, users can find it at `anthropics/claude-plugins-community`

---

## Always-on mode

To have the skill active in every session without invoking it manually, add to `~/.claude/CLAUDE.md`:

```markdown
## LLM Handoff — always-on
If context usage appears high, or if the user says anything like "context is running out"
or "we're almost at the limit", generate handover.md before doing anything else.
Skill: ~/.claude/skills/llm-handoff/SKILL.md
```

---

## Contributing

The skill file (`llm-handoff.skill.md`) is where the handover format lives. If you find a category of information that was missing and caused the next LLM to make a mistake — open an issue or PR against that file.

To add support for a new LLM tool: add an `install_<tool>()` function to `install.sh`, document its hook availability in the README table, and note whether manual invocation is the only option.

---

## License

MIT
