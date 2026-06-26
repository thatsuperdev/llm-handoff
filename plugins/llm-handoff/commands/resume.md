---
description: Load handover.md and brief yourself before continuing a session
allowed-tools: Read, Bash(git:*)
---

You are starting a new session. A `handover.md` was left by the previous session to brief you. Load it and prepare to continue.

## Steps

### 1. Read the handover

Read `handover.md` from the project root (or `git rev-parse --show-toplevel`).

If it does not exist, tell the user:
```
No handover.md found in this directory. Either no handover was created, or you may
need to check a different directory. Run /llm-handoff:create in the previous session
before switching to this one.
```

### 2. Verify repository state

Run:
```bash
git status --short
git log --oneline -5
```

Compare the output to the **Repository state** section in `handover.md`.

If anything conflicts (different branch, unexpected uncommitted files, commits that don't match), report it:
```
Warning: Current state differs from handover.md.
- Expected branch: <from handover>  Got: <actual>
- Expected last commit: <from handover>  Got: <actual>

Investigate before proceeding — the handover may be stale or from a different worktree.
```

### 3. Brief the user

Report in this exact structure:

```
Handover loaded.

Previous LLM:  <model and tool from handover>
Generated:     <timestamp>

Goal:          <session goal>

Completed:
  - <item>
  - <item>

In progress:
  <what was being worked on>

Ready to continue with:
  → Step 1: <first next step title>
     File: <path>
     Action: <what to do>
     Verify: <how to confirm>

Continue? (I'll wait for your go-ahead before making any changes.)
```

### 4. Wait for confirmation

Do not make any changes until the user confirms. If the user says "yes" or "go", begin with Next steps item 1 exactly as described in the handover.

### 5. After completing each step

Check it off in your working context (you do not need to edit handover.md). When all next steps are complete, ask the user if they want to update or remove handover.md.
