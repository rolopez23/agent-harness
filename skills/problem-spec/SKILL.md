---
name: problem-spec
description: >
  First step for solving any complex coding problem. Defines what is and is not being solved,
  identifies all existing interfaces and contracts touched, and produces a structured spec doc.
  Trigger this skill whenever a user asks to build, implement, add, or solve something non-trivial.
  Do NOT trigger for small changes, refactors of a single function, or bug fixes. If there is any
  doubt about whether the problem is complex enough to warrant a spec, trigger it anyway — it is
  much cheaper to over-spec than to under-spec.
---

# Problem Specification Skill

Your job is to define the problem clearly before any solution is considered. You are not designing
the implementation. You are not suggesting technologies. You are figuring out exactly what needs to
be true when this work is done — and exactly what is out of scope.

## Ground Rules

- **Never assume.** If anything is ambiguous, ask. A wrong assumption here costs far more than a
  clarifying question.
- **No solution talk.** If the user starts describing how they want to build it, gently redirect:
  "Let's lock down the what before the how."
- **No partial specs.** Do not write the spec file until you have answers to every open question.
  If the user says "just make something up", push back — a guess here becomes a constraint later.

---

## Step 1: Understand the Problem

Ask the user to describe what they want to achieve. Listen for:

- The goal (what changes in the world when this is done?)
- The actors (who or what initiates this? who or what receives the result?)
- The trigger (what causes this to happen?)
- The success condition (how will we know it worked?)

Do not move on until you can restate the problem back in your own words and the user confirms it.

---

## Step 2: Clarify Until There Is No Ambiguity

Go through every noun and verb in the problem statement and ask yourself: "Is this fully defined?"
If not, ask the user. Common sources of ambiguity:

- Vague quantities ("some", "a few", "many", "fast")
- Undefined entities ("the user", "the system", "the data" — which one?)
- Implicit behaviors ("it should update X" — when? how? what if X doesn't exist?)
- Edge cases ("what happens if there's nothing to process?", "what if it fails halfway?")
- Ownership ("who calls this?", "who owns the output?")

Keep asking until every piece of the problem statement is concrete. Do not batch questions — ask
one or two at a time so the conversation stays focused.

---

## Step 3: Define the Boundary

Once the problem is clear, explicitly define what is and is not included. Work through this with
the user:

**In scope**: What must be true when this work is complete? Keep this tight — only what is
necessary to solve the stated problem.

**Out of scope**: What are we explicitly not solving? This is as important as the in-scope list.
Name the things that are adjacent, tempting, or frequently assumed — and mark them out of scope.
If the user is unsure whether something is in or out, it needs a decision now, not later.

---

## Step 4: Define Interfaces

Identify every connection point between this work and anything that already exists. You are not
designing new interfaces here — you are documenting the contracts this work must respect or
that will be changed by this work.

Ask and document:

- **Schemas**: What data structures does this read from or write to? What are the field names,
  types, and constraints? If a schema is changing, what is the before and what is the after?
- **API contracts**: What existing APIs does this call or expose to? What are the expected inputs
  and outputs? What guarantees exist (auth, rate limits, error shapes)?
- **System boundaries**: What external systems, services, or processes touch this work? What do
  they expect? What do they return?
- **Shared state**: Does this read or write anything that another part of the system also owns?
  Who has authority over it?

If the user says "I'm not sure what the schema looks like" — that is a blocker. Help them find it
before writing the spec.

---

## Step 5: Identify Current Code

Document all code you think you may touch or any prior art that is similar.  Mainly define the interfaces as above and how they interact. 

---

## Step 5: Write the Spec

Once every question is answered, write the spec to `docs/<feature-name>/spec.md`. Choose
`<feature-name>` as a short, lowercase, hyphenated name that describes the feature (confirm with
the user if unsure).

Use this exact structure:

```markdown
# Spec: <Feature Name>

## Problem Statement
One to three sentences. What is broken or missing, and why does it matter?

## What We Are Solving
Bullet list. Each item is a concrete, verifiable outcome.

## What We Are NOT Solving
Bullet list. Each item is something explicitly excluded from this work.

## Actors & Triggers
Who or what initiates this work, and under what conditions.

## Success Criteria
How will we know this is done? What can be checked or observed?

## Interfaces

### Schemas
For each schema touched: name, relevant fields (with types), and any changes being made.

### Contracts
For each external system or API touched: what we call, what we pass, what we get back.

### Shared State
Anything this work reads or writes that is also owned or used by another part of the system.

### Existing Code
Document any reference similar code or code you expect to touch. This is not a design doc, so do not describe how you will change it — just what it is and how it interacts with the interfaces above, and how it relates to the problem being solved.

## Open Questions
Any questions that came up but are deferred. Each entry should note who needs to answer it.
```

Do not add sections that are empty. If there are no shared state concerns, omit that section.
If there are no open questions, omit that section.

After writing the file, tell the user where it was saved and ask them to review it before any
implementation begins.
