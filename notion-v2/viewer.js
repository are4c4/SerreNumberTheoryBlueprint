(() => {
  const params = new URLSearchParams(location.search);
  const codeWrap = document.getElementById('codeWrap');
  const copyBtn = document.getElementById('copyBtn');
  const fileName = document.getElementById('fileName');
  const githubBtn = document.getElementById('githubBtn');
  const targetRow = document.getElementById('targetRow');
  const targetBadge = document.getElementById('targetBadge');
  const targetName = document.getElementById('targetName');
  const proofStatus = document.getElementById('proofStatus');
  const scopeWrap = document.getElementById('scopeWrap');
  const scopeRow = document.getElementById('scopeRow');
  let displayedCode = '';
  let currentBuildVersion = null;

  const esc = value => String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

  async function getJson(path) {
    const response = await fetch(path + (path.includes('?') ? '&' : '?') + 'v=' + Date.now(), {cache: 'no-store'});
    if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
    return response.json();
  }

  function resolveItem(manifest) {
    const decl = params.get('decl');
    const file = params.get('file');
    const line = Number(params.get('line'));

    if (decl) {
      let id = manifest.declarations[decl];
      if (!id && !decl.includes('.')) {
        const candidates = manifest.shortNames[decl] || [];
        const filtered = file ? candidates.filter(x => manifest.items[x]?.file === file) : candidates;
        if (filtered.length === 1) id = filtered[0];
      }
      if (!id) throw new Error(`Declaration "${decl}" was not found or was ambiguous.`);
      return manifest.items[id];
    }

    if (file && Number.isInteger(line) && line > 0) {
      const ids = manifest.files[file] || [];
      const candidates = ids.map(id => manifest.items[id]).filter(Boolean);
      const containing = candidates
        .filter(item => item.startLine <= line && line <= item.endLine)
        .sort((a, b) => (a.endLine - a.startLine) - (b.endLine - b.startLine))[0];
      if (containing) return containing;

      const previous = candidates
        .filter(item => item.startLine <= line)
        .sort((a, b) => b.startLine - a.startLine)[0];
      if (previous) return previous;
      throw new Error(`No Lean item was found near ${file}:${line}.`);
    }

    throw new Error('Specify ?decl=Full.Name or ?file=...&line=....');
  }

  function updateScopes(scopes) {
    if (!scopes?.length) {
      scopeWrap.hidden = true;
      scopeRow.replaceChildren();
      return;
    }
    scopeWrap.hidden = false;
    scopeRow.innerHTML = scopes.map((scope, index) =>
      `${index ? '<span class="scope-sep">›</span>' : ''}<span class="scope-chip"><span class="scope-kind">${esc(scope.kind)}</span>${esc(scope.name)}</span>`
    ).join('');
  }

  function updateProof(item, statuses) {
    proofStatus.hidden = true;
    proofStatus.className = 'proof-status';
    const names = item.defines || [];
    const theorem = (statuses.theorems || []).find(t => names.includes(t.name));
    if (!theorem) return;
    proofStatus.hidden = false;
    if (theorem.status === 'proved') {
      proofStatus.classList.add('proved');
      proofStatus.textContent = '● Proved';
      proofStatus.title = 'Lean kernel dependency check: no sorryAx dependency detected.';
    } else {
      proofStatus.classList.add('incomplete');
      proofStatus.textContent = '● Incomplete';
      proofStatus.title = 'This theorem transitively depends on sorryAx.';
    }
  }

  function githubUrl(manifest, item) {
    const repo = manifest.github?.repository;
    const ref = manifest.github?.ref || 'main';
    if (!repo) return '';
    return `https://github.com/${repo}/blob/${encodeURIComponent(ref)}/${item.file}#L${item.startLine}`;
  }

  function render(item, manifest, statuses) {
    fileName.textContent = item.file;
    targetRow.hidden = false;
    targetBadge.textContent = item.kind || 'Lean';
    targetName.textContent = item.primaryDeclaration || `${item.module}:${item.startLine}`;
    updateScopes(item.scopes);
    updateProof(item, statuses);

    const gh = githubUrl(manifest, item);
    if (gh) {
      githubBtn.href = gh;
      githubBtn.hidden = false;
    } else {
      githubBtn.hidden = true;
    }

    const rows = item.rows || [];
    displayedCode = item.plainText || rows.map(r => r.text || '').join('\n');
    copyBtn.disabled = false;
    codeWrap.innerHTML = `<div class="code-grid"><pre class="line-nos">${rows.map(r => r.line ?? '').join('\n')}</pre><pre class="code-pre">${rows.map(r => r.context ? `<span class="context-line">${r.html || ''}</span>` : (r.html || '')).join('\n')}</pre></div>`;
  }

  async function load() {
    codeWrap.innerHTML = '<div class="empty">Loading…</div>';
    try {
      const [manifest, statuses] = await Promise.all([
        getJson('data/manifest.json'),
        getJson('proof-status.json').catch(() => ({theorems: []}))
      ]);
      const item = resolveItem(manifest);
      render(item, manifest, statuses);
    } catch (error) {
      codeWrap.innerHTML = `<div class="error">${esc(error.message || error)}</div>`;
    }
  }

  async function getBuildVersion() {
    try {
      const value = await getJson('build-version.json');
      return value.commit || value.version || null;
    } catch {
      return null;
    }
  }

  async function initAutoRefresh() {
    currentBuildVersion = await getBuildVersion();
    setInterval(async () => {
      const next = await getBuildVersion();
      if (next && currentBuildVersion && next !== currentBuildVersion) location.reload();
      else if (next && !currentBuildVersion) currentBuildVersion = next;
    }, 30000);
  }

  document.getElementById('reloadBtn').addEventListener('click', () => location.reload());
  copyBtn.addEventListener('click', async () => {
    if (!displayedCode) return;
    await navigator.clipboard.writeText(displayedCode);
    copyBtn.textContent = 'Copied!';
    setTimeout(() => { copyBtn.textContent = 'Copy'; }, 1200);
  });

  load();
  initAutoRefresh();
})();
