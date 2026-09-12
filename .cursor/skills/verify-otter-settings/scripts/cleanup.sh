#!/usr/bin/env bash
set -euo pipefail

# Reclaim abandoned headless temp roots. Never touch artifacts or baselines.
reclaimed=0
for dir in /tmp/otter-headless.*; do
  [[ -d "$dir" ]] || continue
  pids_file="$dir/created-pids"
  live=0
  if [[ -f "$pids_file" ]]; then
    while IFS= read -r pid; do
      [[ -n "$pid" ]] || continue
      if kill -0 "$pid" 2>/dev/null; then
        live=1
        break
      fi
    done <"$pids_file"
  fi
  if [[ "$live" -eq 0 ]]; then
    rm -rf "$dir"
    reclaimed=$((reclaimed + 1))
  else
    printf 'cleanup: skip live root %s\n' "$dir" >&2
  fi
done

printf 'cleanup: reclaimed %s abandoned otter-headless roots; artifacts untouched\n' "$reclaimed"
exit 0
