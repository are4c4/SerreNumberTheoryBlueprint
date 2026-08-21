import MiniBlueprint.Entry
import MiniBlueprint.Notion.Section010101FiniteFields
import MiniBlueprint.Registry.Chapter01.Section010101FiniteFields

set_option autoImplicit false

namespace MiniBlueprint

namespace FiniteFields

open Registry.Chapter01.Section010101

/--
Notion DB の `Lean declarations` を対応キーとして作る最初の連携エントリ。
対応宣言名・タイトル・本文・Notion URL は Notion スナップショット側から参照する。
-/
def notionCor01 : Entry where
  id := "notion-1-1-1-cor01"
  title := Notion.Section010101.cor01Title
  kind := .theorem
  externalDeclaration := Notion.Section010101.cor01PrimaryLeanDeclaration
  description := Notion.Section010101.cor01Statement
  leanExplanation := "Notion DB の `Lean declarations` に登録された完全修飾宣言名をキーに、同じリポジトリ内の実 Lean ファイルから宣言本体と行番号を取得する。"
  dependencies := #["frobenius_ring_hom", "frobenius_injective"]
  progress := .formalized
  source := "Notion: 数論講義DB"
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := "are4c4/SerreNumberTheoryBlueprint"
  sourcePath := "SerreNumberTheory/Formalization/Chapter01/F010101FiniteFields.lean"
  notionPageUrl := Notion.Section010101.cor01PageUrl
  notionPageTitle := Notion.Section010101.cor01Title
  tags := #["finite-field", "frobenius", "notion-linked"]

/--
Notion の「1.1.1_有限体」を本文の正本として表示し、対応する Definition/Theorem を
その後の位置に配置します。`__NOTION_SECTION010101__` は HtmlMain が Notion の
構造化 HTML フラグメントに置き換えるためのマーカーです。
-/
def document : Array DocumentBlock := #[
  .heading 2 "section-1-1-1" "1.1.1 有限体",
  .paragraph "__NOTION_SECTION010101__",

  .heading 3 "topic-characteristic" "標数",
  .entry fieldCharacteristic,
  .entry fieldCharIsPrimeOrZero,

  .heading 3 "topic-frobenius" "Frobenius写像",
  .entry frobeniusMap,
  .entry frobeniusZero,
  .entry frobeniusOne,
  .entry frobeniusMul,
  .entry frobeniusAdd,
  .entry frobeniusRingHom,
  .entry frobeniusInjective,

  .heading 3 "topic-notion-linked" "Notion ↔ Lean 対応",
  .paragraph "以下は Notion の定理ページに設定した `Lean declarations` を対応キーとして表示する最初の実例である。",
  .entry notionCor01
]

end FiniteFields

/-- 定義・定理メタデータ一覧。 -/
def entries : Array Entry :=
  Registry.Chapter01.Section010101.entries ++ #[FiniteFields.notionCor01]

/-- HTMLに表示する文書の流れ。 -/
def document : Array DocumentBlock :=
  FiniteFields.document

end MiniBlueprint
