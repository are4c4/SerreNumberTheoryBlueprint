from pathlib import Path

p = Path("_out/site/html-multi/notion/index.html")
s = p.read_text()

css = """
.proof-status{display:inline-flex;align-items:center;font:600 10px ui-monospace,SFMono-Regular,Menlo,monospace;border:1px solid #454545;border-radius:999px;padding:2px 7px;margin-left:4px}.proof-status.proved{color:#89d185;border-color:#2f6f44;background:#183322}.proof-status.incomplete{color:#f48771;border-color:#8a4038;background:#3a2020}.proof-status.unknown{color:#cca700;border-color:#7a6514;background:#332d13}
"""
if ".proof-status{" not in s:
    s = s.replace("</style>", css + "</style>", 1)

old_target = '<div id="targetRow" class="target-row" hidden><span id="targetBadge" class="target-badge"></span><span id="targetName" class="target-name"></span></div>'
new_target = '<div id="targetRow" class="target-row" hidden><span id="targetBadge" class="target-badge"></span><span id="targetName" class="target-name"></span><span id="proofStatus" class="proof-status" hidden></span></div>'
if old_target in s:
    s = s.replace(old_target, new_target, 1)
elif 'id="proofStatus"' not in s:
    raise SystemExit("target row for proof status badge was not found")

anchor = "function renderRows(rows,text){"
proof_js = r'''async function updateProofStatus(){const badge=document.getElementById('proofStatus');if(!badge)return;badge.hidden=true;badge.className='proof-status';badge.removeAttribute('title');if(targetType!=='decl'||!targetName)return;try{const r=await fetch(`../proof-status.json?v=${Date.now()}`,{cache:'no-store'});if(!r.ok)throw new Error(`HTTP ${r.status}`);const j=await r.json(),items=j.theorems||[];const hit=items.find(x=>x.name===targetName||x.name.endsWith(`.${targetName}`));if(!hit)return;badge.hidden=false;if(hit.status==='proved'){badge.classList.add('proved');badge.textContent='● Proved';badge.title='Lean kernel dependency check: no sorryAx dependency detected.'}else if(hit.status==='incomplete'){badge.classList.add('incomplete');badge.textContent='● Incomplete';badge.title='This theorem transitively depends on sorryAx.'}else{badge.classList.add('unknown');badge.textContent='● Unknown';badge.title='Proof status could not be determined.'}}catch(e){console.warn('proof status',e);badge.hidden=false;badge.classList.add('unknown');badge.textContent='● Unknown';badge.title='proof-status.json could not be loaded.'}}
'''
if "async function updateProofStatus()" not in s:
    if anchor not in s:
        raise SystemExit("renderRows anchor for proof status JS was not found")
    s = s.replace(anchor, proof_js + anchor, 1)

load_anchor = "codeWrap.innerHTML='<div class=\"error\">Loading…</div>';try{const source=await fetchSource();"
load_repl = "codeWrap.innerHTML='<div class=\"error\">Loading…</div>';try{await updateProofStatus();const source=await fetchSource();"
if load_repl not in s:
    if load_anchor not in s:
        raise SystemExit("load anchor for proof status update was not found")
    s = s.replace(load_anchor, load_repl, 1)

p.write_text(s)
