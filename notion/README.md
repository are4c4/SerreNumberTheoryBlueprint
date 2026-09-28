# Notion Viewer

Notion に埋め込むための Lean 静的 Viewer です。

ブラウザ側で raw GitHub source を解析せず、ビルド時に Lean/SubVerso の semantic highlighting と proof status を静的データへ変換します。

```text
Lean source
   ↓
SubVerso highlighted JSON
   ↓
NotionHighlightExport.lean
   ↓
scripts/build-notion.py
   ↓
manifest.json + proof-status.json
   ↓
static viewer
   ↓
Notion embed
```

## URL

推奨:

```text
/notion/?decl=SerreNumberTheory.someTheorem
```

行指定:

```text
/notion/?file=SerreNumberTheory/Formalization/Chapter01/File.lean&line=120
```

旧Viewerとの互換性のため、`decl` の短縮名に加えて `section`、`namespace`、`command` パラメータもサポートします。

## 設定

`config.json` の `sourcePrefixes` でViewerに含めるLeanソースを指定します。リポジトリ名・owner名・branch名はブラウザコードにハードコードせず、ビルド環境からmanifestへ記録します。

## ビルド

```bash
./scripts/build-notion.sh
```

このビルドは Verso Blueprint を使用しません。
