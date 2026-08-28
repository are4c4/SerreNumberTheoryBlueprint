#!/usr/bin/env bash

set -euo pipefail

lake exe vbp build

# Build SubVerso semantic highlighting for every module in the main Lean library.
lake build SerreNumberTheory:highlighted
lake build notion-highlight-export

mkdir -p _out/site/html-multi/notion
mkdir -p _out/site/html-multi/notion/link
mkdir -p _out/site/html-multi/notion-data
cp notion-viewer/index.html _out/site/html-multi/notion/index.html

# Add support for anonymous top-level commands such as `local instance`.
# They have no declaration name, so the viewer addresses them by source line:
#   ?file=...&command=203
python3 - <<'PY'
from pathlib import Path
p = Path('_out/site/html-multi/notion/index.html')
s = p.read_text()
repls = [
    (
        "const decl=params.get('decl'),sectionName=params.get('section'),namespaceName=params.get('namespace');\nconst targets=[['decl',decl],['section',sectionName],['namespace',namespaceName]].filter(([,v])=>v),targetType=targets.length===1?targets[0][0]:null,targetName=targets.length===1?targets[0][1]:null;",
        "const decl=params.get('decl'),sectionName=params.get('section'),namespaceName=params.get('namespace'),commandLine=params.get('command');\nconst targets=[['decl',decl],['section',sectionName],['namespace',namespaceName],['command',commandLine]].filter(([,v])=>v),targetType=targets.length===1?targets[0][0]:null,targetName=targets.length===1?targets[0][1]:null;"
    ),
    (
        "function extractScope(source,kind,name){",
        "function extractCommand(source,lineNo){const lines=source.split('\\n'),start=Number(lineNo)-1;if(!Number.isInteger(start)||start<0||start>=lines.length)throw new Error(`Command line \\\"${lineNo}\\\" is invalid.`);if(!/^\\s*local\\s+instance\\b/.test(lines[start]))throw new Error(`No local instance starts at line ${lineNo}.`);let end=start+1;while(end<lines.length&&lines[end].trim()!==''&&!topCommand.test(lines[end]))end++;return{code:lines.slice(start,end).join('\\n'),startLine:start+1,endLine:end}}\nfunction extractScope(source,kind,name){"
    ),
    (
        "if(targetType==='decl'){const base=extractDecl(source,targetName),block=extractDeclDisplay(source,targetName),vars=relevantVars(source,base.startLine,base.code),rows=[];updateScopeHeader(source,base.startLine);for(const v of vars)rows.push({lineNo:v.lineNo,html:fallback(v.text)});if(vars.length)rows.push({lineNo:null,html:''});const html=overlaySemantic(block,data),lines=block.code.split('\\n');for(let i=0;i<lines.length;i++)rows.push({lineNo:block.startLine+i,html:html[i]});renderRows(rows,(vars.length?vars.map(v=>v.text).join('\\n')+'\\n\\n':'')+block.code);return}const block=extractScope(source,targetType,targetName),html=overlaySemantic(block,data);",
        "if(targetType==='decl'){const base=extractDecl(source,targetName),block=extractDeclDisplay(source,targetName),vars=relevantVars(source,base.startLine,base.code),rows=[];updateScopeHeader(source,base.startLine);for(const v of vars)rows.push({lineNo:v.lineNo,html:fallback(v.text)});if(vars.length)rows.push({lineNo:null,html:''});const html=overlaySemantic(block,data),lines=block.code.split('\\n');for(let i=0;i<lines.length;i++)rows.push({lineNo:block.startLine+i,html:html[i]});renderRows(rows,(vars.length?vars.map(v=>v.text).join('\\n')+'\\n\\n':'')+block.code);return}if(targetType==='command'){const block=extractCommand(source,targetName),html=overlaySemantic(block,data);updateScopeHeader(source,block.startLine);document.getElementById('targetBadge').textContent='local instance';document.getElementById('targetName').textContent=`line ${block.startLine}`;renderRows(html.map((h,i)=>({lineNo:block.startLine+i,html:h})),block.code);return}const block=extractScope(source,targetType,targetName),html=overlaySemantic(block,data);"
    ),
]
for old, new in repls:
    if old not in s:
        raise SystemExit(f'viewer patch target not found: {old[:80]}')
    s = s.replace(old, new)
p.write_text(s)
PY

# The viewer polls this file. When a new Pages deployment changes the commit,
# an existing Notion embed reloads itself automatically.
printf '{"commit":"%s"}\n' "${GITHUB_SHA:-local}" > _out/site/html-multi/build-version.json

# Generate the GitHub -> Notion viewer URL helper directly during the Pages build.
cat > _out/site/html-multi/notion/link/index.html <<'HTML'
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Notion Lean URL Generator</title>
<style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#1e1e1e;color:#d4d4d4;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}.wrap{max-width:900px;margin:0 auto;padding:28px 18px}h1{font-size:22px;margin:0 0 8px}.lead{color:#9d9d9d;margin:0 0 22px;line-height:1.6}.card{background:#181818;border:1px solid #3c3c3c;border-radius:10px;padding:16px}.label{display:block;font-size:12px;color:#9d9d9d;margin-bottom:7px}input{width:100%;background:#1e1e1e;color:#d4d4d4;border:1px solid #4a4a4a;border-radius:7px;padding:11px 12px;font:13px ui-monospace,SFMono-Regular,Menlo,monospace}.buttons{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}button,a.btn{appearance:none;border:1px solid #4a4a4a;background:#252526;color:#ddd;border-radius:7px;padding:8px 11px;font-size:12px;text-decoration:none;cursor:pointer}button:hover,a.btn:hover{background:#2d2d30}.result{margin-top:18px;border-top:1px solid #333;padding-top:16px;display:none}.meta{font:12px/1.7 ui-monospace,SFMono-Regular,Menlo,monospace;color:#bdbdbd}.out{margin-top:10px;word-break:break-all;background:#1e1e1e;border:1px solid #3c3c3c;border-radius:7px;padding:10px;font:12px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace}.error{margin-top:12px;color:#f48771;white-space:pre-wrap}.hint{font-size:12px;color:#858585;margin-top:12px;line-height:1.6}
</style>
</head>
<body><main class="wrap"><h1>Notion Lean URL Generator</h1><p class="lead">GitHubで対象行の行番号をクリックし、<code>#L24</code> のような行番号付きURLを貼り付けてください。</p><section class="card"><label class="label" for="gh">GitHub URL</label><input id="gh" placeholder="https://github.com/are4c4/SerreNumberTheoryBlueprint/blob/.../File.lean#L24"><div class="buttons"><button id="make">Notion用URLを生成</button><button id="clear" type="button">クリア</button></div><div id="err" class="error"></div><div id="result" class="result"><div id="meta" class="meta"></div><div id="out" class="out"></div><div class="buttons"><button id="copy">コピー</button><a id="open" class="btn" target="_blank" rel="noopener">表示を開く</a></div></div><p class="hint">対象行、またはその直前にある theorem / lemma / def / local instance / section / namespace を自動検出します。</p></section></main>
<script>
const $=id=>document.getElementById(id);let generated='';
function parseGithub(raw){const u=new URL(raw.trim());if(u.hostname!=='github.com')throw new Error('github.com のURLを貼り付けてください。');const p=u.pathname.split('/').filter(Boolean);if(p.length<5||p[2]!=='blob')throw new Error('GitHub のファイル表示URLを使用してください。');const line=Number((u.hash.match(/L(\d+)/)||[])[1]);if(!line)throw new Error('GitHubで行番号をクリックし、#L24 のような行番号付きURLにしてください。');return{owner:p[0],repo:p[1],ref:decodeURIComponent(p[3]),file:p.slice(4).map(decodeURIComponent).join('/'),line}}
function findTarget(lines,line){const decl=/^\s*(?:@\[[^\]]*\]\s*)?(?:(?:noncomputable|private|protected)\s+)*(theorem|lemma|example|def|abbrev|instance|structure|class|inductive)\s+([^\s(:{]+)/;const localInstance=/^\s*local\s+instance\b/;const scope=/^\s*(section|namespace)\s+([^\s]+)\b/;for(let i=Math.min(line-1,lines.length-1);i>=0;i--){if(localInstance.test(lines[i]))return{type:'command',name:String(i+1),label:'local instance',line:i+1};const d=lines[i].match(decl);if(d)return{type:'decl',name:d[2],label:d[2],line:i+1};const s=lines[i].match(scope);if(s)return{type:s[1],name:s[2],label:s[2],line:i+1};if(line-1-i>80)break}throw new Error('近くに theorem / lemma / def / local instance / section / namespace が見つかりませんでした。')}
$('make').onclick=async()=>{generated='';$('err').textContent='';$('result').style.display='none';try{const x=parseGithub($('gh').value);if(x.owner!=='are4c4'||x.repo!=='SerreNumberTheoryBlueprint')throw new Error('SerreNumberTheoryBlueprint のGitHub URLを使用してください。');const raw=`https://raw.githubusercontent.com/${x.owner}/${x.repo}/${encodeURIComponent(x.ref)}/${x.file.split('/').map(encodeURIComponent).join('/')}`;const r=await fetch(raw,{cache:'no-store'});if(!r.ok)throw new Error(`Leanファイルを取得できませんでした (HTTP ${r.status})`);const lines=(await r.text()).split('\n'),t=findTarget(lines,x.line);const q=new URLSearchParams({file:x.file,[t.type]:t.name});generated=`https://are4c4.github.io/SerreNumberTheoryBlueprint/notion/?${q}`;$('meta').textContent=`${t.type==='command'?'local instance':t.type}: ${t.label}  |  ${x.file}:${t.line}`;$('out').textContent=generated;$('open').href=generated;$('result').style.display='block'}catch(e){$('err').textContent=String(e.message||e)}};
$('clear').onclick=()=>{generated='';$('gh').value='';$('err').textContent='';$('meta').textContent='';$('out').textContent='';$('open').removeAttribute('href');$('result').style.display='none';$('gh').focus()};
$('copy').onclick=async()=>{if(!generated)return;await navigator.clipboard.writeText(generated);$('copy').textContent='コピーしました';setTimeout(()=>$('copy').textContent='コピー',1200)};
</script></body></html>
HTML

# Convert highlighted source JSON into a lightweight format the browser can render.
while IFS= read -r src; do
  rel="${src#.lake/build/highlighted/}"
  module="${rel%.json}"
  module="${module//\//.}"
  out="_out/site/html-multi/notion-data/${module}.json"
  lake exe notion-highlight-export "$src" "$out"
done < <(find .lake/build/highlighted/SerreNumberTheory/Formalization -type f -name '*.json' | sort)

test -f _out/site/html-multi/index.html
test -f _out/site/html-multi/notion/index.html
test -f _out/site/html-multi/notion/link/index.html
test -f _out/site/html-multi/build-version.json
test -f _out/site/html-multi/notion-data/SerreNumberTheory.Formalization.Chapter01.F010101FiniteFields.json
test -f _out/site/html-multi/-verso-data/blueprint-manifest.json
test -f _out/site/html-multi/-verso-data/blueprint-html-cache.json
