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
def linkedPages : Array LinkedPage :=
  #[
  { pageId := "3b9db819-351e-80a2-a54c-f8f5b7d10a59", title := "1.1.1_Cor01", pageUrl := "https://curved-turner-4ce.notion.site/1-1-1_Cor01-3b9db819351e80a2a54cf8f5b7d10a59", statement := "\\(K\\) の標数が \\(p > 0\\) ならば，写像 \\(\\sigma : x \\mapsto x^p\\) によって \\(K\\) はその部分体 \\(K^p\\) の上に同型に移される．", kind := "Theorem", leanDeclarations := #["SerreNumberTheory.myFrobeniusEquivPowers"], primaryLeanDeclaration := "SerreNumberTheory.myFrobeniusEquivPowers", htmlMarker := "__NOTION_LINKED_3b9db819351e80a2a54cf8f5b7d10a59__", html := "<section class=\"notion-linked-entry\" id=\"notion-3b9db819351e80a2a54cf8f5b7d10a59\">\n  <div class=\"notion-linked-header\">\n    <span>Theorem</span>\n    <a href=\"https://curved-turner-4ce.notion.site/1-1-1_Cor01-3b9db819351e80a2a54cf8f5b7d10a59\" target=\"_blank\" rel=\"noopener noreferrer\">1.1.1_Cor01 ↗</a>\n  </div>\n<div class=\"notion-callout\"> <h3>1.1.1_Cor01</h3>\n<hr>\n<p>\\(K\\) の標数が \\(p &gt; 0\\) ならば，<a class=\"notion-mention\" href=\"https://www.notion.so/3b9db819351e80bb9553f76493c34b82\" target=\"_blank\" rel=\"noopener noreferrer\">写像</a> \\(\\sigma : x \\mapsto x^p\\) によって \\(K\\) はその部分体 \\(K^p\\) の上に同型に移される．</p>\n<hr>\n<details class=\"notion-toggle\"><summary>証明</summary><div class=\"notion-toggle-body\"></div></details></div>\n\n\n\n\n</section>" }
]

end MiniBlueprint.Notion.Section010101
