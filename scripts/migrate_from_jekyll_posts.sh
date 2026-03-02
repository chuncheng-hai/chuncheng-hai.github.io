#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT_DIR/_posts"
DST_DIR="$ROOT_DIR/hugo-macos-blog/content/posts"

mkdir -p "$DST_DIR"

count=0
while IFS= read -r -d '' file; do
  base="$(basename "$file")"
  target="$base"

  if [[ "$base" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-(.+)$ ]]; then
    target="${BASH_REMATCH[1]}"
  fi

  cp "$file" "$DST_DIR/$target"
  # Hugo is strict for date parsing. Remove inline comments and NBSP in date front matter.
  perl -CSDA -i -pe 'if(/^date:\s*(.+)$/){$v=$1;$v=~s/\x{00A0}/ /g;$v=~s/\s+#.*$//;$v=~s/\s+$//;$_="date: $v\n"}' "$DST_DIR/$target"
  count=$((count + 1))
done < <(find "$SRC_DIR" -type f -name '*.md' -print0 | sort -z)

echo "Migrated $count markdown files to $DST_DIR"
