#!/usr/bin/env bash
# =============================================================================
# fetch.sh — Fetch cooling facility data from Overpass API for Sachsen, Germany
#
# Data source: OpenStreetMap (© OpenStreetMap contributors, ODbL v1.0)
# Fetched via: Overpass API (https://overpass-api.de/)
#
# Usage: REPO_URL=https://github.com/you/your-repo bash scripts/fetch.sh
#        (or set REPO_URL in your environment / .env file)
# Output: data/sachsen-cooling.geojson
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
OVERPASS_URL="https://overpass-api.de/api/interpreter"
QUERY_FILE="$(dirname "$0")/sachsen-cooling.overpassql"
OUTPUT_DIR="data"
OUTPUT_FILE="${OUTPUT_DIR}/sachsen-cooling.geojson"
REPO_URL="${REPO_URL:-}"
USER_AGENT="cooling-map-data-pipeline/0.1.0 (${REPO_URL})"

# --- Preflight checks --------------------------------------------------------
if [ -z "$REPO_URL" ]; then
  echo "Error: REPO_URL is not set." >&2
  echo "       Set it to your own repository URL before running:" >&2
  echo "       REPO_URL=https://github.com/you/your-repo bash scripts/fetch.sh" >&2
  exit 1
fi

if ! command -v curl &>/dev/null; then
  echo "Error: curl is required but not installed." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if [ ! -f "$QUERY_FILE" ]; then
  echo "Error: Query file not found: $QUERY_FILE" >&2
  exit 1
fi

# --- Prepare output directory ------------------------------------------------
mkdir -p "$OUTPUT_DIR"

# --- Create temp file for raw API response -----------------------------------
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/overpass_raw.XXXXXX.json")
trap 'rm -f "$TMPFILE"' EXIT

# --- Fetch from Overpass API -------------------------------------------------
echo "[fetch] Sending query to Overpass API..."

QUERY=$(cat "$QUERY_FILE")

HTTP_STATUS=$(curl \
  --silent \
  --show-error \
  --fail-with-body \
  --write-out "%{http_code}" \
  --output "$TMPFILE" \
  --user-agent "$USER_AGENT" \
  --data-urlencode "data=${QUERY}" \
  "$OVERPASS_URL" \
)

if [ "$HTTP_STATUS" != "200" ]; then
  echo "Error: Overpass API returned HTTP ${HTTP_STATUS}" >&2
  cat "$TMPFILE" >&2
  exit 1
fi

echo "[fetch] Received response (HTTP ${HTTP_STATUS})"

# --- Validate response -------------------------------------------------------
ELEMENT_COUNT=$(jq '.elements | length' "$TMPFILE")
echo "[fetch] Elements received: ${ELEMENT_COUNT}"

if [ "$ELEMENT_COUNT" -eq 0 ]; then
  echo "Warning: Query returned 0 elements. Check the query or area filter." >&2
fi

# --- Convert OSM JSON to GeoJSON ---------------------------------------------
echo "[convert] Converting to GeoJSON..."

jq '{
  "type": "FeatureCollection",
  "features": [
    .elements[] |
    select(.type == "node" or (.type != "node" and .center != null)) |
    {
      "type": "Feature",
      "id": "\(.type)/\(.id)",
      "properties": (
        .tags +
        {
          "id": "\(.type)/\(.id)"
        }
      ),
      "geometry": {
        "type": "Point",
        "coordinates": [
          (if .type == "node" then .lon else .center.lon end),
          (if .type == "node" then .lat else .center.lat end)
        ]
      }
    }
  ]
}' "$TMPFILE" > "$OUTPUT_FILE"

echo "[done] Saved to: ${OUTPUT_FILE}"
echo "[done] Features: $(jq '.features | length' "$OUTPUT_FILE")"
