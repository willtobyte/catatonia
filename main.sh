#!/usr/bin/env bash

set -euo pipefail

JOBS_DEFAULT=1
if command -v nproc >/dev/null 2>&1; then
  CORES="$(nproc --all)"
  if [ "${CORES}" -gt 1 ]; then JOBS_DEFAULT="$((CORES - 1))"; fi
fi

JOBS="${JOBS:-$JOBS_DEFAULT}"
[ "$JOBS" -lt 1 ] && JOBS=1

THREADS="${THREADS:-1}"
NICE="${NICE:-10}"
ION_C="${ION_C:-2}"
ION_P="${ION_P:-7}"

export THREADS NICE ION_C ION_P

find . -type f \( -iname '*.png' -o -iname '*.apng' \) -print0 \
| xargs -0 -r -n1 -P "$JOBS" -I{} bash -c '
  set -euo pipefail
  f="$1"
  cmd=(oxipng -o max --strip all --threads "$THREADS" "$f")

  if command -v ionice >/dev/null 2>&1; then
    ionice -c "$ION_C" -n "$ION_P" "${cmd[@]}" && exit 0
  fi

  nice -n "$NICE" "${cmd[@]}"
' _ {}

find . -type f \( -iname '*.html' -o -iname '*.css' -o -iname '*.js' -o -iname '*.json' -o -iname '*.yaml' -o -iname '*.yml' \) -print0 \
| xargs -0 -r -n1 -P "$JOBS" prettier --write

find . -type f -iname '*.lua' -print0 \
| xargs -0 -r -n1 -P "$JOBS" stylua --config-path /dev/null --indent-type Spaces --indent-width 2
