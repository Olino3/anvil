---
name: prompt-gatherer
description: Read Claude session JSONL history and the flint hook log; dedupe and write a prompt inbox
---

# prompt-gatherer

## Inputs

- Path to `~/.claude/projects/<project>/` (directory of session JSONL files)
- Path to `<vault>/.flint/prompts.log` (hook log — may not exist)
- Output path: `<prompts>/inbox.md`

## Task

1. Read every session JSONL under the projects directory. Extract user-role messages.
2. If the hook log exists, read it (JSONL with `{ts, cwd, prompt}`).
3. Merge both sources. Dedupe on `(prompt, ts-to-the-minute)`.
4. Sort by timestamp descending (newest first).
5. Drop prompts shorter than 10 chars and prompts that start with `/` (slash commands are already tracked elsewhere).

## Output

Write `<prompts>/inbox.md` with canonical frontmatter (`source: flint/gather-prompts`, `tags: [prompts, inbox]`).

Body: a bulleted list, each item:

```markdown
- `<iso-ts>` — <first 200 chars of prompt> `[source: session|hook]`
```

Idempotent: overwrite on every run.
