# Procedure: superplan a topic (deep design through questioning)

Superplanning turns a fuzzy body of work into a durable design document before
any task is cut. You do it by interviewing the user relentlessly — one question
at a time — until you and the user share a full understanding of the design. The
output is `thoughts/plan-<topic>.md`: the design, never the tasks.

Trigger: the user says "superplan `<topic>`."

**Manager-only.** Workers never superplan; they only run `.task`/`.done`. This
is also **not** `EnterPlanMode` (you never enter plan mode) — it is a procedure
that ends in a written file.

## The questioning engine

Walk the design tree branch by branch, resolving each dependency before the
things that rest on it. For every question:

1. **One question at a time.** Ask it, give your own **recommended answer**, and
   wait. Each answer can reshape every question that follows, so never batch
   them into a list.
2. **Explore before you ask.** If a question can be answered by reading the
   code, read it — spawn a read-only `Explore`/Agent lookup instead of spending
   the user's attention on what the codebase can already tell you.
3. **Challenge fuzzy terms.** When a word is vague or overloaded, stop and pin
   it down: propose a single canonical term and confirm it. Imprecise language
   now becomes an imprecise design later.
4. **Surface code-reality gaps.** When the user states how something works,
   check that the code agrees. If it contradicts, surface it. For example:
   > "You just said `watch_only` in the config takes priority, but the code has
   > a `watch_only` override from `/v3/curtailment` that takes priority over the
   > config — which is right?"
5. **Be heavy on edge cases.** Invent concrete scenarios specific to *this*
   design and force the user to be precise about each boundary. There is no
   checklist — a fixed taxonomy would only bias you toward the same few cases.
   Probe whatever this design can actually get wrong.

Stop when the user confirms you share a full understanding — not before.

## Keep the plan focused

When a branch turns into deep detail that is tangential to the design at hand,
park it with a hand-off (`references/tasks/hand-off.md`) rather than letting it
bloat the plan. The plan holds the design; the hand-off holds the parked
tangent.

## Output: `thoughts/plan-<topic>.md`

A durable design document — no task breakdown (that is
`references/tasks/task-breakdown.md`, run later). Structure:

- **Goal** — what this is for, in plain terms.
- **Glossary** — the canonical terms pinned down during the interview.
- **Decisions** — each as: the decision · its rationale · the alternatives
  rejected.
- **Edge cases** — each scenario you probed, with its agreed handling.
- **Open / risks** — what is unresolved or risky, carried forward honestly.

The plan persists and is edited when the design shifts. It is the input to task
breakdown, never a substitute for it.
