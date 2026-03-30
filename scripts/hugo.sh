#!/usr/bin/env sh
set -eu

mode="build"
if [ "$#" -gt 0 ]; then
  mode="$1"
  shift
fi

cache_dir="${HUGO_CACHEDIR:-$PWD/.hugo_cache}"
mkdir -p "$cache_dir"

case "$mode" in
  server|serve|dev)
    HUGO_CACHEDIR="$cache_dir" exec hugo server -D "$@"
    ;;
  build)
    HUGO_CACHEDIR="$cache_dir" exec hugo --minify --gc "$@"
    ;;
  *)
    echo "Usage: ./scripts/hugo.sh [build|server] [extra hugo args...]" >&2
    exit 1
    ;;
esac
