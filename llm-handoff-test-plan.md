# llm-handoff test plan

Tests to verify the handover is complete enough for a fresh LLM to continue correctly.

---

## Manual trigger

### Basic invocation
- `/llm-handoff` in a session with active work → `handover.md` created in project root
- `/handoff` → same result
- `/handover` → same result
- `create a handover` → same result

### Gitignore
- `handover.md` appears in `.gitignore` after first run
- If `.gitignore` does not exist, it is created with `handover.md`
- Running `/llm-handoff` a second time does not duplicate the `.gitignore` entry

### Completeness
- No `<!-- TODO: -->` markers in the output
- All sections present: original request, goal, repo state, progress, files in play, decisions, failed approaches, blockers, next steps, critical context, environment, metadata
- Model name and version are stated (not left as "unknown")
- Next steps include at minimum: file path, what to do, how to verify

---

## Auto-trigger — Claude Code

### PreCompact hook
- Hook fires when Claude Code approaches context limit
- `handover.md` skeleton is written with git state before compaction starts
- `.claude/llm-handoff/completion-required` sentinel file is created

### Stop enforcement
- After PreCompact, the Stop hook blocks Claude from stopping if `<!-- TODO: -->` markers remain
- Claude fills in all sections before the session ends
- After all sections complete, sentinel is removed and session ends cleanly
- Running `/llm-handoff:create` manually also clears the sentinel (no double-enforcement)

### Plugin commands
- `/llm-handoff:create` → produces complete `handover.md`
- `/llm-handoff:resume` → reads `handover.md`, reports previous LLM + goal + next step, waits for confirmation before acting

---

## Auto-trigger — Codex CLI

- PreCompact hook fires before compaction
- Hook blocks compaction
- Terminal message prompts user to run `/llm-handoff`
- Once handover is complete, compaction can proceed

---

## Auto-trigger — Gemini CLI

- PreCompress hook fires (async) and writes snapshot to `handover.md`
- Snapshot contains: branch, last commit, git status, recent commits
- Snapshot explicitly notes it is incomplete (reasoning sections not filled)
- No TODO markers in the snapshot — it is clear about what it is

---

## Cross-LLM handover test

The key quality check: give the `handover.md` to a fresh LLM instance with no prior context and verify:

1. The LLM correctly identifies what the session was working on
2. The LLM does not retry any approach listed in "Failed approaches"
3. The LLM starts with "Next steps item 1" without asking "where do we start?"
4. The LLM knows the WHY behind key decisions and does not undo them
5. The LLM can verify repository state before acting

### Test matrix

| Previous LLM | Next LLM | Expected result |
|---|---|---|
| Claude Code | Claude (new session) | Full continuity |
| Claude Code | Codex CLI | Full continuity |
| Claude Code | Gemini CLI | Full continuity |
| Claude Code | ChatGPT | Full continuity |
| Codex | Claude Code | Full continuity |
| Gemini (snapshot) | Claude Code | Partial — reasoning sections missing, explicit warning in doc |

---

## Edge cases

- **No git repo**: handover.md written to `pwd`, repo state section says "not a git repo"
- **Clean working tree**: git status section says "clean working tree"
- **No commits**: last commit field says "no commits"
- **In a worktree**: worktree path is captured correctly
- **Stashed changes**: stash entries listed in repo state
- **No `.gitignore`**: created with `handover.md` as first entry
- **Session with no real work**: next steps = "None in this session" not a TODO placeholder
- **Running services**: listed in environment section
- **Multiple invocations**: second `/llm-handoff` overwrites `handover.md` (not appends)
