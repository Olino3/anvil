---
description: Initialize Anvil for this project — detect tech stack, configure components, write docs/anvil/config.yml.
input: []
---

# Anvil Init

Initialize Anvil for the current project. Detect the tech stack from
repository contents, confirm auto-detected values with the user, and write
or update `docs/anvil/config.yml`. Follow the procedure in the `anvil-init`
skill.

Use the `anvil-config-schema` skill (from anvil-common-stable) as the
authoritative schema for `docs/anvil/config.yml`. Do not introduce keys or
types that the schema does not define.

If `docs/anvil/config.yml` already exists, confirm whether to overwrite or
update it before writing. If a referenced skill cannot be resolved, report
the missing dependency and stop without producing partial output.

At completion, emit as the final assistant message:
`docs/anvil/config.yml` created or updated.
Next step: `/anvil-roadmap` (or `apm run anvil-roadmap`).
