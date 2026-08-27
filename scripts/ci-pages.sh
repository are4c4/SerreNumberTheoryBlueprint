#!/usr/bin/env bash

set -euo pipefail

lake exe vbp build

# Build SubVerso semantic highlighting for every module in the main Lean library.
lake build SerreNumberTheory:highlighted
lake build notion-highlight-export

mkdir -p _out/site/html-multi/notion
mkdir -p _out/site/html-multi/notion/link
mkdir -p _out/site/html-multi/notion-data
cp notion-viewer/index.html _out/site/html-multi/notion/index.html
cp notion-link-generator/index.html _out/site/html-multi/notion/link/index.html

# Keep the original Lean source as the source of truth for every displayed line.
# SubVerso sometimes emits a semantic item whose text covers a line but whose HTML
# only contains part of that line (or empty continuation lines).  Previously those
# empty semantic fragments overwrote the fallback source HTML, making theorem bodies
# disappear.  Overlay semantic HTML only when its plain-text line exactly matches
# the corresponding source line and the semantic HTML is non-empty.
python3 - <<'PY'
from pathlib import Path
p = Path('_out/site/html-multi/notion/index.html')
s = p.read_text()
old = "if(k>=0&&k<html.length)html[k]=sem[j]"
new = "if(k>=0&&k<html.length&&txt[j]===src[k]&&sem[j].trim()!=='')html[k]=sem[j]"
if old not in s:
    raise SystemExit('semantic overlay patch target was not found')
p.write_text(s.replace(old, new))
PY

# Convert highlighted source JSON into a lightweight format the browser can render.
while IFS= read -r src; do
  rel="${src#.lake/build/highlighted/}"
  module="${rel%.json}"
  module="${module//\//.}"
  out="_out/site/html-multi/notion-data/${module}.json"
  lake exe notion-highlight-export "$src" "$out"
done < <(find .lake/build/highlighted/SerreNumberTheory/Formalization -type f -name '*.json' | sort)

test -f _out/site/html-multi/index.html
test -f _out/site/html-multi/notion/index.html
test -f _out/site/html-multi/notion/link/index.html
test -f _out/site/html-multi/notion-data/SerreNumberTheory.Formalization.Chapter01.F010101FiniteFields.json
test -f _out/site/html-multi/-verso-data/blueprint-manifest.json
test -f _out/site/html-multi/-verso-data/blueprint-html-cache.json
