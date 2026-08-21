import MiniBlueprint.Entry

set_option autoImplicit false

namespace MiniBlueprint.Notion.Section010101

structure LinkedPage where
  pageId : String
  title : String
  pageUrl : String
  statement : String
  kind : String
  leanDeclarations : Array String
  primaryLeanDeclaration : String
  htmlMarker : String
  html : String
deriving Repr

/-- Auto-generated from the Notion Number Theory database. -/
def pageUrl : String :=
  "https://www.notion.so/3b9db819351e80808a8bca912f2510a5"

/-- Pages in section 1.1.1 whose `Lean declarations` property is non-empty. -/
def linkedPages : Array LinkedPage := #[
  {
    pageId := "3b9db819351e80a2a54cf8f5b7d10a59"
    title := "1.1.1_Cor01"
    pageUrl := "https://app.notion.com/p/3b9db819351e80a2a54cf8f5b7d10a59"
    statement := "\\(K\\) の標数が \\(p > 0\\) ならば，Frobenius 写像 \\(\\sigma : x \\mapsto x^p\\) によって \\(K\\) はその部分体 \\(K^p\\) の上に同型に移される．"
    kind := "Theorem"
    leanDeclarations := #["SerreNumberTheory.myFrobeniusEquivPowers"]
    primaryLeanDeclaration := "SerreNumberTheory.myFrobeniusEquivPowers"
    htmlMarker := "__NOTION_LINKED_3b9db819351e80a2a54cf8f5b7d10a59__"
    html := "<section class=\"notion-linked-entry\" id=\"notion-3b9db819351e80a2a54cf8f5b7d10a59\"><div class=\"notion-linked-header\"><span>Theorem</span><a href=\"https://app.notion.com/p/3b9db819351e80a2a54cf8f5b7d10a59\" target=\"_blank\" rel=\"noopener noreferrer\">1.1.1_Cor01 ↗</a></div><p>\\(K\\) の標数が \\(p &gt; 0\\) ならば，Frobenius 写像 \\(\\sigma : x \\mapsto x^p\\) によって \\(K\\) はその部分体 \\(K^p\\) の上に同型に移される．</p></section>"
  }
]

end MiniBlueprint.Notion.Section010101
