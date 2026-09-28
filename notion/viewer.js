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
    .replace(/\"/g, '&quot;');

  function syntaxHighlightLeanLine(text) {
    const raw = String(text ?? '');
    if (!raw) return '';
    const commentStart = raw.indexOf('--');
    const code = commentStart >= 0 ? raw.slice(0, commentStart) : raw;
    const comment = commentStart >= 0 ? raw.slice(commentStart) : '';
    const keywordPattern = /\b(import|open|namespace|section|end|variable|variables|universe|include|omit|where|by|fun|in|let|if|then|else|match|with|theorem|lemma|def|abbrev|example|instance|structure|class|inductive|noncomputable|private|protected|local|exact|intro|apply|rw|simp|constructor)\b/g;
    const typePattern = /\b(Type|Prop|Sort|Nat|Int|Rat|Field|CharP|Fact|Set)\b/g;
    const literalPattern = /\b(true|false)\b|\b\d+\b/g;
    const highlightedCode = esc(code)
      .replace(keywordPattern, '<span class="lean-token keyword">$1</span>')
      .replace(typePattern, '<span class="lean-token type-like">$1</span>')
      .replace(literalPattern, '<span class="lean-token literal">$&</span>');
    if (!comment) return highlightedCode;
    return `${highlightedCode}<span class="lean-token comment">${esc(comment)}</span>`;
  }

  const qualifiedIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)+$/;

  function isConstantLikeToken(token, semantic) {
    return semantic === 'const'
      || semantic === 'constructor'
      || token.classList.contains('function-like')
      || token.classList.contains('const')
      || token.classList.contains('member-like')
      || token.classList.contains('declaration');
  }

  function classifyLeanToken(token) {
    const semantic = token.dataset.semantic || '';
    if (semantic) token.classList.add(`semantic-${semantic}`);
    if (semantic === 'variable') token.classList.add('variable-token');

    const text = token.textContent || '';
    const constantLike = isConstantLikeToken(token, semantic);
    if (constantLike) token.classList.add('constant-like');

    if (constantLike && token.dataset.definitionSite === 'true') {
      token.classList.add('definition-site');
    }

    if (constantLike && qualifiedIdentifierPattern.test(text)) {
      const lastDot = text.lastIndexOf('.');
      const prefix = document.createElement('span');
      prefix.className = 'lean-qualified-prefix';
      prefix.textContent = text.slice(0, lastDot);
      const dot = document.createElement('span');
      dot.className = 'lean-qualified-dot';
      dot.textContent = '.';
      const member = document.createElement('span');
      member.className = 'lean-qualified-member';
      member.textContent = text.slice(lastDot + 1);
      token.classList.add('qualified-const');
      token.replaceChildren(prefix, dot, member);
      return;
    }

    if (constantLike && /^[A-ZΑ-Ω]/u.test(text)) {
      token.classList.add('type-const');
    }
  }

  function improveLeanTokenHtml(html) {
    const template = document.createElement('template');
    template.innerHTML = html;
    template.content.querySelectorAll('.lean-token').forEach(classifyLeanToken);
    return template.innerHTML;
  }

  function rowHtml(row) {
    const rendered = String(row.html || '');
    const html = rendered.includes('lean-token') ? rendered : syntaxHighlightLeanLine(row.text || '');
    return improveLeanTokenHtml(html);
  }

  function proofStateForItem(item, statuses) {
    const names = item.defines || [];
    return (statuses.theorems || []).find(t => names.includes(t.name)) || null;
  }

  function theoremStartRow(row) {
    if (row.context) return false;
    const trimmed = String(row.text || '').trim();
    return /^(?:(?:noncomputable|private|protected|unsafe|partial)\s+)*(theorem|lemma)\b/.test(trimmed);
  }

  function proofGutterMarker(proofState) {
    if (!proofState) return '';
    const proved = proofState.status === 'proved';
    const className = proved ? 'proved' : 'incomplete';
    const title = proved
      ? 'Proved: Lean kernel dependency check detected no sorryAx dependency.'
      : 'Incomplete: this theorem transitively depends on sorryAx.';
    const symbol = proved ? '✓' : '!';
    const label = proved ? 'Proved' : 'Incomplete';
    return `<span class="proof-gutter-marker ${className}" title="${esc(title)}" aria-label="${esc(label)}">${symbol}</span>`;
  }

  function renderProofGutterRows(rows, proofState) {
    let proofMarkerRendered = false;
    return rows.map(row => {
      if (proofState && !proofMarkerRendered && theoremStartRow(row)) {
        proofMarkerRendered = true;
        return proofGutterMarker(proofState);
      }
      return '<span class="proof-gutter-spacer" aria-hidden="true"></span>';
    }).join('\n');
  }

  async function getJson(path) {
    const response = await fetch(path + (path.includes('?') ? '&' : '?') + 'v=' + Date.now(), {cache: 'no-store'});
    if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
    return response.json();
  }

  function resolveItem(manifest) {
    const decl = params.get('decl');
    const file = params.get('file');
    const line = Number(params.get('line'));
    const section = params.get('section');
    const namespaceName = params.get('namespace');
    const command = params.get('command');

    const legacy = [
      ['section', section],
      ['namespace', namespaceName],
      ['command', command],
    ].filter(([, value]) => value);

    if (legacy.length > 1) {
      throw new Error('Specify only one legacy target: section, namespace, or command.');
    }

    if (legacy.length === 1) {
      const [kind, name] = legacy[0];
      const entries = Object.entries(manifest.legacyTargets || {});
      const suffix = '\u001f' + kind + '\u001f' + name;
      const candidates = entries
        .filter(([key, item]) => key.endsWith(suffix) && (!file || item.file === file))
        .map(([, item]) => item);
      if (candidates.length === 1) return candidates[0];
      if (!candidates.length) throw new Error(`${kind} "${name}" was not found.`);
      throw new Error(`${kind} "${name}" is ambiguous; include ?file=... in the URL.`);
    }

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

    throw new Error('Specify ?decl=Full.Name, ?file=...&line=..., or a legacy section/namespace/command target.');
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

  function updateHeaderProof() {
    proofStatus.hidden = true;
    proofStatus.className = 'proof-status';
    proofStatus.textContent = '';
    proofStatus.title = '';
  }

  function declarationKeyword(item) {
    const rows = item.rows || [];
    for (const row of rows) {
      if (row.context) continue;
      const text = String(row.text || '').trim();
      if (!text) continue;
      const match = text.match(/^(?:(?:noncomputable|private|protected|unsafe|partial)\s+)*(theorem|lemma|def|abbrev|example|instance|structure|class|inductive)\b/);
      if (match) return match[1];
      if (/^local\s+instance\b/.test(text)) return 'instance';
    }
    return '';
  }

  function displayKind(item) {
    const raw = String(item.kind || '').trim();
    const keyword = declarationKeyword(item);
    if (keyword) return keyword;
    if (raw === 'Lean.Parser.Command.declaration') return 'Declaration';
    if (raw === 'local instance') return 'instance';
    if (raw.startsWith('Lean.Parser.Command.')) return raw.slice('Lean.Parser.Command.'.length);
    return raw || 'Lean';
  }

  function githubUrl(manifest, item) {
    const repo = manifest.github?.repository;
    const ref = manifest.github?.ref || 'main';
    if (!repo) return '';
    return `https://github.com/${repo}/blob/${encodeURIComponent(ref)}/${item.file}#L${item.startLine}`;
  }

  function lockReadonlyCaret(codePre) {
    if (!codePre) return;
    const allowedKeys = new Set([
      'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown',
      'Home', 'End', 'PageUp', 'PageDown',
      'Shift', 'Control', 'Alt', 'Meta', 'Escape', 'Tab'
    ]);
    codePre.addEventListener('beforeinput', event => event.preventDefault());
    codePre.addEventListener('paste', event => event.preventDefault());
    codePre.addEventListener('drop', event => event.preventDefault());
    codePre.addEventListener('keydown', event => {
      if (event.metaKey || event.ctrlKey || event.altKey) return;
      if (allowedKeys.has(event.key)) return;
      event.preventDefault();
    });
    codePre.addEventListener('click', () => codePre.focus({preventScroll: true}));
  }

  function renderCodeRows(rows) {
    let inDocComment = false;
    return rows.map(row => {
      const text = String(row.text || '');
      const trimmed = text.trim();
      const startsDocComment = trimmed.startsWith('/--') || trimmed.startsWith('/-!');
      const isDocComment = inDocComment || startsDocComment;
      if (startsDocComment) inDocComment = true;

      const rendered = rowHtml(row);
      const classes = [];
      if (row.context) classes.push('context-line');
      if (isDocComment) classes.push('doc-comment-line');
      const line = classes.length ? `<span class="${classes.join(' ')}">${rendered}</span>` : rendered;

      if (isDocComment && trimmed.endsWith('-/')) inDocComment = false;
      return line;
    }).join('\n');
  }

  function render(item, manifest, statuses) {
    fileName.textContent = item.file;
    targetRow.hidden = false;
    targetBadge.textContent = displayKind(item);
    targetName.textContent = item.primaryDeclaration || `${item.module}:${item.startLine}`;
    updateScopes(item.scopes);
    updateHeaderProof();

    const gh = githubUrl(manifest, item);
    if (gh) {
      githubBtn.href = gh;
      githubBtn.hidden = false;
    } else {
      githubBtn.hidden = true;
    }

    const rows = item.rows || [];
    const proofState = proofStateForItem(item, statuses);
    displayedCode = item.plainText || rows.map(r => r.text || '').join('\n');
    copyBtn.disabled = false;
    codeWrap.innerHTML = `<div class="code-grid"><pre class="proof-gutter" aria-hidden="true">${renderProofGutterRows(rows, proofState)}</pre><pre class="line-nos">${rows.map(r => r.line ?? '').join('\n')}</pre><pre class="code-pre" tabindex="0" contenteditable="plaintext-only" spellcheck="false" aria-label="Lean source code">${renderCodeRows(rows)}</pre></div>`;
    lockReadonlyCaret(codeWrap.querySelector('.code-pre'));
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