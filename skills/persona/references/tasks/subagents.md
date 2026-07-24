# Procedure: spawning subagents (a worker's own fan-out)

A worker owns one task end-to-end. When the work is heavy or
parallelizable, the worker may spawn **subagents** (the Agent tool) to help.
This is **not delegation**: delegation hands work to another supervised
*persona* and is the manager's job alone. Subagents are disposable,
unsupervised helpers a worker spawns for its *own* task — and remains fully
accountable for.

## Why the rules exist: supervised vs. unsupervised

- **You, the worker, are supervised.** You run in a pane, can ask the **user**
  clarifying questions (one at a time), and the user supervises you. That is
  your value.
- **A subagent is unsupervised.** It cannot talk to the user, cannot clarify
  mid-task, runs to completion, and returns a single result. It knows only what
  you put in its prompt.
- So two rules follow: **resolve every ambiguity before you fan out** (a
  subagent can't ask), and **verify everything it returns** (you own its output
  as if you wrote it).

## When to fan out

Use subagents for sub-work that is **voluminous or parallelizable AND fully
specified**:
- Broad searches/reads across many files — "find every call site of X", "where
  is Y configured".
- A large volume of code to review — split the diff into chunks; each subagent
  reviews its chunk against a fixed rubric you supply.
- Independent, mechanical, unambiguous edits — known-pattern boilerplate,
  repetitive multi-file changes.
- Throwaway analysis you will verify — "summarize what this module does".

Rule of thumb: if the sub-work has one correct outcome you can specify in a
paragraph, and there's enough of it to be worth the overhead, fan out.
Otherwise do it yourself.

## What never leaves you

- **Anything ambiguous** — clarify with the user first; only then is it
  spawnable.
- **Judgment and decisions** — design choices, what to change, accepting or
  rejecting findings.
- **Anything needing the user** — a subagent can't ask; you can.
- **Integration and the result** — you assemble, verify, and own it. A
  subagent's output is never the deliverable on its own.
- **Whole-task coherence** — you hold the full picture; each subagent sees only
  the fragment you handed it.

## Clarify before you fan out

1. **Read the task.** If anything is not perfectly clear, ask the **user** — one
   question at a time — and fully align. **The user's direction overrides the
   task text.**
2. **Spawn only once the sub-work is unambiguous.** If you can't write a
   self-contained brief for it, it isn't ready — clarify or do it yourself.
3. **The brief is self-contained.** Each subagent gets **only what you put in
   its prompt**: goal, exact scope, the rubric/acceptance criteria, and what to
   return. A subagent must **never** read `.task`, `.done`, or `notes-*.md` —
   that is the manager/worker contract and will only confuse it. If the prompt
   doesn't say it, the subagent doesn't know it.

## Verify before you integrate

A subagent's report is a **lead, not a finding.** Verify against the real
artifacts, never the subagent's summary.

- **Code:** read the changed lines yourself; run the build and tests. "I made
  the change" is not evidence — the diff is.
- **Review fan-out:** spot-check every claim against the source — confirm the
  cited `file:line` says what the subagent claims before you surface it. A
  subagent's false positive is still your false positive.
- **Searches:** treat results as pointers to confirm, not ground truth.
- **Surprises:** if output is ambiguous or unexpected, resolve it — re-spawn
  with a tighter brief, do it yourself, or ask the user. Never integrate on a
  guess.

Only verified output ships.
