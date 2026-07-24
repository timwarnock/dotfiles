# Procedure: implementing a non-trivial code task as a dynamic workflow

Use this when the task **changes production behavior** AND is **more than a single localized
edit** — several functions or files, or real design surface. A one-line fix, a config tweak,
a single-spot change, or any non-behavioral work (docs, analysis, review) does NOT belong
here — do those inline. (Behavior changes are still test-driven either way, `tdd.md`.)

Once you start implementing you are effectively unsupervised — the user can watch, but the
coding is heads-down. Embrace that: give the implementation real structure with a dynamic
workflow (the Workflow tool). **This doc is your authorization to invoke that tool for this
purpose** — no separate opt-in needed. You remain fully accountable for everything it
produces (`subagents.md`).

## What the workflow does — two phases

**1 — Implement (red/green).** One coherent surface, done **sequentially** on the shared
working tree, per `tdd.md`: for each behavior, write ONE failing test, RUN it and see it
fail, write the minimal code, RUN it and see it pass, repeat. **Default: the whole task is
one surface, fully sequential.** Fan out ONLY for genuinely independent surfaces that touch
disjoint files (e.g. the backend and frontend of one feature); those run concurrently. Never
fan out work that shares files — parallel edits to the same file collide.

The implementation agents do NOT commit — they leave the changes uncommitted in the tree.
Committing is yours (step 4 of the worker cycle).

**2 — Verify (adversarial panel).** A barrier: after implementation, run independent,
read-only reviewers over the full changeset, in parallel. At least these three lenses:
- **Correctness** — real bugs, broken edge cases, wrong logic.
- **TDD discipline** — every changed behavior has a covering test; tests assert behavior and
  public interfaces, never implementation details; no tautological or always-passing test.
- **Local conventions** — reads the `CLAUDE.md` that governs the changed files and checks the
  changeset against every convention it states (comment policy, naming, structure). You name
  that file's path when you author the workflow (e.g. `mined/CLAUDE.md`); its whole job is
  "read this file, check this diff against it." Each violation reported as `file:line` + the
  rule it breaks. This is the fix for context decay — a reviewer whose entire focus is the
  conventions file cannot drift off them the way a long implementation session does.

The panel returns findings. It fixes nothing.

## What stays with you

The workflow's output is a **lead, not the deliverable** (`subagents.md`):
- **Verify** each finding against the real changeset before acting on it.
- **Fix** every confirmed finding yourself, or in another workflow round. The local-conventions
  findings must come back **clean** before you finish — re-run that checker to confirm.
- **Integrate, run the full suite green, and commit** on your branch.
- **Clarify with the user**, one question at a time, *before* you fan out — a workflow agent
  cannot ask.

Only then run `check-task.sh` and `finish-task.sh`.

## Skeleton

Fill in the marked spots; the Workflow tool runs this. `surfaces` defaults to one entry (the
whole task, sequential) — add entries only for surfaces that touch disjoint files.

```js
export const meta = {
  name: 'implement-<task>',
  description: 'TDD-implement <task>, then adversarially verify the changeset',
  phases: [{ title: 'Implement' }, { title: 'Verify' }],
}

const FINDINGS = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          rule: { type: 'string' },
          detail: { type: 'string' },
        },
        required: ['file', 'detail'],
      },
    },
  },
  required: ['findings'],
}

// One entry = fully sequential. Add a surface ONLY if it touches disjoint files.
const surfaces = [{ name: 'core', brief: 'FILL IN: what to build' }]
const conventionsFile = 'FILL IN: the governing CLAUDE.md, e.g. mined/CLAUDE.md'

phase('Implement')
await parallel(surfaces.map(s => () =>
  agent(
    `Implement the "${s.name}" surface. Follow red/green strictly (tdd.md): for each behavior,
write ONE failing test, RUN it and SEE it fail, write the minimal code, RUN it and SEE it
pass, repeat. Scope: ${s.brief}. Touch only this surface's files. Do NOT commit.`,
    { label: `impl:${s.name}`, phase: 'Implement' }
  )
))

phase('Verify')
const seeChangeset = 'Review the full changeset — run `git diff` and read any new files shown by `git status`.'
const LENSES = [
  { key: 'correctness', prompt: `${seeChangeset} Adversarially find correctness bugs, broken edge cases, wrong logic. Report each as file:line + detail.` },
  { key: 'tdd', prompt: `${seeChangeset} Verify every changed behavior has a covering test that asserts behavior (not internals) and is not tautological. Report each gap as file:line + detail.` },
  { key: 'conventions', prompt: `Read ${conventionsFile}. ${seeChangeset} Check the changeset against EVERY convention that file states — comment policy, naming, structure. Report each violation as file:line + the rule it breaks.` },
]
const panel = await parallel(LENSES.map(l => () =>
  agent(l.prompt, { label: `verify:${l.key}`, phase: 'Verify', schema: FINDINGS })
))

return panel.filter(Boolean).flatMap(r => r.findings)
```
