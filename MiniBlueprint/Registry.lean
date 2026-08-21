import MiniBlueprint.Entry
import MiniBlueprint.Notion.Section010101FiniteFields
import MiniBlueprint.Registry.Chapter01.Section010101FiniteFields

set_option autoImplicit false

namespace MiniBlueprint

namespace FiniteFields

open Registry.Chapter01.Section010101

private def notionLinkedEntry
    (page : Notion.Section010101.LinkedPage) : Entry where
  id := "notion-" ++ page.pageId
  title := page.title
  kind := if page.kind == "Definition" then .definition else .theorem
  externalDeclaration := page.primaryLeanDeclaration
  description := page.statement
  leanExplanation := "Notion DB の `Lean declarations` に登録された完全修飾宣言名をキーに、同じリポジトリ内の実 Lean ファイルから宣言本体と行番号を取得する。"
  progress := .formalized
  source := "Notion: 数論講義DB"
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := "are4c4/SerreNumberTheoryBlueprint"
  sourcePath := "SerreNumberTheory/Formalization/Chapter01/F010101FiniteFields.lean"
  notionPageUrl := page.pageUrl
  notionPageTitle := page.title
  tags := #["finite-field", "notion-linked"]

private def notionLinkedBlocks : Array DocumentBlock :=
  Notion.Section010101.linkedPages.foldl
    (fun blocks page =>
      blocks ++ #[
        .paragraph page.htmlMarker,
        .entry (notionLinkedEntry page)
      ])
    #[]

/--
Notion の「1.1.1_有限体」を本文の正本として表示する。
`Lean declarations` が設定された同節の Notion ページは、Notion 本文の直後に
Notion ページ → 対応する Lean カード、の順で自動的に追加される。
-/
def document : Array DocumentBlock := #[
  .heading 2 "section-1-1-1" "1.1.1 有限体",
  .paragraph "__NOTION_SECTION010101__"
] ++ notionLinkedBlocks ++ #[
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
  .entry frobeniusInjective
]

end FiniteFields

/-- 定義・定理メタデータ一覧。 -/
def entries : Array Entry :=
  Registry.Chapter01.Section010101.entries ++
    Notion.Section010101.linkedPages.map FiniteFields.notionLinkedEntry

/-- HTMLに表示する文書の流れ。 -/
def document : Array DocumentBlock :=
  FiniteFields.document

end MiniBlueprint
