#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-_out/site/notion}"
SEMANTIC_TMP="$OUT/.semantic"

rm -rf "$OUT"
mkdir -p "$OUT/data" "$SEMANTIC_TMP"

lake build SerreNumberTheory:highlighted
lake build notion-highlight-export

while IFS= read -r src; do
  rel="${src#.lake/build/highlighted/}"
  dst="$SEMANTIC_TMP/$rel"
  mkdir -p "$(dirname "$dst")"
  lake exe notion-highlight-export "$src" "$dst"
done < <(find .lake/build/highlighted/SerreNumberTheory -type f -name '*.json' | sort)

NOTION_PROOF_STATUS="$OUT/proof-status.json" lake env lean NotionProofStatusExport.lean

python3 scripts/build-notion.py --semantic-root "$SEMANTIC_TMP" --output "$OUT" --source-root . --config notion/config.json

# Copy the whole static viewer tree so newly added assets cannot be omitted
# from the Pages artifact by an out-of-date list of cp commands.
cp -R notion/. "$OUT/"

ASSET_VERSION="${GITHUB_SHA:-$(git rev-parse --short=12 HEAD 2>/dev/null || printf 'local')}"
python3 scripts/stamp-notion-assets.py "$OUT/index.html" "$ASSET_VERSION"
printf '{"commit":"%s"}\n' "$ASSET_VERSION" > "$OUT/build-version.json"

test -s "$OUT/index.html"
test -s "$OUT/viewer.mjs"
test -s "$OUT/lib/manifest.mjs"
test -s "$OUT/data/manifest.json"
test -s "$OUT/proof-status.json"
test -s "$OUT/link/index.html"

python3 scripts/check-notion-assets.py "$OUT"

python3 - "$OUT/data/manifest.json" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text())
assert data["schemaVersion"] == 3
assert data["items"], "manifest contains no Lean items"
assert data["declarations"], "manifest contains no declarations"
assert "legacyTargets" in data, "legacy URL compatibility data is missing"
prefixes = data.get("sourcePrefixes", [])
assert prefixes, "manifest sourcePrefixes is empty"
assert all(any(item["file"].startswith(prefix) for prefix in prefixes) for item in data["items"].values())
highlighted_decl_rows = sum(
    1
    for item in data["items"].values()
    if item.get("defines")
    for row in item.get("rows", [])
    if '<span class="lean-token' in row.get("html", "")
)
if highlighted_decl_rows == 0:
    print("warning: manifest has no semantic declaration rows; viewer will use client-side syntax fallback")
print(
    "Notion Viewer manifest: "
    f"{len(data['items'])} items, "
    f"{len(data['declarations'])} declarations, "
    f"{len(data['legacyTargets'])} legacy targets, "
    f"{highlighted_decl_rows} highlighted declaration rows"
)
PY

rm -rf "$SEMANTIC_TMP"
