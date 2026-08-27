#!/usr/bin/env bash

set -euo pipefail

lake exe vbp build

mkdir -p _out/site/html-multi/notion
cp notion-viewer/index.html _out/site/html-multi/notion/index.html

test -f _out/site/html-multi/index.html
test -f _out/site/html-multi/notion/index.html
test -f _out/site/html-multi/-verso-data/blueprint-manifest.json
test -f _out/site/html-multi/-verso-data/blueprint-html-cache.json
