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

## 実装構成

Viewer はフレームワークを使わない ES Modules と静的 CSS で構成します。

- `viewer.mjs`: DOM 描画と画面イベント
- `infoview.mjs`: hover / goal InfoView
- `lib/manifest.mjs`: URL と manifest の解決
- `lib/highlight.mjs`: Viewer / InfoView 共通のフォールバック強調
- `lib/proof.mjs`: proof status と gutter
- `lib/data.mjs`: 静的 JSON の取得

`index.html` の asset version は手動更新せず、ビルド時に commit SHA から生成します。

## 検証

`./scripts/build-notion.sh` は生成後に HTML と ES Module のローカル参照を検査し、参照先 asset が欠けている場合は失敗します。
`resolveItem`、semantic 行対応、proof gutter、fallback highlighting は Python `unittest` と Node `node:test` で CI 検証します。
