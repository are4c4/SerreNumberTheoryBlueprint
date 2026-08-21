import MiniBlueprint.Registry
import MiniBlueprint.Html
import MiniBlueprint.SourceLocation

open MiniBlueprint

/--
`lake exe miniblueprint-html` で `blueprint.html` を生成します。
Lean コードと行番号は同じリポジトリ内の実ファイルから毎回取得します。
-/
def main : IO Unit := do
  let output := "blueprint.html"
  let refreshed ← refreshDocumentSources (System.FilePath.mk ".") document
  IO.FS.writeFile output (renderHtml refreshed)
  IO.println s!"Lean sources refreshed from this repository"
  IO.println s!"Generated {output}"
