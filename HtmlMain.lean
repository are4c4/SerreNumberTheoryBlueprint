import MiniBlueprint.Registry
import MiniBlueprint.Html
import MiniBlueprint.SourceLocation

open MiniBlueprint

private def notionMarker : String :=
  "<div class=\"prose math-text\">__NOTION_SECTION010101__</div>"

private def linkedMarker (marker : String) : String :=
  s!"<div class=\"prose math-text\">{marker}</div>"

private def notionStyle : String := String.intercalate "\n" [
  "<style>",
  ".notion-import,.notion-linked-entry{max-width:900px;font-size:1.02rem;line-height:1.95;color:#334155}",
  ".notion-import{margin:0 0 34px}.notion-linked-entry{margin:34px 0 12px;padding:22px 24px;border:1px solid #dbe2ea;border-radius:12px;background:#fff}",
  ".notion-import p,.notion-linked-entry p{margin:0 0 18px}.notion-equation{margin:14px 0 22px;text-align:center}",
  ".notion-source-bar,.notion-linked-header{display:flex;align-items:center;gap:10px;margin:0 0 24px;padding:10px 12px;border:1px solid #e2e8f0;border-radius:8px;background:#fff;font-size:.78rem}",
  ".notion-linked-header{margin:-4px 0 20px;background:#f8fafc}.notion-linked-header span,.notion-source-bar span{font-weight:800;color:#64748b;text-transform:uppercase;letter-spacing:.05em}",
  ".notion-source-bar a,.notion-linked-header a,.notion-mention{color:#2563eb;text-decoration:none}.notion-source-bar a:hover,.notion-linked-header a:hover,.notion-mention:hover{text-decoration:underline}",
  ".notion-toggle{margin:14px 0 22px;border:1px solid #e2e8f0;border-radius:9px;background:#fff;overflow:hidden}.notion-toggle summary{cursor:pointer;padding:13px 16px;font-weight:700;color:#334155}.notion-toggle[open]>summary{border-bottom:1px solid #e2e8f0;background:#f8fafc}.notion-toggle-body{padding:16px 18px}.notion-toggle.nested{margin:12px 0;background:#fbfcfd}",
  ".notion-callout{margin:14px 0;padding:14px 16px;border:1px solid #e2e8f0;border-radius:9px;background:#f8fafc}.notion-list-item{margin:6px 0 6px 18px}.notion-linked-entry + .entry{margin-top:12px;max-width:1120px}",
  "</style>"
]

/--
`lake exe miniblueprint-html` で `blueprint.html` を生成します。
Lean コードと行番号は同じリポジトリ内の実ファイルから毎回取得します。
Notion 本文に加えて、`Lean declarations` が設定された Notion ページを対応する
Lean カードの直前へ差し込みます。
-/
def main : IO Unit := do
  let output := "blueprint.html"
  let refreshed ← refreshDocumentSources (System.FilePath.mk ".") document
  let notion ← IO.FS.readFile "MiniBlueprint/Notion/Section010101FiniteFields.html"
  let html := renderHtml refreshed
  let html := html.replace notionMarker (notionStyle ++ "\n" ++ notion)
  let html := Notion.Section010101.linkedPages.foldl
    (fun current page =>
      current.replace (linkedMarker page.htmlMarker) page.html)
    html
  IO.FS.writeFile output html
  IO.println "Lean sources refreshed from this repository"
  IO.println s!"Notion section inserted; linked pages: {Notion.Section010101.linkedPages.size}"
  IO.println s!"Generated {output}"
