# TDD Rules

Referenced by `plan-step.md`. Apply these rules during every implementation cycle.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

If you wrote code before the test: delete it. Start over. Don't keep it as "reference" —
you'll adapt it and that's testing after. Delete means delete.

## Red-Green-Refactor

**RED** — Write one test for one behavior. Run it. It must fail for the right reason
(feature missing, not a typo or import error). If it passes immediately, it's testing
nothing — fix the test.

**GREEN** — Write the minimum code to make it pass. Not the clean version, not the
configurable version. The simplest thing that works.

**REFACTOR** — Clean up with tests green. Remove duplication, improve names, extract
helpers. Do not add behavior here.

**COMMIT** — Tests green, code and tests together in one commit. Never commit red.

## Choosing the Test Level

Before writing the test, decide what level it lives at. Each cycle's test should be at the
*lowest level that exercises the actual behavior you care about*. Write higher-level tests
only when the behavior genuinely crosses a boundary.

| What you're testing | Test level | Why |
|---|---|---|
| Pure logic — a function with inputs and outputs, no I/O | Unit | Fast, deterministic, easy to enumerate edge cases. No setup. |
| A function that touches one external boundary (DB, HTTP client, filesystem, clock) | Integration | The boundary is the point of the test — mocking it tests nothing real. Use a real test DB, a real local server, real fixture files. |
| A behavior that crosses multiple boundaries (HTTP → service → DB → response) | Integration or E2E | Pick the smallest seam that still proves the behavior. Prefer integration over E2E unless the browser/UI is the thing under test. |
| A user-visible flow (form submit → API → DB → render) | E2E (Playwright/curl) | This is what `/verify` covers. The unit-test version of this flow proves nothing about the real system. |

**The rule:** if mocking the boundary would make the test pass without proving the behavior,
the test is at the wrong level. Move it up.

**The corollary:** do not write integration tests for pure logic. A function that takes a
string and returns a string does not need a database. Pushing pure logic into an integration
test makes the suite slow without making it more correct.

## DAMP Over DRY in Tests

Production code follows DRY (Don't Repeat Yourself). Test code follows **DAMP** —
Descriptive And Meaningful Phrases. Each test should read like a tiny spec for one
behavior, with all the relevant setup visible inline. Repetition across tests is fine.
Hidden setup is not.

```typescript
// ✅ DAMP — the reader sees exactly what this test is asserting
test('rejects a contract larger than 5MB', async () => {
  const file = new File(['x'.repeat(6 * 1024 * 1024)], 'big.pdf', { type: 'application/pdf' });
  const result = await validateContract(file);
  expect(result.ok).toBe(false);
  expect(result.error).toBe('file too large');
});

test('rejects a contract with the wrong mime type', async () => {
  const file = new File(['ok'], 'note.txt', { type: 'text/plain' });
  const result = await validateContract(file);
  expect(result.ok).toBe(false);
  expect(result.error).toBe('unsupported file type');
});

// ❌ Over-DRY — the reader has to chase the helper to know what is being tested
function makeFile(opts) { /* defaults hidden here */ }
test('rejects invalid contracts', async () => {
  for (const c of INVALID_CASES) {
    const result = await validateContract(makeFile(c));
    expect(result.ok).toBe(false);
  }
});
```

**When to extract a helper anyway:**
- It builds a fixture that has nothing to do with what's being asserted (e.g. a fully
  populated `User` object when the test only cares about one field) — extract it, name it
  after the *role* (`anAdminUser()`, `aFreshContract()`), and keep the per-test deviations
  visible at the call site.
- Setup is genuinely expensive (DB connections, server startup) — share it via a fixture,
  not a function the test calls.

**When to leave the duplication:**
- Two tests have similar-looking setup but assert different behaviors. The duplication
  documents the intent. Collapsing them hides which inputs matter.
- A test loop iterating over cases where each case needs slightly different assertions —
  write the cases as separate `test()` blocks. The redundancy is the point: each failure
  names the specific case that broke.

The test name + the test body should tell the whole story. If a reader has to scroll up to
a `beforeEach` or chase a helper to understand what failed, the test is too DRY.

## What a Good Test Looks Like

```typescript
// ✅ Tests real behavior, clear name, one thing
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const op = () => { attempts++; if (attempts < 3) throw new Error(); return 'ok'; };
  const result = await retryOperation(op);
  expect(result).toBe('ok');
  expect(attempts).toBe(3);
});

// ❌ Tests the mock, not the code; vague name
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(2);
});
```

One behavior per test. "and" in the test name means split it. Use real code — mocks only
when the dependency is truly external (network, clock, filesystem).

## Commit Rules

- All tests green → commit
- Any test red → do not commit; fix or ask for help
- Never skip, pend, or comment out a failing test to reach green
- Tests and implementation land in the same commit

## Rationalization Red Flags

Stop and return to Red when you catch yourself thinking:

| Thought | Reality |
|---|---|
| "Too simple to need a test" | Simple code breaks. Test takes 30 seconds. |
| "I'll write tests after to verify" | Tests after pass immediately — they prove nothing. |
| "I already manually tested this" | Manual is ad-hoc. No record, can't re-run. |
| "Keep code as reference, write tests first" | You'll adapt it. That's testing after. Delete it. |
| "Deleting X hours of work is wasteful" | Sunk cost. Keeping unverified code is the waste. |
| "Just this once" | No exceptions without explicit user permission. |

## When Stuck

| Problem | Solution |
|---|---|
| Don't know how to test it | Write the API you wish existed. Write the assertion first. |
| Test is too complicated to set up | The design is too coupled. Simplify the interface. |
| Must mock everything | Inject dependencies instead. |
| Test setup is enormous | Extract helpers. Still complex? The design needs work. |

## Verification Checklist

Before marking a cycle complete:

- [ ] Watched the test fail before writing any code
- [ ] Test failed for the expected reason (feature missing, not a typo)
- [ ] Wrote the minimum code to pass — nothing extra
- [ ] All tests green, including pre-existing ones
- [ ] No skipped, pending, or commented-out tests
- [ ] Tests use real code (mocks only where unavoidable)
