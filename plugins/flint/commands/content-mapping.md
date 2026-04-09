---
name: content-mapping
description: Build or update a Map of Content for a targeted section of the vault
---

# content-mapping

## Inputs

User invokes `/flint:content-mapping <section>`. `<section>` is a relative path inside the vault (e.g., `Notes/authentication` or `Projects/anvil`).

## Steps

1. Invoke `vault-paths` to resolve `maps` folder + validate the target section exists.
2. Enumerate notes under `<vault>/<section>/**/*.md`, parsing their frontmatter.
3. MOC path: `<maps>/<section-slug>-MOC.md` (slashes in section → hyphens).
4. Dispatch to `content-mapper` agent with section path, existing MOC path, and note list.
5. Present link proposals for review.
6. Write the MOC. Idempotent: overwrite on every run.
7. Print the MOC path.
