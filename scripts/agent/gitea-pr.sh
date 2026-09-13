#!/usr/bin/env bash
# Create or comment on a Gitea pull request via REST API (or tea if installed).
#
# Requires GITEA_TOKEN (API access token with repo write).
# IMPORTANT (2026-09-13): https://git.pika-os.com/api/v1/* returns Cloudflare
# challenge (403) from Cloud Agent VMs even with Authorization. Until Howard
# allowlists /api or provides a non-CF API base (GITEA_API_BASE), this script
# will fail closed and print a compare URL for manual PR open.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage:
  gitea-pr.sh create --repo <pkg> --head <branch> [--base <main|master>] [--title T] [--body B]
  gitea-pr.sh comment --repo <pkg> --index N --body B
  gitea-pr.sh review --repo <pkg> --index N --body B [--event COMMENT|APPROVE|REQUEST_CHANGES]
  gitea-pr.sh compare-url --repo <pkg> --head <branch> [--base <main|master>]
EOF
  exit 2
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORG="${GITEA_ORG:-otter-shell}"
API_BASE="${GITEA_API_BASE:-https://git.pika-os.com/api/v1}"
UI_BASE="${GITEA_UI_BASE:-https://git.pika-os.com}"

CMD="${1:-}"
[[ -n "$CMD" ]] || usage
shift || true

REPO=""
HEAD=""
BASE=""
TITLE=""
BODY=""
INDEX=""
EVENT="COMMENT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --head) HEAD="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --body) BODY="$2"; shift 2 ;;
    --index) INDEX="$2"; shift 2 ;;
    --event) EVENT="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$REPO" ]] || usage

if [[ -z "$BASE" ]]; then
  BASE="$("$SCRIPT_DIR/default-branch.sh" "$REPO" 2>/dev/null || "$SCRIPT_DIR/default-branch.sh" "$ROOT/$REPO")"
fi

compare_url() {
  local head="${1:-$HEAD}"
  echo "${UI_BASE}/${ORG}/${REPO}/compare/${BASE}...${head}"
}

api() {
  local method="$1" path="$2" data="${3:-}"
  if [[ -z "${GITEA_TOKEN:-}" ]]; then
    echo "error: GITEA_TOKEN is not set" >&2
    return 1
  fi
  local args=(-sS -X "$method" -H "Authorization: token ${GITEA_TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" --max-time 30)
  if [[ -n "$data" ]]; then
    args+=(-d "$data")
  fi
  local tmp code
  tmp="$(mktemp)"
  code="$(curl "${args[@]}" -o "$tmp" -w "%{http_code}" "${API_BASE}${path}" || true)"
  if [[ "$code" == "403" ]] && grep -qi 'just a moment\|cloudflare\|cf-ray' "$tmp" 2>/dev/null; then
    echo "error: Cloudflare blocked Gitea API (${API_BASE}). Set GITEA_API_BASE to a bypass host or allowlist agent egress." >&2
    echo "fallback compare URL: $(compare_url)" >&2
    rm -f "$tmp"
    return 1
  fi
  if [[ "$code" != 2* ]]; then
    echo "error: API HTTP $code" >&2
    head -c 400 "$tmp" >&2 || true
    echo >&2
    rm -f "$tmp"
    return 1
  fi
  cat "$tmp"
  rm -f "$tmp"
}

case "$CMD" in
  compare-url)
    [[ -n "$HEAD" ]] || usage
    compare_url
    ;;
  create)
    [[ -n "$HEAD" ]] || usage
    TITLE="${TITLE:-$HEAD}"
    BODY="${BODY:-}"
    if command -v tea >/dev/null 2>&1 && [[ -n "${GITEA_TOKEN:-}" ]]; then
      tea pulls create --repo "${ORG}/${REPO}" --head "$HEAD" --base "$BASE" --title "$TITLE" --description "$BODY" || {
        echo "tea failed; trying REST…" >&2
        api POST "/repos/${ORG}/${REPO}/pulls" "$(jq -nc --arg t "$TITLE" --arg b "$BODY" --arg h "$HEAD" --arg base "$BASE" '{title:$t,body:$b,head:$h,base:$base}')"
      }
    else
      if ! command -v jq >/dev/null 2>&1; then
        echo "error: jq required for REST create" >&2
        echo "fallback: $(compare_url)" >&2
        exit 1
      fi
      api POST "/repos/${ORG}/${REPO}/pulls" "$(jq -nc --arg t "$TITLE" --arg b "$BODY" --arg h "$HEAD" --arg base "$BASE" '{title:$t,body:$b,head:$h,base:$base}')"
    fi
    ;;
  comment)
    [[ -n "$INDEX" && -n "$BODY" ]] || usage
    if ! command -v jq >/dev/null 2>&1; then
      echo "error: jq required" >&2
      exit 1
    fi
    api POST "/repos/${ORG}/${REPO}/issues/${INDEX}/comments" "$(jq -nc --arg b "$BODY" '{body:$b}')"
    ;;
  review)
    [[ -n "$INDEX" && -n "$BODY" ]] || usage
    if ! command -v jq >/dev/null 2>&1; then
      echo "error: jq required" >&2
      exit 1
    fi
    # Map friendly names to Gitea review events
    case "$EVENT" in
      APPROVE|APPROVED) EVENT=APPROVED ;;
      REQUEST_CHANGES|REQUEST_CHANGE) EVENT=REQUEST_CHANGES ;;
      COMMENT|*) EVENT=COMMENT ;;
    esac
    api POST "/repos/${ORG}/${REPO}/pulls/${INDEX}/reviews" \
      "$(jq -nc --arg b "$BODY" --arg e "$EVENT" '{body:$b,event:$e}')"
    ;;
  *)
    usage
    ;;
esac
