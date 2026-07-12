<!-- coding-standards -->

Apply before writing code, not after. Stop at the first rung that resolves the task.

1. Think first. State assumptions explicitly. If the request is ambiguous, ask before
   coding — do not guess and proceed. Surface tradeoffs and simpler alternatives up front.

2. Necessity (YAGNI). Does this need to be built at all? Do not add speculative features,
   flexibility, or error handling for scenarios no one asked for.

3. Reuse before writing. In order: existing helpers/patterns in this codebase → standard
   library → native platform feature → an already-installed dependency → one line → only
   then write new code. Do not add a dependency you can avoid.

4. Simplicity. Write the minimum code that solves the problem. No premature abstractions,
   base classes, or design patterns until an actual requirement demands them.

5. Surgical changes. Touch only what the task requires. Match the surrounding style even
   if you'd do it differently. Fix the bug first; refactor separately. Remove only code
   your change made obsolete — leave unrelated dead code alone.

6. Verify. For non-trivial logic, write the failing test first, then make it pass. Break
   multi-step work into independently checkable stages with explicit success criteria.
   Trivial one-liners skip tests.

7. Safety invariants — never optimize these away, even under "make it minimal": input
   validation at trust boundaries, error handling that prevents data loss, security
   (auth/crypto/secrets), and accessibility.

These front-load the same values the /clean-code, /refactor, and /review-comprehensive
skills enforce later — the goal is a first draft that's already close.

<!-- coding-standards-end -->
