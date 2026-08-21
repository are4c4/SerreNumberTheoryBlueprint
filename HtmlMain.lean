import MiniBlueprint.Registry
import MiniBlueprint.Html
import MiniBlueprint.SourceLocation

open MiniBlueprint

private def notionMarker : String :=
  "<div class=\"prose math-text\">__NOTION_SECTION010101__</div>"

private def notionStyle : String := String.intercalate "\n" [
  "<style>",
  ".notion-import{max-width:980px;margin:0 0 34px;font-size:1.02rem;line-height:1.95;color:#334155}",
  ".notion-import p{margin:0 0 18px}.notion-equation{margin:14px 0 22px;text-align:center}",
  ".notion-source-bar{display:flex;align-items:center;gap:10px;margin:0 0 24px;padding:10px 12px;border:1px solid #e2e8f0;border-radius:8px;background:#fff;font-size:.78rem}",
  ".notion-source-bar span{font-weight:800;color:#64748b;text-transform:uppercase;letter-spacing:.05em}.notion-source-bar a,.notion-mention{color:#2563eb;text-decoration:none}.notion-source-bar a:hover,.notion-mention:hover{text-decoration:underline}",
  ".notion-toggle{margin:14px 0 22px;border:1px solid #e2e8f0;border-radius:9px;background:#fff;overflow:hidden}.notion-toggle summary{cursor:pointer;padding:13px 16px;font-weight:700;color:#334155}.notion-toggle[open]>summary{border-bottom:1px solid #e2e8f0;background:#f8fafc}.notion-toggle-body{padding:16px 18px}.notion-toggle.nested{margin:12px 0;background:#fbfcfd}",
  "</style>"
]

/--
`lake exe miniblueprint-html` で `blueprint.html` を生成します。
Lean コードと行番号は同じリポジトリ内の実ファイルから毎回取得します。
Notion 部分は構造化 HTML スナップショットを本文マーカーへ差し込みます。
-/
def main : IO Unit := do
  let output := "blueprint.html"
  let refreshed ← refreshDocumentSources (System.FilePath.mk ".") document
  let notion ← IO.FS.readFile "MiniBlueprint/Notion/Section010101FiniteFields.html"
  let html := renderHtml refreshed
  let html := html.replace notionMarker (notionStyle ++ "\n" ++ notion)
  IO.FS.writeFile output html
  IO.println "Lean sources refreshed from this repository"
  IO.println "Notion section inserted from structured snapshot"
  IO.println s!"Generated {output}"
