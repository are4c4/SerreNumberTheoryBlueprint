import MiniBlueprint.Entry
import MiniBlueprint.Registry.Chapter01.Section010101FiniteFields

set_option autoImplicit false

namespace MiniBlueprint

namespace FiniteFields

open Registry.Chapter01.Section010101

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
  .entry frobeniusInjective
]

end FiniteFields

/-- 定義・定理メタデータ一覧。 -/
def entries : Array Entry :=
  Registry.Chapter01.Section010101.entries

/-- HTMLに表示する文書の流れ。 -/
def document : Array DocumentBlock :=
  FiniteFields.document

end MiniBlueprint
