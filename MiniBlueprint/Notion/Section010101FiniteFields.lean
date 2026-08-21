import MiniBlueprint.Entry

set_option autoImplicit false

namespace MiniBlueprint.Notion.Section010101

/--
Notion の「1.1.1_有限体」から取り込んだ試作用スナップショット。
現段階では自動同期ではなく、Notion を自然言語ノートの正本として利用できるかを
確認するための最小構成です。
-/
def pageUrl : String :=
  "https://app.notion.com/p/3b9db819351e80808a8bca912f2510a5"

/-- Notion ノート冒頭を Blueprint の本文ブロックへ変換した試作。 -/
def document : Array DocumentBlock := #[
  .heading 3 "notion-note-1-1-1" "Notionノート（試作）",
  .paragraph "以下は Notion の「1.1.1_有限体」で整理している数学ノートを Blueprint に取り込んだ試作である。現段階ではスナップショットとして取り込んでおり、Lean コードは同じリポジトリ内の実ファイルから別途自動取得する。",
  .paragraph "\\(K\\) を体とする。環準同型 \\(f : \\mathbb{Z} \\to K\\) を \\(f(1_{\\mathbb{Z}})=1_K\\) となるように定める。このとき、\\[f(n)=n\\cdot 1_K.\\] ここで \\(n\\cdot1_K\\) は \\(K\\) において \\(1_K\\) を \\(n\\) 回加えるという意味である。",
  .paragraph "上の等式は、\\(f\\) が環準同型であり \\(f(1_{\\mathbb{Z}})=1_K\\) であることから、\\[f(n)=f(n\\cdot1_{\\mathbb{Z}})=n\\cdot f(1_{\\mathbb{Z}})=n\\cdot1_K\\] として得られる。",
  .paragraph "さらに \\(f(\\mathbb{Z})\\) は \\(K\\) の部分環であり、体 \\(K\\) の中にあるため零因子を持たない。したがって \\(f(\\mathbb{Z})\\) は整域となる。この像の構造を調べるために \\(\\ker f\\) を考える。",
  .paragraph "\\(\\ker f=\\{0\\}\\) の場合は \\(f\\) は単射であり、\\(f:\\mathbb{Z}\\to f(\\mathbb{Z})\\) は全射でもあるため、\\[\\mathbb{Z}\\cong f(\\mathbb{Z}).\\] 一方、\\(\\ker f\\neq\\{0\\}\\) の場合には、\\(f(p)=0\\) となる最小の正整数 \\(p\\) を取り、\\(\\ker f=p\\mathbb{Z}\\) となることを示すことで、\\[\\mathbb{Z}/p\\mathbb{Z}\\cong f(\\mathbb{Z})\\] が得られる。"
]

end MiniBlueprint.Notion.Section010101
