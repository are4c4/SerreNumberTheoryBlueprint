# Serre Number Theory Formalization

Jean-Pierre Serre の *A Course in Arithmetic*（邦訳『数論講義』）を題材に、Lean 4 / mathlib で数論の結果を形式化する研究用リポジトリです。

自然言語による数学的な説明は Notion で管理し、このリポジトリでは Lean の形式化コードと、Notion からコード・型情報・proof state を参照するための静的 Viewer を管理します。

## 構成

```text
SerreNumberTheory/
  Formalization/
    Chapter01/
      F010101FiniteFields.lean
      F010102MultiplicativeGroup.lean
      F010201PowerSums.lean
      F010202ChevalleyWarning.lean

notion/
  index.html
  viewer.js
  viewer.css
  infoview.js
  infoview.css
  link/
  config.json

scripts/
  build-notion.py
  build-notion.sh
```

## Lean

- Lean 4.32.0
- mathlib 4.32.0
- SubVerso is pinned directly for semantic highlighting used by the Notion Viewer.

通常のビルド:

```bash
lake build
```

## Notion Viewer

Viewer はブラウザで GitHub の raw source を解析しません。ビルド時に SubVerso の semantic highlighting、Lean の宣言情報、proof status を静的 JSON に変換し、GitHub Pages から配信します。

ローカル生成:

```bash
./scripts/build-notion.sh
```

生成先:

```text
_out/site/notion/
```

推奨URL:

```text
/notion/?decl=SerreNumberTheory.someTheorem
```

旧Viewerで使用していた `?file=...&decl=...`、`?section=...`、`?namespace=...`、`?command=...` 形式にも互換対応しています。

GitHub の行番号付きURLからNotion用URLを作る補助画面は `/notion/link/` にあります。

## GitHub Pages

`.github/workflows/notion-pages.yml` が pull request でViewerをビルドし、`main` へのpushで GitHub Pages にdeployします。
