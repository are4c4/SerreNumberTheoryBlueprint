import MiniBlueprint.Entry

set_option autoImplicit false

namespace MiniBlueprint

private def htmlEscape (s : String) : String :=
  ((((s.replace "&" "&amp;").replace "<" "&lt;").replace ">" "&gt;").replace "\"" "&quot;").replace "'" "&#39;"

private def progressClass : Progress → String
  | .planned => "planned"
  | .inProgress => "in-progress"
  | .formalized => "formalized"

private def progressLabel : Progress → String
  | .planned => "Planned"
  | .inProgress => "In progress"
  | .formalized => "Formalized"

private def kindLabel : EntryKind → String
  | .definition => "Definition"
  | .theorem => "Theorem"

private def declarationLabel (entry : Entry) : String :=
  match entry.declaration with
  | some declaration => toString declaration
  | none => entry.externalDeclaration

private def sourceLineLabel (entry : Entry) : String :=
  match entry.sourceLineStart, entry.sourceLineEnd with
  | some a, some b => if a == b then s!"L{a}" else s!"L{a}–L{b}"
  | some a, none => s!"L{a}"
  | none, some b => s!"L{b}"
  | none, none => ""

private def sourceUrl (entry : Entry) : String :=
  if entry.sourceRepository.isEmpty || entry.sourcePath.isEmpty then ""
  else
    let base := s!"https://github.com/{entry.sourceRepository}/blob/{entry.sourceRef}/{entry.sourcePath}"
    match entry.sourceLineStart, entry.sourceLineEnd with
    | some a, some b => s!"{base}#L{a}-L{b}"
    | some a, none => s!"{base}#L{a}"
    | none, some b => s!"{base}#L{b}"
    | none, none => base

private def renderDependencies (entry : Entry) : String :=
  if entry.dependencies.isEmpty then "—"
  else String.intercalate " " (entry.dependencies.toList.map fun id =>
    s!"<a class=\"dependency-chip\" href=\"#{htmlEscape id}\">{htmlEscape id}</a>")

private def renderProof (entry : Entry) : String :=
  if entry.proofExplanation.isEmpty then ""
  else String.intercalate "\n" [
    "<div class=\"book-block proof-block\">",
    "<div class=\"book-label\">Proof</div>",
    s!"<div class=\"math-text\">{htmlEscape entry.proofExplanation}</div>",
    "</div>"
  ]

private def renderRemark (entry : Entry) : String :=
  if entry.remark.isEmpty then ""
  else String.intercalate "\n" [
    "<div class=\"book-block remark-block\">",
    "<div class=\"book-label\">Remark</div>",
    s!"<div class=\"math-text\">{htmlEscape entry.remark}</div>",
    "</div>"
  ]

private def renderProofSteps (entry : Entry) : String :=
  if entry.proofSteps.isEmpty then ""
  else
    let rows := entry.proofSteps.toList.zipIdx.map fun (step, i) =>
      String.intercalate "\n" [
        "<div class=\"step-row\">",
        s!"<div class=\"step-natural\"><span class=\"step-number\">{i + 1}</span><div class=\"math-text\">{htmlEscape step.natural}</div></div>",
        s!"<div class=\"step-lean\"><pre><code class=\"language-lean proof-code\">{htmlEscape step.lean}</code></pre></div>",
        "</div>"
      ]
    String.intercalate "\n" ([
      "<details class=\"proof-steps\">",
      "<summary>Proof correspondence <span>自然言語 ↔ Lean</span></summary>",
      "<div class=\"steps-body\">"
    ] ++ rows ++ ["</div>", "</details>"])

private def renderReferenceData (entry : Entry) : String :=
  String.intercalate "\n" (entry.leanReferences.toList.map fun ref =>
    s!"<span class=\"ref-data\" hidden data-name=\"{htmlEscape ref.name}\" data-type=\"{htmlEscape ref.typeText}\" data-description=\"{htmlEscape ref.description}\" data-source=\"{htmlEscape ref.source}\"></span>")

private def renderDeclaration (entry : Entry) : String :=
  let declarationName := declarationLabel entry
  if declarationName.isEmpty then "—"
  else if entry.leanExplanation.isEmpty then s!"<code>{htmlEscape declarationName}</code>"
  else s!"<button type=\"button\" class=\"declaration-button\" data-entry-id=\"{htmlEscape entry.id}\">{htmlEscape declarationName}</button>"

private def renderSourceLocation (entry : Entry) : String :=
  if entry.sourcePath.isEmpty then ""
  else
    let lineLabel := sourceLineLabel entry
    let display := if lineLabel.isEmpty then entry.sourcePath else s!"{entry.sourcePath} : {lineLabel}"
    let url := sourceUrl entry
    if url.isEmpty then
      s!"<div class=\"source-location\"><span>Source</span><code>{htmlEscape display}</code></div>"
    else
      s!"<div class=\"source-location\"><span>Source</span><a href=\"{htmlEscape url}\" target=\"_blank\" rel=\"noopener noreferrer\">{htmlEscape display} ↗</a></div>"

private def renderExplanationData (entry : Entry) : String :=
  String.intercalate "\n" [
    s!"<div id=\"explanation-{htmlEscape entry.id}\" class=\"explanation-data\" hidden>",
    s!"<span class=\"exp-title\">{htmlEscape entry.title}</span>",
    s!"<span class=\"exp-decl\">{htmlEscape (declarationLabel entry)}</span>",
    s!"<span class=\"exp-body\">{htmlEscape entry.leanExplanation}</span>",
    s!"<span class=\"exp-source\">{htmlEscape entry.sourceRepository}</span>",
    s!"<span class=\"exp-path\">{htmlEscape entry.sourcePath}</span>",
    s!"<span class=\"exp-lines\">{htmlEscape (sourceLineLabel entry)}</span>",
    "</div>"
  ]

private def renderLeanCode (entry : Entry) : String :=
  if entry.leanCode.isEmpty then
    "<div class=\"no-code\">この項目専用の Lean 宣言は登録されていません。</div>"
  else
    let startLine := match entry.sourceLineStart with | some n => n | none => 1
    s!"<pre class=\"lean-pre\"><code class=\"lean-source\" data-entry-id=\"{htmlEscape entry.id}\" data-start-line=\"{startLine}\">{htmlEscape entry.leanCode}</code></pre>"

private def renderEntry (entry : Entry) : String :=
  let declarationName := declarationLabel entry
  String.intercalate "\n" [
    s!"<article class=\"entry\" id=\"{htmlEscape entry.id}\">",
    "<header class=\"entry-header\"><div>",
    s!"<div class=\"eyebrow\">{htmlEscape entry.sectionId} · {htmlEscape entry.id}</div>",
    s!"<h2>{htmlEscape entry.title}</h2></div>",
    s!"<span class=\"status {progressClass entry.progress}\">{progressLabel entry.progress}</span></header>",
    "<div class=\"split\">",
    "<section class=\"natural-language\">",
    s!"<div class=\"book-label main-label\">{kindLabel entry.kind}</div>",
    s!"<div class=\"math-text statement\">{htmlEscape entry.description}</div>",
    renderProof entry,
    renderRemark entry,
    "<dl>",
    s!"<dt>Lean declaration</dt><dd>{renderDeclaration entry}</dd>",
    s!"<dt>Dependencies</dt><dd class=\"dependencies\">{renderDependencies entry}</dd>",
    "</dl></section>",
    "<section class=\"lean-code\"><div class=\"lean-heading\"><h3>Lean</h3>",
    if declarationName.isEmpty then "" else s!"<span class=\"lean-name\">{htmlEscape declarationName}</span>",
    "</div>",
    renderLeanCode entry,
    renderSourceLocation entry,
    if entry.leanReferences.isEmpty then "" else "<div class=\"lean-hint\">青い下線の宣言名をクリックすると型・説明・出典を表示します。</div>",
    "</section></div>",
    renderProofSteps entry,
    renderReferenceData entry,
    renderExplanationData entry,
    "</article>"
  ]

private def renderHeading (level : Nat) (id title : String) : String :=
  if level <= 2 then s!"<h2 class=\"doc-heading doc-heading-2\" id=\"{htmlEscape id}\">{htmlEscape title}</h2>"
  else s!"<h3 class=\"doc-heading doc-heading-3\" id=\"{htmlEscape id}\">{htmlEscape title}</h3>"

private def renderBlock : DocumentBlock → String
  | .heading level id title => renderHeading level id title
  | .paragraph text => s!"<div class=\"prose math-text\">{htmlEscape text}</div>"
  | .entry entry => renderEntry entry

private def renderTocBlock : DocumentBlock → String
  | .heading level id title =>
      if level <= 2 then s!"<a class=\"toc-heading toc-level-2\" href=\"#{htmlEscape id}\">{htmlEscape title}</a>"
      else s!"<a class=\"toc-heading toc-level-3\" href=\"#{htmlEscape id}\">{htmlEscape title}</a>"
  | .paragraph _ => ""
  | .entry entry => s!"<a class=\"toc-entry\" href=\"#{htmlEscape entry.id}\"><span>{kindLabel entry.kind}</span>{htmlEscape entry.title}</a>"

/-- 通常本文と定義・定理ブロックを混在させたHTMLを生成します。 -/
def renderHtml (document : Array DocumentBlock) : String :=
  let content := String.intercalate "\n" (document.toList.map renderBlock)
  let toc := String.intercalate "\n" ((document.toList.map renderTocBlock).filter fun s => !s.isEmpty)
  String.intercalate "\n" [
    "<!doctype html>",
    "<html lang=\"ja\"><head>",
    "<meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>Serre Number Theory Blueprint</title>",
    "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/github-dark.min.css\">",
    "<script defer src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js\"></script>",
    "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js\"></script>",
    "<script src=\"https://unpkg.com/highlightjs-lean/dist/lean.min.js\"></script>",
    "<style>",
    ":root{font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",sans-serif;color:#1f2937;background:#f4f6f8}*{box-sizing:border-box}body{margin:0}.app{display:grid;grid-template-columns:270px minmax(0,1fr);min-height:100vh}",
    ".sidebar{position:sticky;top:0;height:100vh;overflow:auto;padding:24px 16px;background:#fff;border-right:1px solid #e5e7eb}.brand{font-size:1.05rem;font-weight:800;margin:0 8px 20px}.toc-heading,.toc-entry{display:block;text-decoration:none;color:#334155;border-radius:7px}.toc-heading:hover,.toc-entry:hover{background:#f1f5f9}.toc-level-2{font-size:.88rem;font-weight:800;padding:9px}.toc-level-3{font-size:.8rem;font-weight:700;padding:8px 10px 5px 18px}.toc-entry{font-size:.76rem;padding:6px 10px 6px 30px}.toc-entry span{display:block;font:600 .58rem ui-monospace,SFMono-Regular,Menlo,monospace;color:#94a3b8;text-transform:uppercase}",
    "main{max-width:1500px;width:100%;margin:0 auto;padding:34px 28px 80px}.doc-heading{scroll-margin-top:18px}.doc-heading-2{font-size:1.8rem;margin:8px 0 16px}.doc-heading-3{font-size:1.3rem;margin:42px 0 12px;padding-bottom:8px;border-bottom:1px solid #dbe2ea}.prose{max-width:900px;font-size:1.02rem;line-height:2;margin:0 0 24px;color:#334155}",
    ".entry{background:#fff;border:1px solid #dfe3e8;border-radius:14px;margin:28px 0;overflow:hidden;box-shadow:0 2px 8px rgba(15,23,42,.04);scroll-margin-top:16px}.entry:target{box-shadow:0 0 0 3px rgba(148,163,184,.22)}.entry-header{display:flex;justify-content:space-between;gap:16px;padding:20px 26px;border-bottom:1px solid #e5e7eb}.entry-header h2{margin:4px 0 0;font-size:1.25rem}.eyebrow{font-size:.8rem;color:#667085}.status{height:max-content;border-radius:999px;padding:5px 10px;font-size:.78rem;font-weight:700}.formalized{background:#dcfce7;color:#166534}.in-progress{background:#fef3c7;color:#92400e}.planned{background:#e5e7eb;color:#475569}",
    ".split{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.15fr)}.split section{min-width:0;padding:26px}.natural-language{border-right:1px solid #e5e7eb}.book-label{font:700 .75rem ui-monospace,SFMono-Regular,Menlo,monospace;text-transform:uppercase;letter-spacing:.08em;color:#475569}.main-label{margin-bottom:14px}.math-text{line-height:1.9;white-space:pre-wrap}.book-block{margin-top:24px;padding:16px 18px;border-left:4px solid #cbd5e1;background:#f8fafc;border-radius:0 8px 8px 0}.remark-block{border-left-color:#a5b4fc;background:#f8f9ff}",
    "dl{display:grid;grid-template-columns:130px 1fr;gap:10px 12px;margin:24px 0 0;font-size:.85rem}dt{color:#667085}dd{margin:0;overflow-wrap:anywhere}.dependencies{display:flex;flex-wrap:wrap;gap:6px}.dependency-chip{padding:3px 8px;border-radius:999px;background:#eef2ff;color:#4338ca;text-decoration:none;font:12px ui-monospace,SFMono-Regular,Menlo,monospace}.declaration-button,.lean-ref{border:0;padding:0;background:transparent;color:#2563eb;cursor:pointer;font:inherit;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;text-decoration:underline;text-decoration-style:dotted;text-underline-offset:3px}",
    ".lean-heading{display:flex;align-items:baseline;justify-content:space-between;gap:12px}.lean-heading h3{margin:0 0 14px;font-size:.9rem;color:#475569;text-transform:uppercase}.lean-name{color:#64748b;font:11px ui-monospace,SFMono-Regular,Menlo,monospace}.lean-pre{margin:0;overflow:auto;border-radius:10px;background:#0d1117}.lean-source{display:block;padding:14px 0;font:13px/1.65 ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;color:#c9d1d9}.code-row{display:grid;grid-template-columns:54px minmax(max-content,1fr)}.line-no{padding:0 12px 0 8px;text-align:right;color:#6e7681;user-select:none;border-right:1px solid #30363d}.line-body{padding:0 16px;white-space:pre}.proof-code{font:13px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace}.no-code{padding:16px;border-radius:8px;background:#f8fafc;color:#64748b;font-size:.85rem}",
    ".source-location{display:grid;grid-template-columns:auto minmax(0,1fr);gap:8px;margin-top:12px;padding:9px 11px;border:1px solid #e2e8f0;border-radius:8px;background:#f8fafc;font-size:.72rem}.source-location span{color:#64748b;font-weight:700;text-transform:uppercase}.source-location a,.source-location code{font:11px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;overflow-wrap:anywhere}.source-location a{color:#2563eb;text-decoration:none}.lean-hint{margin-top:9px;font-size:.72rem;color:#94a3b8}",
    ".proof-steps{border-top:1px solid #e5e7eb;background:#fbfcfd}.proof-steps summary{cursor:pointer;padding:18px 26px;font-weight:750}.proof-steps summary span{font-weight:400;color:#64748b;font-size:.82rem;margin-left:8px}.steps-body{padding:0 26px 22px}.step-row{display:grid;grid-template-columns:1fr 1.15fr;border:1px solid #e5e7eb;border-bottom:0}.step-row:last-child{border-bottom:1px solid #e5e7eb}.step-natural,.step-lean{padding:14px;min-width:0}.step-natural{display:flex;gap:10px;border-right:1px solid #e5e7eb}.step-number{display:grid;place-items:center;flex:0 0 24px;height:24px;border-radius:50%;background:#e2e8f0;font-size:.72rem;font-weight:700}",
    "dialog{width:min(680px,calc(100vw - 32px));border:0;border-radius:14px;padding:0;box-shadow:0 24px 80px rgba(15,23,42,.28)}dialog::backdrop{background:rgba(15,23,42,.45)}.dialog-inner{padding:22px}.dialog-top{display:flex;justify-content:space-between;gap:16px}.dialog-top h3{margin:0}.dialog-type{margin-top:14px;padding:10px 12px;border-radius:8px;background:#f1f5f9;font:12px ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap}.dialog-meta{margin-top:10px;font-size:.8rem;color:#64748b}.dialog-body{margin-top:16px;line-height:1.8;white-space:pre-wrap}.dialog-close{border:1px solid #d1d5db;background:#fff;border-radius:8px;padding:6px 10px;cursor:pointer}",
    "@media(max-width:1050px){.app{grid-template-columns:1fr}.sidebar{position:static;height:auto}.split,.step-row{grid-template-columns:1fr}.natural-language,.step-natural{border-right:0;border-bottom:1px solid #e5e7eb}}",
    "</style></head><body>",
    "<div class=\"app\"><aside class=\"sidebar\"><div class=\"brand\">Serre Blueprint</div><nav>", toc, "</nav></aside><main>", content, "</main></div>",
    "<dialog id=\"lean-dialog\"><div class=\"dialog-inner\"><div class=\"dialog-top\"><div><h3 id=\"dialog-title\"></h3><div id=\"dialog-declaration\"></div></div><button id=\"dialog-close\" class=\"dialog-close\">閉じる</button></div><div id=\"dialog-type\" class=\"dialog-type\"></div><div id=\"dialog-meta\" class=\"dialog-meta\"></div><div id=\"dialog-body\" class=\"dialog-body math-text\"></div></div></dialog>",
    "<script>",
    "document.addEventListener('DOMContentLoaded',()=>{",
    " document.querySelectorAll('code.lean-source').forEach(code=>{const start=Number(code.dataset.startLine||1),lines=code.textContent.split('\\n');code.innerHTML='';lines.forEach((line,i)=>{const row=document.createElement('span');row.className='code-row';const no=document.createElement('span');no.className='line-no';no.textContent=String(start+i);const body=document.createElement('span');body.className='line-body';body.innerHTML=window.hljs?hljs.highlight(line,{language:'lean',ignoreIllegals:true}).value:line;row.append(no,body);code.appendChild(row);});});",
    " document.querySelectorAll('code.proof-code').forEach(code=>{if(window.hljs)hljs.highlightElement(code);});",
    " const dialog=document.getElementById('lean-dialog'),title=document.getElementById('dialog-title'),decl=document.getElementById('dialog-declaration'),type=document.getElementById('dialog-type'),meta=document.getElementById('dialog-meta'),body=document.getElementById('dialog-body');",
    " const show=(t,d,ty,desc,src)=>{title.textContent=t;decl.textContent=d;type.textContent=ty||'型情報なし';body.textContent=desc||'';meta.textContent=src?('出典: '+src):'';dialog.showModal();};",
    " document.querySelectorAll('.declaration-button').forEach(b=>b.addEventListener('click',()=>{const s=document.getElementById('explanation-'+b.dataset.entryId);if(!s)return;show(s.querySelector('.exp-title').textContent,s.querySelector('.exp-decl').textContent,'',s.querySelector('.exp-body').textContent,[s.querySelector('.exp-source').textContent,s.querySelector('.exp-path').textContent,s.querySelector('.exp-lines').textContent].filter(Boolean).join(' / '));}));",
    " document.querySelectorAll('code.lean-source').forEach(code=>{const card=code.closest('.entry'),refs=[...card.querySelectorAll('.ref-data')];if(!refs.length)return;refs.forEach(r=>{[...code.querySelectorAll('.line-body')].forEach(line=>{const walker=document.createTreeWalker(line,NodeFilter.SHOW_TEXT),nodes=[];while(walker.nextNode())nodes.push(walker.currentNode);nodes.forEach(node=>{if(!node.nodeValue.includes(r.dataset.name))return;const parts=node.nodeValue.split(r.dataset.name),frag=document.createDocumentFragment();parts.forEach((p,i)=>{if(p)frag.appendChild(document.createTextNode(p));if(i<parts.length-1){const btn=document.createElement('button');btn.className='lean-ref';btn.type='button';btn.textContent=r.dataset.name;btn.addEventListener('click',()=>show(r.dataset.name,r.dataset.name,r.dataset.type,r.dataset.description,r.dataset.source));frag.appendChild(btn);}});node.parentNode.replaceChild(frag,node);});});});});",
    " document.getElementById('dialog-close').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});",
    "});",
    "</script></body></html>"
  ]

end MiniBlueprint
