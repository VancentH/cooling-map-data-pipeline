#!/usr/bin/env bash
# =============================================================================
# fetch-cities.sh — Fetch every Sachsen municipality (Kreisfreie Städte +
#                    all Gemeinden/Städte, e.g. Glauchau) from Overpass
#                    API as a flat city list
#
# Data source: OpenStreetMap (© OpenStreetMap contributors, ODbL v1.0)
# Fetched via: Overpass API (https://overpass-api.de/)
#
# Usage: REPO_URL=https://github.com/you/your-repo bash scripts/fetch-cities.sh
#        (or set REPO_URL in your environment / .env file)
# Output: data/sachsen-cities.json
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
OVERPASS_URL="https://overpass-api.de/api/interpreter"
QUERY_FILE="$(dirname "$0")/sachsen-cities.overpassql"
OUTPUT_DIR="data"
OUTPUT_FILE="${OUTPUT_DIR}/sachsen-cities.json"
REPO_URL="${REPO_URL:-}"
USER_AGENT="cooling-map-data-pipeline/0.1.0 (${REPO_URL})"

# --- Preflight checks --------------------------------------------------------
if [ -z "$REPO_URL" ]; then
  echo "Error: REPO_URL is not set." >&2
  echo "       Set it to your own repository URL before running:" >&2
  echo "       REPO_URL=https://github.com/you/your-repo bash scripts/fetch-cities.sh" >&2
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
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/overpass_cities_raw.XXXXXX.json")
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

# --- Convert OSM JSON to city JSON array --------------------------------------
echo "[convert] Converting to city JSON array..."

# The query returns two kinds of relation:
#   - admin_level=6: the 3 Kreisfreie Städte (independent cities) + 10
#     Landkreise (counties). Only the 3 cities are emitted here directly
#     (district: "Kreisfreie Stadt"); the 10 counties are not cities
#     themselves, they're only used below to label every town inside them.
#   - admin_level=8: every Gemeinde/Stadt (e.g. Glauchau) belonging to
#     one of those 10 Landkreise.
# A Gemeinde's own tags don't name its parent Landkreis, but Germany's
# official municipality key (de:amtlicher_gemeindeschluessel / AGS) encodes
# it: a Gemeinde's 8-digit AGS always starts with its parent Kreis's own
# 5-digit AGS (e.g. Glauchau "14524080" starts with Zwickau's "14524").
# That lets us build a Kreis-code -> Kreis-name lookup from the
# admin_level=6 results and resolve each Gemeinde's "district" with it.
jq '
  (
    [.elements[] | select(.tags.admin_level == "6") |
      { (.tags["de:amtlicher_gemeindeschluessel"][0:5]): .tags.name }
    ] | add
  ) as $kreis_lookup |
  [
    .elements[] |
    select(.tags.name != null) |
    if .tags.admin_level == "6" then
      select(.tags["admin_title:de"] == "Kreisfreie Stadt") |
      {
        name: .tags.name,
        district: "Kreisfreie Stadt",
        longitude: .center.lon,
        latitude: .center.lat
      }
    else
      {
        name: .tags.name,
        district: $kreis_lookup[(.tags["de:amtlicher_gemeindeschluessel"] // "")[0:5]],
        longitude: .center.lon,
        latitude: .center.lat
      } | with_entries(select(.value != null))
    end
  ] | sort_by(.name)
' "$TMPFILE" > "$OUTPUT_FILE"

FINAL_COUNT=$(jq 'length' "$OUTPUT_FILE")
echo "[done] Cities written: ${FINAL_COUNT}"
echo "[done] Saved to: ${OUTPUT_FILE}"
