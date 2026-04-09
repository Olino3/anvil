---
name: gather-prompts
description: Read recent prompts from Claude session history and the flint hook log; write a prompt inbox note
---

# gather-prompts

## Steps

1. Invoke `vault-paths` to resolve `prompts` folder.
2. Resolve the Claude projects directory for the current repo (`~/.claude/projects/<encoded-path>/`).
3. Dispatch to `prompt-gatherer` with:
   - projects dir path
   - `<vault>/.flint/prompts.log` (even if missing — the agent handles absence)
   - output: `<prompts>/inbox.md`
4. Print the output path and total prompt count.
