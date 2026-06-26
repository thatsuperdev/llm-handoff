---
name: llm-handoff
description: "LLM Handoff creates a complete handover.md document so any LLM can continue the current task without mistakes. Captures git state, model identity, decisions, failed approaches, blockers, and exact next steps. Use when context is full, switching tools, or ending a session."
trigger: /llm-handoff
aliases:
  - /handoff
  - /handover
---

# LLM Handoff

A universal AI skill that creates a complete, self-contained `handover.md` document so any LLM — Claude, Codex, Gemini, KiloCode, Aider, or any other tool — can continue the current task without mistakes, repeated work, or lost context.

The goal is not a summary. It is a **transfer of working state** — specific enough that the next LLM can act correctly on the first try without needing to re-derive decisions, retry failed paths, or ask clarifying questions the current session already answered.

---

## Invocation modes

### Explicit mode (default)

Triggered manually with `/llm-handoff`, `/handoff`, or `/handover`. Generates `handover.md` in the current working directory and adds it to `.gitignore`.

### Auto mode (hook-triggered)

On platforms with PreCompact / PreCompress hooks (Claude Code, Codex CLI, Gemini CLI), a partial handover skeleton is written automatically before context compaction. On Claude Code and Codex, the Stop hook enforces that the LLM completes all sections before stopping, while context is still intact.

On platforms without hooks (KiloCode, Aider, Amazon Q, Continue.dev, Windsurf, Cline), invoke explicitly before the context degrades.

### Skip on a single request

Prefix any command with `--raw` to suppress handoff in always-on mode.

---

## Core instruction

When LLM Handoff is invoked, do not summarize the conversation.

Instead, produce a **complete transfer document** — everything the next LLM needs to continue the task correctly, including things that are not written anywhere in the codebase but exist only in this session's context: reasoning behind decisions, paths that were tried and failed, constraints that were discovered, and the exact state at the moment of handoff.

Write `handover.md` to the project root (or current working directory if no git root is found). Auto-add `handover.md` to `.gitignore`.

Tell the user: "Handover complete. `handover.md` is ready and gitignored."

---

## Prime directive

The next LLM starts with zero context. Write as if explaining to a capable engineer who knows nothing about this session.

Assume:
- They cannot read your conversation history
- They cannot infer what you were working on from the codebase alone
- They will make mistakes if they do not know the WHY behind decisions
- They will waste time retrying approaches that already failed
- They will miss non-obvious constraints that are not in the code

Do not:
- Summarize for brevity at the expense of completeness
- Omit decisions because they seem obvious
- Skip failed approaches because they feel embarrassing
- Leave next steps vague when specific is possible

---

## Gather phase

Before writing, run the following deterministic checks. Do not skip any.

### Repository state
```bash
git rev-parse --show-toplevel         # project root
git branch --show-current             # active branch
git log --oneline -10                 # recent commits
git status --short                    # uncommitted changes
git diff --stat HEAD                  # what changed
git stash list                        # stashed work
git worktree list                     # active worktrees
```

### Model and tool identity

State your own model name and version. State which tool is running you (Claude Code, Codex CLI, Gemini CLI, KiloCode, Aider, etc.). State the handoff trigger reason (context limit / manual / session end).

### Environment
```bash
# Check for running services
lsof -i -P -n 2>/dev/null | grep LISTEN | head -20
# Or on systems without lsof:
ss -tlnp 2>/dev/null | head -20

# Check for relevant env vars (list names only, never values for secrets)
env | grep -E 'NODE_ENV|APP_ENV|DATABASE|API_URL|PORT|HOST' | sed 's/=.*/=<set>/'

# Check package manager / language version
node --version 2>/dev/null; python3 --version 2>/dev/null; go version 2>/dev/null; cargo --version 2>/dev/null
```

### Test state
```bash
# Find test runner
cat package.json 2>/dev/null | grep -E '"test"|"spec"' | head -5
cat Makefile 2>/dev/null | grep -E '^test' | head -5
```

---

## Write phase

After gathering, write `handover.md` using the template below. Fill every section completely. Do not use placeholder text, "N/A", or "TBD" unless genuinely not applicable. If a section is empty (e.g., no failed approaches), write "None in this session."

---

## Handover document template

````markdown
---
generated: <ISO 8601 timestamp>
previous_llm: <model name and version, e.g. claude-sonnet-4-6>
tool: <e.g. Claude Code / Codex CLI / Gemini CLI / KiloCode>
trigger: <manual | auto (PreCompact) | auto (PreCompress) | session end>
branch: <git branch or "not a git repo">
worktree: <path if in a worktree, otherwise "N/A">
---

# LLM Handover

> Read this file completely before taking any action. Verify repository state matches
> what is documented before starting work. If anything conflicts, investigate first.

## Quick start checklist

- [ ] Read this entire file
- [ ] Run `git status` — confirm it matches **Repository state** below
- [ ] Run `git log --oneline -5` — confirm last commit matches
- [ ] Read the files listed in **Files in play**
- [ ] Start with **Next steps item 1**

---

## Original request

> Verbatim or near-verbatim: what the user asked for when this session started.

<original user request>

## Session goal

One sentence: what we are trying to achieve.

**Scope — in:**
- <what is in scope>

**Scope — out:**
- <what is explicitly not in scope, if established>

**Constraints:**
- <stated or discovered constraints the next LLM must respect>

---

## Repository state at handoff

| Field | Value |
|-------|-------|
| Branch | `<branch>` |
| Worktree | `<path or N/A>` |
| Last commit | `<hash> <message>` |
| Working tree | `<clean / dirty — list files if dirty>` |
| Staged | `<list staged files or "none">` |
| Stashed | `<list stash entries or "none">` |

**Uncommitted changes:**
```
<output of git status --short, or "clean working tree">
```

**Recent commits:**
```
<output of git log --oneline -5>
```

---

## Progress

### Completed this session
- <specific task with file:line reference where relevant>
- <another completed task>

### In progress when handoff triggered
<Describe exactly what was being worked on. Include the file being edited, the function being implemented, the test being fixed — be as specific as possible.>

### Not started (known remaining work)
- <task not yet touched>

---

## Files in play

Files the next LLM must read before acting. Ordered by importance.

| File | Why it matters |
|------|----------------|
| `path/to/file.ts` | <one line: what's relevant here> |
| `path/to/other.ts` | <one line> |

---

## Key decisions made

These decisions have already been evaluated. Do not reverse them without good reason — the reasoning is documented here.

### Decision: <title>
**Chose:** <what was chosen>
**Why:** <full reasoning — what alternatives were considered and why this was picked>
**Implications:** <what this decision constrains going forward>

### Decision: <title>
**Chose:** <...>
**Why:** <...>

---

## Failed approaches — do not retry

Approaches that were tried and did not work. Retrying them will waste time.

### Failed: <description>
**Tried:** <exactly what was attempted>
**Error / result:** <exact error message or observed behavior>
**Why it failed:** <root cause>
**Alternative taken:** <what was done instead, if anything>

---

## Blockers and open questions

- [ ] <unresolved issue — be specific about what is unknown or blocked and why>
- [ ] <open question that must be answered before proceeding>

---

## Next steps

Execute in order. Do not skip steps or reorder without understanding the dependencies.

1. **<Action title>**
   - File: `<path>`
   - What to do: <specific instruction — enough to act without guessing>
   - How to verify: <command or check that confirms this step succeeded>

2. **<Action title>**
   - File: `<path>`
   - What to do: <...>
   - How to verify: <...>

3. <continue as needed>

---

## Critical context

Things that are not obvious from the codebase but will cause mistakes if the next LLM does not know them.

- **<title>:** <description — workaround, gotcha, invariant, or constraint discovered this session>
- **<title>:** <...>

---

## Environment at handoff

| Item | Value |
|------|-------|
| Language / runtime | `<e.g. Node 22.3.0 / Python 3.12>` |
| Package manager | `<npm / pip / cargo / etc.>` |
| Running services | `<list port:service pairs, or "none">` |
| Relevant env vars | `<names only — e.g. DATABASE_URL=<set>, API_KEY=<set>>` |
| Test command | `<exact command to run tests>` |
| Dev server command | `<exact command to start dev server, if applicable>` |

---

## Handoff metadata

| Field | Value |
|-------|-------|
| Handoff reason | `<context limit / manual request / session end>` |
| Previous LLM | `<model name and version>` |
| Tool | `<Claude Code / Codex CLI / Gemini CLI / KiloCode / etc.>` |
| Generated | `<ISO 8601 timestamp>` |
| Suggested next LLM | `<any, or specific suggestion with reason>` |

---

*Generated by [llm-handoff](https://github.com/thatsuperdev/llm-handoff)*
````

---

## Verify phase

Before writing the file, check the draft against this quality bar. Every point must pass.

1. **Next steps are executable** — each step names a file, what to change, and how to verify. A fresh LLM could act without asking questions.
2. **Decisions include WHY** — not just what was chosen but why, and what alternatives were considered.
3. **Failed approaches are specific** — not "tried X, didn't work" but exact error and root cause.
4. **No TODO placeholders remain** — every section is filled or explicitly states "None in this session."
5. **Blockers are actionable** — each blocker says what is unknown and what information would unblock it.
6. **Original request is verbatim or near-verbatim** — not paraphrased in a way that loses nuance.
7. **Repository state is accurate** — reflects actual git output, not inferred or approximate.
8. **Model and tool identity are stated** — the next LLM must know what model wrote this.

---

## After writing

1. Write `handover.md` to the project root (or `git rev-parse --show-toplevel` output).
2. If `.gitignore` exists: append `handover.md` if not already present. If it does not exist: create it with `handover.md` as the first entry.
3. Confirm to the user:
   ```
   Handover complete.
   → handover.md written to <path>
   → gitignored: yes
   
   The next LLM can continue from "Next steps item 1":
   <first next step title>
   ```

---

## Invocation detection

Treat any of the following as invoking LLM Handoff:

- `/llm-handoff`
- `/handoff`
- `/handover`
- `@llm-handoff`
- `create handover`
- `create handoff`
- `write a handover`
- `write handover.md`
- `generate handoff document`
- `context is running out, create handover`
- `before you stop, write a handover`

---

## Resume mode

When invoked with `/llm-handoff:resume` or `@llm-handoff resume`, the LLM is beginning a new session and a `handover.md` exists.

**Steps:**

1. Read `handover.md` completely.
2. Run the quick start checklist (verify git state).
3. Report to the user:
   - Previous LLM and tool
   - Session goal
   - What was completed
   - What is in progress
   - First next step
4. Ask: "Ready to continue? I'll start with: `<next step 1>`"
5. Wait for confirmation before acting.

---

## Platform-specific notes

### Claude Code
- Auto-trigger via PreCompact hook (if llm-handoff plugin installed)
- PreCompact writes the deterministic skeleton (git state, branch, recent commits)
- Stop hook blocks the session from stopping until all TODO sections are filled in by the LLM
- Output is `handover.md` — a portable file the user pastes into any LLM to continue

### Codex CLI
- PreCompact hook blocks compaction until handover is complete or user overrides
- Manual: `/llm-handoff` or `distill this: create handover`

### Gemini CLI
- PreCompress hook runs asynchronously — writes deterministic skeleton only
- Full handover requires manual invocation: `llm-handoff` or `/llm-handoff`

### KiloCode / Aider / Amazon Q / Continue.dev / Windsurf / Cline
- No lifecycle hooks available — invoke manually before context degrades
- Watch for context size warnings and invoke proactively

---

## Quality bar

A good handover satisfies the test: "Could a capable engineer who has never seen this codebase or this conversation read this document and continue the work correctly in their first session?"

If the answer is no — add more.
