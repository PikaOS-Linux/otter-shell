#!/usr/bin/env bash
set -euo pipefail

repo_root=${OTTER_REPO_ROOT:-/home/ferreo/otter-shell}
out_dir=${OTTER_QA_OUT:-"$repo_root/reports/otter-port-qa"}
workspace_name=${OTTER_QA_WORKSPACE:-otter-qa}
monitor=${OTTER_QA_MONITOR:-}

mkdir -p "$out_dir/screens" "$out_dir/logs"

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'missing required tool: %s\n' "$1" >&2
    exit 2
  }
}

require hyprctl
require grim
require jq
require magick

active_workspace() {
  hyprctl activeworkspace -j | jq -r '.name'
}

focused_monitor_geometry() {
  hyprctl monitors -j | jq -r '
    (map(select(.focused == true))[0] // .[0]) |
    "\(.x),\(.y) \(.width)x\(.height)"'
}

park_cursor() {
  hyprctl monitors -j | jq -r '
    (map(select(.focused == true))[0] // .[0]) |
    "\(.x + .width - 2) \(.y + .height - 2)"' |
  while read -r x y; do
    if command -v ydotool >/dev/null 2>&1; then
      ydotool mousemove --absolute --xpos "$x" --ypos "$y" >/dev/null 2>&1 || true
    fi
  done
  sleep 0.05
}

capture_memory() {
  local pid=$1
  local label=$2
  local file=$3
  local rss="" pss="" cmd=""
  if [[ -r "/proc/$pid/smaps_rollup" ]]; then
    rss=$(awk '/^Rss:/{print $2}' "/proc/$pid/smaps_rollup")
    pss=$(awk '/^Pss:/{print $2}' "/proc/$pid/smaps_rollup")
  fi
  if [[ -r "/proc/$pid/cmdline" ]]; then
    cmd=$(tr '\0' ' ' <"/proc/$pid/cmdline")
  fi
  printf '%s,%s,%s,%s,"%s"\n' "$label" "$pid" "$rss" "$pss" "$cmd" >>"$file"
}

wait_client_rect() {
  local pid=$1
  local deadline=$((SECONDS + ${2:-6}))
  local rect=""
  while (( SECONDS < deadline )); do
    rect=$(hyprctl clients -j | jq -r --argjson pid "$pid" '
      map(select(.pid == $pid))[0] // empty |
      "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    if [[ -n "$rect" ]]; then
      printf '%s\n' "$rect"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

client_address() {
  local pid=$1
  hyprctl clients -j | jq -r --argjson pid "$pid" '
    map(select(.pid == $pid))[0].address // empty'
}

arrange_client() {
  local pid=$1
  local x=$2
  local y=$3
  local width=$4
  local height=$5
  local address
  address=$(client_address "$pid")
  [[ -n "$address" ]] || return 1
  hyprctl dispatch focuswindow "address:$address" >/dev/null || true
  hyprctl dispatch setfloating active >/dev/null || true
  hyprctl dispatch resizeactive exact "$width" "$height" >/dev/null || true
  hyprctl dispatch moveactive exact "$x" "$y" >/dev/null || true
  sleep 0.15
}

launch_bg() {
  local log=$1
  shift
  ("$@" >"$log" 2>&1) &
  printf '%s\n' "$!"
}

cleanup_pid() {
  local pid=$1
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
    sleep 0.2
  fi
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill -9 "$pid" >/dev/null 2>&1 || true
  fi
}

qa_window_pair() {
  local app=$1
  local old_bin=$2
  local new_bin=$3
  shift 3
  local args=("$@")
  local old_ws
  old_ws=$(active_workspace)
  local memory="$out_dir/${app}-memory.csv"
  printf 'label,pid,rss_kb,pss_kb,cmd\n' >"$memory"

  hyprctl dispatch workspace "name:$workspace_name" >/dev/null
  sleep 0.2

  local old_pid new_pid old_rect new_rect
  old_pid=$(launch_bg "$out_dir/logs/${app}-old.log" "$old_bin" "${args[@]}")
  wait_client_rect "$old_pid" 8 >/dev/null || true
  arrange_client "$old_pid" 16 64 900 960 || true
  new_pid=$(launch_bg "$out_dir/logs/${app}-new.log" "$new_bin" "${args[@]}")
  wait_client_rect "$new_pid" 8 >/dev/null || true
  arrange_client "$new_pid" 940 64 900 960 || true

  if old_rect=$(wait_client_rect "$old_pid" 2); then
    park_cursor
    grim -g "$old_rect" "$out_dir/screens/${app}-old.png"
    capture_memory "$old_pid" old "$memory"
  else
    printf 'failed to find old %s client pid=%s\n' "$app" "$old_pid" >&2
  fi
  if new_rect=$(wait_client_rect "$new_pid" 2); then
    park_cursor
    grim -g "$new_rect" "$out_dir/screens/${app}-new.png"
    capture_memory "$new_pid" new "$memory"
  else
    printf 'failed to find new %s client pid=%s\n' "$app" "$new_pid" >&2
  fi

  if [[ -s "$out_dir/screens/${app}-old.png" && -s "$out_dir/screens/${app}-new.png" ]]; then
    magick "$out_dir/screens/${app}-old.png" "$out_dir/screens/${app}-new.png" \
      +append "$out_dir/screens/${app}-side-by-side.png"
    compare -metric AE "$out_dir/screens/${app}-old.png" "$out_dir/screens/${app}-new.png" \
      "$out_dir/screens/${app}-diff.png" 2>"$out_dir/${app}-diff.txt" || true
  fi

  cleanup_pid "$old_pid"
  cleanup_pid "$new_pid"
  hyprctl dispatch workspace "$old_ws" >/dev/null || true
}

qa_layer_sequential() {
  local app=$1
  local old_start=$2
  local new_start=$3
  local old_stop=${4:-}
  local new_stop=${5:-}
  local geometry
  geometry=${OTTER_QA_GEOMETRY:-$(focused_monitor_geometry)}
  local memory="$out_dir/${app}-memory.csv"
  printf 'label,pid,rss_kb,pss_kb,cmd\n' >"$memory"

  local old_pid new_pid
  old_pid=$(launch_bg "$out_dir/logs/${app}-old.log" bash -lc "$old_start")
  sleep 1.0
  park_cursor
  grim -g "$geometry" "$out_dir/screens/${app}-old.png"
  capture_memory "$old_pid" old "$memory"
  if [[ -n "$old_stop" ]]; then bash -lc "$old_stop" || true; fi
  cleanup_pid "$old_pid"

  new_pid=$(launch_bg "$out_dir/logs/${app}-new.log" bash -lc "$new_start")
  sleep 1.0
  park_cursor
  grim -g "$geometry" "$out_dir/screens/${app}-new.png"
  capture_memory "$new_pid" new "$memory"
  if [[ -n "$new_stop" ]]; then bash -lc "$new_stop" || true; fi
  cleanup_pid "$new_pid"

  if [[ -s "$out_dir/screens/${app}-old.png" && -s "$out_dir/screens/${app}-new.png" ]]; then
    magick "$out_dir/screens/${app}-old.png" "$out_dir/screens/${app}-new.png" \
      +append "$out_dir/screens/${app}-side-by-side.png"
    compare -metric AE "$out_dir/screens/${app}-old.png" "$out_dir/screens/${app}-new.png" \
      "$out_dir/screens/${app}-diff.png" 2>"$out_dir/${app}-diff.txt" || true
  fi
}

case "${1:-}" in
  window-pair)
    shift
    qa_window_pair "$@"
    ;;
  layer-sequential)
    shift
    qa_layer_sequential "$@"
    ;;
  *)
    printf 'usage:\n'
    printf '  %s window-pair APP /usr/bin/APP /path/to/new [args...]\n' "$0"
    printf '  %s layer-sequential APP OLD_START NEW_START [OLD_STOP] [NEW_STOP]\n' "$0"
    exit 2
    ;;
esac
