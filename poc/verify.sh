#!/usr/bin/env bash
#
# verify.sh — POC go/no-go checks for a Product Bus PDP.
# Run once the site is live (Code Sync/BYOG) AND products are ingested (push.sh).
# It fetches the PDP with NO JavaScript (plain curl = what a crawler sees) and
# checks the pre-render/SEO signals, then checks the SKU->path query index.
#
# Usage:
#   ./verify.sh <BASE_URL> <PDP_PATH> [SKU] [CONTENT_NEEDLE]
# Example:
#   ./verify.sh https://main--ap-eds-poc--<owner>.aem.page \
#     /com/de/watch-collection/royal-oak/26545XT.OO.1240XT.01 \
#     26545XT.OO.1240XT.01 "royal oak"
#
set -uo pipefail

BASE="${1:?BASE_URL, e.g. https://main--ap-eds-poc--<owner>.aem.page}"
PDP_PATH="${2:?PDP_PATH, e.g. /com/de/watch-collection/royal-oak/26545XT.OO.1240XT.01}"
SKU="${3:-}"
NEEDLE="${4:-royal oak}"
BASE="${BASE%/}"
URL="${BASE}${PDP_PATH}"

pass=0; fail=0
check() { # $1 = label, $2 = command
  if eval "$2" >/dev/null 2>&1; then printf '  \033[32m✅\033[0m %s\n' "$1"; pass=$((pass+1));
  else printf '  \033[31m❌\033[0m %s\n' "$1"; fail=$((fail+1)); fi
}

echo "Fetching (no JS): $URL"
HTML="$(curl -fsSL "$URL")" || { echo "❌ could not fetch $URL"; exit 1; }

echo "── Pre-render / SEO (server-rendered, JS off) ──"
check "product content present in raw HTML"        "printf '%s' \"\$HTML\" | grep -qi '$NEEDLE'"
check "JSON-LD (application/ld+json) present"        "printf '%s' \"\$HTML\" | grep -q 'application/ld\\+json'"
check "meta description present"                     "printf '%s' \"\$HTML\" | grep -qi 'name=\"description\"'"
check "OpenGraph title present"                      "printf '%s' \"\$HTML\" | grep -qi 'og:title'"
check "<title> present"                              "printf '%s' \"\$HTML\" | grep -qi '<title>'"
[ -n "$SKU" ] && check "SKU visible in HTML"         "printf '%s' \"\$HTML\" | grep -q '$SKU'"

echo "── Routing / SKU→path index ──"
check "query-index.json reachable"                   "curl -fsS '${BASE}/query-index.json' -o /dev/null"
[ -n "$SKU" ] && check "SKU present in query-index"  "curl -fsS '${BASE}/query-index.json' | grep -q '$SKU'"

echo "── URL parity ──"
check "PDP served at the exact vanity path (200)"    "curl -fsS -o /dev/null -w '%{http_code}' '$URL' | grep -q '^200'"

echo
echo "Result: ${pass} passed, ${fail} failed"
if [ "$fail" -eq 0 ]; then echo "GO ✅  — Product Bus pre-render verified for this PDP."; exit 0;
else echo "Investigate ❌ — see failed checks above."; exit 1; fi
