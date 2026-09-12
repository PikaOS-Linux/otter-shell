#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  ui-parity-capture.sh APP BASELINE_CMD CURRENT_CMD [CLASS_OR_TITLE]

Runs BASELINE_CMD and CURRENT_CMD sequentially, captures screenshots via grim,
samples RSS/PSS from smaps_rollup, and writes a side-by-side sheet under:
  reports/ui-parity/<timestamp>/<app>/

Optional environment:
  OTTER_BASELINE_TRIGGER='command run after baseline starts'
  OTTER_CURRENT_TRIGGER='command run after current starts'
  OTTER_CAPTURE_DELAY='seconds before screenshot, default 1.25'

Examples:
  tools/ui-parity-capture.sh settings "/usr/bin/otter-settings" "./zig-out/bin/otter-settings" otter-settings
  tools/ui-parity-capture.sh bar "/usr/bin/otter-bar" "./zig-out/bin/otter-bar" ""
USAGE
}

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  usage
  exit 2
fi

app="$1"
baseline_cmd="$2"
current_cmd="$3"
match="${4:-}"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stamp="${OTTER_PARITY_STAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
out_dir="${root}/reports/ui-parity/${stamp}/${app}"
mkdir -p "${out_dir}"

delay="${OTTER_CAPTURE_DELAY:-1.25}"

sample_mem() {
  local pid="$1"
  local out="$2"
  if [ ! -r "/proc/${pid}/smaps_rollup" ]; then
    printf '{"pid":%s,"rss_kb":null,"pss_kb":null}\n' "$pid" >"$out"
    return
  fi
  awk -v pid="$pid" '
    /^Rss:/ { rss=$2 }
    /^Pss:/ { pss=$2 }
    END {
      if (rss == "") rss = "null";
      if (pss == "") pss = "null";
      printf("{\"pid\":%s,\"rss_kb\":%s,\"pss_kb\":%s}\n", pid, rss, pss);
    }
  ' "/proc/${pid}/smaps_rollup" >"$out"
}

client_geometry() {
  local pid="$1"
  local needle="$2"
  if [ -z "$needle" ]; then
    return 1
  fi
  hyprctl clients -j |
    jq -r --argjson pid "$pid" --arg needle "$needle" '
      .[]
      | select((.pid == $pid) or (.class == $needle) or (.initialClass == $needle) or (.title | contains($needle)))
      | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"
    ' |
    head -n 1
}

capture() {
  local label="$1"
  local command="$2"
  local trigger="$3"
  local png="${out_dir}/${label}.png"
  local meta="${out_dir}/${label}.json"
  local mem="${out_dir}/${label}-memory.json"
  local log="${out_dir}/${label}.log"

  printf 'running %s: %s\n' "$label" "$command" | tee -a "${out_dir}/capture.log"
  setsid bash -lc "$command" >"$log" 2>&1 &
  local pid="$!"
  sleep "$delay"

  if [ -n "$trigger" ]; then
    printf 'trigger %s: %s\n' "$label" "$trigger" | tee -a "${out_dir}/capture.log"
    bash -lc "$trigger" >>"$log" 2>&1 || true
    sleep "$delay"
  fi

  sample_mem "$pid" "$mem"

  local geom=""
  geom="$(client_geometry "$pid" "$match" || true)"
  if [ -n "$geom" ]; then
    grim -g "$geom" "$png"
  else
    grim "$png"
  fi

  sha="$(sha256sum "$png" | awk '{print $1}')"
  jq -n \
    --arg app "$app" \
    --arg label "$label" \
    --arg command "$command" \
    --arg png "$png" \
    --arg geometry "$geom" \
    --arg sha256 "$sha" \
    --argjson memory "$(cat "$mem")" \
    '{app:$app,label:$label,command:$command,png:$png,geometry:$geometry,sha256:$sha256,memory:$memory}' \
    >"$meta"

  kill "$pid" >/dev/null 2>&1 || true
  sleep 0.2
  kill -9 "$pid" >/dev/null 2>&1 || true
}

capture baseline "$baseline_cmd" "${OTTER_BASELINE_TRIGGER:-}"
capture current "$current_cmd" "${OTTER_CURRENT_TRIGGER:-}"

magick "${out_dir}/baseline.png" "${out_dir}/current.png" +append "${out_dir}/side-by-side.png"
if magick compare -metric RMSE "${out_dir}/baseline.png" "${out_dir}/current.png" "${out_dir}/diff.png" >"${out_dir}/diff.txt" 2>&1; then
  :
else
  # compare returns non-zero when images differ; diff artifact is still useful.
  :
fi

jq -s '{
  app: .[0].app,
  baseline: .[0],
  current: .[1],
  rss_delta_kb: (.[1].memory.rss_kb - .[0].memory.rss_kb),
  pss_delta_kb: (.[1].memory.pss_kb - .[0].memory.pss_kb)
}' "${out_dir}/baseline.json" "${out_dir}/current.json" >"${out_dir}/summary.json"

printf '%s\n' "${out_dir}/summary.json"
