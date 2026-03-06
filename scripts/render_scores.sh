#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/assets/scores"
OUT_DIR="$ROOT_DIR/static/generated/scores"

mkdir -p "$OUT_DIR"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

render_abc_file() {
  local src="$1"
  local rel="${src#$SRC_DIR/}"
  local base="${rel%.abc}"
  local out="$OUT_DIR/$base.svg"

  mkdir -p "$(dirname "$out")"

  if have_cmd abc2svg; then
    abc2svg "$src" -O "$out"
    echo "[abc] rendered: $rel -> ${out#$ROOT_DIR/}"
  elif have_cmd abcm2ps; then
    echo "[abc] skipped (abcm2ps found, but script outputs SVG only): $rel"
    echo "      tip: keep using abcscore shortcode; it can render ABC via abcjs fallback."
  else
    echo "[abc] skipped (missing abc2svg): $rel"
    echo "      tip: abcscore shortcode supports abcjs fallback without local abc2svg."
  fi
}

render_lily_file() {
  local src="$1"
  local rel="${src#$SRC_DIR/}"
  local base="${rel%.ly}"
  local out="$OUT_DIR/$base"
  local expected="$OUT_DIR/$base.svg"

  mkdir -p "$(dirname "$out")"

  if have_cmd lilypond; then
    lilypond -dbackend=svg -dno-point-and-click -o "$out" "$src" >/dev/null
    if [[ -f "$expected" ]]; then
      echo "[ly]  rendered: $rel -> ${expected#$ROOT_DIR/}"
    else
      echo "[ly]  warning: no SVG output detected for $rel"
    fi
  else
    echo "[ly]  skipped (missing lilypond): $rel"
  fi
}

if [[ ! -d "$SRC_DIR" ]]; then
  echo "[info] $SRC_DIR not found, nothing to render."
  exit 0
fi

while IFS= read -r -d '' file; do
  render_abc_file "$file"
done < <(find "$SRC_DIR" -type f -name "*.abc" -print0)

while IFS= read -r -d '' file; do
  render_lily_file "$file"
done < <(find "$SRC_DIR" -type f -name "*.ly" -print0)

echo "[ok] score rendering completed."
