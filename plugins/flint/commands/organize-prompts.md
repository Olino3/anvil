---
name: organize-prompts
description: Split the prompt inbox into linked, tagged prompt notes with frequent-use flags
---

# organize-prompts

## Preconditions

`<prompts>/inbox.md` must exist. If missing, tell the user to run `/flint:gather-prompts` first.

## Steps

1. Invoke `vault-paths` to resolve `prompts` folder.
2. Ensure `<prompts>/notes/` exists (create if missing).
3. Dispatch to `prompt-organizer` agent with inbox path, notes dir, and existing vault notes for link proposals.
4. Present any LLM link proposals for user approval before any file is written.
5. Print summary.
