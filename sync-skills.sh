#!/bin/sh
set -e

src="skills"
dst="skills-flat"

rm -rf "$dst"
mkdir -p "$dst"

for d in "$src"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  if [ -f "$d/SKILL.md" ]; then
    cp "$d/SKILL.md" "$dst/$name.md"
    echo "  $name.md"
  fi
done

echo "Done — $dst/ has $(ls -1 "$dst" | wc -l | tr -d ' ') files"
