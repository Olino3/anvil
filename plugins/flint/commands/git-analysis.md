---
name: git-analysis
description: Generate a git history report (areas, most-edited files, velocity, bug hotspots) for the current repo
---

# git-analysis

## Preconditions

- Cwd is a git repo (`git rev-parse --is-inside-work-tree`); if not, error and stop
- `vault-paths` resolves `reports` folder

## Step 1: Gather deterministic stats

Run these git commands and parse their output into a JSON payload matching the `git-analyzer` input contract:

```bash
git log --numstat --pretty=format:'%H%x09%s'                 # for most_edited + fix_commits
git log --pretty=format:'%H%x09%ad%x09%s' --date=iso          # for velocity by ISO week
git ls-files | awk -F/ '{print $1}' | sort -u                # top-level dirs → areas
git log --pretty=format:'%s' --grep='fix\|bug\|hotfix' -i     # fix commits
```

Extract:
- `most_edited`: top 20 paths by total change count
- `velocity`: aggregate commits + loc by ISO week
- `areas`: top-level dirs + commit count + file count
- `fix_commits`: subject, files touched, issue refs (regex `#\d+`)
- `hotspots`: files that appear in ≥2 fix commits, sorted by `fix_count` desc

Always full rescan. No cursors.

## Step 2: Dispatch to git-analyzer

Pass the JSON payload and the output path `<reports>/git-analysis-<project>.md` to the `git-analyzer` subagent. It writes the narrative report.

## Step 3: Print the report path

Idempotent: re-running overwrites the previous report.
