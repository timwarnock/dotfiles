# Procedure: break the plan into tasks

You have a design (`thoughts/plan-<topic>.md`, from
`references/tasks/superplan.md`). Now turn it into an ordered queue of tasks and
delegate them. You do this **with the user**, aligning the breakdown and the
order — never the implementation; how each task is built is the worker's call
with the user later.

Trigger: the user says "break down the plan into tasks."

## What a task is

Each task is a **user-verifiable, full-stack feature, tests included** — one
complete change someone can verify on its own, end to end. The code and its
tests are a single deliverable, never split.

Each such task is also **one branch, one worktree, one PR** — so cutting the work
into tasks is cutting it into PRs. The manager creates the worktree and ships the
PR (see `references/roles/manager.md`).

Do **not** split one feature into a "backend" task and a "frontend" task, or a
change into a "code" task and a "tests" task, handed to different workers. That
rebuilds exactly the integrate-and-test-afterward handoffs this model removes.
When a task spans specialties, one worker still owns the whole of it.

## Build the queue

1. **Cut by feature.** Work spanning db + app + ui becomes one full-stack task
   per feature — never a "database task" or a "frontend task."
2. **Sketch what each task touches.** A rough list of the files/modules each
   task hits. Collisions drive the ordering.
3. **Give each task a `depends-on` list.** The queue is ordered; each task names
   the tasks it waits on. A logical dependency and a file collision (the later
   writer waits) collapse into that one list — there is no separate
   mutual-exclusion concept.
4. **Concurrency falls out of the graph.** Tasks whose `depends-on` is satisfied
   run in parallel; only truly isolated tasks run at once. You don't schedule
   it — the dependencies do.

The queue lives in `notes-*.md` — its home, not a new file. A context-lost
manager resumes the breakdown from there. Per-task *state* lives in the team
protocol — `worker-states.sh` for who is working on what now, `list-tasks.sh` for
finished outcomes; the queue is the *plan*.

## Delegate

Create and delegate each task by the normal flow (see "Delegate" in
`references/roles/manager.md`): author the task file in `/tmp` (and, for
production code, a check), then
`delegate-task.sh <Worker> <task-file> [check-file]`. Route only to available
workers; fit is a tiebreak, never a fence.

## Verify against the plan

As tasks finish, do not just check each one in isolation — compare the work back
to `thoughts/plan-<topic>.md`. Where the build reveals the design was wrong or
incomplete, iterate **both** the plan and the queue with the user, then cut
follow-up tasks. The plan is the standing source of truth for the design; keep
it accurate as the work teaches you things.
