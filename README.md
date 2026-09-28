# Serre Number Theory Blueprint

セール『数論講義』に現れる定義・命題・定理を、Lean 4 と mathlib を用いて形式化するプロジェクトです。
自然言語による記述と Lean の形式化を対応づけるため、[Verso Blueprint](https://github.com/leanprover/verso-blueprint) を使用しています。

## 現在の内容

現在、Chapter 01 について次の形式化を収録しています。

- `F010101FiniteFields.lean`: 有限体、Frobenius 写像、有限体の存在・一意性に関する結果
- `F010102MultiplicativeGroup.lean`: 有限体の乗法群の巡回性
- `F010201PowerSums.lean`: 有限体上のべき乗和
- `F010202ChevalleyWarning.lean`: Chevalley–Warning の定理

Blueprint 側では、現在 `B010101FiniteFields.lean` を公開文書として接続しています。
後続節の自然言語側は順次追加予定です。

## ディレクトリ構成

```text
SerreNumberTheoryBlueprint/
├── SerreNumberTheory/
│   ├── Formalization/
│   │   └── Chapter01/
│   │       ├── F010101FiniteFields.lean
│   │       ├── F010102MultiplicativeGroup.lean
│   │       ├── F010201PowerSums.lean
│   │       └── F010202ChevalleyWarning.lean
│   ├── Blueprint/
│   │   └── Chapter01/
│   │       └── B010101FiniteFields.lean
│   └── Blueprint.lean
├── SerreNumberTheory.lean
├── SerreNumberTheoryMain.lean
├── lakefile.lean
└── lean-toolchain
```

- `Formalization/`: Lean による形式化本体
- `Blueprint/`: 自然言語の定理文・証明概要と Lean 宣言の対応
- `SerreNumberTheory/Blueprint.lean`: Blueprint 文書全体と依存関係グラフ・進捗表示
- `SerreNumberTheoryMain.lean`: Verso Blueprint の生成エントリポイント

## 環境

- Lean 4.32.0
- mathlib 4.32.0
- Verso Blueprint 4.32.0

依存関係は `lake-manifest.json` に固定しています。

## ビルド

初回は必要に応じて依存関係を取得します。

```bash
lake update
```

Lean コード全体の確認:

```bash
lake build
```

Blueprint の生成:

```bash
lake exe vbp build
```

生成物は `_out/site/html-multi/` に出力されます。ローカルで確認する場合は、例えば次のようにします。

```bash
python3 -m http.server 8000 --directory _out/site/html-multi
```

ブラウザで `http://localhost:8000/` を開いて確認できます。

ローカルで GitHub Pages と同じ確認を行う場合:

```bash
./scripts/ci-pages.sh
```

## GitHub Pages

`main` への push 時に GitHub Actions で Blueprint をビルドし、GitHub Pages に公開します。
Pull Request でも同じビルドを実行し、生成可能かを確認します。
