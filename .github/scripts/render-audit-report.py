#!/usr/bin/env python3
"""Aggregate per-cell audit result files into a markdown report.

Each input file contains one line: ``file|model|C|L|T|A``. Renders a
matrix table (rows=files, cols=models) plus a "lowest action scores"
priority list. Prints the report to stdout.
"""
from __future__ import annotations

import glob
import os
import sys


def parse_results(results_dir: str) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    for path in sorted(glob.glob(os.path.join(results_dir, "**", "*.txt"), recursive=True)):
        with open(path, encoding="utf-8") as fh:
            line = fh.read().strip()
        parts = line.split("|")
        if len(parts) != 6:
            continue
        records.append(
            {
                "file": parts[0],
                "model": parts[1],
                "C": parts[2],
                "L": parts[3],
                "T": parts[4],
                "A": parts[5],
            }
        )
    return records


def short(path: str) -> str:
    parts = path.split("/")
    return "/".join(parts[-3:]) if len(parts) >= 3 else path


def avg_action(scores: list[str]) -> float | None:
    nums = [int(s) for s in scores if s.isdigit()]
    return sum(nums) / len(nums) if nums else None


def render(records: list[dict[str, str]]) -> str:
    if not records:
        return "## APM Audit Report\n\nNo audit results found."

    models = sorted({r["model"] for r in records})
    files = sorted({r["file"] for r in records})
    idx = {(r["file"], r["model"]): r for r in records}

    lines = [
        "## APM Audit Report",
        "",
        f"**Files audited:** {len(files)} · **Models:** {len(models)}",
        "",
        "Each cell shows `Clarity / Length / Tone / Action` (each scored 1-10).",
        "",
    ]

    header = "| File | " + " | ".join(f"`{m}`" for m in models) + " |"
    sep = "|---|" + "---|" * len(models)
    lines += [header, sep]

    action_avgs: dict[str, float | None] = {}
    for file in files:
        action_scores: list[str] = []
        cells: list[str] = []
        for model in models:
            r = idx.get((file, model))
            if r is None:
                cells.append("—")
                continue
            cells.append(f"{r['C']} / {r['L']} / {r['T']} / {r['A']}")
            action_scores.append(r["A"])
        action_avgs[file] = avg_action(action_scores)
        lines.append(f"| `{short(file)}` | " + " | ".join(cells) + " |")

    lines += ["", "### Lowest Average Action Scores", ""]
    scored = [(f, a) for f, a in action_avgs.items() if a is not None]
    ranked = sorted(scored, key=lambda x: x[1])
    for file, avg in ranked[:5]:
        lines.append(f"- `{short(file)}` — avg Action: **{avg:.1f}**")

    return "\n".join(lines) + "\n"


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: render-audit-report.py <results-dir>", file=sys.stderr)
        return 2
    records = parse_results(sys.argv[1])
    sys.stdout.write(render(records))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
