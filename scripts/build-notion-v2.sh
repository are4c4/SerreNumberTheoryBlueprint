#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-_out/notion-v2}"
SEMANTIC_TMP="$OUT/.semantic"

rm -rf "$OUT"
mkdir -p "$OUT/data" "$OUT/link" "$SEMANTIC_TMP"

lake build SerreNumberTheory:highlighted
lake build notion-highlight-export

while IFS= read -r src; do
  rel="${src#.lake/build/highlighted/}"
  dst="$SEMANTIC_TMP/$rel"
  mkdir -p "$(dirname "$dst")"
  lake exe notion-highlight-export "$src" "$dst"
done < <(find .lake/build/highlighted/SerreNumberTheory -type f -name '*.json' | sort)

NOTION_V2_PROOF_STATUS="$OUT/proof-status.json" lake env lean NotionProofStatusExport.lean

python3 scripts/build-notion-v2.py \
  --semantic-root "$SEMANTIC_TMP" \
  --output "$OUT" \
  --source-root .

cp notion-v2/index.html "$OUT/index.html"
cp notion-v2/viewer.css "$OUT/viewer.css"
cp notion-v2/viewer.js "$OUT/viewer.js"
cp notion-v2/infoview.css "$OUT/infoview.css"
cp notion-v2/infoview.js "$OUT/infoview.js"
cp notion-v2/link/index.html "$OUT/link/index.html"
cp notion-v2/link/link.css "$OUT/link/link.css"
cp notion-v2/link/link.js "$OUT/link/link.js"

printf '{"commit":"%s"}\n' "${GITHUB_SHA:-local}" > "$OUT/build-version.json"

test -s "$OUT/index.html"
test -s "$OUT/data/manifest.json"
test -s "$OUT/proof-status.json"
test -s "$OUT/link/index.html"

python3 - "$OUT/data/manifest.json" <<'PY'
import json
import sys
from pathlib import Path
p = Path(sys.argv[1])
data = json.loads(p.read_text())
assert data["schemaVersion"] == 2
assert data["items"], "manifest contains no Lean items"
assert data["declarations"], "manifest contains no declarations"
print(f"Notion Viewer v2 manifest: {len(data['items'])} items, {len(data['declarations'])} declarations")
PY

rm -rf "$SEMANTIC_TMP"
