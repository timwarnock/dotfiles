# Procedure: test-driven change (red/green, stay-green)

Use this when you are changing production-code behavior, fixing a bug, or
refactoring production code. Pick the matching mode below. Anything else — docs,
config, analysis, review, mechanical renames, non-production code — does not
belong here.

## Red/green — new/changed behavior, bug fix

1. Write ONE test for the next behavior the task calls for. Only the test.
2. RUN it. You must SEE it fail — and read the error to confirm it fails because
   the behavior is missing, not because of a typo or an import error.
   ⛔ Do not write any implementation until you have seen this failure.
3. Write the minimal code to make that one test pass. Touch nothing else.
4. RUN it. You must SEE it pass.
5. Refactor if needed; re-run; stay green.
6. Repeat for the next behavior.

Bug fix: the failing test in step 1 reproduces the bug. Can't reproduce it → you
don't understand it → ask. Unsure what correct behavior is → ask before writing
the assertion (one question at a time); a test against a misunderstood
requirement encodes the wrong truth.

Never:
- write the test and the code together — you never saw red, so the test is unproven.
- accept a test that passes the first time you run it — it asserts nothing; fix it.
- skip the run — "it should pass" is not evidence. Run it and read the output.

## Stay-green — pure refactor (behavior unchanged)

1. Before touching code, RUN the tests covering what you'll change. They must pass.
   None exist → write characterization tests for the current behavior, run them
   green, FIRST.
   ⛔ Do not change code until that green baseline exists.
2. Refactor in small steps. RUN the tests after each step. They must stay green.
3. A test goes red → your refactor changed behavior. Revert or fix until green.

- A behavior change is no longer a refactor — it's red/green. Switch modes.
- Surface untested behavior you're about to touch; don't proceed silently over it.
- Existing behavior looks wrong → ask. Don't silently "fix" it mid-refactor.

## Both modes

- Test features, behaviors, and public interfaces — never implementation details.
  A test bound to internals breaks on every refactor and proves nothing about
  what the code does.
- Tests are part of the deliverable: your task is done when the code and its
  passing tests ship together.
