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
cp notion-link/index.html _out/site/html-multi/notion/link/index.html

# Add a small launcher on the Blueprint home page so the URL generator is easy to find.
python3 - <<'PY'
from pathlib import Path
p = Path('_out/site/html-multi/index.html')
s = p.read_text()
marker = '</body>'
button = '''<a href="./notion/link/" style="position:fixed;right:18px;bottom:18px;z-index:9999;padding:9px 12px;border-radius:8px;background:#0e639c;color:white;text-decoration:none;font:12px -apple-system,BlinkMacSystemFont,Segoe UI,sans-serif;box-shadow:0 2px 8px rgba(0,0,0,.25)">Notion URLを作成</a>'''
if button not in s and marker in s:
    s = s.replace(marker, button + marker, 1)
p.write_text(s)
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
