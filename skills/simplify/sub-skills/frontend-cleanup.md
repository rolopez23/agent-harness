# Frontend Cleanup

Sub-skill of `/simplify`. Run this **automatically** when the diff touches React components
(`.tsx` files that export JSX). These checks supplement the main simplify pass — they are
specific to React/frontend code and catch patterns that generic code review misses.

## What to Check

### 1. Component Extraction

A component doing too much is the frontend equivalent of a function doing too much.

- **Route between variants**: If a component has an early return for an empty/error state and
  a main render path, extract each into its own named component. The parent becomes a stateless
  router (e.g., `ClauseSection` → `NoClauses` | `ExpandableClauses`).
- **Move state down**: If a parent holds state only one child uses, extract that child as a
  component that owns its own state. The parent should not hold state it doesn't read.
- **Presentational vs stateful**: Presentational components (no hooks, pure props → JSX) should
  be clearly separated from stateful ones. If a component has both, consider splitting.

### 2. Semantic HTML

React defaults to `<div>` and `<span>` for everything. Push toward semantic elements:

| Instead of | Use | When |
|---|---|---|
| `<div>` wrapping a list of items | `<ul>` / `<ol>` + `<li>` | Rendering an array of similar items |
| `<div>` for a titled section | `<section>` with heading | Grouping related content with a label |
| `<div>` for standalone content | `<article>` | Content that makes sense on its own (e.g., a full evaluation result) |
| `<div>` + `<span>` for a title | `<h2>`–`<h6>` | Hierarchical headings within a page |
| `<div>` for a card | `<div>` is fine | When the content needs its parent section for context |

**Key judgment call**: `<article>` means standalone — content that could be syndicated or
understood without its parent. A clause card inside a section is not an article. An entire
evaluation result is.

### 3. Accessibility Attributes

Check for missing ARIA that a screen reader would need:

- **`aria-label`** on `<section>` elements — e.g., `aria-label="Unfair clauses"`
- **`aria-expanded`** on toggle buttons that show/hide content
- **`role="status"`** on loading indicators
- **`aria-busy`** on containers that are loading
- **`sr-only`** text for visual-only indicators (icons, color-coded badges)

### 4. Readable Class Names

Long Tailwind class strings inline in JSX hurt readability. Extract to named constants when:

- The class string is **longer than ~60 characters**
- The same class string appears in **2+ places** (also a DRY issue)
- The class string represents a **reusable concept** (e.g., section border, card layout)

Name the constant after what it represents, not what it looks like:

```typescript
// Good
const SECTION_HEADER = 'flex w-full items-center justify-between rounded-lg border ...';
const BADGE_STYLING = 'inline-block rounded-full border px-3 py-1 text-sm font-semibold';

// Bad
const FLEX_ROUNDED_BORDER = '...';
```

Short utility classes (`mt-4`, `text-sm`, `font-bold`) are fine inline — don't over-extract.

### 5. Data Transformations

Prefer declarative over imperative when transforming data for rendering:

| Pattern | Use | Instead of |
|---|---|---|
| Array → grouped object | `reduce` | `for` loop with manual accumulator |
| Array → filtered subset | `filter` | `for` loop with `if` + `push` |
| Array → mapped output | `map` | `for` loop with `push` |

The `reduce` / `filter` / `map` versions read as transformations (what), not procedures (how).
Performance is equivalent for UI-scale data.

### 6. Color and Style Constants

When colors or styles map to domain concepts (severity, status, state), use semantically
named constants:

```typescript
// Good — names describe meaning
const COLORS = {
  fail: 'text-red-600 bg-red-50 border-red-200',
  warning: 'text-yellow-600 bg-yellow-50 border-yellow-200',
  pass: 'text-green-600 bg-green-50 border-green-200',
} as const;

// Bad — names describe appearance
const RED_CLASSES = 'text-red-600 bg-red-50 border-red-200';
```

### 7. Test Assertions on Styles

Tests should assert against semantic names, roles, or behavior — not raw CSS class names:

- Assert `COLORS.fail` not `'text-red-600'`
- Assert `getByRole('list')` not `closest('[class*="max-h-"]')`
- Assert `aria-expanded` state not presence of a CSS class

### 8. The "AI Aesthetic" — Default Tells

LLM-generated UIs have recognizable defaults. They look generic, dated, and "AI-shaped"
even when they technically work. Flag and replace these defaults with choices that match
the project's actual design system (or, if there isn't one, with anything more specific
than the defaults below).

| AI default | Why it reads as AI | Replace with |
|---|---|---|
| Purple / indigo for everything (`bg-indigo-600`, `text-purple-500`) | Tailwind's "look how nice the defaults are" palette; nobody's brand is actually indigo | The project's actual brand color, or a neutral primary like slate / zinc |
| Gradient buttons (`from-purple-500 to-pink-500`) | Bootstrap-era "make it pop" energy | Solid color buttons; reserve gradients for hero sections only |
| Generic emoji icons in headings (✨ 🚀 🎉) | Filler that adds no information | Lucide / Heroicons SVGs, or no icon at all |
| `rounded-2xl` / `rounded-3xl` on every card | The "soft modern" default; everything looks like a kids' app | `rounded-md` or `rounded-lg`; reserve large radii for hero cards |
| Drop shadows on every container (`shadow-lg`, `shadow-xl`) | Material Design 2014 leaking through | Borders or subtle `shadow-sm`; flat by default |
| `text-gray-500` body copy on white | Low contrast, fails WCAG AA at small sizes | `text-gray-700` or darker for body text |
| "Glassmorphism" — `backdrop-blur` + translucent white | Cliché since 2021 | Solid backgrounds; use blur only when content is genuinely behind something |
| Centered single-column layout with huge vertical padding | Default Tailwind landing-page template | Layout that matches the actual content density of the app |
| `max-w-7xl mx-auto` everywhere with no thought to content | Cargo-culted from starter templates | Width chosen for the content (prose ~65ch, dashboards full-width, forms ~md) |
| Lorem-ipsum-shaped real copy ("Welcome to our amazing platform") | Marketing template energy in a working app | Concrete, specific copy that names what the user is actually looking at |

The fix isn't always to apply a project-specific design — it's to *notice* the default and
flag it. If the project has a design system, point to it. If it doesn't, suggest a neutral
alternative and ask the user.

### 9. Responsive Breakpoint Coverage

Every UI change should be checked at the four standard breakpoints. If the diff touches
layout (flex, grid, width, padding, position, max-w), verify each:

| Width | Represents | What to check |
|---|---|---|
| **320px** | Smallest phones (iPhone SE) | No horizontal scroll; tap targets ≥ 44px; text doesn't overflow containers |
| **768px** | Tablet portrait, larger phones landscape | Layout transitions cleanly from mobile to multi-column; nothing awkwardly half-stacked |
| **1024px** | Tablet landscape, small laptops | Sidebars/columns appear if the design has them; line lengths stay readable (≤ ~80ch for prose) |
| **1440px** | Standard desktop | Content doesn't stretch into unreadably long lines; max-widths kick in; whitespace is intentional, not infinite |

The check is: open the page at each width, scroll top to bottom, look for overflow, broken
alignment, illegible line lengths, and tap targets that are too small for touch. If the diff
only touches a leaf component (a button, an icon, a single label), 320 + 1440 is enough.
If it touches layout, all four.

This is a `/verify` activity for the live system, not a code-only check — flag the missing
coverage here so it gets into the verification step.

## Output

For each finding, state:
- Which category (1–9) it falls under
- The specific file and component
- The fix (apply directly if clear, suggest if uncertain)

If no React-specific issues are found, output: "Frontend cleanup: nothing to flag."
