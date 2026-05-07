---
description: Create or update ROADMAP.md by delegating to the Product Director agent.
input: []
---

# Anvil Roadmap

Produce or update `ROADMAP.md` via the Product Director agent (`@pd`).

- **Procedure:** follow the `anvil-roadmap` skill.
- **Output structure:** the `roadmap-format` skill (from anvil-common-stable)
  is authoritative; do not introduce sections it does not define.
- **Update mode:** if `ROADMAP.md` already exists, pass its current contents
  to `@pd` for incremental update rather than rewriting from scratch.
- **Failure:** if `docs/anvil/config.yml` is missing or `@pd` cannot
  produce a roadmap, report the blocker and stop. Do not write a partial
  `ROADMAP.md`. Do not re-invoke `@pd` after it returns.

At completion, emit as the final assistant message:
`ROADMAP.md` created or updated.
Next step: `/anvil-sprint <phase>` (or `apm run anvil-sprint --param phase=<phase>`).
