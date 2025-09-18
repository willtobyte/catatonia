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

find . -type f \( -iname '*.wav' -o -iname '*.flac' \) -print0 \
| xargs -0 -r -P "${JOBS:-1}" -I{} bash -Eeuo pipefail -c '
  f=$1
  [ -f "$f" ] || exit 0

  out="${f%.*}.ogg"
  tmp="${out}.tmp"

  # limpa temporário em qualquer erro/interrupção
  cleanup() { rm -f -- "$tmp"; }
  trap cleanup EXIT

  ffmpeg -hide_banner -loglevel error -y \
    -i "$f" \
    -map 0:a:0 -vn -map_metadata -1 -map_chapters -1 \
    -c:a libvorbis -q:a 2 -ar 44100 \
    -f ogg \
    "$tmp" \
  || exit 1

  mv -f -- "$tmp" "$out"
  trap - EXIT
  touch -r "$f" "$out" 2>/dev/null || true
  rm -f -- "$f"
' _ {}

find . -type f \( -iname '*.png' -o -iname '*.apng' \) -print0 \
| xargs -0 -r -n1 -P "${JOBS:-1}" -I{} bash -Eeuo pipefail -c '
  f=$1
  [ -f "$f" ] || exit 0

  dir=$(dirname -- "$f")
  tmp="$dir/.oxipng.$$.$RANDOM.tmp"

  mtime=$(date -r "$f" +%s 2>/dev/null || printf 0)

  cmd=(oxipng -o max --strip all --threads "${THREADS:-0}" --out "$tmp" "$f")

  if command -v ionice >/dev/null 2>&1; then
    ionice -c "${ION_C:-2}" -n "${ION_P:-7}" "${cmd[@]}" \
    || { rm -f -- "$tmp"; exit 1; }
    mv -f -- "$tmp" "$f"
    [ "$mtime" -gt 0 ] && touch -d "@$mtime" -- "$f" 2>/dev/null || true
    exit 0
  fi

  nice -n "${NICE:-10}" "${cmd[@]}" \
  || { rm -f -- "$tmp"; exit 1; }

  mv -f -- "$tmp" "$f"
  [ "$mtime" -gt 0 ] && touch -d "@$mtime" -- "$f" 2>/dev/null || true
' _ {}

find . -type f \( -iname '*.html' -o -iname '*.css' -o -iname '*.js' -o -iname '*.json' -o -iname '*.yaml' -o -iname '*.yml' \) -print0 \
| xargs -0 -r -n1 -P "$JOBS" prettier --write

find . -type f -iname '*.lua' -print0 \
| xargs -0 -r -n1 -P "$JOBS" stylua --config-path /dev/null --indent-type Spaces --indent-width 2
