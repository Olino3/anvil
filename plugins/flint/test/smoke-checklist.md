# Flint Smoke-Test Checklist

Run in order against a scratch vault:

1. [ ] `/flint:obsidian-setup` — creates `<vault>/.flint/config.json` + folders
2. [ ] `/flint:personalize` — round-trip config update, backup created
3. [ ] UserPromptSubmit hook — send a prompt, verify `prompts.log` has a new line
4. [ ] `/flint:quick-note hello` — creates a note with valid frontmatter
5. [ ] `/flint:session-note` — writes session note + updates `Prompts/inbox.md`
6. [ ] `/flint:git-analysis` — run against fixture repo, verify report has all 6 H2 sections and no invented numbers
7. [ ] `/flint:memory-analysis` — verify report lists covered + gaps
8. [ ] `/flint:gather-prompts` — verify inbox dedupes hook + session sources
9. [ ] `/flint:organize-prompts` — verify link proposals are presented for review
10. [ ] `/flint:content-mapping Notes` — MOC page written with H2 groups
11. [ ] `/flint:deep-note <report> "Bug Hotspots"` — detailed expansion written
12. [ ] Re-run every command → confirms idempotent overwrite
