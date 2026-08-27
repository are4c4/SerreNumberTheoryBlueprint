#!/usr/bin/env bash

set -euo pipefail

lake exe vbp build

# Build SubVerso semantic highlighting for every module in the main Lean library.
lake build SerreNumberTheory:highlighted
lake build notion-highlight-export

mkdir -p _out/site/html-multi/notion
mkdir -p _out/site/html-multi/notion-data
cp notion-viewer/index.html _out/site/html-multi/notion/index.html

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
test -f _out/site/html-multi/notion-data/SerreNumberTheory.Formalization.Chapter01.F010101FiniteFields.json
test -f _out/site/html-multi/-verso-data/blueprint-manifest.json
test -f _out/site/html-multi/-verso-data/blueprint-html-cache.json
