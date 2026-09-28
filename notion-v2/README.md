# Notion Viewer v2

Notion に埋め込むための Lean 静的ビューアです。

## 設計

ブラウザは GitHub の raw source を取得・解析しません。GitHub Actions またはローカルビルド時に、Lean/SubVerso が生成する semantic highlighting から静的データを作成します。

```text
Lean source
   ↓
SubVerso highlighted JSON
   ↓
NotionHighlightExport.lean
   ↓
build-notion-v2.py
   ↓
manifest.json + proof-status.json
   ↓
static viewer
   ↓
Notion embed
```

このため、ファイル移動に弱い `file + short declaration name` より、完全修飾された Lean 宣言名を安定URLとして利用できます。

## URL

推奨:

```text
/?decl=SerreNumberTheory.someTheorem
```

行指定の fallback:

```text
/?file=SerreNumberTheory/Formalization/Chapter01/File.lean&line=120
```

`link/` では GitHub の行番号付きURLから上記Viewer URLを生成できます。

## 設定

`config.json` の `sourcePrefixes` でViewerに含めるLeanソースを指定します。リポジトリ名・owner名・branch名はブラウザコードにはハードコードせず、ビルド環境からmanifestへ記録します。

## ビルド

```bash
./scripts/build-notion-v2.sh
```

生成物:

```text
_out/notion-v2/
├── index.html
├── viewer.css
├── viewer.js
├── infoview.css
├── infoview.js
├── proof-status.json
├── build-version.json
├── data/
│   └── manifest.json
└── link/
    ├── index.html
    ├── link.css
    └── link.js
```

このビルドは Verso Blueprint を呼び出しません。
