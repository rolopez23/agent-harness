# Builder prompts

Fill `{{…}}` with absolute paths and values. Subagents start cold: everything they need
is in the prompt.

---

## Frontend builder

```
You are the FRONTEND builder for {{REPO}} (branch {{BRANCH}}). A backend builder is
working in parallel; the orchestrator links them afterwards.

Read first:
1. Skill: {{SKILLS}}/next-react-boot/SKILL.md (read the file; it can't be invoked via the Skill tool). Use its templates/ dir.
2. Contract: {{REPO}}/docs/boot/contract.md (wins over skill defaults).
3. {{REPO}}/AGENTS.md for product context.

Inputs: APP_NAME={{APP_NAME}}, APP_TAGLINE={{APP_TAGLINE}}.

Rules:
- Only create/edit files under frontend/. No repo-root, backend/, docker/, docs/ edits.
- No commits or state-changing git commands.
- Environment: {{ENV_NOTES}}  (e.g. "macOS, no `timeout`; Docker down: you don't need it")

Follow the skill's Steps and Verify exactly. Final report:
1. Files tree. 2. Commands + pass/fail. 3. Resolved versions.
4. FRICTION LOG (most important): every place the skill was wrong, outdated, ambiguous,
   or missing a step: what it says, what happened, the concrete fix to the skill text.
   Plus time sinks.
```

---

## Backend builder

```
You are the BACKEND builder for {{REPO}} (branch {{BRANCH}}). A frontend builder is
working in parallel; the orchestrator links them afterwards.

Read first:
1. Skill: {{SKILLS}}/python-psql-boot/SKILL.md (read the file; it can't be invoked via the Skill tool). Use its templates/ dir.
2. Contract: {{REPO}}/docs/boot/contract.md (wins over skill defaults).
3. {{REPO}}/AGENTS.md for product context.
4. Orchestrator-owned, already present: {{REPO}}/docker-compose.yml, {{REPO}}/docker/initdb/.

Inputs: APP_NAME={{APP_NAME}}. Entities/endpoints: {{ENTITIES or "none: health-only boot"}}.

Rules:
- Only create/edit files under backend/. No repo-root, frontend/, docker/, docs/ edits.
- No commits or state-changing git commands.
- Docker: {{DOCKER_STATE}}. Probe Postgres with `nc -z -G 2 localhost 5432`, never bare docker.
- Environment: {{ENV_NOTES}}

Follow the skill's Steps and Verify exactly. Final report:
1. Files tree. 2. Commands + pass/fail/skip. 3. Resolved versions.
4. Exact run/test/migrate commands (for root scripts).
5. FRICTION LOG (most important): as above.
```

---

## Continuation (after a stopped or failed builder)

```
You are the {{SIDE}} builder for {{REPO}} (branch {{BRANCH}}). A previous builder was
stopped mid-task. CONTINUE from the files in {{SIDE_DIR}}/. Don't start over: inspect,
fix, finish, verify.

Existing files: {{FILE_LIST}}
Where it stopped: {{LAST_KNOWN_STATE}}  (e.g. its last message)
Timebox any single blocker: if the first fix fails, take the simplest working
alternative and log it.

[Then the same Read first / Rules / Final report blocks as the matching builder above.
Ask it to inspect the inherited files for evidence of what the previous builder hit.]
```
