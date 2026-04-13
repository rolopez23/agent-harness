# Prior-Art Review

The fourth reviewer. While the other three look at the diff in isolation, this one looks
at *history* — every prior review that touched the files in this diff, or files that are
templates / siblings / close analogues. The goal: surface findings from earlier reviews
that may still apply to this code, and confirm that issues raised on similar files have
been avoided here.

**Why this matters.** A review finding caught on file A often applies to file B if B was
written by copy-pasting A or implementing the same pattern. Without this check, the same
bug class gets caught once on file A, fixed there, and silently shipped on file B because
nobody connected the two reviews. This sub-skill is the connection.

## What to Find

For each file in the diff:

1. **Direct prior reviews on this exact file** — any earlier review that touched the same
   path, regardless of feature
2. **Reviews on similar files** — files identified as templates, siblings, or
   close-purpose analogues to the current file (see "Identifying Similar Files" below)
3. **Pattern-tagged learnings** — entries in `.claude/learnings.md` whose pattern tag
   matches code in this diff (e.g., `unnecessary-type-cast`, `accessibility-not-reviewed`,
   `cors-not-tested`)

For each prior finding found, decide one of:

- **Still applies** — the same issue is present in the current diff. Surface it as a
  finding tagged with the source review.
- **Already addressed** — the current code visibly handles what the prior review flagged.
  Note it briefly so the human knows the connection was checked, not missed.
- **Not applicable** — the prior finding was specific to a different concern that doesn't
  exist here. Note it briefly with a one-line reason.

## Where to Look

In order:

### 1. Saved review reports
```bash
# Same-feature reviews on this file
ls docs/<feature>/reviews/ 2>/dev/null
# All reviews across all features
find docs -path '*/reviews/*.md' -type f 2>/dev/null
```

For each report, search for the file path or basename. Reports are markdown — grep for
the filename and read the surrounding context to capture the finding.

### 2. Saved simplify reports
```bash
find docs -path '*/simplify/*.md' -type f 2>/dev/null
```

Simplify reports often contain the same kind of feedback (magic numbers, dead code,
unclear names) and applying the same lens here is cheap.

### 3. The learnings log
```bash
cat .claude/learnings.md 2>/dev/null
```

Search for entries that mention the file path, the directory, or pattern tags that match
code in the current diff. Each entry has a `Pattern tag:` line — these are the durable
labels. Multiple occurrences of the same tag are a strong signal that this class of issue
recurs and should be checked here too.

### 4. Git history on the file
```bash
git log --all --oneline --follow -- <file>
git log --all -p --follow -- <file> | head -200
```

Look for commit messages mentioning "review", "feedback", "fix from review", or
"address comment". Read those commits — they capture what a prior reviewer caught.

### 5. GitHub PR review comments (if available)
```bash
# Find PRs that touched the file
gh pr list --state merged --search "<file basename>" --json number,title 2>/dev/null

# Get review comments on a PR
gh api "repos/{owner}/{repo}/pulls/<N>/comments" --jq '.[] | {path, line, body}' 2>/dev/null
```

Filter to comments on the file (or similar files). Each comment is a candidate prior
finding.

If `gh` is not available or there is no remote, skip this step — do not block on it.

## Identifying Similar Files

A "similar file" is one where review findings are likely to transfer. Check, in order:

1. **Explicit templates named in the spec or plan.** Look in `docs/<feature>/spec.md` and
   `docs/<feature>/steps/<step>.md` for phrases like "based on X", "modeled after X",
   "follow the pattern in X", "see X for an example". Files named this way are
   high-confidence templates — review findings on them almost always apply here.
2. **Sibling files in the same directory with the same naming pattern.** E.g., for
   `app/api/contracts/[id]/route.ts`, sibling routes in `app/api/*/[id]/route.ts` are
   strong analogues.
3. **Files implementing the same interface or extending the same base.** Grep for
   `extends <BaseClass>`, `implements <Interface>`, or `from '<shared module>'` to find
   files that share contracts.
4. **Files with the same suffix and purpose.** `*Service.ts`, `*Controller.ts`,
   `*.test.ts`, `use*.ts` (React hooks) — files in the same role.
5. **Files mentioned in the current diff's commit messages or PR description.** If the
   author says "copied from X and adapted", X is the template.

For each candidate similar file, repeat the "Where to Look" steps above to harvest its
prior reviews.

**Cap:** look at the top 3–5 most-similar files. Going broader produces noise without
proportional value. If you have to choose, prefer explicit templates (#1) and immediate
siblings (#2) over inheritance-based matches.

## Output Format

```markdown
### Prior-Art Review

#### Files checked
- **Direct prior reviews on:** <file 1>, <file 2>, ...
- **Similar files inspected:** <file A> (template per spec.md), <file B> (sibling in same dir), ...
- **Learnings log entries scanned:** <N> entries, <M> matching the current diff's patterns

#### Findings that still apply
- **<current file>:<line>** — From `docs/<feature>/reviews/<step>-<date>.md` (review on `<other file>`):
  "<the original finding>". This issue is present here at <line> because <one-sentence reason>.
- ...

#### Already addressed
- **From `docs/<feature>/reviews/<step>-<date>.md`** on `<other file>`: "<finding>" — handled
  here at <file>:<line> by <how>.
- ...

#### Not applicable
- **From `<source>`** on `<other file>`: "<finding>" — does not apply because <one-line reason>.
- ...
```

If no prior reviews exist anywhere, output:

```
### Prior-Art Review

No prior reviews found on these files or any close analogues. This may be the first
review of code in this area — flag for the human so they know the prior-art coverage
was checked, not skipped.
```

## What This Sub-Skill Is Not

- It is **not** a redundant correctness check. The standard, edge-case, and adversarial
  reviewers already do that on the current diff. Prior-art only surfaces things that
  *another reviewer caught before* on related code.
- It does **not** make new findings. Every entry in its output must trace back to a
  specific prior source (a review report, a learnings entry, a PR comment, a commit).
  If you can't cite the source, it doesn't belong in this sub-skill's output.
- It is **not** a search through the whole codebase for similar bugs. Stay scoped to
  files that have an explicit template/sibling relationship to the current file.

The discipline is: only raise what was caught before. Trust the other three reviewers
for everything else.
