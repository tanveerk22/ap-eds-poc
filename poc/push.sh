#!/usr/bin/env bash
#
# push.sh — send product data to Product Bus.
# Ready to run the moment you have a `sitekey`. Until then it is documentation
# of the exact API calls (endpoints, auth, method) the POC depends on.
#
# Usage:
#   export SITEKEY=...        # bearer token from the Adobe AEM/EDS team
#   export ORG=your-git-org   # EDS org (Git org that owns the code repo)
#   export SITE=ap-eds-poc    # EDS site name
#   export STORE=com          # store code
#   export VIEW=de            # store view / locale
#   ./push.sh single 26545XT.OO.1240XT.01
#   ./push.sh bulk            # POST every *.json in products/ at once
#
set -euo pipefail

: "${SITEKEY:?Set SITEKEY (bearer token from the Adobe AEM/EDS team)}"
: "${ORG:?Set ORG (your EDS/Git org)}"
: "${SITE:?Set SITE (your EDS site, e.g. ap-eds-poc)}"
STORE="${STORE:-com}"
VIEW="${VIEW:-de}"

BASE="https://api.adobecommerce.live/${ORG}/${SITE}/catalog/${STORE}/${VIEW}/products"
DIR="$(cd "$(dirname "$0")/products" && pwd)"
MODE="${1:-single}"

case "$MODE" in
  single)
    SKU="${2:?Pass a SKU, e.g. ./push.sh single 26545XT.OO.1240XT.01}"
    echo "PUT ${BASE}/${SKU}.json"
    curl -fsS -X PUT "${BASE}/${SKU}.json" \
      -H "Authorization: Bearer ${SITEKEY}" \
      -H "Content-Type: application/json" \
      --data-binary "@${DIR}/${SKU}.json"
    ;;
  bulk)
    echo "POST ${BASE}/*  (all products in ${DIR})"
    # Bulk expects an array; jq -s slurps every file into one JSON array.
    # NOTE: bulk POST has a product-count cap (per docs, subject to change) —
    # batch large catalogs. 6k x locales is fine in reasonable batches.
    jq -s '.' "${DIR}"/*.json | curl -fsS -X POST "${BASE}/*" \
      -H "Authorization: Bearer ${SITEKEY}" \
      -H "Content-Type: application/json" \
      --data-binary @-
    ;;
  verify)
    # PB has no publish event, so confirm ingestion by reading the JSON back.
    SKU="${2:?Pass a SKU}"
    echo "GET ${BASE}/${SKU}.json"
    curl -fsS "${BASE}/${SKU}.json" -H "Authorization: Bearer ${SITEKEY}" | jq .
    ;;
  *)
    echo "Unknown mode: ${MODE} (use: single | bulk | verify)" >&2
    exit 1
    ;;
esac

echo
echo "Done."
