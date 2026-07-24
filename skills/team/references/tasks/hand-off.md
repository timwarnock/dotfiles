# Procedure: hand-off a topic (park detail for a future session)

A hand-off is context you are deliberately **not** working on right now — a
tangent worth digging into later. You set it aside in its own doc so it leaves
the active session entirely, keeping `notes-*.md` and your working context lean.
It lives in `thoughts/hand-off-<topic>.md` and waits there until someone reloads
it.

This is a manager procedure. Read and write the file with the Read/Write tools.

## Park it (user: "hand-off the `<topic>` details")

1. Gather everything the active session knows about `<topic>` — from
   `notes-*.md` and your working context.
2. Write it to `thoughts/hand-off-<topic>.md` (content below).
3. **Remove it from `notes-*.md` entirely.** Leave no pointer, no stub, no "see
   hand-off" line. The filename topic is the only index — that is the whole
   point: the active notes get shorter, not longer.

## Content — short and loosely structured

Capture only enough that a fresh session can pick the topic up later without
re-deriving it. Do not impose a rigid template; keep it loose. State plainly at
the top that this is parked context set aside on purpose, not active work — so
whoever opens it later knows why it is here. Roughly:

- **Topic** — one line: what this tangent is.
- **What we know** — the findings so far: relevant code as `file:line`, data,
  links, decisions already reached.
- **Open issues** — the unresolved questions, what is left to dig into.

## Discover (orient)

On orient the manager scans `thoughts/hand-off-*.md` and surfaces each one **by
topic** (its filename). Do **not** read them — their existence is the signal;
the content stays parked until the user asks for it.

## Reload (user: "load the `<topic>` hand-off")

Read `thoughts/hand-off-<topic>.md` into the session's working context. This is
non-destructive: the file stays where it is, and its content is **not** merged
back into `notes-*.md`. Reloading just brings the parked detail back into view.

## Lifecycle

A hand-off persists until the user explicitly says to delete it. Never
auto-delete one, and never delete it just because you reloaded it.
