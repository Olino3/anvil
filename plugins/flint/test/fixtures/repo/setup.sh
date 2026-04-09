#!/usr/bin/env bash
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
rm -rf "$dir/src" "$dir/.git"
cd "$dir"
git init -q
git -c user.email=flint@test -c user.name=flint commit -q --allow-empty -m "root" >/dev/null 2>&1 || true
mkdir -p src/api src/ui
echo "a" > src/api/auth.py
git add .
git -c user.email=flint@test -c user.name=flint commit -qm "feat: initial auth"
echo "b" >> src/api/auth.py
git -c user.email=flint@test -c user.name=flint commit -qam "fix: auth bug #1"
echo "c" >> src/api/auth.py
git -c user.email=flint@test -c user.name=flint commit -qam "fix: auth hotfix #2"
echo "d" > src/ui/button.tsx
git add .
git -c user.email=flint@test -c user.name=flint commit -qm "feat: button"
echo "e" >> src/ui/button.tsx
git -c user.email=flint@test -c user.name=flint commit -qam "fix: button hover #3"
