#!/usr/bin/env bash
set -euo pipefail

# Convert Markdown in docs/ to HTML in _site/ using pandoc.
# SRC and OUT can be overridden via environment variables when needed.

SRC="${SRC:-docs}"
OUT="${OUT:-_site}"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc is required but not installed." >&2
  echo "Install pandoc and rerun this script." >&2
  exit 1
fi

mkdir -p "$OUT"

while IFS= read -r file; do
  rel="${file#$SRC/}"
  dest="${OUT}/${rel%.md}.html"
  mkdir -p "$(dirname "$dest")"

  title="$(grep -m1 '^# ' "$file" | sed 's/^# //')"
  [ -n "$title" ] || title="${rel%.md}"

  pandoc "$file" \
    -s \
    --toc \
    --metadata title="$title" \
    -o "$dest"
done < <(find "$SRC" -name '*.md' -print | sort)

# Rewrite links from .md to .html in generated files so navigation stays intact.
if find "$OUT" -name '*.html' -print -quit | grep -q .; then
  find "$OUT" -name '*.html' -print0 | while IFS= read -r -d '' html; do
    # Inline replacement; works on GNU and BSD sed using a transient backup.
    sed -i.bak 's/href="\([^"]*\)\.md\([^"]*\)"/href="\1.html\2"/g' "$html"
    rm -f "${html}.bak"
  done
fi
