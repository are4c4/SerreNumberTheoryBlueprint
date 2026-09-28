# Notion Viewer

Notion に埋め込むための Lean 静的 Viewer です。

ブラウザ側で raw GitHub source を解析せず、ビルド時に Lean/SubVerso の semantic metadata と proof status を静的データへ変換し、Lean 公式 TextMate grammar と VS Code Dark+ theme で最終的な構文色を生成します。

```text
Lean source
   ├─ SubVerso highlighted JSON → semantic metadata / InfoView / proof ranges
   └─ Lean official TextMate grammar + VS Code Dark+
                         ↓
             apply-vscode-highlighting.mjs
                         ↓
             manifest.json + proof-status.json
                         ↓
                    static viewer
                         ↓
                    Notion embed
```

通常のソース色は `vscode-textmate` + `vscode-oniguruma` でビルド時に生成します。Lean の `/-- ... -/` doc comment では公式 `source.lean4.markdown` grammar も読み込み、バッククォートで囲まれた inline code などを VS Code と同じ TextMate scope で処理します。`lib/highlight.mjs` の独自 tokenizer は、生成済み HTML がない場合だけ使うフォールバックです。

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
npm install --ignore-scripts
./scripts/build-notion.sh
```

このビルドは Verso Blueprint を使用しません。TextMate/Oniguruma はビルド時だけ必要で、生成された Notion Viewer はこれらをブラウザへ配信しません。

## 実装構成

Viewer はフレームワークを使わない ES Modules と静的 CSS で構成します。

- `viewer.mjs`: DOM 描画と画面イベント
- `infoview.mjs`: hover / goal InfoView
- `lib/manifest.mjs`: URL と manifest の解決
- `lib/highlight.mjs`: 生成済み VS Code highlighting がない場合のフォールバック強調
- `../scripts/apply-vscode-highlighting.mjs`: 公式 grammar・Dark+・SubVerso metadata の合成
- `vendor/`: バージョン固定した Lean grammar / Lean doc-comment Markdown grammar / VS Code theme
- `lib/proof.mjs`: proof status と gutter
- `lib/data.mjs`: 静的 JSON の取得

`index.html` の asset version は手動更新せず、ビルド時に commit SHA から生成します。

## 検証

`./scripts/build-notion.sh` は生成後に HTML と ES Module のローカル参照を検査し、参照先 asset が欠けている場合は失敗します。
`resolveItem`、semantic 行対応、proof gutter、fallback highlighting は Python `unittest` と Node `node:test` で CI 検証します。
