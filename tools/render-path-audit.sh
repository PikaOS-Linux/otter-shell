#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

manual_pattern='fillRoundedRectLogical|roundedSolidRect|roundedBlendRect|roundedRectOutline|drawTextScaled|drawScaled\(|drawCover|DefaultCommandList|CommandList|cmds\.|font\.drawText'
old_path_pattern='compatibility widget path|legacy in-bar path|old render|old renderer|while apps migrate|manual command list'
ported_surface_pattern='@memset\(surface\.pixels|drawPopup\(surface|drawStandalone\(surface|menu\.drawStandalone\(surface|m\.drawPopup\(surface|v\.drawPopup\(surface'

printf '['
first_app=1
for build in */build.zig; do
  app="${build%/build.zig}"
  case "$app" in
    otter-render|otter-wayland|otter-ui|otter-vte|otter-geo|otter-utils|otter-conf|otter-theme|otter-desktop|otter-config-types|zig-regex|zango|otter-bar-baseline)
      continue
      ;;
  esac
  [ -d "$app/src" ] || continue
  matches="$(rg -n "$manual_pattern" "$app/src" -g '*.zig' -g '!**/tests.zig' || true)"
  count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l)"
  files="$(printf '%s\n' "$matches" | sed '/^$/d' | cut -d: -f1 | sort -u | jq -R . | jq -s .)"
  old_matches="$(rg -n "$old_path_pattern" "$app/src" "$app/README.md" -g '*.zig' -g '!**/tests.zig' 2>/dev/null || true)"
  old_count="$(printf '%s\n' "$old_matches" | sed '/^$/d' | wc -l)"
  old_files="$(printf '%s\n' "$old_matches" | sed '/^$/d' | cut -d: -f1 | sort -u | jq -R . | jq -s .)"
  ported_surface_matches=""
  case "$app" in
    otter-bar|otter-launcher|otter-settings)
      ported_surface_matches="$(rg -n "$ported_surface_pattern" "$app/src" -g '*.zig' -g '!**/tests.zig' || true)"
      ;;
  esac
  ported_surface_count="$(printf '%s\n' "$ported_surface_matches" | sed '/^$/d' | wc -l)"
  ported_surface_files="$(printf '%s\n' "$ported_surface_matches" | sed '/^$/d' | cut -d: -f1 | sort -u | jq -R . | jq -s .)"
  if [ "$first_app" -eq 0 ]; then printf ','; fi
  first_app=0
  jq -n \
    --arg app "$app" \
    --argjson count "$count" \
    --argjson files "$files" \
    --argjson old_count "$old_count" \
    --argjson old_files "$old_files" \
    --argjson ported_surface_count "$ported_surface_count" \
    --argjson ported_surface_files "$ported_surface_files" \
    '{app:$app, manual_render_match_count:$count, files:$files, old_render_path_match_count:$old_count, old_render_path_files:$old_files, ported_surface_match_count:$ported_surface_count, ported_surface_files:$ported_surface_files}'
done
printf ']\n'
